

-- -------------------------------------
--  Begin WiFi configuration
-- -------------------------------------

wifiConf = {}

-- wifi.STATION         -- station: join a WiFi network
-- wifi.SOFTAP          -- access point: create a WiFi network
-- wifi.wifi.STATIONAP  -- both station and access point

wifiConf.mode = wifi.STATIONAP  -- both station and access point

wifiConf.accessPoint = {}
wifiConf.accessPoint.ssid = "Arctic-"..node.chipid()   -- Name of the SSID you want to create
wifiConf.accessPoint.pwd  = "password"                 -- WiFi password - at least 8 characters

wifiConf.accessPointIp = {}
wifiConf.accessPointIp.ip      = "192.168.111.1"
wifiConf.accessPointIp.netmask = "255.255.255.0"
wifiConf.accessPointIp.gateway = "192.168.111.1"


-- wifiConf = nil
collectgarbage()

-- End WiFi configuration

-- ---------------------------------------------------------------------
-- Compile server code and remove original .lua files.
-- This only happens the first time afer the .lua files are uploaded.
-- ---------------------------------------------------------------------

local compileAndRemoveIfNeeded = function(f)
   if file.open(f) then
      file.close()
      print('Compiling:', f)
      node.compile(f)
      file.remove(f)
      collectgarbage()
   end
end

local serverFiles = {
   'httpserver.lua',
   'httpserver-b64decode.lua',
   'httpserver-basicauth.lua',
   'httpserver-conf.lua',
   'httpserver-connection.lua',
   'httpserver-error.lua',
   'httpserver-header.lua',
   'httpserver-request.lua',
   'httpserver-static.lua',
}
for i, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()


-- --------------------------------------------------------------------------------------------
--  Scan for available access points and 
--  Try to connect to the first access point that is registered on MCU (with a password).
--
--    FIXME: Check RSSI and select the best if there are more than one. Consider 
--    adding a priority parameter. 
-----------------------------------------------------------------------------------------------

shell = false
cr = nil

function scanAp()
   if (not not shell) then
     return
   end
   if (wifiConf.mode == wifi.STATION) or (wifiConf.mode == wifi.STATIONAP) then
      wifi.sta.getap(1, function(t)
      
         -- Since mcu_checkAp is "blocking", we need to do this in a coroutine
         local cr = coroutine.create(function(t)
            local ap = {}
            ap.passwd = nil
            ap.i = 999
            ap.rssi = -999;
            
            for bssid,v in pairs(t) do
               local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
               local i, passwd = string.match(mcu_checkAp(ssid), "([^,]+),([^,]+)")
               if (passwd == "_OPEN_") then
                  passwd = ""
               end
               if not (i == "999") then 
                  if ((tonumber(i) < ap.i) and (tonumber(rssi) > -80)) or 
                     ((tonumber(rssi) > -80) and (ap.rssi < -80)) or (ap.i == 999) then
                      ap.i = tonumber(i)
                      ap.ssid = ssid
                      ap.rssi = tonumber(rssi)
                      ap.passwd = passwd
                  end
               end
            end
          
            if (not not ap.passwd) then
               local ssid, pwd, bssid_set, bssid = wifi.sta.getconfig()
               if  not (ssid == ap.ssid) or not (pwd == ap.passwd) or not (wifi.sta.status() == 5 ) then
                   wifi.sta.config(ap.ssid, ap.passwd, 1)
               end
            else
               wifi.sta.disconnect()  
            end
         end ) 
         coroutine.resume(cr, t)
         
      end )
   end
   collectgarbage()
end



-- -----------------------------------------------------------
--  Send response to main mcu
-- -----------------------------------------------------------

function mcu_sendResponse(r)
  if (not r) then
     uart.write(0, "#-\r\n")
  else
     uart.write(0, "#" .. r .. "\r\n")
  end
end



-- --------------------------------------------------------------
-- Do a command on the main MCU (Teensy)
-- Read and return a parameter value
-- Write a parameter value 
-- --------------------------------------------------------------

function mcu_doCommand(c)
  uart.write(0, "#" .. c .. "\r\n")
  cr = coroutine.running()
  client = true
  return coroutine.yield()
end

function mcu_getParam(p)
   return mcu_doCommand("R " .. p)
