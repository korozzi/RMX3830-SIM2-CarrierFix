# RMX3830 Original IMEI Test

Experimental Magisk property-layer test.

The module does not write NV. It uses Magisk resetprop -n to expose user-configured original identifiers through several Android/RIL-related property names.

Create /data/adb/rmx3830_original_imei_test/imei.conf as root:

IMEI1=<your original IMEI1>
IMEI2=<your original IMEI2>

The values are validated as exactly 15 decimal digits.

After installing the module, reboot once. It applies the values during Magisk late-start. The Magisk Action button can also apply the test immediately.

Action logs are written to /sdcard/Download/RMX3830_Original_IMEI_Test/.

No prodnv, l_fixnv*, runtimenv, deltanv, modem character device, or persistent property storage is written by v1.


Build trigger update.
