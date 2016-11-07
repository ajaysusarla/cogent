/*
 * Copyright 2016, NICTA
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(NICTA_GPL)
 */

#include <plat/linux/wrapper_pp_inferred.c>

static struct dentry *f2fs_mount(struct file_system_type *fs_type, int flags,
                                 const char *dev_name, void *data)
{
        return mount_bdev(fs_type, flags, dev_name, data, f2fs_fill_super);
}

static void kill_f2fs_super(struct super_block *sb)
{
        /* XXX: Check f2fs in kernel implementation on how to set the SBI
         flag here.*/
        kill_block_super(sb);
}

static struct file_system_type f2fs_fs_type = {
        .owner    = THIS_MODULE,
        .name     = "cogent-f2fs",
        .mount    = f2fs_mount,
        .kill_sb  = kill_f2fs_super,
        .fs_flags = FS_REQUIRES_DEV
};

static int __init init_f2fs_fs(void)
{
        int err = 0;

        err = register_filesystem(&f2fs_fs_type);
        /* TODO: Implement init functions here. */

        return err;
}


static void __exit exit_f2fs_fs(void)
{
        unregister_filesystem(&f2fs_fs_type);
}


module_init(init_f2fs_fs)
module_exit(exit_f2fs_fs)

MODULE_AUTHOR("Original Author: Samsung. Cogent implementation: Data61");
MODULE_DESCRIPTION("Flash Friendly File System in Cogent");
MODULE_LICENSE("GPL");

