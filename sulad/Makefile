INSTALL_PREFIX = /usr/local
PROG_NAME = sulad
INITDDIR = /etc/init.d
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


$(ODIR)/%.o: $(SDIR)/%.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(PROG_NAME): $(OBJ)
	gcc -o $@ $^ $(CFLAGS) $(LIBS)

.PHONY: clean

clean:
	find . -type f | xargs touch
	rm -f $(ODIR)/*.o *~ core $(INCDIR)/*~ $(PROG_NAME)

.PHONY: install
install: $(PROG_NAME)
	mkdir -p $(DESTDIR)$(INSTALL_PREFIX)/bin
	cp $< $(DESTDIR)$(INSTALL_PREFIX)/bin/$(PROG_NAME)
	cp conf/initd.sh $(DESTDIR)$(INITDDIR)/$(PROG_NAME)
	chmod 755 $(DESTDIR)$(INITDDIR)/$(PROG_NAME)
	cp conf/config $(DESTDIR)/etc/$(PROG_NAME).conf
	update-rc.d $(PROG_NAME) defaults

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(INSTALL_PREFIX)/bin/$(PROG_NAME)
	rm -f $(DESTDIR)$(INITDDIR)/$(PROG_NAME)
	update-rc.d $(PROG_NAME) remove
	rm -f $(DESTDIR)/etc/$(PROG_NAME).conf