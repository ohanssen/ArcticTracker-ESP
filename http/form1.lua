
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
     <link rel="stylesheet" href="style.css.gz" type="text/css"></head><body><h2>APRS settings</h2>
   ]===])
  
   if req.method == "GET" then
     con:send('<form action="submit1.lua" method="POST"><fieldset>')
     textField(con, "MYCALL",        10, "[a-zA-Z0-9\-]+",                       'My Callsign:');        br(con)
     textField(con, "SYMBOL",        2,  "..",                                   'Symbol (tab/sym):');   br(con)
     textField(con, "REPORT_COMMENT",30, ".*",                                   'Report comment:');     br(con)
     textField(con, "DIGIS",         30, "([a-zA-Z0-9\-]+)(\,([a-zA-Z0-9\-]+)*", 'Digipeater path:');    br(con)
     textField(con, "TRX_TX_FREQ",   10, "[0-9]+\.[0-9]+",                       'TX frequency:');       br(con)
     textField(con, "TRX_RX_FREQ",   10, "[0-9]+\.[0-9]+",                       'RX frequency:');       br(con)
     br(con)
     label(con,"TIMESTAMP", "Tracking attributes:")
     checkbox(con, "TIMESTAMP", "Timestamp")
     checkbox(con, "COMPRESS", "Compress")
     checkbox(con, "ALTITUDE", "Altitude")
     br(con)
     textField(con, "TRACKER_TURN_LIMIT",   5, "[0-9]+",          'Turn limit (degrees):');       br(con)
     textField(con, "TRACKER_MAXPAUSE",     5, "[0-9]+",          'Max pause (seconds):');        br(con)
     textField(con, "TRACKER_MINPAUSE",     5, "[0-9]+",          'Min pause (seconds):');        br(con)
     textField(con, "TRACKER_MINDIST",     5, "[0-9]+",          'Min distance (meters):');        br(con)
     
     con:send('</fieldset> <button type="submit" name="update" id="update">Update\n')
     con:send('</button></form>\n')

   else
     con:send("ERROR. req.method is ", req.method)
   end
   con:send('</body></html>\n')
end



