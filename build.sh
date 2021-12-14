#!/bin/bash

set -eux

if [ ! -d "essence" ]; then
	git clone --depth=1 https://gitlab.com/nakst/essence.git
fi

cd essence
COMMIT=`git log | head -n 1 | cut -b 8-14`
mkdir -p bin
echo accepted_license=1 >> bin/build_config.ini
echo automated_build=1 >> bin/build_config.ini
./start.sh get-source prefix https://github.com/nakst/build-gcc-x86_64-essence/releases/download/gcc-v11.1.0/out.tar.xz
./start.sh setup-pre-built-toolchain
./start.sh b
cd ..
xz -z essence/bin/drive
mv essence/bin/drive.xz .

echo "::set-output name=OUTPUT_BINARY::drive.xz"
echo "::set-output name=RELEASE_NAME::essence-${COMMIT}"
echo "::set-output name=COMMIT::${COMMIT}"
