#!/system/bin/sh
LOG=/data/adb/rmx3830_sim2_carrierfix.log
exec >>"$LOG" 2>&1

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 20

echo "=== RMX3830 SIM2 CarrierFix 3.1.0: service $(date) ==="

echo "--- SIM/modem props BEFORE clear ---"
for p in gsm.sim.state gsm.operator.alpha gsm.operator.numeric gsm.operator.iso-country gsm.network.type persist.vendor.radio.phone_count persist.vendor.radio.primarysim persist.vendor.radio.nitz.info.sim1 persist.vendor.radio.nitz.info.sim2 persist.radio.multisim.config persist.vendor.radio.modem.capability persist.vendor.radio.modem.config persist.vendor.radio.modem.workmode; do
  echo "$p=$(getprop "$p")"
done

echo "--- subscription/slot mapping ---"
dumpsys isub 2>&1 | grep -Ei 'subId|slot|carrier|43404|43405|Beeline|Ucell' | tail -n 250

echo "--- clear SIM2 CarrierConfig persistent overrides ---"
cmd phone cc clear-values -s 1 > /data/adb/rmx3830_cc_clear.out 2>&1
CC_RC=$?
echo "cmd phone cc clear-values -s 1 rc=$CC_RC"
cat /data/adb/rmx3830_cc_clear.out 2>/dev/null
rm -f /data/adb/rmx3830_cc_clear.out

# Give CarrierConfigLoader time to rebuild the config for the loaded SIM.
sleep 8

echo "--- SIM2 CarrierConfig values AFTER clear ---"
for k in mccmnc carrier_config_applied_bool carrier_config_version_string carrier_volte_available_bool carrier_vt_available_bool prefer_2g_bool hide_enable_2g_bool config_ims_package_override_string carrier_metered_apn_types_strings carrier_metered_roaming_apn_types_strings; do
  echo "### $k"
  cmd phone cc get-value -s 1 "$k" 2>&1 || true
done

echo "--- CarrierConfig files AFTER clear ---"
for base in /data/user_de/0/com.android.phone /data/data/com.android.phone /data/user_de/0/com.android.providers.telephony /data/data/com.android.providers.telephony; do
  [ -d "$base" ] || continue
  find "$base" -type f -name 'carrierconfig-com.android.carrierconfig-*.xml' -print
done

echo "--- SIM2 registry ---"
dumpsys telephony.registry 2>/dev/null | grep -E 'phoneId=1|subId=1|Beeline UZ|43404|OUT_OF_SERVICE|NOT_REG_OR_SEARCHING|NOT_REG_MT|reasonForDenial|rejectCause' | tail -n 350

echo "--- SIM2 radio registration/auth/NITZ ---"
logcat -b radio -d -v threadtime 2>/dev/null | grep -Ei 'phoneId=1|subId=1|PHONE1|simId\[1\]|43404|Beeline|reject|denied|forbidden|registration|attach|auth|aka|nitz|UICC|carrier.?config' | tail -n 1000

echo "--- relevant system log ---"
logcat -d -v threadtime 2>/dev/null | grep -Ei 'CarrierConfig|CarrierConfigLoader|SubscriptionInfo|LocaleTracker-1|NitzStateMachineImpl|phoneId=1|subId=1|43404|Beeline' | tail -n 600

echo "service complete"
