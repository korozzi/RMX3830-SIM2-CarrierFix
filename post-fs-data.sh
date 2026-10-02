#!/system/bin/sh
LOG=/data/adb/rmx3830_sim2_carrierfix.log
exec >>"$LOG" 2>&1
echo "=== RMX3830 SIM2 CarrierFix 3.1.0: post-fs-data $(date) ==="

# Early stage: only remove stale CarrierConfig cache files.
# No phone command is run here because Android telephony is not fully started yet.
for base in /data/user_de/0/com.android.phone /data/data/com.android.phone /data/user_de/0/com.android.providers.telephony /data/data/com.android.providers.telephony; do
  [ -d "$base" ] || continue
  find "$base" -type f -name 'carrierconfig-com.android.carrierconfig-*.xml' -print -delete
done

echo "early carrierconfig cache clear complete"
echo "post-fs-data complete"
