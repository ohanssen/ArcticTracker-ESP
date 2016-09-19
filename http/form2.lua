


local function label(con, id, attr)
  con:send('<label for="'..id..'" class="leftlab">'..attr..'</label>\n')
end


local function sendAttr(conn, id, attr, val)
  conn:send('<label for="'.. id .. '" class="leftlab">'.. attr .. '</label>\n')
  conn:send('<label id="'.. id .. '"> ' .. val .. '</label>\n')
end


local function apFieldI(con, id, i, attr)
   local val = mcu_getParam(id .. i)
   local ssid, passwd = string.match(val, "([^,]*),([^,]*)")
   if (ssid == '-') then
       ssid = ''
   end
   if (passwd == '-') then
       passwd = ''
   end
   label(con, id, attr)
   con:send('<input type="text" id="'..id..i..'_ssid'..'" name="'..id..i..'_ssid'..'" size="15" value="'..ssid..'" />\n')
   con:send('<input type="text" id="'..id..i..'_pwd'..'" name="'..id..i..'_pwd'..'" size="15" value="'..passwd..'" />\n')
end


local function textField(con, id, size, attr, val)
  con:send('<label for="'..id..'" class="leftlab">'..attr..'</label>\n')
  con:send('<input type="text" id="'..id..'" name="'..id..'" size="'..size..'" value="'..val..'" />\n')
end

local function textFieldR(con, id, size, pattern, attr)
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
     <link rel="stylesheet" href="style.css.gz" type="text/css"></head><body><h2>WIFI settings</h2>
   ]===])
  
   if req.method == "GET" then
     con:send('<form action="submit2.lua" method="POST"><fieldset>')
     apFieldI(con, "WIFIAP", 0, 'AP 1 (ssid,passwd):');        br(con)
     apFieldI(con, "WIFIAP", 1, 'AP 2 (ssid,passwd):');        br(con)
     apFieldI(con, "WIFIAP", 2, 'AP 3 (ssid,passwd):');        br(con)
     apFieldI(con, "WIFIAP", 3, 'AP 4 (ssid,passwd):');        br(con)
     apFieldI(con, "WIFIAP", 4, 'AP 5 (ssid,passwd):');        br(con)
     apFieldI(con, "WIFIAP", 5, 'AP 6 (ssid,passwd):');        br(con)
     br(con)
     sendAttr(con, "ap_ssid",   'Soft AP SSID:', wifiConf.accessPoint.ssid)
     textField(con, "SOFTAP_PASSWD", 15,  'Soft AP password:', wifiConf.accessPoint.pwd)
     br(con); br(con)
     textFieldR(con, "HTTP_USER", 15, "[a-zA-Z0-9\-]+",   'Webserver username:' ); br(con)
     textFieldR(con, "HTTP_PASSWD", 15, ".*", 'Webserver password:')
     
     con:send('</fieldset> <button type="submit" name="update" id="update">Update\n')
     con:send('</button></form>\n')

   else
     con:send("ERROR. req.method is ", req.method)
   end
   con:send('</body></html>\n')
   collectgarbage()
end



