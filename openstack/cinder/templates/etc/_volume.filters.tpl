# cinder-rootwrap command filters for volume nodes
# This file should be owned by (and only-writeable by) the root user

[Filters]
# cinder/volume/iscsi.py: iscsi_helper '--op' ...
ietadm: CommandFilter, ietadm, root
tgtadm: CommandFilter, tgtadm, root
iscsictl: CommandFilter, iscsictl, root
tgt-admin: CommandFilter, tgt-admin, root
cinder-rtstool: CommandFilter, cinder-rtstool, root
scstadmin: CommandFilter, scstadmin, root

# HyperScale command to handle cinder operations
hscli: CommandFilter, hscli, root

# LVM related show commands
pvs: EnvFilter, env, root, LC_ALL=C, pvs
vgs: EnvFilter, env, root, LC_ALL=C, vgs
lvs: EnvFilter, env, root, LC_ALL=C, lvs
lvdisplay: EnvFilter, env, root, LC_ALL=C, lvdisplay

# -LVM related show commands with suppress fd warnings
pvs2: EnvFilter, env, root, LC_ALL=C, LVM_SUPPRESS_FD_WARNINGS=, pvs
vgs2: EnvFilter, env, root, LC_ALL=C, LVM_SUPPRESS_FD_WARNINGS=, vgs
lvs2: EnvFilter, env, root, LC_ALL=C, LVM_SUPPRESS_FD_WARNINGS=, lvs
lvdisplay2: EnvFilter, env, root, LC_ALL=C, LVM_SUPPRESS_FD_WARNINGS=, lvdisplay


# -LVM related show commands conf var
pvs3: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, pvs
vgs3: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, vgs
lvs3: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, lvs
lvdisplay3: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, lvdisplay

# -LVM conf var with suppress fd_warnings
pvs4: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, LVM_SUPPRESS_FD_WARNINGS=, pvs
vgs4: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, LVM_SUPPRESS_FD_WARNINGS=, vgs
lvs4: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, LVM_SUPPRESS_FD_WARNINGS=, lvs
lvdisplay4: EnvFilter, env, root, LC_ALL=C, LVM_SYSTEM_DIR=, LVM_SUPPRESS_FD_WARNINGS=, lvdisplay

# os-brick library commands
# os_brick.privileged.run_as_root oslo.privsep context
# This line ties the superuser privs with the config files, context name,
# and (implicitly) the actual python code invoked.
privsep-rootwrap: RegExpFilter, privsep-helper, root, privsep-helper, --config-file, /etc/(?!\.\.).*, --privsep_context, os_brick.privileged.default, --privsep_sock_path, /tmp/.*
# The following and any cinder/brick/* entries should all be obsoleted
# by privsep, and may be removed once the os-brick version requirement
# is updated appropriately.
scsi_id: CommandFilter, /lib/udev/scsi_id, root
drbdadm: CommandFilter, drbdadm, root

# cinder/brick/local_dev/lvm.py: 'vgcreate', vg_name, pv_list
vgcreate: CommandFilter, vgcreate, root

# cinder/brick/local_dev/lvm.py: 'lvcreate', '-L', sizestr, '-n', volume_name,..
# cinder/brick/local_dev/lvm.py: 'lvcreate', '-L', ...
lvcreate: EnvFilter, env, root, LC_ALL=C, lvcreate
lvcreate_lvmconf: EnvFilter, env, root, LVM_SYSTEM_DIR=, LC_ALL=C, lvcreate
lvcreate_fdwarn: EnvFilter, env, root, LC_ALL=C, LVM_SUPPRESS_FD_WARNINGS=, lvcreate
lvcreate_lvmconf_fdwarn: EnvFilter, env, root, LVM_SYSTEM_DIR=, LVM_SUPPRESS_FD_WARNINGS=, LC_ALL=C, lvcreate

# cinder/volume/driver.py: 'dd', 'if=%s' % srcstr, 'of=%s' % deststr,...
dd: CommandFilter, dd, root

# cinder/volume/driver.py: 'lvremove', '-f', %s/%s % ...
lvremove: CommandFilter, lvremove, root

