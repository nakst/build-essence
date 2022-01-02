#!/bin/bash
set -eux

# Get the source.
git clone --depth=1 https://gitlab.com/nakst/essence.git
cd essence
COMMIT=`git log | head -n 1 | cut -b 8-14`

# If this commit has already been built, exit.
curl -sfLo nul https://api.github.com/repos/nakst/build-essence/releases/tags/essence-${COMMIT}-minimal && exit

# Setup config files.
mkdir -p bin root
echo "accepted_license=1"               >> bin/build_config.ini
echo "automated_build=1"                >> bin/build_config.ini
echo "Flag.DEBUG_BUILD=0"               >> bin/config.ini
echo "BuildCore.NoImportPOSIX=1"        >> bin/config.ini
echo "BuildCore.RequiredFontsOnly=1"    >> bin/config.ini
echo "Emulator.PrimaryDriveMB=32"       >> bin/config.ini
echo "Emulator.PrimaryDriveMB=32"       >> bin/config.ini
echo "Dependency.ACPICA=0"              >> bin/config.ini
echo "Dependency.stb_image=0"           >> bin/config.ini
echo "Dependency.stb_image_write=0"     >> bin/config.ini
echo "Dependency.stb_sprintf=0"         >> bin/config.ini
echo "Dependency.FreeTypeAndHarfBuzz=0" >> bin/config.ini

# Setup toolchain and build the system.
./start.sh get-source prefix https://github.com/nakst/build-gcc/releases/download/gcc-11.1.0/gcc-x86_64-essence.tar.xz
./start.sh setup-pre-built-toolchain
./start.sh build-optimised
cd ..

# Compress the result.
mv essence/bin/drive .
tar -cJf drive.tar.xz drive
echo $COMMIT > essence/bin/commit.txt
rm -rf essence/cross essence/.git essence/bin/cache essence/bin/freetype essence/bin/harfbuzz essence/bin/musl essence/root/Applications/POSIX/lib
tar -cJf debug_info.tar.xz essence

# Set outputs for workflow.
echo "::set-output name=OUTPUT_BINARY::drive.tar.xz"
echo "::set-output name=DEBUG_OUTPUT_BINARY::debug_info.tar.xz"
echo "::set-output name=RELEASE_NAME::essence-${COMMIT}-minimal"
echo "::set-output name=COMMIT::${COMMIT}"
