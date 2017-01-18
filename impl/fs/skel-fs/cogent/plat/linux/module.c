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
#include <plat/linux/super_pp_inferred.c>

/*
  Super operations.

  Not all filesystems need to implement all the super operations.
 */
static const struct super_operations skelfs_sops = {
        .alloc_inode = skelfs_alloc_inode,
        .destroy_inode = skelfs_destroy_inode,
        .dirty_inode = skelfs_dirty_inode,
        .write_inode = skelfs_write_inode,
        .drop_inode = skelfs_drop_inode,
        .evict_inode = skelfs_evict_inode,
        .put_super = skelfs_put_super,
        .sync_fs = skelfs_sync_fs,
        .freeze_super = skelfs_freeze_super,
        .freeze_fs = skelfs_freeze_fs,
        .thaw_super = skelfs_thaw_super,
        .unfreeze_fs = skelfs_unfreeze_fs,
        .statfs = skelfs_statfs,
        .remount_fs = skelfs_remount_fs,
        .umount_begin = skelfs_umount_begin,
        .show_options = skelfs_show_options,
        .show_devname = skelfs_show_devname,
        .show_path = skelfs_show_path,
#ifdef CONFIG_QUOTA
        .quota_read = skelfs_quota_read,
        .quota_write = skelfs_quota_write,
        .get_dquots = skelfs_get_dquots,
#endif  /* CONFIG_QUOTA */
#if 0   /* Available only in the latest kernels */
        .bdev_try_to_free_page = skelfs_bdev_try_to_free_page,
#endif
        .nr_cached_objects = skelfs_nr_cached_objects,
        .free_cached_objects = skelfs_free_cached_objects,
};

static struct dentry *skelfs_mount(struct file_system_type *fs_type, int flags,
                                   const char *dev_name, void *data)
{
        return mount_bdev(fs_type, flags, dev_name, data, skelfs_fill_super);
}

static void kill_skelfs_super(struct super_block *sb)
{
        /* TODO: implement filesystem specific super block tear-down here. */
        kill_block_super(sb);
}

static struct file_system_type skelfs_fs_type = {
        .owner    = THIS_MODULE,
        .name     = "cogent-skelfs",
        .mount    = skelfs_mount,
        .kill_sb  = kill_skelfs_super,
        .fs_flags = FS_REQUIRES_DEV
};

static int __init init_skel_fs(void)
{
        int err = 0;

        printk(KERN_INFO "Registering SKEL-FS!\n");

        /* TODO: Implement filesystem specific init functions here. */
        err = register_filesystem(&skelfs_fs_type);

        return err;
}


static void __exit exit_skel_fs(void)
{
        printk(KERN_INFO "Un-Registering SKEL-FS!\n");

        /* TODO: Implement filesystem specific tear-down functions here. */
        unregister_filesystem(&skelfs_fs_type);
}


module_init(init_skel_fs)
module_exit(exit_skel_fs)

MODULE_AUTHOR("Data61 TFS Team");
MODULE_DESCRIPTION("Sekeleton FS implementation in Cogent");
MODULE_LICENSE("GPL");
