#!/usr/bin/env python3

"""
    Consolidate the results obtained after running 'run_experiments.sh'.

    Usage: ./consolidate.py <results directory>
"""

# imports
import abc
import argparse
import logging
import os
import sys
import re
import datetime
from collections import OrderedDict

import xlsxwriter

# constants
EXECUTION_TIME_RESULT = "execution_time"
OUTPUT_RESULT = "output"
ARTIFACT_RESULT = "artifact"

LIST_TYPE_RESULTS = [ARTIFACT_RESULT]

RESULTS_TYPES_MAPPING = OrderedDict()

RESULTS_TYPES_MAPPING[EXECUTION_TIME_RESULT] = re.compile("^.*_time$")  # exec time of the tool
RESULTS_TYPES_MAPPING[OUTPUT_RESULT] = re.compile("^.*_output$") # the stdout output of the tool
RESULTS_TYPES_MAPPING[ARTIFACT_RESULT] = re.compile(".*") # any other output file generated by the tool

RESULTS_TYPES = RESULTS_TYPES_MAPPING.keys()

RESULTS_TYPES_DISPLAY_NAMES = {}
RESULTS_TYPES_DISPLAY_NAMES[EXECUTION_TIME_RESULT] = "Execution time (HH:MM:SS)"
RESULTS_TYPES_DISPLAY_NAMES[OUTPUT_RESULT] = "Tool output"
RESULTS_TYPES_DISPLAY_NAMES[ARTIFACT_RESULT] = "Artifacts"

# classes
class ResultFileContentResolver():

    """
    Inspects the given file and then returns a string representation of it.
    This abstract class can't be instantiated, it needs to be extended by
    a concrete child class.
    """

    __metaclass__ = abc.ABCMeta

    def __init__(self, filename, filepath, tool):

        self.filename = filename
        self.filepath = filepath
        self.tool = tool

    @abc.abstractmethod
    def get_str(self):

        """
        Returns a string representation of the given file.

        @returns: a string representation of the results file.
        """

        pass


class ExecutionTimeResolver(ResultFileContentResolver):

    """
    A concrete child of the 'ResultFileContentResolver' abstract class.

    It can handle files that contain output of the 'time' *Nix command.
    """

    def __init__(self, filename, filepath, tool):

        super().__init__(filename, filepath, tool)

    def get_str(self):

        def get_time_delta(time_string):

            tokens = [float(s) for s in re.split("h|m|s", time_string) if s]

            if "h" in time_string:

                delta = datetime.timedelta(hours=tokens[0],
                                           minutes=tokens[1],
                                           seconds=tokens[2])

            else:

                delta = datetime.timedelta(minutes=tokens[0],
                                           seconds=tokens[1])

            return delta

        times = {}

        with open(self.filepath) as f:

            for line in f:

                line = line.strip()

                if 'real' in line or 'user' in line or 'sys' in line:

                    time_type, time_value = line.split("\t")

                    times[time_type] = get_time_delta(time_value)

        return str(times["user"] + times["sys"])


class OutputResolver(ResultFileContentResolver):

    """
    A concrete child of the 'ResultFileContentResolver' abstract class.

    It can handle output files from static analysis tools.
    """

    def __init__(self, filename, filepath, tool):

        super().__init__(filename, filepath, tool)

    def get_str(self):

        # TODO: Parse the output file according to each tool to show the ICC links

        return self.filepath


class ArtifactResolver(ResultFileContentResolver):

    """
    A concrete child of the 'ResultFileContentResolver' abstract class.

    It can handle generic artifacts created by static analysis tools.
    """

    def __init__(self, filename, filepath, tool):

        super().__init__(filename, filepath, tool)

    def get_str(self):

        # TODO: Parse the artifact file according to each tool

        return self.filename


# more constants
RESOLVERS_MAPPING = {EXECUTION_TIME_RESULT: ExecutionTimeResolver,
                     OUTPUT_RESULT: OutputResolver,
                     ARTIFACT_RESULT: ArtifactResolver}


# module functions
def handle_results_file(result_filepath, result_filename, tool_map, tool):

    """
    Given a results file, discover the type of result and delegate to the
    the correct resolver the task of retrieving a string representation of that
    result.

    @param: result_filepath, the path to the result file

    @param: result_filename, the filename of the result file

    @param: tool_map, the map containing the results of the given tool

    @param: tool, the tool that generated the result file
    """

    for result_type in RESULTS_TYPES_MAPPING:

        # based on the filename, discover what type of result this file represents
        if RESULTS_TYPES_MAPPING[result_type].match(result_filename):

            # get the right resolver to handle the file
            resolved_file = RESOLVERS_MAPPING[result_type](result_filename,
                                                           result_filepath,
                                                           tool).get_str()

            # list-type results
            if result_type in LIST_TYPE_RESULTS:

                # initialize the list
                if not result_type in tool_map:

                    tool_map[result_type] = []

                tool_map[result_type].append(resolved_file)

            else:

                tool_map[result_type] = resolved_file

            return

    raise Exception("Could not handle file '%s'!" % result_filepath)


