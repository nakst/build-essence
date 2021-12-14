#!/bin/bash
set -eux

# TODO:
# More sample content.
# Identifying errors.
# Mesa (and object viewer), Bochs ports (needs libstdc++), ffmpeg, GCC.

# Get the source.
git clone --depth=1 https://gitlab.com/nakst/essence.git
cd essence
COMMIT=`git log | head -n 1 | cut -b 8-14`

# Setup config files.
mkdir -p bin root
echo "accepted_license=1"                              >> bin/build_config.ini
echo "automated_build=1"                               >> bin/build_config.ini
echo "Flag.DEBUG_BUILD=0"                              >> bin/config.ini
echo "Flag.ENABLE_POSIX_SUBSYSTEM=1"                   >> bin/config.ini
echo "General.wallpaper=0:/Sample Images/Abstract.jpg" >> bin/config.ini
echo "apps/samples/list.ini"                           >> bin/extra_applications.ini
echo "apps/samples/hello.ini"                          >> bin/extra_applications.ini
echo "apps/samples/game_loop.ini"                      >> bin/extra_applications.ini
echo "apps/samples/converter.ini"                      >> bin/extra_applications.ini
echo "util/designer2.ini"                              >> bin/extra_applications.ini
echo "ports/uxn/emulator.ini"                          >> bin/extra_applications.ini

# Setup toolchain.
./start.sh get-source prefix https://github.com/nakst/build-gcc-x86_64-essence/releases/download/gcc-v11.1.0/out.tar.xz
./start.sh setup-pre-built-toolchain
./start.sh build-optimised

# Build ports.
./start.sh build-port nasm    > /dev/null
./start.sh build-port busybox > /dev/null
./start.sh build-port uxn     > /dev/null

# Copy sample data.
cp -r res/Sample\ Images root
cp bin/noodle.rom root/Noodle.uxn
cp res/A\ Study\ in\ Scarlet.txt root
cp res/Theme\ Source.dat root/Theme.designer

# Build the system.
./start.sh build-optimised

# Compress result.
cd ..
xz -z essence/bin/drive
mv essence/bin/drive.xz .

# Set outputs for workflow.
echo "::set-output name=OUTPUT_BINARY::drive.xz"
echo "::set-output name=RELEASE_NAME::essence-${COMMIT}"
echo "::set-output name=COMMIT::${COMMIT}"
