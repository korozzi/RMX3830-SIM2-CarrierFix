#!/system/bin/sh
set -u

OUTBASE=/sdcard/Download/RMX3830_SIM2_CarrierFix/fixnv_restore_v2
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="$OUTBASE/$STAMP"
LOG="$OUT/restore.log"
mkdir -p "$OUT"
exec >"$LOG" 2>&1

EXPECTED_SIZE=2097152

log(){ echo "$*"; }
fail(){ log "RESULT: FAILED"; log "$*"; exit 1; }

log "=== RMX3830 Original fixnv Restore v2.0.0 ==="
log "Started: $(date)"
log "uid=$(id)"
log "model=$(getprop ro.product.model)"

[ "$(getprop ro.product.model)" = "RMX3830" ] || fail "Wrong model."

find_one(){
  name="$1"; expected_sha="$2"; outvar="$3"
  found=""
  for f in $(find /sdcard/Download -type f -name "$name" 2>/dev/null); do
    [ -f "$f" ] || continue
    sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
    [ "$sz" = "$EXPECTED_SIZE" ] || continue
    sha=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    [ "$sha" = "$expected_sha" ] || continue
    if [ -n "$found" ]; then fail "Multiple valid backups found for $name"; fi
    found="$f"
  done
  [ -n "$found" ] || fail "Verified backup not found: $name"
  eval "$outvar=\"$found\""
  log "$name -> $found"
}

find_one l_fixnv1_a.img beb99e1f48341d431191ae69df98f659aa4ec342aa4fb308d790c6639f7a196b B1
find_one l_fixnv1_b.img 94f6bf65e56e0a1d1c0891cd46b141e5d735070a5380b742e9763ee4aa101e93 B2
find_one l_fixnv2_a.img beb99e1f48341d431191ae69df98f659aa4ec342aa4fb308d790c6639f7a196b B3
find_one l_fixnv2_b.img 94f6bf65e56e0a1d1c0891cd46b141e5d735070a5380b742e9763ee4aa101e93 B4

log "--- Current partition hashes ---"
for n in l_fixnv1_a l_fixnv1_b l_fixnv2_a l_fixnv2_b; do
  d="/dev/block/by-name/$n"
  [ -e "$d" ] || fail "Missing partition $n"
  log "$n $(sha256sum "$d" | awk '{print $1}')"
done

log "--- Stop NV disk service and modem logger ---"
setprop ctl.stop vendor.cp_diskserver
setprop ctl.stop slogmodem
sleep 2
log "cp_diskserver=$(getprop init.svc.vendor.cp_diskserver)"
log "slogmodem=$(getprop init.svc.slogmodem)"
[ "$(getprop init.svc.vendor.cp_diskserver)" = "stopped" ] || fail "cp_diskserver did not stop; no writes performed."
[ "$(getprop init.svc.slogmodem)" = "stopped" ] || fail "slogmodem did not stop; no writes performed."

restore_one(){
  src="$1"; dst="$2"
  log "Restoring $dst from $src"
  dd if="$src" of="$dst" bs=4M conv=fsync 2>&1 || return 1
  sync
  got=$(sha256sum "$dst" | awk '{print $1}')
  want=$(sha256sum "$src" | awk '{print $1}')
  log "$dst SHA256=$got"
  [ "$got" = "$want" ]
}

restore_one "$B1" /dev/block/by-name/l_fixnv1_a || fail "l_fixnv1_a restore/verify failed"
restore_one "$B2" /dev/block/by-name/l_fixnv1_b || fail "l_fixnv1_b restore/verify failed"
restore_one "$B3" /dev/block/by-name/l_fixnv2_a || fail "l_fixnv2_a restore/verify failed"
restore_one "$B4" /dev/block/by-name/l_fixnv2_b || fail "l_fixnv2_b restore/verify failed"

log "--- Start services ---"
setprop ctl.start slogmodem
sleep 3
setprop ctl.start vendor.cp_diskserver
sleep 5
log "cp_diskserver=$(getprop init.svc.vendor.cp_diskserver)"
log "slogmodem=$(getprop init.svc.slogmodem)"

log "--- Immediate post-start hash check ---"
for n in l_fixnv1_a l_fixnv1_b l_fixnv2_a l_fixnv2_b; do
  d="/dev/block/by-name/$n"
  got=$(sha256sum "$d" | awk '{print $1}')
  case "$n" in
    l_fixnv1_a|l_fixnv2_a) want=beb99e1f48341d431191ae69df98f659aa4ec342aa4fb308d790c6639f7a196b;;
    *) want=94f6bf65e56e0a1d1c0891cd46b141e5d735070a5380b742e9763ee4aa101e93;;
  esac
  log "$n $got"
  [ "$got" = "$want" ] || fail "$n changed after modem services restarted."
done

log "Waiting 10 seconds to detect an immediate NV overwrite..."
sleep 10
for n in l_fixnv1_a l_fixnv1_b l_fixnv2_a l_fixnv2_b; do
  d="/dev/block/by-name/$n"
  got=$(sha256sum "$d" | awk '{print $1}')
  case "$n" in
    l_fixnv1_a|l_fixnv2_a) want=beb99e1f48341d431191ae69df98f659aa4ec342aa4fb308d790c6639f7a196b;;
    *) want=94f6bf65e56e0a1d1c0891cd46b141e5d735070a5380b742e9763ee4aa101e93;;
  esac
  log "$n after 10s: $got"
  [ "$got" = "$want" ] || fail "$n was overwritten after restore."
done

log "RESULT: SUCCESS"
log "The four existing original fixnv backups were restored and remained unchanged for 10 seconds after service restart."
log "Reboot the phone once, then check *#06#."
log "Report: $LOG"