end

function mcu_setParam(p, val)
   return mcu_doCommand("W " .. p .. " " .. val)
end


-- --------------------------------------------------------------
-- Check if access point (ssid) is approved and return password
--   nil if not found
--   Empty string if access point is open 
-- --------------------------------------------------------------

function mcu_checkAp(ssid)
   return mcu_doCommand("A " .. ssid .. " ")
end



-- ------------------------------
--  List files
-- ------------------------------

function ls(arg)
  for k,v in pairs(file.list()) do 
    if string.match(k,arg) then 
      print(k.." ("..v.." bytes)") 
    end
  end
end



-- -----------------------------------------
-- Listen for data on serial port
-- -----------------------------------------

function mcu_listen(func)
  uart.on("data", "\r", func, 0)
end



-- ------------------------------------------------------------------------------
-- Start a listener for events from the serial port. 
-- Can listen for commands (from main MCU) or responses to commands (from ESP)
-- ------------------------------------------------------------------------------

client = false

listener = coroutine.create( function()
   while true do
      shell = false
      mcu_listen(function(data) 
         data = string.sub(data,0,-2)
         if (client) then
	    -- CLIENT MODE: Get responses from main MCU. Return result to 
	    -- coroutine that initiated the command. 
            client = false
            coroutine.resume(cr, data)
         else
	    -- SERVER MODE: Get and respond to commands from main MCU
            -- Return to shell
            if string.match(data, "^SHELL") then
               -- unregister callback function
               uart.on("data")
               shell = true
               print("Returning to NODEMCU shell")
            
            -- Show status
            elseif string.match(data, "^STAT") then
               mcu_sendResponse(wifi.sta.status())
           
            -- Show config
            elseif string.match(data, "^CONF") then
               ssid, password, bssid_set, bssid = wifi.sta.getconfig()
               if not (wifi.sta.status() == 5) then
                  mcu_sendResponse("-")
               else
                  mcu_sendResponse(ssid .. " (" .. bssid .. ")")
               end
               
            -- Show IP address
            elseif string.match(data, "^IP") then
               mcu_sendResponse(wifi.sta.getip())
            
            -- Show mac address
            elseif string.match(data, "^MAC") then
               mcu_sendResponse(wifi.sta.getmac())   
            
               -- Show AP IP address
            elseif string.match(data, "^AP.IP") then
               mcu_sendResponse(wifi.ap.getip())
               
            elseif string.match(data, "^AP.SSID") then
               mcu_sendResponse(wifiConf.accessPoint.ssid);   
              
            else
               print("Unknown command: ", data)
            end
         end
      end )
      coroutine.yield()
   end
end )




-- -------------------------------------------------------------------------
-- Configure WIFI AP and tell the chip to connect to the access point
-- -------------------------------------------------------------------------

wifi.setmode(wifiConf.mode)
print('set (mode='..wifi.getmode()..')')


tmr.alarm(1, 3000, tmr.ALARM_SINGLE, function () 
  scanAp()
  tmr.alarm(1, 30000, tmr.ALARM_AUTO, scanAp)
end )

-- Tell main MCU that we are booted and ready
uart.write(0, "$__BOOT__\r\n")



start_softap = function(ssid, passwd)
  if (wifiConf.mode == wifi.SOFTAP) or (wifiConf.mode == wifi.STATIONAP) then
     if not (ssid == "Arctic-NOCALL") then
        wifiConf.accessPoint.ssid = ssid
     end
     wifiConf.accessPoint.pwd = passwd
     
     wifi.ap.config(wifiConf.accessPoint)
     wifi.ap.setip(wifiConf.accessPointIp)
  end
  start_softap = nil
end



-- -------------------------------------------------------------------
-- Function to start the web server on port 80
-- It is called only once so it will be deleted after use
-- -------------------------------------------------------------------

start_http_server = function(uname, passwd) 
   tmr.alarm(2, 10000, tmr.ALARM_AUTO, function()
      if (not not wifi.sta.getip()) or (not not wifi.ap.getip()) then
         dofile("httpserver.lc")(80, uname, passwd)
         tmr.unregister(2)
         start_http_server = nil
      end 
   end )
end

collectgarbage()











