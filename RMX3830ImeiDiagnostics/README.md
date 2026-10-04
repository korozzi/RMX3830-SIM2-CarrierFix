# RMX3830 IMEI Diagnostics

Read-only diagnostics for realme RMX3830 / Unisoc modem + Android telephony.

This project does not write IMEI/NV data, does not spoof properties, and does not modify modem state.

Components: LSPosed diagnostic APK and Magisk root-side diagnostic module.

Known fixnv records: NV item 0x0005 payload at offset 0x16F4 and NV item 0x0179 payload at offset 0x1533C.

No writes are performed.
