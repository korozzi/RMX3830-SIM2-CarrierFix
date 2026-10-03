#!/system/bin/sh
MODDIR=${0%/*}
CFG=/data/adb/rmx3830_original_imei_test/imei.conf
LOGDIR=/data/adb/rmx3830_original_imei_test
LOGFILE="$LOGDIR/service.log"
mkdir -p "$LOGDIR"
exec >>"$LOGFILE" 2>&1

echo "=== RMX3830 Original IMEI Test ==="
echo "Started: $(date)"
echo "Mode: volatile property layer only; no NV partition writes."

if [ ! -f "$CFG" ]; then
  echo "ERROR: $CFG is missing."
  echo "Create it with:"
  echo "IMEI1=<your original IMEI1>"
  echo "IMEI2=<your original IMEI2>"
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

echo "Device: $(getprop ro.product.model) / $(getprop ro.product.device)"
echo "Platform: $(getprop ro.board.platform)"
echo "--- applying configured values to volatile candidate properties ---"

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

echo "--- verification ---"
getprop | grep -Ei '(^|\])\[([^]]*imei[^]]*)\]' || true
echo "--- telephony after property injection ---"
dumpsys iphonesubinfo 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
dumpsys telephony.registry 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
echo "Finished: $(date)"
