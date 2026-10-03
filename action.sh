#!/system/bin/sh
set -u

ROOT="/sdcard/Download/RMX3830_NV_Analyzer"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$ROOT/analysis_$STAMP"
LOG="$OUT/report.txt"
mkdir -p "$OUT"
exec >"$LOG" 2>&1

echo "=== RMX3830 UMS9230 NV / MODEM READ-ONLY TEST ==="
echo "Started: $(date)"
echo "SAFETY: READ-ONLY. No NV/modem partition is opened for writing."
echo
echo "--- DEVICE / MAGISK CONTEXT ---"
for P in ro.product.model ro.product.device ro.board.platform ro.boot.hardware ro.boot.slot_suffix ro.vendor.modem.nv ro.vendor.modem.diag ro.vendor.modem.tty ro.vendor.radio.imei.sv; do printf "%s=" "$P"; getprop "$P"; done
echo "id=$(id 2>/dev/null || true)"
echo "getenforce=$(getenforce 2>/dev/null || true)"
echo
echo "--- MODEM INTERFACES (NO READ/WRITE ATTEMPT) ---"
for DEV in /dev/spipe_lte0 /dev/spipe_lte1 /dev/spipe_lte2 /dev/spipe_lte3 /dev/sdiag_lte /dev/stty_lte /dev/slog_lte; do
  if [ -e "$DEV" ]; then
    echo "[$DEV] EXISTS"
    ls -lZ "$DEV" 2>/dev/null || ls -l "$DEV" 2>/dev/null || true
    stat -c "mode=%a uid=%u gid=%g type=%F size=%s" "$DEV" 2>/dev/null || true
  else echo "[$DEV] MISSING"; fi
done
echo "No open/read/write operation is performed on modem character devices."
echo
echo "--- CURRENT TELEPHONY IDENTIFIERS ---"
for CMD in "dumpsys iphonesubinfo" "dumpsys telephony.registry"; do echo "### $CMD"; sh -c "$CMD" 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true; done
echo
echo "--- PARTITION MAP / ACCESS ---"
for NAME in prodnv l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b l_runtimenv1 l_runtimenv2 l_deltanv_a l_deltanv_b; do
  DEV="/dev/block/by-name/$NAME"
  if [ -e "$DEV" ]; then
    echo "[$NAME] $DEV"
    ls -lZ "$DEV" 2>/dev/null || ls -l "$DEV" 2>/dev/null || true
    stat -c "size=%s mode=%a uid=%u gid=%g type=%F" "$DEV" 2>/dev/null || true
    sha256sum "$DEV" 2>/dev/null || true
    dd if="$DEV" of="$OUT/$NAME.head.bin" bs=512 count=1 2>/dev/null || true
    od -An -tx1 -N 64 "$OUT/$NAME.head.bin" 2>/dev/null || true
  else echo "[$NAME] MISSING"; fi
done
echo
echo "--- A/B COMPARISON ---"
for PAIR in "l_fixnv1_a l_fixnv1_b" "l_fixnv2_a l_fixnv2_b" "l_fixnv1_a l_fixnv2_a" "l_fixnv1_b l_fixnv2_b"; do
  set -- $PAIR; A="/dev/block/by-name/$1"; B="/dev/block/by-name/$2"
  if [ -e "$A" ] && [ -e "$B" ]; then
    HA="$(sha256sum "$A" 2>/dev/null | awk "{print \$1}")"; HB="$(sha256sum "$B" 2>/dev/null | awk "{print \$1}")"
    if [ "$HA" = "$HB" ]; then echo "$1 == $2 : IDENTICAL"; else echo "$1 != $2 : DIFFERENT"; fi
  fi
done
echo
find_imei_patterns() {
  IMEI="$1"; LABEL="$2"; [ "${#IMEI}" -eq 15 ] || return 0; echo "### $LABEL / IMEI=$IMEI"
  for NAME in l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b l_runtimenv1 l_runtimenv2; do
    DEV="/dev/block/by-name/$NAME"; [ -e "$DEV" ] || continue
    HIT="$(grep -aob -m 5 "$IMEI" "$DEV" 2>/dev/null || true)"; [ -n "$HIT" ] && echo "$NAME ASCII: $HIT"
  done
}
IMEIS="$(for CMD in "dumpsys iphonesubinfo" "dumpsys telephony.registry"; do sh -c "$CMD" 2>/dev/null; done | grep -Eo "[0-9]{15}" | sort -u || true)"
if [ -n "$IMEIS" ]; then while IFS= read -r I; do find_imei_patterns "$I" "Android-exposed identifier"; done <<EOF
$IMEIS
EOF
else echo "No 15-digit IMEI-like identifier was exposed by dumpsys."; fi
echo
echo "--- RAW NV TEXT MARKERS ---"
for NAME in l_fixnv1_a l_fixnv2_a l_fixnv1_b l_fixnv2_b l_runtimenv1 l_runtimenv2; do DEV="/dev/block/by-name/$NAME"; [ -e "$DEV" ] || continue; echo "[$NAME]"; grep -aob -m 20 -E "IMEI|imei|NV|nv" "$DEV" 2>/dev/null || true; done
echo
echo "--- CONCLUSION ---"
echo "This test only checks Android/root visibility, device-node permissions, partition access, hashes, A/B equality and read-only raw representations."
echo "It does NOT write, erase, patch, resetprop, or restore any IMEI/NV/modem data."
echo "If modem nodes exist but no IMEI is found in raw ASCII, that does not prove the IMEI is absent: Unisoc NV data may use a structured/binary record format."
echo "Completed: $(date)"
echo "Report: $LOG"
