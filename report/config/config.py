#!/usr/bin/python
from configparser import ConfigParser
import os

BASE_DIR = os.getcwd()
SQL_DIR = os.path.join(BASE_DIR, 'config/')


def config(filename=SQL_DIR + 'database.ini', section='covid19'):
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)

    # get section, default to postgresql
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))

    return db