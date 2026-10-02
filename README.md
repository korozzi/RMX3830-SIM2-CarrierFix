# RMX3830 NV Restore

Controlled restore module for realme C51 RMX3830.

Restores the newest backup directory from `/sdcard/Download/RMX3830_NV_Backup/<timestamp>/`.

Partitions:
- prodnv
- l_fixnv1_a
- l_fixnv1_b
- l_fixnv2_a
- l_fixnv2_b

Before writing, it creates a fresh rollback copy of all five current partitions.

## Safety

The module is blocked by default. To authorize a restore, create:
`/sdcard/Download/RMX3830_NV_Backup/RESTORE_NOW`
Then run the Magisk Action.

It verifies partition existence and exact image sizes before any write. If validation fails, it aborts without writing.

**Important:** this restores the selected backup exactly. A backup made after an IMEI change contains that changed state; it is not a factory-IMEI repair image.
