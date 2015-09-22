#/usr/bin/env bash

#
# Sets up the environment so that the run_experiments.sh script can be run.
#

# Android SDK: http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz
# IC3: https://github.com/siis/ic3/releases/download/v0.1.0/ic3-0.1.0-bin.tgz
# Epicc dowload link: http://siis.cse.psu.edu/epicc/downloads/epicc-0.1.tgz
# Dare: https://github.com/dare-android/platform_dalvik/releases/download/dare-1.1.0/dare-1.1.0-linux.tgz
# Apks suggestion: https://github.com/secure-software-engineering/DroidBench

# should be run with sudo!
# @Vinicius: it is fine.  but in general it is safer to ask the user to install (providing the command) if some specific tool is not installed

# Good job, Vinicius.  Some TODOs for later (not critical for now):
# - it is good practice to avoid unneded downloads.  for example, epicc will be downloaded if one runs this script twice

ANDROID_VERSION="23"

function onMac()
{
  if [[ "$(uname -s)" == "Darwin" ]]; then
    return 0
  else
    return 1
  fi
}

function onLinux()
{
  if [[ "$(uname -s)" == "Linux" ]]; then
    return 0
  else
    return 1
  fi
}

function updateAndroidSDK()
{
  ANDROID_SDK_DIR="$1"

  # update
  cd "$ANDROID_SDK_DIR/tools"

  sudo ./android update sdk --no-ui --all --filter "android-$ANDROID_VERSION"

  cd -
}

function decompress()
{
  FULLNAME="$1"
  EXTENSION="$(echo $1 | rev | cut -d . -f 1 | rev)"

  if [[ "$EXTENSION" == "tgz" ]]; then

    tar -xzvf "$FULLNAME"

  elif [[ "$EXTENSION" == "zip" ]]; then

    unzip "$FULLNAME"

  else

    echo "\"$EXTENSION\" is not currently supported as a compressed file format!"
    exit 1

  fi
}

## download input file and decompress in current directory
function downloadDecompress() {
    NAME=$1  # should match the name of the extracted folder (assuming only one)
    URL=$2
    fullname=$(echo $URL | rev | awk -F"/" '{print $1}' | rev)
    direxists=$(ls -d ${NAME}*/)
    if [[ -z "$direxists" ]];  # check if already downloaded
    then
    	echo "not exist dir"
     	wget $URL             # download from url
     	decompress $fullname  # decompress .tgz or .zip file
     	rm $fullname         # delete file (clean house)
    else
	    echo "skipped $fullname"
    fi
}

mkdir -p deps

(cd deps

### android SDK
if onLinux; then
  downloadDecompress "android-sdk" http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz
elif onMac; then
  downloadDecompress "android-sdk" http://dl.google.com/android/android-sdk_r24.3.4-macosx.zip
else
  echo "$(uname -s) is not a supported OS!"
  exit 1
fi

### IC3
downloadDecompress "ic3" https://github.com/siis/ic3/releases/download/v0.1.0/ic3-0.1.0-bin.tgz

### Epicc
downloadDecompress "epicc"  http://siis.cse.psu.edu/epicc/downloads/epicc-0.1.tgz

### Dare
if onLinux; then
  downloadDecompress "dare" https://github.com/dare-android/platform_dalvik/releases/download/dare-1.1.0/dare-1.1.0-linux.tgz
elif onMac; then
  downloadDecompress "dare" https://github.com/dare-android/platform_dalvik/releases/download/dare-1.1.0/dare-1.1.0-macos.tgz
else
  echo "$(uname -s) is not a supported OS!"
  exit 1
fi

# extra steps required by dare on Linux
if onLinux; then

  # 64-bit system
  if [[ "$(uname -m )" == "x86_64" ]]; then

    # install 32-bit dependencies
    sudo apt-get install gcc-multilib

  fi

  cd dare*

  # optimization required by the authors of 'dare'
  ./dex-preopt --bootstrap

  cd -

fi

if [ ! -d "DroidBench" ];
then
    git clone git@github.com:secure-software-engineering/DroidBench.git
fi

# @ Marcelo: We still clone the DroidBench repository, but the choice of which
# apk folder should be used as input to IC3 and Epicc is given as an argument
# of the run_experiments.sh script -V
# @ Vinicius: OK -M

# mkdir droidbench-apks; cd droidbench-apks
# for x in `find ../DroidBench -name "*.apk"`
# do
#     ln -fs $x
# done
) ## leaving dir deps

## create symbolic links

if onLinux; then

  ANDROID_SDK_FOLDER="deps/android-sdk-linux"

elif onMac; then

  ANDROID_SDK_FOLDER="deps/android-sdk-macosx"

else

  echo "$(uname -s) is not a supported OS!"
  exit 1

fi

updateAndroidSDK "$ANDROID_SDK_FOLDER"

ln -fs "$ANDROID_SDK_FOLDER/platforms/android-$ANDROID_VERSION/android.jar" android.jar

ln -fs `find deps/ic3* -name "ic3*.jar"` ic3.jar
ln -fs `find deps -name "epicc*.jar"` epicc.jar
### @Vinicius: Please check.  I am not sure what you want.  maybe this is an executable whose bin should be appended to the PATH.  -M
### @Marcelo: I was avoiding messing with the environment variables as long as I could. Do you agree with the following approach? -V
### @Vinicius: OK.  Please remove this comments.  
ln -fs `find deps/dare* -name dare` dare
