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
mkdir tmp/1 tmp/2 tmp/3 tmp/4 tmp/5 tmp/6
set -x
dd if=/dev/random of=tmp/1/hello1 bs=2048 count=4 # keep !
cp tmp/1/hello1 tmp/2/hello2                      # remove !
cp tmp/1/hello1 tmp/3/hello3                      # remove !
ln tmp/1/hello1 tmp/1/hello4                      # keep !
ln tmp/2/hello2 tmp/2/hello5                      # remove !
ln tmp/2/hello2 tmp/2/hello6                      # remove !
dd if=/dev/random of=tmp/1/hello7 bs=2048 count=4 # keep !
cp tmp/1/hello7 tmp/2/hello8                      # remove !
dd if=/dev/random of=tmp/3/hello9 bs=2048 count=3 # keep
dd if=/dev/random of=tmp/1/hello10 bs=2048 count=3 # keep !
cp tmp/1/hello10 tmp/1/hello11                     # remove !
cp tmp/1/hello10 tmp/1/hello12                     # remove !
dd if=/dev/random of=tmp/1/hello13 bs=2048 count=3 # keep
cp tmp/1/hello13 tmp/1/hello14                     # remove
cp tmp/1/hello13 tmp/1/hello15                     # remove
cp tmp/1/hello13 tmp/2/hello16                     # remove
(cat tmp/1/hello13; dd if=/dev/random bs=2048 count=1) >tmp/3/hello17
(cat tmp/1/hello13; dd if=/dev/random bs=2048 count=2) >tmp/3/hello18
(cat tmp/1/hello7;  dd if=/dev/random bs=2048 count=1) >tmp/3/hello19
(cat tmp/1/hello7;  dd if=/dev/random bs=2048 count=2) >tmp/3/hello20
../bin/dedupebysize -n tmp
