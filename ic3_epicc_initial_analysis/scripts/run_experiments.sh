#/usr/bin/env bash

# ---------------------------
# Runs Epicc and IC3 on every apk from the 'apks' folder.
#
# Note: You have to run setup.sh first in order to create the symbolic links
# needed by this script.
#
# Note 2: Use the --sequential option if you don't want both tools to run at the same time.
#
# Usage: ./run_experiments.sh [--sequential]
# ---------------------------

# -- init code
APK_COUNT=0
mkdir ic3_results epicc_results

SEQUENTIAL=0

# -- parsing the args
usage() { echo "Usage: $0 [--sequential]"; exit 1; }

while [ ! $# -eq 0 ]
do
    case "$1" in
        --sequential)
            SEQUENTIAL=1
            ;;
        *)
            usage
            ;;
    esac
    shift
done


# -- loop through the 'apks' folder
for apk in `ls apks`;
do

  APK_COUNT=$(($APK_COUNT + 1))

  apk_path="`pwd`/apks/$apk"
  apk_name="`echo $apk | cut -d . -f 1`"

  echo "----------------"
  echo "Target APK #$APK_COUNT: $apk_name"

  echo -e "\n"
  echo "Retargeting the application..."

  # -- retargeting the application (.dex/.apk files --> .class files)
  dare_output_dir="`pwd`/retargeted/$apk_name"
  mkdir -p "$dare_output_dir"
  ./dare -d "$dare_output_dir" "$apk_path" &> /dev/null

  retargeted_dir="$dare_output_dir/retargeted/$apk_name/"

  # -- run epicc on the background and get its PID
  epicc_cmd="java -Xmx2g -jar epicc -apk \"$apk_path\" -android-directory \
           \"$retargeted_dir\" -cp android -icc-study epicc_results"

  { time { eval $epicc_cmd &> epicc_output; }; } &> epicc_time &

  epicc_pid="$!"

  # sequential execution
  if [[ $SEQUENTIAL == 1 ]]; then

    echo -e "\n"
    echo "Epicc is running on apk \"$apk\", with PID: $epicc_pid"

    echo -e "\n"
    echo "Waiting for it to finish..."

    wait

  fi

  # -- run ic3 on the background and get its PID
  ic3_cmd="java -Xmx2g -jar ic3 -apkormanifest \"$apk_path\" \
          -input \"$retargeted_dir\" -cp android -output ic3_results"

  { time { eval $ic3_cmd > ic3_output; }; } &> ic3_time &

  ic3_pid="$!"

  # sequential execution
  if [[ $SEQUENTIAL == 1 ]]; then

    echo -e "\n"
    echo "IC3 is running on apk \"$apk\", with PID: $ic3_pid"

    echo -e "\n"
    echo "Waiting for it to finish..."

    wait

  fi

  # parallel execution
  if [[ $SEQUENTIAL != 1 ]]; then

    echo -e "\n"
    echo "Epicc is running on apk \"$apk\", with PID: $epicc_pid"
    echo "IC3 is running on apk \"$apk\", with PID: $ic3_pid"

    echo -e "\n"
    echo "Waiting for them to finish..."

    wait

  fi

  echo -e "\n"
  echo "Both Epicc and IC3 finished analysing the apk!"

  # -- handling the results (files generated, time results, etc)

  epicc_results_folder="results/$apk_name/epicc"
  ic3_results_folder="results/$apk_name/icc"

  mkdir -p $epicc_results_folder $ic3_results_folder

  mv ic3_results/* $ic3_results_folder
  mv epicc_results/* $epicc_results_folder

  mv ic3_time $ic3_results_folder
  mv epicc_time $epicc_results_folder

  mv ic3_output $ic3_results_folder
  mv epicc_output $epicc_results_folder

done

echo -e "\n"
echo "****************"
echo "All $APK_COUNT apks were analysed!"

# -- removing some artifacts
rm -rf retargeted
rm -rf ic3_results
rm -rf epicc_results
rm -rf sootOutput

# -- consolidating the results in a spreadsheet
./consolidate.py results
