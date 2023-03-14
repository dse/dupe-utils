#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
shopt -s lastpipe
# set -o xtrace
progdir="$(dirname "$0")"
cd "${progdir}"
rm -fr tmp || true
mkdir tmp
:; mkdir tmp/1 tmp/2 tmp/3 tmp/4 tmp/5 tmp/6
:; echo 'hello world' >tmp/1/hello1
:; echo 'hello world' >tmp/2/hello2 #
:; echo 'hello world' >tmp/3/hello3 #
:; ln tmp/1/hello1 tmp/1/hello4
:; ln tmp/2/hello2 tmp/2/hello5    #
:; ln tmp/2/hello2 tmp/2/hello6    #
:; echo 'hello cruel world' >tmp/1/hello7
:; echo 'hello cruel world' >tmp/2/hello8 #
:; echo 'hello crap world' >tmp/3/hello9
:; echo 'hello one world' >tmp/1/hello10
:; echo 'hello one world' >tmp/1/hello11
:; echo 'hello one world' >tmp/1/hello12
:; echo 'hello two world' >tmp/1/hello13
:; echo 'hello two world' >tmp/1/hello14
:; echo 'hello two world' >tmp/1/hello15
:; echo 'hello two world' >tmp/2/hello16
grep '^:;' "$0"
../bin/dupefind tmp >tmp/dupefind.out
../bin/dupeclean <tmp/dupefind.out
