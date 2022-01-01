#!/bin/bash
set -eux

git clone --depth=1 https://gitlab.com/nakst/essence.git
cd essence

mkdir -p bin
echo "accepted_license=1" >> bin/build_config.ini
echo "desktop/api_tests.ini" >> bin/extra_applications.ini
./start.sh get-source prefix https://github.com/nakst/build-gcc/releases/download/gcc-11.1.0/gcc-x86_64-essence.tar.xz
./start.sh setup-pre-built-toolchain
./start.sh run-tests

cd ..
echo `git log | head -n 1 | cut -b 8-14` > essence/bin/commit.txt
rm -rf essence/cross essence/.git essence/bin/cache essence/bin/freetype essence/bin/harfbuzz essence/bin/musl essence/root/Applications/POSIX/lib essence/bin/drive
