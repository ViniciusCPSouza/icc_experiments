#!/usr/bin/env bash

APKS_FOLDER="${1}"

for APK in `ls $APKS_FOLDER`
do

  echo "Retrieving the components from $APK ..."

  APK_NAME="`echo $APK | rev | cut -d . -f 2- | rev`"

  mkdir -p components/$APK_NAME/

  mkdir -p decompíled_apks/$APK_NAME/

  # de-compile
  # TODO: install apktool on the machine!
  apktool d -f $APKS_FOLDER/$APK -o decompíled_apks/$APK_NAME/

  ./manifest_parser.py decompíled_apks/$APK_NAME/AndroidManifest.xml

  echo "Finished retrieving the components, `cat components.txt | wc -l` found"

  mv components.txt components/$APK_NAME/

done
