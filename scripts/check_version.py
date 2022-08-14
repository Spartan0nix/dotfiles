#!/usr/bin/python
from subprocess import run
from re import search
from sys import argv, stderr, stdout

if len(argv) < 3:
    stderr.write("Missing required argument 'name' and 'version'.\nArguments passed : {}.".format(argv))
    exit(1)

pkg_name = argv[1]
pkg_version = argv[2]

dpkg_res = run(["dpkg -s {} | grep Version | sed 's/Version\: //'".format(pkg_name)], shell=True, capture_output=True)

if dpkg_res.returncode != 0:
    stderr.write("Error when executing dpkg command.\nReason : {}".format(dpkg_res.stderr))
    exit(1)

current_version = dpkg_res.stdout.decode('utf-8').replace("\n", '')

if search(current_version, pkg_version):
    stdout.write("match")
    exit(0)
else:
    stdout.write("no match")
    exit(0)