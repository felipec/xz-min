CC := gcc

CPPFLAGS := -g -O2
LDFLAGS := -Wl,--no-undefined

all: liblzma.so libsystemd.so

liblzma.so: override LDFLAGS += -Wl,-soname -Wl,liblzma.so.5 -Wl,--version-script=liblzma.map -Wl,--sort-section=name,-X,-z,now
liblzma.so: liblzma.o liblzma_la-crc64-fast-5.6.1.o

libsystemd.so: override LDFLAGS += -Wl,-soname -Wl,libsystemd.so.0 -Wl,--version-script=libsystemd.map
libsystemd.so: override LDLIBS += -llzma -lgcrypt
libsystemd.so: libsystemd.o

%.so: override CPPFLAGS += -fPIC

%.so:
	$(CC) -shared $(LDFLAGS) $^ $(LDLIBS) -o $@
