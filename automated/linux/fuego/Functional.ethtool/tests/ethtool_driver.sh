#!/bin/sh

#  In target, run command ethtool.
#  option: -i

test="driver"

. ./fuego_board_function_lib.sh

ETHERNET_DEVICE_NAME=$(detect_active_eth_device)

if [ "${ETHERNET_DEVICE_NAME}x" = "have no Ethernet devicex" ]
then
    echo " -> $test: TEST-FAIL"
    exit 1
fi

if ethtool -i $ETHERNET_DEVICE_NAME | grep driver
then
    echo " -> $test: TEST-PASS"
else
    echo " -> $test: TEST-FAIL"
fi
