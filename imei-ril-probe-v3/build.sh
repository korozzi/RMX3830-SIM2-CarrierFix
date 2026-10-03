#!/system/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="$ROOT/dist"
rm -rf "$OUT"
mkdir -p "$OUT/package"
cp "$ROOT/module.prop" "$ROOT/service.sh" "$ROOT/action.sh" "$ROOT/README.md" "$OUT/package/"
chmod 0755 "$OUT/package/service.sh" "$OUT/package/action.sh"
VERSION="$(sed -n 's/^version=//p' "$ROOT/module.prop")"
NAME="RMX3830_IMEI_RIL_Probe_v${VERSION}.zip"
(cd "$OUT/package" && zip -9 -r "$OUT/$NAME" . >/dev/null)
echo "$OUT/$NAME"
