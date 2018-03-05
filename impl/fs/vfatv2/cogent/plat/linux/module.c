/*
 * Copyright 2018, Data61
 * Commonwealth Scientific and Industrial Research Organisation (CSIRO)
 * ABN 41 687 119 230.
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(DATA61_GPL)
 */

#include <plat/linux/wrapper_pp_inferred.c>

static struct dentry *vfat_mount(struct file_system_type *fs_type, int flags,
                                   const char *dev_name, void *data)
{
        return mount_bdev(fs_type, flags, dev_name, data, vfat_fill_super);
}

static void kill_vfat_super(struct super_block *sb)
{
        /* TODO: implement filesystem specific super block tear-down here. */
        kill_block_super(sb);
}

static struct file_system_type vfat_fs_type = {
        .owner    = THIS_MODULE,
        .name     = "cogent-vfatv2",
        .mount    = vfat_mount,
        .kill_sb  = kill_vfat_super,
        .fs_flags = FS_REQUIRES_DEV
};

static int __init init_vfat_fs(void)
{
        int err = 0;

        printk(KERN_INFO "Registering VFAT!\n");

        /* TODO: Implement filesystem specific init functions here. */
        err = register_filesystem(&vfat_fs_type);

        return err;
}


static void __exit exit_vfat_fs(void)
{
        printk(KERN_INFO "Un-Registering VFAT!\n");

        /* TODO: Implement filesystem specific tear-down functions here. */
        unregister_filesystem(&vfat_fs_type);
}


module_init(init_vfat_fs)
module_exit(exit_vfat_fs)

MODULE_AUTHOR("Data61 TFS Team");
MODULE_DESCRIPTION("Sekeleton FS implementation in Cogent");
MODULE_LICENSE("GPL");
