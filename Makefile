CC := gcc

CPPFLAGS := -g -O2
LDFLAGS := -Wl,--no-undefined

all: liblzma.so

liblzma.so: override LDFLAGS += -Wl,-soname -Wl,liblzma.so.5 -Wl,--version-script=liblzma.map
liblzma.so: liblzma.o

%.so: override CPPFLAGS += -fPIC

%.so:
	$(CC) -shared $(LDFLAGS) $^ $(LDLIBS) -o $@
