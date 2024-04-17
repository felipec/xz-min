This project tries to minimize the number of steps necessary to trigger the
[xz backdoor](https://en.wikipedia.org/wiki/XZ_Utils_backdoor).

The backdoor needs `sshd` compiled with libsystemd support, which requires a
patch most distributions don't ship.

Here's how you can check if `sshd` is linked against libsystemd:

```sh
readelf -d /usr/sbin/sshd | grep NEEDED
```

To help testing a script to build `sshd` with the libsystemd patch is included:

```sh
make sd_sshd
```

Then just `sshd` with the helper script:

```sh
sudo ./run_sshd
```

This is simply a wrapper to run `sshd` in a clean environment and with
debugging options:

```sh
env -i LD_LIBRARY_PATH="$PWD" "$PWD/sd_sshd" -D -d -oListenAddress=127.0.0.1 -p2222
```

Then you can use [xzbot](https://github.com/amlweems/xzbot) to trigger the
backdoor. It will use a custom ed448 key generated with 0 as seed.

```
make xzbot
./xzbot -cmd 'id > /root/xz'
```

# How?

The backdoor is installed before the program starts, when the linker is
executing checks. It's abusing the
[IFUNC](https://sourceware.org/glibc/wiki/GNU_IFUNC) functionality in a
resolver function that is supposed to be calling `__get_cpuid` to check for cpu
features, but instead the build system modified the code to call `_get_cpuid`
which is inside the backdoor binary, and does **much more**.

Since this repository contains a simplified version of liblzma it's clear what
they were trying to do in commit
[f8c8e5a](https://github.com/felipec/xz-min/commit/f8c8e5a).

The backdoor works because many people made mistakes:

 1. The complexity of xz trying to build for a bajillion systems with two
    build systems and few development resources enabled a malicious developer
    to inject a couple of lines in a script with tens of thousans of lines of
    code that is generated for tarballs and nobody looks at.
 2. The developers of systemd did not design it with modularity in mind, so the
    singular libsystemd library provides a ton of functionality most people
    won't use and has nothing to do with an init system, like process
    compressed system logs. Therefore everyone that links to libsystemd links
    to liblzma as well.
 3. Maintainers patched `sshd` to link to libsystemd for a minor feature.

The backdoor binary is incredibly complex and it will take a while to properly
understand all what it does.

# Why?

I created this project to simplify the process of analysis.

The injection scripts are very intricate and do numerous checks, such as
ensuring the environment is for packaging as deb or rpm on x86. However, our
primary concern is simply to activate the backdoor, and for that we only need
to call `_get_cpuid` from two
[ifunc](https://sourceware.org/glibc/wiki/GNU_IFUNC) resolvers.

Although I could provide a patch for this purpose and include the backdoor
binary in the build process for you to execute manually, this is not necessary.
The backdoor doesn't rely on the entire liblzma; it merely uses it as a
launchpad.

All it requires are the ifunc resolvers along with `lzma_alloc` and
`lzma_free`.

Unfortunately creating a mock liblzma triggers errors about unresolved symbols
from libsystemd (despite not using them in this context).

Therefore we also craft a mock libsystemd.

The backdoor doesn't interact with libsystemd at all; its sole requirement is
that the `sshd` binary is linked to it. As libsystemd is linked to liblzma, the
dynamic loader invokes the ifunc resolvers **before** `sshd` is loaded.
Additionally, it seems that libsystemd must also link to libgcrypt.

Now the backdoor is primed for activation, but at this stage, we've merely
facilitated the creation of an `sshd` instance that's readily exploitable by
malicious actors.

We need to replace the attacker's ed448 key with our own. Following the
instructions in xzbot's
[ed448-patch](https://github.com/amlweems/xzbot?tab=readme-ov-file#ed448-patch),
I created equivalent assembly code for improved readability, and then used
binutils' [objcopy](https://sourceware.org/binutils/docs/binutils/objcopy.html)
to integrate it into the correct section in the ELF binary.

We can now locally trigger the backdoor using xzbot with seed=0, but only with
the observed requirements outlined in the initial [Openwall
post](https://openwall.com/lists/oss-security/2024/03/29/4). The most
inconvenient one is that argv0 must be `/usr/sbin/sshd`.

According to another researcher, the place in the code where these requirements
are checked is `lzma_file_info_decodea`. By introducing a `ret` instruction
there, we can execute our patched `sd_sshd` from the current directory and with
debugging enabled.

So:

  1. Patch `sshd` to use libsystemd
  2. Create a mock libsystemd that links to liblzma and libgcrypt
  3. Create a minimal mock liblzma containing the backdoor
  4. Patch the backdoor with a custom ed448 key and bypass checks

Then we can run our `sshd` locally and use xzbot to activate the backdoor
easily.
