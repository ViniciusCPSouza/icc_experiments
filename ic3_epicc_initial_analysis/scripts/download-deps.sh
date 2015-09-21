#!/bin/bash

# Android SDK: http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz
# IC3: https://github.com/siis/ic3/releases/download/v0.1.0/ic3-0.1.0-bin.tgz
# Epicc dowload link: http://siis.cse.psu.edu/epicc/downloads/epicc-0.1.tgz
# Dare: https://github.com/dare-android/platform_dalvik/releases/download/dare-1.1.0/dare-1.1.0-linux.tgz
# Apks suggestion: https://github.com/secure-software-engineering/DroidBench

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
 	tar -xzvf $fullname  # decompress .tgz file
 	rm $fullname         # delete file (clean house)
    else
	echo "skipped $fullname"
    fi
}

mkdir -p deps

(cd deps

## shouldn't i use a different .tgz for MAC?  -M
downloadDecompress "android-sdk" http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz
downloadDecompress "ic3" https://github.com/siis/ic3/releases/download/v0.1.0/ic3-0.1.0-bin.tgz
downloadDecompress "IGNORE"  http://siis.cse.psu.edu/epicc/downloads/epicc-0.1.tgz
downloadDecompress "dare" https://github.com/dare-android/platform_dalvik/releases/download/dare-1.1.0/dare-1.1.0-linux.tgz

if [ ! -d "DroidBench" ];
then
    git clone git@github.com:secure-software-engineering/DroidBench.git
fi

mkdir droidbench-apks; cd droidbench-apks
for x in `find ../DroidBench -name "*.apk"`
do
    ln -fs $x
done
) ## leaving dir deps

## create symbolic links

### @Vinicius: Please check.  I am not sure which jar you want to link -M
### ln -fs deps/android.jar ../android.jar    
ln -fs `find deps/ic3* -name "ic3*.jar"` ic3.jar
ln -fs `find deps -name "epicc*.jar"` epicc.jar
### @Vinicius: Please check.  I am not sure what you want.  maybe this is an executable whose bin should be appended to the PATH.  -M
### ln -fs deps/"${DARE_PROGRAM}" dare        
