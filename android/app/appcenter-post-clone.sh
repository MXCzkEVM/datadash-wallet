#!/usr/bin/env bash
#Place this script in project/android/app/

cd ..

# fail if any command fails
set -e
# debug log
set -x

cd ..
git clone -b stable https://github.com/flutter/flutter.git
export PATH=`pwd`/flutter/bin:$PATH

flutter clean

# accepting all licenses
yes | flutter doctor --android-licenses

echo "Installed flutter to `pwd`/flutter"

echo "Installed flutter to `pwd`/flutter"

# build APK
flutter build apk --flavor prod

# if you need build bundle (AAB) in addition to your APK, uncomment line below and last line of this script.
flutter build appbundle --flavor play

# copy the APK where AppCenter will find it
mkdir -p android/app/build/outputs/apk/; mv build/app/outputs/apk/prod/release/app-prod-release.apk $_

# copy the AAB where AppCenter will find it
mkdir -p android/app/build/outputs/bundle/; mv build/app/outputs/bundle/playRelease/app-play-release.aab $_
