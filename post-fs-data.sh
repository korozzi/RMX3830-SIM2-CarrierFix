#!/system/bin/sh
LOG=/data/adb/rmx3830_sim2_carrierfix.log
exec >>"$LOG" 2>&1
echo "=== RMX3830 SIM2 CarrierFix 3.0.0: post-fs-data $(date) ==="

# Clear only CarrierConfig cache files. Never touch IMEI/NV/EFS.
for base in /data/user_de/0/com.android.phone /data/data/com.android.phone /data/user_de/0/com.android.providers.telephony /data/data/com.android.providers.telephony; do
  [ -d "$base" ] || continue
  find "$base" -type f -name 'carrierconfig-com.android.carrierconfig-*.xml' -print -delete
done

# Remove only persistent CarrierConfig shell overrides for SIM2, if the Android build exposes this command.
# This does not modify modem NV, SIM data, IMEI, or EFS.
if cmd phone cc clear-values -s 1 >/tmp/rmx3830_cc_clear.out 2>/tmp/rmx3830_cc_clear.err; then
  echo "carrier config persistent overrides for slot1 cleared"
else
  echo "carrier config override clear unavailable/failed:"
  cat /tmp/rmx3830_cc_clear.err 2>/dev/null
fi
rm -f /tmp/rmx3830_cc_clear.out /tmp/rmx3830_cc_clear.err

echo "carrierconfig cache clear complete"
echo "post-fs-data complete"
