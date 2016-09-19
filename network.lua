

return function (host, port)
 
  local function _connect(host, port) 
     srv = net.createConnection(net.TCP, 0)
     srv:connect(port, host)
     srv:on("connection", function(sck, c)
       sock = sck
       mcu_sendResponse("OK")
     end)
    
     srv:on("disconnection", function(sck, c)
        if (not not sock) then
          uart.write(0, "!\r\n")
        else
          mcu_sendResponse("ERROR 1")
        end
        sock = nil
     end)

     srv:on("receive", function(sck, c)
       mcu_sendData(c)
     end)
  end   
  
  
  if string.match(host, "[0-9\.]+") then
     _connect(host, port)
  else
     net.dns.resolve(host, function(sk, ip)
        if (not ip) then 
           mcu_sendResponse("ERROR 2") 
        else 
           _connect(ip, port);
        end
     end)
  end
end
