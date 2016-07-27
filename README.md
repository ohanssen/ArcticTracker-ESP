# ArcticTracker-ESP

Arctic Tracker is an APRS tracker platform based on the Teensy 3.2
MCU module, a SR_FRS_1W VHF transceiver module and a ESP8266 WIFI module
(ESP-12) with NodeMCU. The ESP module will function as a WIFI interface, 
a webserver and possibly a storage for data files. A small display
and a PA module will also be condidered. 

See http://www.hamlabs.no for more info about this project. 

This repository contains the LUA scripts (and CSS/HTML code) to 
be uploaded to the WIFI module. The features implemented include: 

* HTTP server (based on nodemcu-httpserver by Marcos Kirsch). 
* Establish connection to a WIFI access point. It queries
  the Teensy for info about configured APs. It will also 
  act as a AP. 
* Send commands to the teensy over the serial line, mainly 
  to read or write settings. 
* Receive commands from the Teensy over the serial line... 