# RMX3830 SIM2 CarrierFix

Independent Magisk module for investigating and recovering SIM2 registration on realme C51 (RMX3830).

## Diagnostic basis

The device dump showed DSDS, two loaded SIMs, SIM2/phoneId=1 as Beeline UZ (43404), repeated GSM/WCDMA/HSPA visibility, but phoneId=1 remained OUT_OF_SERVICE/emergency-only. CarrierConfigLoader repeatedly restored the phoneId=1 cached configuration, and the shown cached config reported mccmnc=[43405], matching SIM1/Ucell rather than SIM2/Beeline.

## Safety

This module does not modify modem NV, EFS, IMEI, modem firmware, SIM authentication data, or persist.radio registration controls. It only removes the stale phoneId=1 CarrierConfig cache entry observed in the dump and records the regenerated state.

## Installation

Build the ZIP from GitHub Actions, install it in Magisk, reboot, wait 1-2 minutes, then check SIM2 registration.

## Diagnostics

su -c 'cat /data/adb/rmx3830_sim2_carrierfix.log'
su -c 'logcat -b radio -d -v threadtime | tail -n 500'
su -c 'dumpsys telephony.registry'
