######################################################################
# User configuration
######################################################################
# Path to nodemcu-uploader (https://github.com/kmpm/nodemcu-uploader)
NODEMCU-UPLOADER=/usr/local/bin/nodemcu
# Serial port
PORT=/dev/ttyUSB0
SPEED=115200

######################################################################
# End of user config
######################################################################
HTTP_FILES := \
   http/index.html.gz \
   http/file_list.lua \
   http/node_info.lua \
   http/form1.lua \
   http/form2.lua \
   http/form3.lua \
   http/submit1.lua \
   http/submit2.lua \
   http/submit3.lua \
   http/style.css.gz \
   http/config_menu.css.gz 
   
LUA_FILES := \
   init.lua \
   scanap.lua \
   network.lua \
   commands.lua \
   httpserver.lua \
   httpserver-b64decode.lua \
   httpserver-basicauth.lua \
   httpserver-conf.lua \
   httpserver-connection.lua \
   httpserver-error.lua \
   httpserver-header.lua \
   httpserver-request.lua \
   httpserver-static.lua \

# Print usage
usage:
	@echo "make upload FILE:=<file>  to upload a specific file (i.e make upload FILE:=init.lua)"
	@echo "make upload_http          to upload files to be served"
	@echo "make upload_server        to upload the server code and init.lua"
	@echo "make upload_all           to upload all"
	@echo $(TEST)

# Upload one files only
upload:
	@python $(NODEMCU-UPLOADER) --start_baud $(SPEED) -p $(PORT) upload $(FILE)

	
http/index.html.gz: http/index.html
	gzip -f -k http/index.html

http/style.css.gz: http/style.css
	gzip -f -k http/style.css
	
http/config_menu.css.gz: http/config_menu.css	
	gzip -f -k http/config_menu.css
	
# Upload HTTP files only
upload_http: $(HTTP_FILES)
	@python $(NODEMCU-UPLOADER) --start_baud $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f))

# Upload httpserver lua files (init and server module)
upload_server: $(LUA_FILES)
	@python $(NODEMCU-UPLOADER) --start_baud $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f))

# Upload all
upload_all: $(LUA_FILES) $(HTTP_FILES)
	@python $(NODEMCU-UPLOADER) --start_baud $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f))

