
local function sendAttr(con, id, attr, val)
   con:send('<label for="'.. id .. '" class="leftlab">'.. attr .. '</label>\n')
   con:send('<label id="'.. id .. '"> ' .. val .. '</label>\n')
end


local function label(con, id, attr)
  con:send('<label for="'..id..'" class="leftlab">'..attr..'</label>\n')
end


local function checkbox(con, id, attr)
   local checked = ""
   if (mcu_getParam(id) == "ON") then
     checked = 'checked'
   end
   con:send('<input type="checkbox" id="'..id..'" name="'..id.. '" value="true" '..checked..'/>'..attr..'\n')
end
  
local function textField(con, id, size, pattern, attr)
   val = mcu_getParam(id)
   label(con, id, attr)
   con:send('<input type="text" id="'..id..'" name="'..id..'" size="'..size..'" pattern="'..pattern..'" value="'..val..'" />\n')
end


local function br(con)
  con:send("<br/>\n")
end






return function (con, req, args)
     
   dofile("httpserver-header.lc")(con, 200, 'html')
   con:send( [===[
     <!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
     <title>Arctic Tracker</title>
     <link rel="stylesheet" href="style.css.gz" type="text/css"></head><body><h2>Digipeater/Igate settings</h2>
   ]===])
  
   if req.method == "GET" then
     con:send('<form action="submit3.lua" method="POST"><fieldset>')
     
     label(con,"DIGIPEATER_ON", "<b>Digipeater:</b>")
     checkbox(con, "DIGIPEATER_ON", "Activate")
     br(con)
     label(con,"DIGIP_WIDE1_ON", "Digipeating modes:")
     checkbox(con, "DIGIP_WIDE1_ON", "Wide-1 (fill-in)")
     checkbox(con, "DIGIP_SAR_ON", "Preemption on 'SAR'")
     br(con)
     br(con)
     label(con,"IGATE_ON", "<b>Internet gate:</b>")
     checkbox(con, "IGATE_ON", "Activate")
     br(con)
     textField(con, "IGATE_HOST",     30, "[a-zA-Z0-9\-\.]+",       'APRS/IS server:');  br(con)
     textField(con, "IGATE_PORT",      6, "[0-9]+",                 'Port:');            br(con)
     textField(con, "IGATE_USERNAME", 10, "[a-zA-Z0-9\-\.]+",       'Username :');       br(con)
     textField(con, "IGATE_PASSCODE",  6, "[0-9]+",                 'Passcode:');        br(con)
     
     con:send('</fieldset> <button type="submit" name="update" id="update">Update\n')
     con:send('</button></form>\n')

   else
     con:send("ERROR. req.method is ", req.method)
   end
   con:send('</body></html>\n')
   collectgarbage()
end



