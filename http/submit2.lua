 

local ssid = {}
local passwd = {}


local function updateField(con, name, value)
  local result = mcu_setParam(name, tostring(value))
  local class="ok"
  if string.match(result, "ERROR.*") then
    class="error"
  end
  con:send('Set <b>' .. name .. '</b> = ' .. tostring(value) .. ' : <span class="'..class..'"> ' .. result .. '</span><br>\n')
end


local function br(con)
  con:send("<br/>\n")
end



return function (con, req, args)

   dofile("httpserver-header.lc")(con, 200, 'html')
   con:send( [===[
     <!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
     <title>Arctic Tracker</title>
     <link rel="stylesheet" href="style.css.gz" type="text/css"></head><body><h2>WIFI settings</h2>
     ]===])
     
        
   if req.method == "POST" then
      local rd = req.getRequestData()
      con:send('<fieldset><h4>Received the following values:</h4>\n')
      mcu_setParam('WIFIAP_RESET', "")
      for name, value in pairs(rd) do
          local n1,n2 = string.match(name, '(WIFIAP[0-9])_(.*)')
          if (not not n1) then
            if (n2 == 'ssid') then
               ssid[n1] = value
            end
            if (n2 == 'pwd') then
              passwd[n1] = value
            end
          else
             updateField(con, name, value)
          end
      end
      for key,val in pairs(ssid) do 
         updateField(con, key, val..','..passwd[key])
      end
      con:send("</fieldset>\n"..node.heap().."\n")
      
    else
      con:send("ERROR. req.method is ", req.method)
    end
    
    con:send('</body></html>\n')
    ssid = nil
    passwd = nil
    collectgarbage()
  end
  
  
  
  