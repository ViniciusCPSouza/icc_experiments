#/usr/bin/env bash

# ---------------------------
# Runs Epicc and IC3 on every apk from the 'apks' folder.
#
# Note: You have to run setup.sh first in order to create the symbolic links
# needed by this script.
#
# Usage: ./run_experiments.sh
# ---------------------------

APK_COUNT=0

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

  { time { eval $epicc_cmd > epicc_output; }; } &> epicc_time &

  epicc_pid="$!"

  # -- run ic3 on the background and get its PID
  ic3_cmd="java -Xmx2g -jar ic3 -apkormanifest \"$apk_path\" \
           -input \"$retargeted_dir\" -cp android -output ic3_results"

  { time { eval $ic3_cmd > ic3_output; }; } &> ic3_time &

  ic3_pid="$!"

  # -- printing some info
  echo -e "\n"
  echo "Epicc is running on apk \"$apk\", with PID: $epicc_pid"
  echo "IC3 is running on apk \"$apk\", with PID: $ic3_pid"

  echo -e "\n"
  echo "Waiting for Epicc and IC3 to finish their analysis..."

  # waiting for the background jobs to finish
  wait

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

  # -- remove all the data from this run
  rm -rf ic3_results/*
  rm -rf epicc_results/*

  rm -f ic3_time
  rm -f epicc_time

  rm -f ic3_output
  rm -f epicc_output

  rm -rf sootOutput

done

echo -e "\n"
echo "****************"
echo "All $APK_COUNT apks were analysed!"

# -- Consolidating the results in a spreadsheet
./consolidate.py results
