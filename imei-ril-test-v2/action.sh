#!/system/bin/sh
OUT=/sdcard/Download/RMX3830_IMEI_RIL_Test
mkdir -p "$OUT"
LOG="$OUT/test_$(date +%Y%m%d_%H%M%S).txt"
exec >"$LOG" 2>&1

echo "=== RMX3830 IMEI RIL/DIAG ACCESS TEST v2 ==="
echo "Started: $(date)"
echo "READ-ONLY: no NV write, no modem command, no ioctl, no property injection."
echo

echo "--- DEVICE ---"
getprop ro.product.model
getprop ro.product.device
getprop ro.board.platform
getprop ro.boot.hardware
getprop ro.boot.slot_suffix
echo

echo "--- MODEM PROPERTIES ---"
getprop | grep -Ei 'modem|radio|ril|imei|diag' || true
echo

echo "--- MODEM NODES ---"
for N in /dev/spipe_lte0 /dev/spipe_lte1 /dev/spipe_lte2 /dev/spipe_lte3 /dev/sdiag_lte /dev/stty_lte /dev/slog_lte; do
  if [ -e "$N" ]; then
    echo "EXISTS: $N"
    ls -lZ "$N" 2>/dev/null || ls -l "$N"
    if [ -r "$N" ]; then echo "  readable=yes"; else echo "  readable=no"; fi
    if [ -w "$N" ]; then echo "  writable=yes"; else echo "  writable=no"; fi
  else
    echo "MISSING: $N"
  fi
done
echo

echo "--- SELINUX ---"
getenforce 2>/dev/null || true
echo

echo "--- RADIO/RIL PROCESSES ---"
ps -A 2>/dev/null | grep -Ei 'rild|radio|modem|ims|ril' | grep -v grep || true
echo

echo "--- ANDROID RADIO SERVICES ---"
service list 2>/dev/null | grep -Ei 'phone|telephony|radio|ims' || true
echo

echo "--- CURRENT TELEPHONY IDENTIFIERS ---"
echo "iphonesubinfo:"
dumpsys iphonesubinfo 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
echo "telephony.registry:"
dumpsys telephony.registry 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
echo

echo "--- NV PARTITION ACCESS (METADATA ONLY) ---"
for N in prodnv l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b l_runtimenv1 l_runtimenv2 l_deltanv_a l_deltanv_b; do
  P=""
  for C in /dev/block/by-name/$N /dev/block/bootdevice/by-name/$N /dev/block/platform/*/by-name/$N; do
    if [ -e "$C" ]; then P="$C"; break; fi
  done
  if [ -n "$P" ]; then
    echo "$N -> $P"
    ls -lZ "$P" 2>/dev/null || ls -l "$P"
  else
    echo "$N -> NOT FOUND"
  fi
done
echo

echo "--- RESULT ---"
echo "This test only establishes which RIL/Diag/NV interfaces are exposed to root."
echo "It does not prove that an interface accepts an IMEI write."
echo "No modem node was opened for data transfer and no NV partition was written."
echo
echo "Log: $LOG"
