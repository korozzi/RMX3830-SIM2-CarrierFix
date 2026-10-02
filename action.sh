#!/system/bin/sh
set -u

ROOT="/sdcard/Download/RMX3830_NV_Analyzer"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$ROOT/analysis_$STAMP"
LOG="$OUT/report.txt"
mkdir -p "$OUT"
exec >"$LOG" 2>&1

echo "=== RMX3830 UMS9230 NV ANALYZER ==="
echo "Started: $(date)"
echo "READ-ONLY: this module does not write NV/modem partitions."
echo

echo "--- DEVICE ---"
getprop ro.product.model
getprop ro.product.device
getprop ro.board.platform
getprop ro.boot.hardware
getprop ro.boot.slot_suffix
echo

echo "--- CURRENT TELEPHONY IDENTIFIERS ---"
for CMD in "dumpsys iphonesubinfo" "dumpsys telephony.registry" "getprop"; do
  echo "### $CMD"
  sh -c "$CMD" 2>/dev/null | grep -Eo '[0-9]{15}' | sort -u || true
done
echo

echo "--- PARTITIONS ---"
for NAME in prodnv l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b l_runtimenv1 l_runtimenv2; do
  DEV="/dev/block/by-name/$NAME"
  if [ -e "$DEV" ]; then
    echo "[$NAME]"
    stat -c 'size=%s' "$DEV" 2>/dev/null || true
    sha256sum "$DEV" 2>/dev/null || true
    dd if="$DEV" of="$OUT/$NAME.head.bin" bs=512 count=1 2>/dev/null || true
    od -An -tx1 -N 64 "$OUT/$NAME.head.bin" 2>/dev/null || true
  else
    echo "[$NAME] MISSING"
  fi
done
echo

echo "--- A/B COMPARISON ---"
for PAIR in "l_fixnv1_a l_fixnv2_a" "l_fixnv1_b l_fixnv2_b" "l_fixnv1_a l_fixnv1_b" "l_fixnv2_a l_fixnv2_b"; do
  set -- $PAIR
  A="/dev/block/by-name/$1"
  B="/dev/block/by-name/$2"
  if [ -e "$A" ] && [ -e "$B" ]; then
    HA="$(sha256sum "$A" 2>/dev/null | awk '{print $1}')"
    HB="$(sha256sum "$B" 2>/dev/null | awk '{print $1}')"
    if [ "$HA" = "$HB" ]; then
      echo "$1 == $2 : IDENTICAL"
    else
      echo "$1 != $2 : DIFFERENT"
    fi
  fi
done
echo

find_imei_patterns() {
  IMEI="$1"
  LABEL="$2"
  [ "${#IMEI}" -eq 15 ] || return 0
  echo "### $LABEL / IMEI=$IMEI"

  for NAME in l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b l_runtimenv1 l_runtimenv2; do
    DEV="/dev/block/by-name/$NAME"
    [ -e "$DEV" ] || continue
    HIT="$(grep -aob -m 5 "$IMEI" "$DEV" 2>/dev/null || true)"
    [ -n "$HIT" ] && echo "$NAME ASCII: $HIT"
  done
}

IMEIS="$(for CMD in "dumpsys iphonesubinfo" "dumpsys telephony.registry"; do sh -c "$CMD" 2>/dev/null; done | grep -Eo '[0-9]{15}' | sort -u || true)"
if [ -n "$IMEIS" ]; then
  while IFS= read -r I; do
    find_imei_patterns "$I" "Android-exposed identifier"
  done <<EOF
$IMEIS
EOF
else
  echo "No 15-digit IMEI-like identifier was exposed by dumpsys."
fi

echo
echo "--- RAW NV TEXT MARKERS ---"
for NAME in l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b l_runtimenv1 l_runtimenv2; do
  DEV="/dev/block/by-name/$NAME"
  [ -e "$DEV" ] || continue
  echo "[$NAME]"
  grep -aob -m 20 -E 'IMEI|imei|NV|nv' "$DEV" 2>/dev/null || true
done

echo
echo "--- CONCLUSION ---"
echo "The report identifies:"
echo "1) which NV partitions exist and their hashes;"
echo "2) whether A/B NV copies are identical;"
echo "3) which 15-digit identifiers Android exposes;"
echo "4) whether those identifiers occur as plain ASCII in the NV partitions."
echo
echo "If the current IMEI is not found in these raw forms, the NV data is encoded/structured and a blind byte patch is NOT justified."
echo "Completed: $(date)"
echo "Report: $LOG"
