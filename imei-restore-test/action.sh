#!/system/bin/sh
CFG=/data/adb/rmx3830_original_imei_test/imei.conf
OUT=/sdcard/Download/RMX3830_Original_IMEI_Test
mkdir -p "$OUT"
LOG="$OUT/test_$(date +%Y%m%d_%H%M%S).txt"
exec >"$LOG" 2>&1

echo "=== RMX3830 Original IMEI Test / ACTION ==="
echo "Started: $(date)"
echo "This action changes only volatile Android properties."
echo "It does NOT write prodnv, fixnv, runtimenv, modem NV, or persistent property storage."
echo

if [ ! -f "$CFG" ]; then
  echo "ERROR: $CFG is missing."
  echo "Create it with:"
  echo "IMEI1=<your original IMEI1>"
  echo "IMEI2=<your original IMEI2>"
  echo "Log: $LOG"
  exit 1
fi
. "$CFG"

case "${IMEI1:-}" in ''|*[!0-9]*) echo "ERROR: invalid IMEI1"; exit 1;; esac
case "${IMEI2:-}" in ''|*[!0-9]*) echo "ERROR: invalid IMEI2"; exit 1;; esac
[ "${#IMEI1}" = 15 ] || { echo "ERROR: IMEI1 must be 15 digits"; exit 1; }
[ "${#IMEI2}" = 15 ] || { echo "ERROR: IMEI2 must be 15 digits"; exit 1; }

setp() {
  NAME="$1"
  VALUE="$2"
  OLD="$(resetprop "$NAME" 2>/dev/null || true)"
  resetprop -n "$NAME" "$VALUE" 2>&1 || true
  NEW="$(resetprop "$NAME" 2>/dev/null || true)"
  echo "$NAME: [$OLD] -> [$NEW]"
}

echo "--- BEFORE ---"
for P in ro.ril.oem.imei ro.ril.oem.imei1 ro.ril.oem.imei2 ro.vendor.radio.imei ro.vendor.radio.imei1 ro.vendor.radio.imei2 vendor.ril.imei vendor.ril.imei1 vendor.ril.imei2 ril.gsm.imei ril.gsm.imei1 ril.gsm.imei2 ro.boot.imei1 ro.boot.imei2; do
  printf "%s=" "$P"; resetprop "$P" 2>/dev/null || true
done

echo
echo "--- APPLY ---"
setp ro.ril.oem.imei "$IMEI1"
setp ro.ril.oem.imei1 "$IMEI1"
setp ro.ril.oem.imei2 "$IMEI2"
setp ro.vendor.radio.imei "$IMEI1"
setp ro.vendor.radio.imei1 "$IMEI1"
setp ro.vendor.radio.imei2 "$IMEI2"
setp vendor.ril.imei "$IMEI1"
setp vendor.ril.imei1 "$IMEI1"
setp vendor.ril.imei2 "$IMEI2"
setp ril.gsm.imei "$IMEI1"
setp ril.gsm.imei1 "$IMEI1"
setp ril.gsm.imei2 "$IMEI2"
setp ro.boot.imei1 "$IMEI1"
setp ro.boot.imei2 "$IMEI2"

echo
echo "--- AFTER ---"
getprop | grep -Ei '(^|\])\[([^]]*imei[^]]*)\]' || true
echo
echo "--- TELEPHONY CHECK ---"
dumpsys iphonesubinfo 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
dumpsys telephony.registry 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
echo
echo "Test complete."
echo "Log: $LOG"
