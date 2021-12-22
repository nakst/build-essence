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

# If this commit has already been built, exit.
curl -sfLo nul https://api.github.com/repos/nakst/build-essence/releases/tags/essence-${COMMIT} && exit

# Setup config files.
mkdir -p bin root
echo "accepted_license=1"                             >> bin/build_config.ini
echo "automated_build=1"                              >> bin/build_config.ini
echo "Flag.DEBUG_BUILD=0"                             >> bin/config.ini
echo "Flag.ENABLE_POSIX_SUBSYSTEM=1"                  >> bin/config.ini
echo "General.wallpaper=0:/Demo Content/Abstract.jpg" >> bin/config.ini
echo "General.window_color=5"                         >> bin/config.ini

# Setup toolchain.
./start.sh get-source prefix https://github.com/nakst/build-gcc/releases/download/gcc-11.1.0/gcc-x86_64-essence.tar.xz
./start.sh setup-pre-built-toolchain
./start.sh build-optimised

# Build ports.
./start.sh build-port nasm    > /dev/null
./start.sh build-port busybox > /dev/null
./start.sh build-port uxn     > /dev/null
./start.sh build-port bochs   > /dev/null
./start.sh build-port ffmpeg  > /dev/null
./start.sh build-port gcc     > /dev/null

# Copy a few sample files.
mkdir -p root/Demo\ Content
cp -r res/Sample\ Images/* root/Demo\ Content/
cp bin/noodle.rom root/Demo\ Content/Noodle.uxn
cp res/A\ Study\ in\ Scarlet.txt root/Demo\ Content/
cp res/Theme\ Source.dat root/Demo\ Content/Theme.designer
cp res/Flip.* root/Demo\ Content/
cp res/Fonts/Atkinson\ Hyperlegible\ Regular.ttf root/Demo\ Content/
cp help/API\ Documentation.md root/Demo\ Content/

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
cd ..

# Create a virtual machine file.
mkdir -p ova
qemu-img convert -f raw essence/bin/drive -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 ova/Essence-disk001.vmdk
python genovf.py > ova/Essence.ovf
cd ova
tar -cf Essence.ova Essence.ovf Essence-disk001.vmdk
mv Essence.ova ..
cd ..

# Compress the result.
mv essence/bin/drive .
tar -cJf drive.tar.xz drive
tar -cJf Essence.ova.tar.xz Essence.ova
echo $COMMIT > essence/bin/commit.txt
rm -rf essence/cross essence/.git essence/bin/cache essence/bin/freetype essence/bin/harfbuzz essence/bin/musl essence/root/Applications/POSIX/lib
tar -cJf debug_info.tar.xz essence

# Set outputs for workflow.
echo "::set-output name=OUTPUT_BINARY::drive.tar.xz"
echo "::set-output name=DEBUG_OUTPUT_BINARY::debug_info.tar.xz"
echo "::set-output name=OVA_OUTPUT_BINARY::Essence.ova.tar.xz"
echo "::set-output name=RELEASE_NAME::essence-${COMMIT}"
echo "::set-output name=COMMIT::${COMMIT}"
