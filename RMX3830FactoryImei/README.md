# RMX3830 Factory IMEI Injector

Device-specific restoration layer for a realme RMX3830 / RE58BC / ums9230_hulk.

Factory values supplied for this device:
- IMEI1: 863754010100350
- IMEI2: 863754010100368

This project does not write fixnv/prodnv/runtimenv or send modem NV commands. It injects the factory identifiers at the Android property/framework layer and is deliberately locked to the RMX3830 device profile.

The Magisk side sets an allowlisted set of Android radio/IMEI properties when the device identity matches RMX3830/RE58BC/ums9230_hulk. The LSPosed side intercepts TelephonyManager and internal telephony IMEI/device-id getters and returns the factory pair.

This is a restoration-oriented software layer; it does not repair the modem's persistent NV contents.
