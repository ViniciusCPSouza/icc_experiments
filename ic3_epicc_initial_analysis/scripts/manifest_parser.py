#!/usr/bin/env python3

"""
    ...
"""

import xml.etree.ElementTree as ET
import sys


ANDROID_SCHEMA = "{http://schemas.android.com/apk/res/android}"
RESULT_FILE = "components.txt"

class ComponentType():

    def __init__(self, name):

        self.name = name
        self.elements = []

    def __str__(self):

        return str(self.elements)

    def __repr__(self):

        return "%s list: %s" % (self.name, str(self.elements))

    def _get_attr(self, xml_obj, attr):

        return xml_obj.get("%s%s" % (ANDROID_SCHEMA, attr))

    def find(self, application):

        self.elements.extend([self._get_attr(elem, "name") for elem in application.findall(self.name)])


COMPONENT_TYPES = ("activity",
                   "service",
                   "receiver",
                   "provider")

def main():

    filename = sys.argv[1]

    root = ET.parse(filename).getroot()

    package = root.get("package")

    components = [ComponentType(key_type) for key_type in COMPONENT_TYPES]

    apps = root.findall("application")

    for app in apps:

        for component in components:

            component.find(app)

    # write the results to a file
    with open(RESULT_FILE, 'w') as out:

        for component in components:

            for elem in component.elements:

                out.write("%s: %s\n" % (component.name, elem))

if __name__ == "__main__":

    main()
