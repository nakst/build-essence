#!/bin/bash
set -eux

# TODO:
# Copy the source onto the drive for self hosting.
# Producing installer images (including for real hardware).
# Mesa and object viewer port.

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
echo "General.window_color=5"                          >> bin/config.ini

# Setup toolchain.
./start.sh get-source prefix https://github.com/nakst/build-gcc-x86_64-essence/releases/download/gcc-v11.1.0/out.tar.xz
./start.sh setup-pre-built-toolchain
./start.sh build-optimised

# Build ports.
./start.sh build-port nasm    > /dev/null
./start.sh build-port busybox > /dev/null
./start.sh build-port uxn     > /dev/null
./start.sh build-port gcc     > /dev/null
./start.sh build-port bochs   > /dev/null
./start.sh build-port ffmpeg  > /dev/null

# Copy sample files.
cp -r res/Sample\ Images root
cp bin/noodle.rom root/Noodle.uxn
cp res/A\ Study\ in\ Scarlet.txt root
cp res/Theme\ Source.dat root/Theme.designer
cp res/Flip.* root

# Enable extra applications.
echo "apps/samples/list.ini"      >> bin/extra_applications.ini
echo "apps/samples/hello.ini"     >> bin/extra_applications.ini
echo "apps/samples/game_loop.ini" >> bin/extra_applications.ini
echo "apps/samples/converter.ini" >> bin/extra_applications.ini
echo "util/designer2.ini"         >> bin/extra_applications.ini
echo "ports/uxn/emulator.ini"     >> bin/extra_applications.ini
echo "ports/bochs/bochs.ini"      >> bin/extra_applications.ini

# Build the system.
./start.sh build-optimised

# Compress result.
cd ..
mv essence/bin/drive .
tar -cJf drive.tar.xz drive
mkdir -p debug_info
cp essence/bin/Kernel debug_info
cp essence/bin/Desktop debug_info
cp essence/bin/File\ Manager debug_info
cp essence/bin/build.ini debug_info
echo $COMMIT > debug_info/commit.txt
tar -cJf debug_info.tar.xz debug_info

# Set outputs for workflow.
echo "::set-output name=OUTPUT_BINARY::drive.tar.xz"
echo "::set-output name=DEBUG_OUTPUT_BINARY::debug_info.tar.xz"
echo "::set-output name=RELEASE_NAME::essence-${COMMIT}"
echo "::set-output name=COMMIT::${COMMIT}"
