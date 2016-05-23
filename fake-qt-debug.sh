#!/bin/sh

cd "$(dirname "$(readlink -f "$0")")"

cd usr/i686-w64-mingw32.static/qt5

find . -name '*.a' | while read f; do
    printf 'Found static library: %s\n' "$f"
    ln -s "$(basename "$f")" "${f%.a}d.a"
done

find . -regex '.*[^d].prl' | while read f; do
    printf 'Found .prl: %s\n' "$f"
    ln -s "$(basename "$f")" "${f%.prl}d.prl"
done


