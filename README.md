# RMX3830 NV Analyzer

Read-only diagnostic Magisk module for realme C51 / RMX3830 / UMS9230.

This is the final diagnostic step before any IMEI repair attempt. It does not write, erase, restore, or patch any NV/modem partition.

## What it checks

- current Android-exposed 15-digit telephony identifiers;
- existence and SHA-256 of `prodnv`, `l_fixnv1/2`, and `l_runtimenv1/2`;
- A/B and main/backup NV equality;
- raw ASCII occurrence of the currently exposed IMEI;
- raw NV text markers and partition headers.

The report is written to:

`/sdcard/Download/RMX3830_NV_Analyzer/analysis_<timestamp>/report.txt`

The module is intentionally read-only. If the current IMEI is absent even from the raw representations, the next repair step must use the actual Unisoc NV record format rather than an arbitrary offset.

Public UMS9230 tooling examples show IMEI values being read from `l_fixnv1`, while partition references identify `l_fixnv1` as the IMEI store and `l_fixnv2` / runtime NV as backup-related storage. The exact byte-level record format is firmware/device specific.
