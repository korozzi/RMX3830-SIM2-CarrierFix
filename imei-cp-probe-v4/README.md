# RMX3830 cp_diskserver Analyzer v4

Read-only Magisk test module for the realme C51 RMX3830.

## Purpose

The previous probe established that the stock process /vendor/bin/cp_diskserver owns /dev/spipe_lte1, while /vendor/bin/modem_control owns /dev/spipe_lte2. The Android property ro.vendor.modem.nv points to /dev/spipe_lte1.

v4 therefore inspects the existing stock process and its binary instead of opening the shared modem endpoint itself.

## What it collects

- cp_diskserver executable permissions, SELinux label, size, SHA-256 and ELF type when available
- running PID(s), command line, executable path and process status
- loaded library paths
- fd links and fdinfo for relevant modem endpoints
- read-only strings from /vendor/bin/cp_diskserver filtered for NV/modem/IMEI/SPipe/diagnostic terms
- narrowly scoped likely configuration and init/service references

## Safety

This module does not open or read from modem character devices and does not access NV partitions. It does not execute cp_diskserver, issue ioctl calls, change properties, or write/erase anything.

## Output

/sdcard/Download/RMX3830_IMEI_CP_Probe/report.txt

After running the action from Magisk, upload report.txt for analysis.
