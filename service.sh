#!/system/bin/sh
LOG=/data/adb/rmx3830_sim2_carrierfix.log
exec >>"$LOG" 2>&1

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 20

echo "=== RMX3830 SIM2 CarrierFix 3.0.0: service $(date) ==="
echo "--- SIM/modem props ---"
for p in gsm.sim.state gsm.operator.alpha gsm.operator.numeric gsm.operator.iso-country gsm.network.type persist.vendor.radio.phone_count persist.vendor.radio.primarysim persist.vendor.radio.nitz.info.sim1 persist.vendor.radio.nitz.info.sim2 persist.radio.multisim.config persist.vendor.radio.modem.capability persist.vendor.radio.modem.config persist.vendor.radio.modem.workmode; do
  echo "$p=$(getprop "$p")"
done

echo "--- SIM2 carrier config ---"
for k in mccmnc carrier_config_applied_bool carrier_config_version_string carrier_volte_available_bool carrier_vt_available_bool prefer_2g_bool hide_enable_2g_bool config_ims_package_override_string carrier_metered_apn_types_strings carrier_metered_roaming_apn_types_strings; do
  echo "### $k"
  cmd phone cc get-value -s 1 "$k" 2>&1 || true
done

echo "--- CarrierConfig files ---"
for base in /data/user_de/0/com.android.phone /data/data/com.android.phone /data/user_de/0/com.android.providers.telephony /data/data/com.android.providers.telephony; do
  [ -d "$base" ] || continue
  find "$base" -type f -name 'carrierconfig-com.android.carrierconfig-*.xml' -print
done

echo "--- SIM2 subscription/registry ---"
dumpsys telephony.registry 2>/dev/null | grep -E 'phoneId=1|subId=1|Beeline UZ|43404|OUT_OF_SERVICE|NOT_REG_OR_SEARCHING|NOT_REG_MT|reasonForDenial|rejectCause' | tail -n 350

echo "--- SIM2 radio registration/auth/NITZ ---"
logcat -b radio -d -v threadtime 2>/dev/null | grep -Ei 'phoneId=1|subId=1|PHONE1|simId\[1\]|43404|Beeline|reject|denied|forbidden|registration|attach|auth|aka|nitz|UICC|carrier.?config' | tail -n 900

echo "--- relevant system log ---"
logcat -d -v threadtime 2>/dev/null | grep -Ei 'CarrierConfig|CarrierConfigLoader|SubscriptionInfo|LocaleTracker-1|NitzStateMachineImpl|phoneId=1|subId=1|43404|Beeline' | tail -n 500

echo "service complete"
