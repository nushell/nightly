# Nightly Release for Nushell

This is the nightly release repo for [Nushell](https://github.com/nushell/nushell), they are not production ready and just for test purpose.

**ONLY THE LATEST 10 NIGHTLY BUILDS WILL BE KEPT.**

[![Nightly Build](https://github.com/nushell/nightly/actions/workflows/nightly-build.yml/badge.svg)](https://github.com/nushell/nightly/actions/workflows/nightly-build.yml)

## Pull the latest nightly build in the REPL
One can use the `toolkit.nu` module provided in this repo to download one of the latest nightly builds.

- download the module
```nushell
git clone https://github.com/nushell/nightly.git; cd nightly
# or download the file alone
http get https://raw.githubusercontent.com/nushell/nightly/nightly/toolkit.nu | save --force toolkit.nu
```
- activate the module
```nushell
overlay use --reload --prefix toolkit.nu as tk
```
- get some help
```nushell
tk get-latest-nightly-build --help
```
- an example for Linux
```nushell
> tk get-latest-nightly-build x86_64-linux-gnu
latest nightly build (version: 0.85.1, hash: c925537) saved as `nu-0.85.1-x86_64-linux-gnu-full.tar.gz`
hint: run `tar xvf nu-0.85.1-x86_64-linux-gnu-full.tar.gz --directory .` to unpack the tarball
```
