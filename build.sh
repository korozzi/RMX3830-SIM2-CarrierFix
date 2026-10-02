#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="$ROOT/dist"
rm -rf "$OUT"
mkdir -p "$OUT/package"
cp "$ROOT/module.prop" "$ROOT/post-fs-data.sh" "$ROOT/service.sh" "$ROOT/uninstall.sh" "$OUT/package/"
chmod 0755 "$OUT/package/post-fs-data.sh" "$OUT/package/service.sh" "$OUT/package/uninstall.sh"
(cd "$OUT/package" && zip -9 -r "$OUT/RMX3830_SIM2_CarrierFix_v1.0.0.zip" . >/dev/null)
echo "$OUT/RMX3830_SIM2_CarrierFix_v1.0.0.zip"
