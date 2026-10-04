# RMX3830 Original fixnv Restore v2

Restores the four existing original `l_fixnv*.img` backups. This module does **not** create another backup.

Expected backup SHA-256:

- `l_fixnv1_a.img` = `beb99e1f48341d431191ae69df98f659aa4ec342aa4fb308d790c6639f7a196b`
- `l_fixnv2_a.img` = `beb99e1f48341d431191ae69df98f659aa4ec342aa4fb308d790c6639f7a196b`
- `l_fixnv1_b.img` = `94f6bf65e56e0a1d1c0891cd46b141e5d735070a5380b742e9763ee4aa101e93`
- `l_fixnv2_b.img` = `94f6bf65e56e0a1d1c0891cd46b141e5d735070a5380b742e9763ee4aa101e93`

The files must already exist under `/sdcard/Download`. The module refuses to use a file unless its size is exactly 2 MiB and its SHA-256 matches the expected original backup.

It stops `slogmodem` and `vendor.cp_diskserver` before writing, restores the complete four partitions, verifies each hash, restarts the services, and checks again after 10 seconds for an immediate overwrite.

It does not touch `prodnv`, modem images, runtime NV, system properties, or the Hotspot Enhancer project/module.
