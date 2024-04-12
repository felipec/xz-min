CC := gcc

CPPFLAGS := -g -O2
LDFLAGS := -Wl,--no-undefined

all: liblzma.so libsystemd.so

liblzma.so: override LDFLAGS += -Wl,-soname -Wl,liblzma.so.5 -Wl,--version-script=liblzma.map
liblzma.so: liblzma.o

libsystemd.so: override LDFLAGS += -Wl,-soname -Wl,libsystemd.so.0 -Wl,--version-script=libsystemd.map
libsystemd.so: override LDLIBS += -llzma -lgcrypt
libsystemd.so: libsystemd.o

%.so: override CPPFLAGS += -fPIC

%.so:
	$(CC) -shared $(LDFLAGS) $^ $(LDLIBS) -o $@