#!/system/bin/sh
LOG=/data/adb/rmx3830_sim2_carrierfix.log
exec >>"$LOG" 2>&1

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 20

echo "=== RMX3830 SIM2 CarrierFix 2.0.0: service $(date) ==="
echo "--- SIM props ---"
getprop gsm.sim.state
getprop gsm.operator.alpha
getprop gsm.operator.numeric
getprop gsm.operator.iso-country
getprop gsm.network.type
getprop persist.vendor.radio.phone_count
getprop persist.vendor.radio.primarysim
getprop persist.vendor.radio.nitz.info.sim1
getprop persist.vendor.radio.nitz.info.sim2
getprop persist.radio.multisim.config
getprop persist.vendor.radio.modem.capability
getprop persist.vendor.radio.modem.config
getprop persist.vendor.radio.modem.workmode

echo "--- CarrierConfig files ---"
for base in /data/user_de/0/com.android.phone /data/data/com.android.phone /data/user_de/0/com.android.providers.telephony /data/data/com.android.providers.telephony; do
  [ -d "$base" ] || continue
  find "$base" -type f -name 'carrierconfig-com.android.carrierconfig-*.xml' -print
done

echo "--- SIM2 registry snapshot ---"
dumpsys telephony.registry 2>/dev/null | grep -E 'phoneId=1|subId=1|Beeline UZ|43404|OUT_OF_SERVICE|NOT_REG_OR_SEARCHING|rejectCause' | tail -n 250

echo "--- radio snapshot ---"
logcat -b radio -d -v threadtime 2>/dev/null | grep -Ei 'phoneId=1|subId=1|43404|Beeline|reject|denied|forbidden|registration|attach|auth|aka|SIM|UICC' | tail -n 500

echo "service complete"
