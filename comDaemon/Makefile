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

slcomD: $(OBJ)
	gcc -o $@ $^ $(CFLAGS) $(LIBS)

.PHONY: clean

clean:
	rm -f $(ODIR)/*.o *~ core $(INCDIR)/*~ 