INSTALL_PREFIX = /usr/local
PROG_NAME = sulad
INITDDIR = /etc/init.d
CONFIGDIR = /etc
IDIR =include
SDIR =src
CC=gcc
CFLAGS=-I$(IDIR)

ODIR=obj
LDIR =lib

LIBS=-lm

_DEPS = main.h uart.h
DEPS = $(patsubst %,$(IDIR)/%,$(_DEPS))

_OBJ = main.o uart.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))



INIT_SCRIPT = $(INITDDIR)/$(PROG_NAME)
CONFIG = $(CONFIGDIR)/$(PROG_NAME).conf
COPY_FILES = $(DESTDIR)$(INIT_SCRIPT) $(DESTDIR)$(CONFIG)
#conf/initd.sh conf/config

$(ODIR)/%.o: $(SDIR)/%.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(PROG_NAME): $(OBJ)
	gcc -o $@ $^ $(CFLAGS) $(LIBS)

.PHONY: clean

clean:
	find . -type f | xargs touch
	rm -f $(ODIR)/*.o *~ core $(INCDIR)/*~ $(PROG_NAME)

.PHONY: install
install: $(PROG_NAME) copy_config
	$(INIT_SCRIPT) stop
	mkdir -p $(DESTDIR)$(INSTALL_PREFIX)/bin
	cp $< $(DESTDIR)$(INSTALL_PREFIX)/bin/$(PROG_NAME)
	chmod 755 $(INIT_SCRIPT)
	update-rc.d $(PROG_NAME) defaults
	$(INIT_SCRIPT) start
	
.PHONY: copy_config
copy_config: $(COPY_FILES)

$(DESTDIR)$(INIT_SCRIPT): files$(INIT_SCRIPT)
	mkdir -p $(DESTDIR)$(INITDDIR)
	cp -f $< $@

$(DESTDIR)$(CONFIG): files$(CONFIG)
	mkdir -p $(DESTDIR)$(CONFIGDIR)
	cp -f $< $@
	
.PHONY: uninstall
uninstall:
	$(DESTDIR)$(INIT_SCRIPT) stop
	rm -f $(DESTDIR)$(INSTALL_PREFIX)/bin/$(PROG_NAME)
	rm -f $(DESTDIR)$(INIT_SCRIPT)
	rm -f $(DESTDIR)$(CONFIG)
	update-rc.d $(PROG_NAME) remove