# cinder/volume/driver.py: 'lvrename', '%(vg)s', '%(orig)s' '(new)s'...
lvrename: CommandFilter, lvrename, root

# cinder/brick/local_dev/lvm.py: 'lvextend', '-L' '%(new_size)s', '%(lv_name)s' ...
# cinder/brick/local_dev/lvm.py: 'lvextend', '-L' '%(new_size)s', '%(thin_pool)s' ...
lvextend: EnvFilter, env, root, LC_ALL=C, lvextend
lvextend_lvmconf: EnvFilter, env, root, LVM_SYSTEM_DIR=, LC_ALL=C, lvextend
lvextend_fdwarn: EnvFilter, env, root, LC_ALL=C, LVM_SUPPRESS_FD_WARNINGS=, lvextend
lvextend_lvmconf_fdwarn: EnvFilter, env, root, LVM_SYSTEM_DIR=, LC_ALL=C, LVM_SUPPRESS_FD_WARNINGS=, lvextend

# cinder/brick/local_dev/lvm.py: 'lvchange -a y -K <lv>'
lvchange: CommandFilter, lvchange, root

# cinder/brick/local_dev/lvm.py: 'lvconvert', '--merge', snapshot_name
lvconvert: CommandFilter, lvconvert, root

# cinder/volume/driver.py: 'iscsiadm', '-m', 'discovery', '-t',...
# cinder/volume/driver.py: 'iscsiadm', '-m', 'node', '-T', ...
iscsiadm: CommandFilter, iscsiadm, root

# cinder/volume/utils.py: utils.temporary_chown(path, 0)
chown: CommandFilter, chown, root

# cinder/volume/utils.py: copy_volume(..., ionice='...')
ionice_1: ChainingRegExpFilter, ionice, root, ionice, -c[0-3], -n[0-7]
ionice_2: ChainingRegExpFilter, ionice, root, ionice, -c[0-3]

# cinder/volume/utils.py: setup_blkio_cgroup()
cgcreate: CommandFilter, cgcreate, root
cgset: CommandFilter, cgset, root
cgexec: ChainingRegExpFilter, cgexec, root, cgexec, -g, blkio:\S+

# cinder/volume/driver.py
dmsetup: CommandFilter, dmsetup, root
ln: CommandFilter, ln, root

# cinder/image/image_utils.py
qemu-img: EnvFilter, env, root, LC_ALL=C, qemu-img
qemu-img_convert: CommandFilter, qemu-img, root

udevadm: CommandFilter, udevadm, root

# cinder/volume/driver.py: utils.read_file_as_root()
cat: CommandFilter, cat, root

# cinder/volume/nfs.py
stat: CommandFilter, stat, root
mount: CommandFilter, mount, root
df: CommandFilter, df, root
du: CommandFilter, du, root
truncate: CommandFilter, truncate, root
chmod: CommandFilter, chmod, root
rm: CommandFilter, rm, root

# cinder/volume/drivers/remotefs.py
mkdir: CommandFilter, mkdir, root

# cinder/volume/drivers/netapp/dataontap/nfs_base.py:
netapp_nfs_find: RegExpFilter, find, root, find, ^[/]*([^/\0]+(/+)?)*$, -maxdepth, \d+, -name, img-cache.*, -amin, \+\d+
netapp_nfs_touch: CommandFilter, touch, root

# cinder/volume/drivers/glusterfs.py
chgrp: CommandFilter, chgrp, root
umount: CommandFilter, umount, root

# cinder/volumes/drivers/hds/hds.py:
hus-cmd: CommandFilter, hus-cmd, root
hus-cmd_local: CommandFilter, /usr/local/bin/hus-cmd, root

# cinder/volumes/drivers/hds/hnas_backend.py
ssc: CommandFilter, ssc, root

# cinder/brick/initiator/connector.py:
ls: CommandFilter, ls, root
tee: CommandFilter, tee, root
multipath: CommandFilter, multipath, root
multipathd: CommandFilter, multipathd, root
systool: CommandFilter, systool, root

# cinder/volume/drivers/block_device.py
blockdev: CommandFilter, blockdev, root

