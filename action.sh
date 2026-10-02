#!/system/bin/sh
set -eu
ROOT="/sdcard/Download/RMX3830_NV_Backup"
STAMP="$(date +%Y%m%d_%H%M%S)"
SAFE="$ROOT/RESTORE_PREVIOUS_$STAMP"
LOG="$ROOT/restore_$STAMP.log"
mkdir -p "$ROOT" "$SAFE"
exec >>"$LOG" 2>&1
echo "=== RMX3830 NV RESTORE ==="
echo "Started: $(date)"
MARKER="$ROOT/RESTORE_NOW"
if [ ! -f "$MARKER" ]; then
  echo "ABORT: create $MARKER to explicitly authorize restore."
  echo "No NV partition was written."
  exit 2
fi
rm -f "$MARKER"
LATEST="$(ls -1dt "$ROOT"/*/ 2>/dev/null | grep -v '/RESTORE_PREVIOUS_' | head -n 1 || true)"
[ -n "$LATEST" ] || { echo "ABORT: no backup directory found."; exit 3; }
echo "Backup: $LATEST"
check_part() {
  NAME="$1"; EXPECTED="$2"; SRC="$LATEST/$NAME.img"; DEV="/dev/block/by-name/$NAME"
  [ -f "$SRC" ] || { echo "ABORT: missing $SRC"; exit 4; }
  ACTUAL="$(stat -c %s "$SRC")"
  [ "$ACTUAL" = "$EXPECTED" ] || { echo "ABORT: bad size for $NAME ($ACTUAL != $EXPECTED)"; exit 5; }
  [ -e "$DEV" ] || { echo "ABORT: missing $DEV"; exit 6; }
}
check_part prodnv 67108864
check_part l_fixnv1_a 2097152
check_part l_fixnv1_b 2097152
check_part l_fixnv2_a 2097152
check_part l_fixnv2_b 2097152
echo "--- Creating pre-restore rollback copies ---"
for NAME in prodnv l_fixnv1_a l_fixnv1_b l_fixnv2_a l_fixnv2_b; do
  dd if="/dev/block/by-name/$NAME" of="$SAFE/$NAME.img" bs=4M
  sync
done
echo "--- Restoring backup ---"
for NAME in prodnv l_fixnv1_a l_fixnv1_b l_fixnv2_a l_fixnv2_b; do
  dd if="$LATEST/$NAME.img" of="/dev/block/by-name/$NAME" bs=4M
  sync
done
echo "Completed: $(date)"
echo "Rollback copy: $SAFE"
echo "Restored: $LATEST"
echo "REBOOT REQUIRED."
