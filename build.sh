#!/bin/bash
set -eux

# TODO:
# Copy the source onto the drive for self hosting.
# Producing installer images (including for real hardware).

# Get the source.
git clone --depth=1 https://gitlab.com/nakst/essence.git
cd essence
COMMIT=`git log | head -n 1 | cut -b 8-14`

# Setup config files.
mkdir -p bin root
echo "accepted_license=1"                             >> bin/build_config.ini
echo "automated_build=1"                              >> bin/build_config.ini
echo "Flag.DEBUG_BUILD=0"                             >> bin/config.ini
echo "Flag.ENABLE_POSIX_SUBSYSTEM=1"                  >> bin/config.ini
echo "General.wallpaper=0:/Demo Content/Abstract.jpg" >> bin/config.ini
echo "General.window_color=5"                         >> bin/config.ini

# Setup toolchain, build the system and ports.
./start.sh get-source prefix https://github.com/nakst/build-gcc/releases/download/gcc-11.1.0/gcc-x86_64-essence.tar.xz
./start.sh setup-pre-built-toolchain
./start.sh build-optimised
./start.sh build-optional-ports > /dev/null

# Copy a few sample files.
mkdir -p root/Demo\ Content
cp -r res/Sample\ Images/* root/Demo\ Content/
cp -r help root/Demo\ Content/
cp bin/noodle.rom root/Demo\ Content/Noodle.uxn
cp res/A\ Study\ in\ Scarlet.txt root/Demo\ Content/
cp res/Theme\ Source.dat root/Demo\ Content/Theme.designer
cp res/Flip.* root/Demo\ Content/
cp res/Teapot.obj root/Demo\ Content/
cp res/Fonts/Atkinson\ Hyperlegible\ Regular.ttf root/Demo\ Content/

# Copy API samples.
mkdir -p root/API\ Samples
python ../genapisamples.py

# Enable extra applications.
echo "util/designer2.ini"         >> bin/extra_applications.ini
echo "util/build_core.ini"        >> bin/extra_applications.ini
echo "ports/uxn/emulator.ini"     >> bin/extra_applications.ini
echo "ports/bochs/bochs.ini"      >> bin/extra_applications.ini
echo "ports/mesa/obj_viewer.ini"  >> bin/extra_applications.ini

# Build the extra applications.
./start.sh build-optimised
cd ..

# Create a virtual machine file.
mkdir -p ova
qemu-img convert -f raw essence/bin/drive -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 ova/Essence-disk001.vmdk
python genovf.py > ova/Essence.ovf
cd ova
tar -cf Essence.ova Essence.ovf Essence-disk001.vmdk
cd ..

# Copy licenses.
mkdir -p Essence Essence/Licenses
cp essence/LICENSE.md Essence/Licenses/Essence\ License.txt
cp essence/util/nanosvg.h Essence/Licenses/
cp essence/util/hsluv.h Essence/Licenses/
cp essence/util/stb_*.h Essence/Licenses/
cp essence/shared/stb_*.h Essence/Licenses/
cp essence/res/Fonts/Hack\ License.md Essence/Licenses/
cp essence/res/Fonts/Inter\ License.txt Essence/Licenses/
cp essence/res/Fonts/Atkinson\ Hyperlegible\ License.txt Essence/Licenses/
cp essence/res/Fonts/OpenDyslexic\ License.txt Essence/Licenses/
cp essence/res/elementary\ Icons\ License.txt Essence/Licenses/
cp essence/res/Sample\ Images/Licenses.txt Essence/Licenses/Sample\ Images.txt
cp essence/res/Keyboard\ Layouts/License.txt Essence/Licenses/Keyboard\ Layouts.txt
cp essence/ports/acpica/licensing.txt Essence/Licenses/ACPICA.txt
cp essence/ports/bochs/COPYING Essence/Licenses/Bochs.txt
cp essence/ports/efitoolkit/LICENSE Essence/Licenses/EFI.txt
cp essence/ports/freetype/FTL.TXT Essence/Licenses/FreeType.txt
cp essence/ports/harfbuzz/LICENSE Essence/Licenses/HarfBuzz.txt
cp essence/ports/md4c/LICENSE.md Essence/Licenses/Md4c.txt
cp essence/ports/musl/COPYRIGHT Essence/Licenses/Musl.txt
cp essence/ports/uxn/LICENSE Essence/Licenses/Uxn.txt
cp essence/bin/BusyBox\ License.txt Essence/Licenses/BusyBox.txt
cp -r essence/bin/FFmpeg\ License Essence/Licenses/
cp essence/bin/Mesa\ License.html Essence/Licenses/Mesa.html
cp essence/bin/Nasm\ License.txt Essence/Licenses/Nasm.txt
cp essence/bin/GCC\ License.txt Essence/Licenses/GCC.txt
cp essence/bin/Binutils\ License.txt Essence/Licenses/Binutils.txt
cp essence/bin/GMP\ License.txt Essence/Licenses/GMP.txt
cp essence/bin/MPFR\ License.txt Essence/Licenses/GMPF.txt
cp essence/bin/MPC\ License.txt Essence/Licenses/MPC.txt

# Compress the result.
mv ova/Essence.ova Essence/
mv essence/bin/drive Essence/
tar -cJf Essence.tar.xz Essence/
echo $COMMIT > essence/bin/commit.txt
rm -rf essence/cross essence/.git essence/bin/cache essence/bin/freetype essence/bin/harfbuzz essence/bin/musl essence/root/Applications/POSIX/lib
tar -cJf debug_info.tar.xz essence

# Set outputs for workflow.
echo "::set-output name=OUTPUT_BINARY::Essence.tar.xz"
echo "::set-output name=DEBUG_OUTPUT_BINARY::debug_info.tar.xz"
echo "::set-output name=RELEASE_NAME::essence-`date +%Y_%m_%d`-${COMMIT}"
echo "::set-output name=COMMIT::${COMMIT}"
