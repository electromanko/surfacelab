INSTALL_PREFIX = /usr/local
PROG_NAME = sulad
IDIR =include
CC=gcc
CFLAGS=-I$(IDIR)

ODIR=obj
LDIR =lib

LIBS=-lm

_DEPS = main.h uart.h
DEPS = $(patsubst %,$(IDIR)/%,$(_DEPS))

_OBJ = main.o uart.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))


$(ODIR)/%.o: %.c $(DEPS)
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

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(INSTALL_PREFIX)/bin/$(PROG_NAME)