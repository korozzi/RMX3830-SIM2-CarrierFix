#!/system/bin/sh
OUT=/sdcard/Download/RMX3830_IMEI_RIL_Probe
mkdir -p "$OUT"
LOG="$OUT/probe_$(date +%Y%m%d_%H%M%S).txt"
exec >"$LOG" 2>&1

echo "=== RMX3830 IMEI RIL PROBE v3 ==="
echo "Started: $(date)"
echo "NON-INVASIVE: no open/read/write/ioctl on modem nodes; no NV access."
echo

echo "--- TARGET MODEM CONFIG ---"
for P in ro.vendor.modem.nv ro.vendor.modem.diag ro.vendor.modem.tty ro.vendor.modem.loop ro.vendor.modem.halo ro.vendor.modem.log persist.vendor.modem.fixnv_size persist.vendor.modem.runnv_size persist.vendor.sys.modem.diag; do
  printf "%s=" "$P"
  getprop "$P" 2>/dev/null || true
done
echo

echo "--- MODEM NODE METADATA ---"
for N in /dev/spipe_lte0 /dev/spipe_lte1 /dev/spipe_lte2 /dev/spipe_lte3 /dev/sdiag_lte /dev/stty_lte /dev/slog_lte; do
  if [ -e "$N" ]; then
    echo "NODE: $N"
    stat "$N" 2>/dev/null || ls -lZ "$N" 2>/dev/null || ls -l "$N"
  else
    echo "MISSING: $N"
  fi
done
echo

echo "--- PROCESS OWNERSHIP / OPEN FDS ---"
for PIDDIR in /proc/[0-9]*; do
  PID="${PIDDIR##*/}"
  CMD="$(cat "$PIDDIR/cmdline" 2>/dev/null | tr '\000' ' ' | cut -c1-200)"
  [ -n "$CMD" ] || continue
  MATCH=""
  for FD in "$PIDDIR"/fd/*; do
    LINK="$(readlink "$FD" 2>/dev/null || true)"
    case "$LINK" in
      /dev/spipe_lte0|/dev/spipe_lte1|/dev/spipe_lte2|/dev/spipe_lte3|/dev/sdiag_lte|/dev/stty_lte|/dev/slog_lte)
        MATCH="$MATCH $LINK"
        ;;
    esac
  done
  if [ -n "$MATCH" ]; then
    echo "PID=$PID"
    echo "CMD=$CMD"
    echo "OPEN=$MATCH"
  fi
done
echo

echo "--- RIL/MODEM PROCESSES ---"
ps -A 2>/dev/null | grep -Ei 'urild|rild|radio|modem|ims|slog' | grep -v grep || true
echo

echo "--- UNISOC RADIO SERVICES ---"
service list 2>/dev/null | grep -Ei 'vendor.unisoc.hardware.radio|android.hardware.radio|radio.modem|radio.sim|radio.voice' || true
echo

echo "--- SELINUX ---"
getenforce 2>/dev/null || true
echo

echo "--- CURRENT TELEPHONY ---"
echo "iphonesubinfo:"
dumpsys iphonesubinfo 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
echo "telephony.registry:"
dumpsys telephony.registry 2>/dev/null | grep -Eo "[0-9]{15}" | sort -u || true
echo

echo "--- SAFETY CHECK ---"
echo "No modem node was opened by this script."
echo "No bytes were read from or written to /dev/spipe_lte*, /dev/sdiag_lte, /dev/stty_lte or /dev/slog_lte."
echo "No block NV partition was opened."
echo "No ioctl, resetprop, erase, format or NV write was performed."
echo
echo "Log: $LOG"
