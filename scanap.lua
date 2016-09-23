 

-- --------------------------------------------------------------------------------------------
--  Scan for available access points and 
--  Try to connect to the first access point that is registered on MCU (with a password).
-----------------------------------------------------------------------------------------------


return function() 
  
  shell = false
  cr = nil

  
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


