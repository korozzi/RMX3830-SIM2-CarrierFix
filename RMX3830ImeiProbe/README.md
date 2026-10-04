# RMX3830 IMEI Probe

Standalone modern LibXposed/LSPosed diagnostic module for realme RMX3830.

## Safety
- Read-only diagnostics only.
- Does not write NV/fixnv/prodnv.
- Does not change IMEI.
- Does not use resetprop.
- Logs IMEI/device-ID getter results with all but the last 4 characters masked.

## Scope
- android
- com.android.phone

## Build
Uses LibXposed API 101.0.0.

Requires Android SDK 35, JDK 17, and Gradle/Android Gradle Plugin compatible with the files in this project.

## What to inspect after installation
Enable the module for the two scopes above, reboot, then collect:

logcat -d | grep -F RMX3830ImeiProbe

The module preserves every original method return value.
