#!/system/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="$ROOT/dist"
rm -rf "$OUT"
mkdir -p "$OUT/package"
cp "$ROOT/module.prop" "$ROOT/action.sh" "$OUT/package/"
chmod 0755 "$OUT/package/action.sh"
VERSION="$(sed -n 's/^version=//p' "$ROOT/module.prop")"
(cd "$OUT/package" && zip -9 -r "$OUT/RMX3830_NV_Backup_v${VERSION}.zip" . >/dev/null)
echo "$OUT/RMX3830_NV_Backup_v${VERSION}.zip"
