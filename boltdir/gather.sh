#!/bin/sh
echo "System Uptime Information:"
uptime
echo
echo "System Memory Information:"
free
echo
echo "System CPU Information: "
lscpu |grep -i '^CPU(s)'
lscpu |grep 'Model name'
