#!/usr/bin/env bash
#Place this script in project/ios/

# fail if any command fails
set -e
# debug log
set -x

cd ..
git clone -b stable https://github.com/flutter/flutter.git
export PATH=`pwd`/flutter/bin:$PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Note: there is a bug with Flutter 3.10.0 when the whole app rebuilds when we open keyboard
# version 3.7.12 => 4d9e56e694b656610ab87fcf2efbcd226e0ed8cf
cd flutter
git reset --hard 4d9e56e694b656610ab87fcf2efbcd226e0ed8cf
cd ..

flutter clean

echo "Installed flutter to `pwd`/flutter"

flutter build ios --release --no-codesign

## WALDO SECTION
## To configure appCenter builds with Waldo UI Automation tool

export WALDO_CLI_BIN=/usr/local/bin

bash -c "$(curl -fLs https://github.com/waldoapp/waldo-go-cli/raw/master/install-waldo.sh)"

# Remove START-SIM-SEC secion from Podfile
sed -i ''  "/#-START-SIM-SEC/,/#-END-SIM-SEC/d" 'ios/Podfile'
flutter build ios --simulator
# the `--simulator` option is critical here

_build_path="build/ios/iphonesimulator/Runner.app"
# adjust this as necessary

export WALDO_UPLOAD_TOKEN=7359ffbc47e3005dd303a0161d48b890

/usr/local/bin/waldo upload "$_build_path"