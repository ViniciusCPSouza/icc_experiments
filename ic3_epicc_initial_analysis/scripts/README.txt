We ran IC3 and Epicc on the DroidBench apps that contained inter-component communication.
Their execution times and outputs were consolidated and then compared.

# Steps

  - Download epicc, ic3 and dare and then decompress the archives:

      IC3: https://github.com/siis/ic3/releases/download/v0.1.0/ic3-0.1.0-bin.tgz
      Epicc dowload link: http://siis.cse.psu.edu/epicc/downloads/epicc-0.1.tgz
      Dare: https://github.com/dare-android/platform_dalvik/releases/download/dare-1.1.0/dare-1.1.0-linux.tgz

  - epicc and ic3 come with an android.jar, but you can also download the Android sdk:

      Android SDK: http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz

  - run the 'setup.sh' script:

      ./setup.sh <path to the android jar> <path to the ic3 jar> <path to the epicc jar> <path to the dare script> <path to apks folder>

  - run the './run_experiments.sh' script:

      ./run_experiments.sh [--sequential]

  The results (execution time, console output and output files) of the executions will be under the 'results' folder.

  # TODO
  The results will also be consolidated in a spreadsheet under '...'.
