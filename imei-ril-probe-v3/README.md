# RMX3830 IMEI RIL Probe v3

This is a non-invasive follow-up to the v2 access test.

v2 showed that the RMX3830 exposes /dev/spipe_lte1 as the configured modem NV endpoint and /dev/sdiag_lte as the configured diagnostic endpoint.

v3 does not open those devices. It determines which RIL/modem processes already have them open by inspecting /proc file-descriptor links. This avoids stealing or consuming shared modem traffic.

It also records the configured modem endpoints, node metadata, RIL process list and Unisoc radio services.

No modem bytes are read or written. No NV partition is opened. No ioctl or property change is performed.

Run Action in Magisk. The report is saved under:
 /sdcard/Download/RMX3830_IMEI_RIL_Probe/
