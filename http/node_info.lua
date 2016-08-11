local function sendAttr(conn, id, attr, val)
   conn:send('<label for="'.. id .. '" class="leftlab">'.. attr .. '</label>\n')
   conn:send('<label id="'.. id .. '"> ' .. val .. '</label>\n')
end




return function (conn, req, args)
   dofile("httpserver-header.lc")(conn, 200, 'html')
   
   conn:send('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>A Lua script sample</title>')
   conn:send('<link rel="stylesheet" href="style.css.gz" type="text/css"></head><body><h2>Node info</h2>')
   conn:send('<fieldset>')

   local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info();
   
   sendAttr(conn, "nodever",   "NodeMCU version:"      , majorVer.."."..minorVer.."."..devVer)
   sendAttr(conn, "chipid",    "Chip id:"              , chipid)
   sendAttr(conn, "flashsize", "Flash size:"           , flashsize)
   sendAttr(conn, "heap",      "Free heap space:"      , node.heap())
   sendAttr(conn, "ipaddr",    'IP address:'           , wifi.sta.getip())
   sendAttr(conn, "macaddr",   'MAC address:'          , wifi.sta.getmac())
   sendAttr(conn, "ap_ssid",   'AP SSID:'              , wifiConf.accessPoint.ssid)
   sendAttr(conn, "ap_ip",     "AP IP address"         , wifi.ap.getip())
   sendAttr(conn, "mycall",    'Mycall:'               , mcu_getParam('MYCALL'))
   sendAttr(conn, "dest",      'Dest addr:'            , mcu_getParam('DEST'))
   sendAttr(conn, "sym",       'Symbol (tab/sym):'     , mcu_getParam('SYMBOL'))
   sendAttr(conn, "digipath",  'Digipeater path:'      , mcu_getParam('DIGIS'))
   sendAttr(conn, "tfreq",     'TX frequency:'         , mcu_getParam('TRX_TX_FREQ'))
   
   conn:send('</fieldset></body></html>')
end









