#!/system/bin/sh
OUT="/data/local/tmp/rmx3830-imei-diag-$(date +%Y%m%d-%H%M%S).txt"
exec >"$OUT" 2>&1
echo 'RMX3830 IMEI DIAGNOSTICS'
echo "time: $(date)"
echo
echo '== identity =='
getprop ro.product.model
getprop ro.product.device
getprop ro.build.version.release
echo
echo '== modem properties =='
getprop | grep -Ei 'ro.vendor.modem|persist.vendor.modem|ril|radio|modemversion|oplus_nv_id'
echo
echo '== modem processes =='
ps -A | grep -Ei 'cp_diskserver|modem_control|urild|slogmodem' | grep -v grep
echo
echo '== device nodes =='
for d in /dev/spipe_lte0 /dev/spipe_lte1 /dev/spipe_lte2 /dev/spipe_lte3 /dev/sdiag_lte /dev/stty_lte /dev/slog_lte; do
  if [ -e "$d" ]; then ls -l "$d"; else echo "MISSING $d"; fi
done
echo
echo '== radio services =='
service list | grep -Ei 'radio|telephony|modem'
echo
echo '== fixnv records (read-only) =='
for p in l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b; do
  dev="/dev/block/by-name/$p"
  echo "-- $p --"
  if [ -r "$dev" ]; then
    echo 'item 0x0005 @ 0x16F4:'
    dd if="$dev" bs=1 skip=$((0x16F4)) count=8 2>/dev/null | od -An -tx1
    echo 'item 0x0179 @ 0x1533C:'
    dd if="$dev" bs=1 skip=$((0x1533C)) count=8 2>/dev/null | od -An -tx1
  else echo 'UNREADABLE_OR_MISSING'; fi
done
echo
echo '== fixnv hashes =='
for p in l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b; do
  dev="/dev/block/by-name/$p"
  if [ -r "$dev" ]; then sha256sum "$dev"; fi
done
echo
echo '== Android telephony snapshot =='
dumpsys iphonesubinfo 2>&1 | head -n 120
echo
dumpsys telephony.registry 2>&1 | head -n 120
echo
printf 'REPORT=%s\n' "$OUT"