# cinder/volume/drivers/ibm/gpfs.py
# cinder/volume/drivers/tintri.py
# cinder/volume/drivers/netapp/dataontap/nfs_base.py
mv: CommandFilter, mv, root

# cinder/volume/drivers/ibm/gpfs.py
cp: CommandFilter, cp, root
mmgetstate: CommandFilter, mmgetstate, root
mmclone: CommandFilter, mmclone, root
mmlsattr: CommandFilter, mmlsattr, root
mmchattr: CommandFilter, mmchattr, root
mmlsconfig: CommandFilter, mmlsconfig, root
mmlsfs: CommandFilter, mmlsfs, root
mmlspool: CommandFilter, mmlspool, root
mkfs: CommandFilter, mkfs, root
mmcrfileset: CommandFilter, mmcrfileset, root
mmlsfileset: CommandFilter, mmlsfileset, root
mmlinkfileset: CommandFilter, mmlinkfileset, root
mmunlinkfileset: CommandFilter, mmunlinkfileset, root
mmdelfileset: CommandFilter, mmdelfileset, root
mmcrsnapshot: CommandFilter, mmcrsnapshot, root
mmdelsnapshot: CommandFilter, mmdelsnapshot, root

# cinder/volume/drivers/ibm/gpfs.py
# cinder/volume/drivers/ibm/ibmnas.py
find_maxdepth_inum: RegExpFilter, find, root, find, ^[/]*([^/\0]+(/+)?)*$, -maxdepth, \d+, -ignore_readdir_race, -inum, \d+, -print0, -quit

# cinder/brick/initiator/connector.py:
aoe-revalidate: CommandFilter, aoe-revalidate, root
aoe-discover: CommandFilter, aoe-discover, root
aoe-flush: CommandFilter, aoe-flush, root

# cinder/brick/initiator/linuxscsi.py:
sg_scan: CommandFilter, sg_scan, root

#cinder/backup/services/tsm.py
dsmc:CommandFilter,/usr/bin/dsmc,root

# cinder/volume/drivers/hitachi/hbsd_horcm.py
raidqry: CommandFilter, raidqry, root
raidcom: CommandFilter, raidcom, root
pairsplit: CommandFilter, pairsplit, root
paircreate: CommandFilter, paircreate, root
pairdisplay: CommandFilter, pairdisplay, root
pairevtwait: CommandFilter, pairevtwait, root
horcmstart.sh: CommandFilter, horcmstart.sh, root
horcmshutdown.sh: CommandFilter, horcmshutdown.sh, root
horcmgr: EnvFilter, env, root, HORCMINST=, /etc/horcmgr

# cinder/volume/drivers/hitachi/hbsd_snm2.py
auman: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auman
auluref: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auluref
auhgdef: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auhgdef
aufibre1: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/aufibre1
auhgwwn: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auhgwwn
auhgmap: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auhgmap
autargetmap: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/autargetmap
aureplicationvvol: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/aureplicationvvol
auluadd: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auluadd
auludel: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auludel
auluchgsize: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auluchgsize
auchapuser: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auchapuser
autargetdef: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/autargetdef
autargetopt: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/autargetopt
autargetini: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/autargetini
auiscsi: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/auiscsi
audppool: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/audppool
aureplicationlocal: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/aureplicationlocal
aureplicationmon: EnvFilter, env, root, LANG=, STONAVM_HOME=, LD_LIBRARY_PATH=, STONAVM_RSP_PASS=, STONAVM_ACT=, /usr/stonavm/aureplicationmon

# cinder/volume/drivers/hgst.py
vgc-cluster: CommandFilter, vgc-cluster, root

# cinder/volume/drivers/vzstorage.py
pstorage-mount: CommandFilter, pstorage-mount, root
pstorage: CommandFilter, pstorage, root
ploop: CommandFilter, ploop, root

# initiator/connector.py:
drv_cfg: CommandFilter, /opt/emc/scaleio/sdc/bin/drv_cfg, root, /opt/emc/scaleio/sdc/bin/drv_cfg, --query_guid

# cinder/volume/drivers/quobyte.py
mount.quobyte: CommandFilter, mount.quobyte, root
umount.quobyte: CommandFilter, umount.quobyte, root

