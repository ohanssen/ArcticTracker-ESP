 

local cbox = {}

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
   cbox["IGATE_ON"] = false
   cbox["DIGIPEATER_ON"] = false
   cbox["DIGIP_WIDE1_ON"] = false
   cbox["DIGIP_SAR_ON"] = false

   dofile("httpserver-header.lc")(con, 200, 'html')
   con:send( [===[
     <!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
     <title>Arctic Tracker</title>
     <link rel="stylesheet" href="style.css.gz" type="text/css"></head><body><h2>Igate settings</h2>
     ]===])
     
     
   if req.method == "POST" then
      local rd = req.getRequestData()
      con:send('<fieldset><h4>Received the following values:</h4>\n')
      for name, value in pairs(rd) do
        -- Input should be sanitized. Either here or on the Teensy
        
        if (value=="true") then
          cbox[name] = true
        else
          updateField(con, name, value)
        end
      end
      for key,val in pairs(cbox) do
        updateField(con, key, val)
      end 
      con:send("</fieldset>\n"..node.heap().."\n")
      
    else
      con:send("ERROR. req.method is ", req.method)
    end
    
    con:send('</body></html>\n')
    cbox = nil
    collectgarbage()
  end
  
  
  
  
