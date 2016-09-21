 


return function ()
  
  
  -- -----------------------------------------------------------
  --  Send response to main mcu
  -- -----------------------------------------------------------
  
  function mcu_sendResponse(r)
    if (not r) then
       uart.write(0, "@-\r\n")
    else
       uart.write(0, "@" .. r .. "\r\n")
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
  
  function mcu_sendData(d)
    uart.write(0, ":" .. d .. "\r\n")
  end
  
  
  -- --------------------------------------------------------------
  -- Check if access point (ssid) is approved and return password
  --   nil if not found
  --   Empty string if access point is open 
  -- --------------------------------------------------------------
  
  function mcu_checkAp(ssid)
     return mcu_doCommand("A " .. ssid .. " ")
  end
  
  
  -- -----------------------------------------
  -- Listen for data on serial port
  -- -----------------------------------------
  
  function mcu_listen(func)
     uart.on("data", "\r", func, 0)
  end
  
  
  -- ----------------------------------------
  --  Open a socket and start a connection
  -- ----------------------------------------
srv = nil
sock = nil
  
  function net_connect(host, port)
     dofile("network.lc")(host, port)
  end
  
  function net_data(d)
     sock:send(d, function() 
       mcu_sendResponse("OK");
     end)
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
            if string.match(data, "^SHELL=1") then
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
      
               elseif string.match(data, "^NET.OPEN .*") then
                   local port,host = string.match(data, "NET.OPEN ([0-9]+) (.*)")
                   net_connect(host, port)
      
               elseif string.match(data, "^NET.DATA .*") then
                   print("'"..data.."'")
                   if  (not not sock) then
                      local dt = string.match(data, "NET.DATA (.*)")
                      if (not dt) then
                        net_data("\r\n")
                      else
                        net_data(dt.."\r\n")
                      end
                   end   
      
               elseif string.match(data, "^NET.CLOSE") then
                   if (not not sock) then
                      sock:close()
                   end
                   mcu_sendResponse("OK");
           
               else
                   print("Unknown command: ", data)
            end
         end
     end )
     coroutine.yield()
   end
end )


end