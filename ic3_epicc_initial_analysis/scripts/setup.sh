#/usr/bin/env bash

# ---------------------------
# Prepares the symbolic links so the execution scripts can find the android, epicc and ic3 jars,
# the dare program, and also the folder that contains the apks to be tested on.
#
# Android SDK: http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz
# IC3: https://github.com/siis/ic3/releases/download/v0.1.0/ic3-0.1.0-bin.tgz
# Epicc dowload link: http://siis.cse.psu.edu/epicc/downloads/epicc-0.1.tgz
# Dare: https://github.com/dare-android/platform_dalvik/releases/download/dare-1.1.0/dare-1.1.0-linux.tgz
# Apks suggestion: https://github.com/secure-software-engineering/DroidBench
#
# Usage: ./setup.sh <path to the android jar> <path to the ic3 jar> <path to the epicc jar> <path to the dare script> <path to apks folder>
# ---------------------------

ANDROID_JAR="${1}"
IC3_JAR="${2}"
EPICC_JAR="${3}"
DARE_PROGRAM="${4}"
APKS_FOLDER="${5}"

# create the links
ln -s "${ANDROID_JAR}" android
ln -s "${IC3_JAR}" ic3
ln -s "${EPICC_JAR}" epicc
ln -s "${DARE_PROGRAM}" dare
ln -s "${APKS_FOLDER}" apks