def list_only_dirs(directory):

    """
    Lists only the child directories of the given directories.

    @param: directory, the directory whose child directories will be listed.

    @returns: an item of the list, iterator-style
    """

    for f in os.listdir(directory):

        if os.path.isdir(os.path.join(directory, f)):

            yield f


def list_only_files(directory):

    """
    Lists only the child files (but not directories) of the given directories.

    @param: directory, the directory whose child files will be listed.

    @returns: an item of the list, iterator-style
    """

    for f in os.listdir(directory):

        fullpath = os.path.join(directory, f)

        if os.path.isfile(fullpath) and not os.path.isdir(fullpath):

            yield f


def create_spreadsheet(filename, apks_results, tools):

    """
    Creates a xlsx spreadsheet using the xlsxwriter modules using the given
    apks results map, tools list and filename.

    @param: filename, the name of the xlsx file to be created.

    @param: apks_results, the map with the extracted results

    @param: tools, the list of tools used
    """

    # TODO: Add the ground-truth information

    workbook = xlsxwriter.Workbook(filename)
    worksheet = workbook.add_worksheet()

    logging.info("Creating the spreadsheet...")

    # -- creating the header
    row = 0
    col = 0

    worksheet.write(row, col, "Application")

    col += 1

    for result_type in RESULTS_TYPES:

        for tool in tools:

            worksheet.write(row, col, "%s - %s" % (RESULTS_TYPES_DISPLAY_NAMES[result_type],
                                                   tool))

            col += 1

    # -- putting the result data into the spreadsheet
    row = 1

    for apk in apks_results.keys():

        col = 0

        worksheet.write(row, col, apk)

        col += 1

        for result_type in RESULTS_TYPES:

            for tool in tools:

                cell_content = apks_results[apk][tool][result_type]

                if result_type in LIST_TYPE_RESULTS:

                    cell_content = ", ".join(cell_content)

                worksheet.write(row, col, cell_content)

                col += 1

        row += 1

    workbook.close()

    logging.info("Consolidation complete. Resulting xlsx file is '%s'" % filename)


def main():

    # -- parsing the arguments
    parser = argparse.ArgumentParser(prog="consolidate.py",
                                     description="Consolidates the results from "
                                     "the 'run_experiments.sh' script into a xlsx spreadsheet.",
                                     add_help=True)

    parser.add_argument("results_folder",
                        help="The folder where the results are held.")

    parser.add_argument("-f", "--filename",
                        help="The filename of the resulting xlsx sheet.",
                        required=False,
                        default="ConsolidatedResults.xlsx",
                        dest="filename")

    parser.add_argument("-v", "--verbose",
                        help="Whether or not progress info should be sent to the script's output.",
                        required=False,
                        action="store_true",
                        default=False,
                        dest="verbose")

    args = parser.parse_args()

    FILENAME = os.path.join(os.getcwd(), args.filename)
    INPUT_FOLDER = args.results_folder

    # -- logger setup
    if args.verbose:

        logging.basicConfig(level=logging.DEBUG)

    else:

        logging.basicConfig(level=logging.ERROR)

    # -- extracting the results

    TOOLS = []
    APKS_RESULTS = {}

    for apk in list_only_dirs(INPUT_FOLDER):

        logging.debug("Analysing folder '%s'" % apk)

        apk_folder = os.path.join(INPUT_FOLDER, apk)

        # add the apk tothe APKS_RESULTS dict
        APKS_RESULTS[apk] = apk_map = OrderedDict()

        for tool in list_only_dirs(apk_folder):

            logging.debug("Analysing the results of tool '%s'" % tool)

            tool_dir = os.path.join(apk_folder, tool)

            # add to the 'tools' list
            if tool not in TOOLS:

                TOOLS.append(tool)

            # add the tool results to the apk map
            apk_map[tool] = tool_map = {}

            for result in list_only_files(tool_dir):

                result_file = os.path.join(tool_dir, result)

                # handle each result file differently
                handle_results_file(result_file, result, tool_map, tool)

    # -- creating the sheet
    create_spreadsheet(FILENAME, APKS_RESULTS, TOOLS)

if __name__ == "__main__":

    main()
