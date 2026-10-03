#!/system/bin/sh
MODDIR="$(dirname "$0")"
OUT="/sdcard/Download/RMX3830_IMEI_CP_Probe"
mkdir -p "$OUT"
LOG="$OUT/report.txt"
: > "$LOG"
exec >"$LOG" 2>&1
echo "RMX3830 cp_diskserver Analyzer v4.0.0"
echo "READ-ONLY: no modem nodes, no NV partitions, no ioctl, no resetprop, no write/erase."
echo
echo "=== TIME / BASIC INFO ==="
date
getprop ro.build.version.release
getprop ro.product.device
getprop ro.vendor.modem.nv
getprop ro.vendor.modem.diag
getprop ro.vendor.modem.tty
echo
echo "=== cp_diskserver PATH / METADATA ==="
ls -lZ /vendor/bin/cp_diskserver 2>&1 || true
stat /vendor/bin/cp_diskserver 2>&1 || true
sha256sum /vendor/bin/cp_diskserver 2>&1 || true
readlink -f /vendor/bin/cp_diskserver 2>&1 || true
file /vendor/bin/cp_diskserver 2>&1 || true
echo
echo "=== RUNNING cp_diskserver PIDS ==="
PIDS="$(for p in /proc/[0-9]*; do
  [ -r "$p/comm" ] || continue
  c="$(cat "$p/comm" 2>/dev/null)"
  [ "$c" = "cp_diskserver" ] && basename "$p"
done)"
printf '%s\n' "$PIDS"
echo
for PID in $PIDS; do
  echo "=== PROCESS $PID ==="
  echo "--- cmdline ---"
  tr '\0' ' ' < "/proc/$PID/cmdline" 2>/dev/null || true
  echo
  echo "--- exe ---"
  readlink "/proc/$PID/exe" 2>&1 || true
  echo "--- status ---"
  cat "/proc/$PID/status" 2>&1 || true
  echo "--- maps (library names only) ---"
  awk '{print $6}' "/proc/$PID/maps" 2>/dev/null | sort -u | grep '^/' || true
  echo "--- fd links ---"
  for F in /proc/$PID/fd/*; do
    [ -e "$F" ] || continue
    L="$(readlink "$F" 2>/dev/null || true)"
    case "$L" in
      /dev/spipe_lte1|/dev/spipe_lte2|/dev/sdiag_lte|/dev/stty_lte|/dev/slog_lte)
        echo "$F -> $L"
        N="$(basename "$F")"
        echo "fdinfo:"
        cat "/proc/$PID/fdinfo/$N" 2>&1 || true
        ;;
    esac
  done
  echo
done
echo "=== cp_diskserver STRINGS: NV / MODEM / IMEI / SPIPES ==="
if command -v strings >/dev/null 2>&1; then
  strings -a -n 4 /vendor/bin/cp_diskserver 2>/dev/null |
    grep -Ei 'cp.?disk|diskserver|spipe|fixnv|runnv|runtime.?nv|delta.?nv|nv|imei|diag|modem|read|write|backup|restore|open|ioctl|socket|partition' |
    sort -u || true
else
  echo "strings command unavailable"
fi
echo
echo "=== LIKELY CONFIG FILES (NARROW SEARCH) ==="
for D in /vendor/etc /vendor/etc/init /vendor/etc/vintf /system/etc /system_ext/etc /product/etc /odm/etc; do
  [ -d "$D" ] || continue
  find "$D" -maxdepth 2 -type f \( -iname '*cp*disk*' -o -iname '*diskserver*' -o -iname '*modem*' -o -iname '*nv*' \) -print 2>/dev/null
done | sort -u
echo
echo "=== MATCHING INIT / SERVICE TEXT ==="
for F in /vendor/etc/init/*.rc /vendor/etc/init/*.xml /system/etc/init/*.rc /system/etc/init/*.xml; do
  [ -f "$F" ] || continue
  grep -HniE 'cp_diskserver|spipe_lte1|spipe_lte2|sdiag_lte|fixnv|runnv' "$F" 2>/dev/null || true
done
echo
echo "=== SAFETY CHECK ==="
echo "This module does NOT:"
echo "- open/read/write /dev/spipe_lte*"
echo "- open/read/write /dev/sdiag_lte or /dev/stty_lte"
echo "- access l_fixnv*, l_runtimenv*, l_deltanv* or prodnv"
echo "- issue ioctl/resetprop"
echo "- execute cp_diskserver"
echo "- modify modem/NV state"
echo
echo "Report: $LOG"
