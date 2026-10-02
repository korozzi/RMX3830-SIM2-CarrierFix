#!/system/bin/sh
LOG=/data/adb/rmx3830_sim2_carrierfix.log
exec >>"$LOG" 2>&1
echo "=== RMX3830 SIM2 CarrierFix 2.0.0: post-fs-data $(date) ==="

# Only clear CarrierConfig cache entries. Never touch IMEI/NV/EFS.
for base in /data/user_de/0/com.android.phone /data/data/com.android.phone /data/user_de/0/com.android.providers.telephony /data/data/com.android.providers.telephony; do
  [ -d "$base" ] || continue
  find "$base" -type f -name 'carrierconfig-com.android.carrierconfig-*.xml' -print -delete
done

echo "carrierconfig cache clear complete"
echo "post-fs-data complete"
