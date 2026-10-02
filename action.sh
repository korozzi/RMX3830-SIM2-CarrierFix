#!/system/bin/sh
OUT="/sdcard/Download/RMX3830_NV_Backup"
TS="$(date +%Y%m%d_%H%M%S)"
DEST="$OUT/$TS"
LOG="$DEST/backup.log"
mkdir -p "$DEST" || exit 1
exec >>"$LOG" 2>&1
echo "=== RMX3830 NV BACKUP ==="
echo "Started: $(date)"
echo "Model: $(getprop ro.product.model)"
echo "Device: $(getprop ro.product.device)"
echo "Board: $(getprop ro.product.board)"
echo "Hardware: $(getprop ro.hardware)"
backup_part() {
  NAME="$1"
  SRC="/dev/block/by-name/$NAME"
  DST="$DEST/$NAME.img"
  echo "--- $NAME ---"
  [ -e "$SRC" ] || { echo "MISSING: $SRC"; return 1; }
  echo "size=$(blockdev --getsize64 "$SRC" 2>/dev/null || echo unknown)"
  dd if="$SRC" of="$DST" bs=4M || { rm -f "$DST"; return 1; }
  sync
  echo "sha256=$(sha256sum "$DST" 2>/dev/null | awk '{print $1}')"
}
OK=0
FAIL=0
for NAME in prodnv l_fixnv1_a l_fixnv1_b l_fixnv2_a l_fixnv2_b; do
  if backup_part "$NAME"; then OK=$((OK+1)); else FAIL=$((FAIL+1)); fi
done
echo "--- IMEI info (read-only) ---"
dumpsys iphonesubinfo 2>&1 | grep -Ei 'imei|slot|phoneId|deviceId' || true
echo "Completed: $(date)"
echo "Successful=$OK Failed=$FAIL"
echo "Backup=$DEST"
echo "READ-ONLY: no NV/modem partition was written."
