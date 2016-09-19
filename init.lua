

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
   'network.lua',
   'commands.lua',
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



-- ------------------------------------------------------------------------------
-- Start a listener for events from the serial port. 
-- ------------------------------------------------------------------------------

dofile("commands.lc")()



-- -------------------------------------------------------------------------
-- Configure WIFI AP and tell the chip to connect to the access point
-- -------------------------------------------------------------------------

wifi.setmode(wifiConf.mode)
print('set (mode='..wifi.getmode()..')')


tmr.alarm(1, 3000, tmr.ALARM_SINGLE, function () 
  scanAp()
  tmr.alarm(1, 30000, tmr.ALARM_AUTO, scanAp)
end )


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

-- Tell main MCU that we are booted and ready
uart.write(0, "$__BOOT__\r\n")











