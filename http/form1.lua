local function sendAttr(con, id, attr, val)
   con:send('<label for="'.. id .. '" class="leftlab">'.. attr .. '</label>\n')
   con:send('<label id="'.. id .. '"> ' .. val .. '</label>\n')
end


local function textField(con, id, size, pattern, attr, val)
   con:send('<label for="'..id..'" class="leftlab">'..attr..'</label>\n')
   con:send('<input type="text" id="'..id..'" name="'..id..'" size="'..size..'" pattern="'..pattern..'" value="'..val..'" />\n')
end


local function br(con)
  con:send("<br/>")
end


return function (con, req, args)
   dofile("httpserver-header.lc")(con, 200, 'html')
   con:send( [===[
     <!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
     <title>Arctic Tracker</title>
     <link rel="stylesheet" href="style.css" type="text/css"></head><body><h2>APRS settings</h2>
   ]===])
   
   if req.method == "GET" then
     con:send('<form method="POST"><fieldset>')
     textField(con, "MYCALL",     10, "[a-zA-Z0-9\-]+",                       'My Callsign:',      mcu_getParam('MYCALL')); br(con)
     textField(con, "DEST",       10, "[a-zA-Z0-9\-]+",                       'Destination addr:', mcu_getParam('DEST'));   br(con)
     textField(con, "DIGIS",      20, "([a-zA-Z0-9\-]+)(\,([a-zA-Z0-9\-]+)*", 'Digipeater path:',  mcu_getParam('DIGIS'));  br(con)
     textField(con, "TRX_TX_FREQ",10, "[0-9]+\.[0-9]+",                       'TX frequency:',     mcu_getParam('TRX_TX_FREQ')); br(con)
     textField(con, "TRX_RX_FREQ",10, "[0-9]+\.[0-9]+",                       'RX frequency:',     mcu_getParam('TRX_RX_FREQ'))
     
     con:send('</fieldset> <button type="submit" name="update" id="update">Update</button>\n')
     
   -- Submit button pressed   
   elseif req.method == "POST" then
     local rd = req.getRequestData()
     con:send('<fieldset><h4>Received the following values:</h4>\n')
     for name, value in pairs(rd) do
       -- Input should be sanitized. Either here or on the Teensy
       local result = mcu_setParam(name, value)
       con:send('Set <b>' .. name .. '</b> = ' .. tostring(value) .. " : " .. result .. "<br>\n")
     end
     con:send("</fieldset>\n")
     
   else
     con:send("ERROR. req.method is ", req.method)
   end
   con:send('</form></body></html>\n')
end





