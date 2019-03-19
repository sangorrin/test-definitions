#!/bin/sh

#  In target, run command ethtool.
#  option: help

test="help"

if ethtool -h | grep Usage
then
    echo " -> $test: TEST-PASS"
else
    echo " -> $test: TEST-FAIL"
fi;
