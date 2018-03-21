INSTALL_PREFIX = /usr/local
PROG_NAME = sulad
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
	cp conf/initd.sh /etc/init.d/$(PROG_NAME)
	chmod 755 /etc/init.d/$(PROG_NAME)
	cp conf/config /etc/$(PROG_NAME).conf

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(INSTALL_PREFIX)/bin/$(PROG_NAME)
	rm -f $(DESTDIR)/etc/init.d/$(PROG_NAME)
	rm -f $(DESTDIR)/etc/$(PROG_NAME).conf