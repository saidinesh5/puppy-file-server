
# Puppy File Server (https://github.com/saidinesh5/puppy-file-server)
# Copyright (c) 2012 Dinesh Manajipet <saidinesh5@gmail.com>

APP_NAME = puppy-file-server

all:
	true

install:
	mkdir -p $(DESTDIR)/opt/$(APP_NAME)/
	cp *.qml *.png *.html *.py $(DESTDIR)/opt/$(APP_NAME)/
	cp -r cgi-bin $(DESTDIR)/opt/$(APP_NAME)/
	cp -r css $(DESTDIR)/opt/$(APP_NAME)/
	cp -r files $(DESTDIR)/opt/$(APP_NAME)/
	cp -r img $(DESTDIR)/opt/$(APP_NAME)/
	cp -r jquery $(DESTDIR)/opt/$(APP_NAME)/
	cp -r js $(DESTDIR)/opt/$(APP_NAME)/
	chmod +x $(DESTDIR)/opt/$(APP_NAME)/cgi-bin/connector.py
	chmod +x $(DESTDIR)/opt/$(APP_NAME)/$(APP_NAME).py
	mkdir -p $(DESTDIR)/usr/share/applications/
	cp $(APP_NAME).desktop $(DESTDIR)/usr/share/applications/

.PHONY: all install

