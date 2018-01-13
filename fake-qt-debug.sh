#!/bin/sh

cd "$(dirname "$(readlink -f "$0")")"

find usr/*/qt5 -regex '.*[^d]\.a$' | while read f; do
    printf 'Found static library: %s\n' "$f"
    ln -s "$(basename "$f")" "${f%.a}d.a"
done

find usr/*/qt5 -regex '.*[^d].prl' | while read f; do
    printf 'Found .prl: %s\n' "$f"
    ln -s "$(basename "$f")" "${f%.prl}d.prl"
done


