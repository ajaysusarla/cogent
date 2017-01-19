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
#include <plat/linux/file_pp_inferred.c>

/**
  Super operations.

  Not all filesystems need to implement all the super operations.
**/
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

/**
   File Operations and inode operations for files
**/
static const struct file_operations skelfs_file_operations = {
        .llseek = skelfs_file_llseek,
        .read = skelfs_seq_file_read,
        .write = skelfs_seq_file_write,
        .read_iter = skelfs_file_read_iter,
        .write_iter = skelfs_file_write_iter,
        .poll = skelfs_file_poll,
        .unlocked_ioctl = skelfs_file_ioctl,
        .compat_ioctl = skelfs_file_compat_ioctl,
#if 0
        .mmap = skelfs_file_mmap,
        .open = skelfs_file_open,
        .flush = skelfs_file_flush,
        .release = skelfs_file_release,
        .fsync = skelfs_file_sync,
        .fasync = skelfs_file_async,
        .lock = skelfs_lock,
        .sendpage = skelfs_sendpage,
        .get_unmapped_area = skelfs_file_get_unmapped_area,
        .check_flags = skelfs_file_check_flags,
        .flock = skelfs_flock,
        .splice_read = skelfs_file_splice_read,
        .splice_write = skelfs_file_splice_write,
        .setlease = skelfs_setlease,
        .fallocate = skelfs_file_allocate,
#endif
};

#if 0
static const struct inode_operations skelfs_file_inode_operations = {
        .setattr = skelfs_file_setattr,
        .getattr = skelfs_file_getattr,
        .listxattr = skelfs_file_listxatter,
        .get_acl = skelfs_file_get_acl,
        .set_acl = skelfs_file_set_acl,
        .fiemap = skelfs_file_fiemap
};

/**
   File Operations and inode operations for directories
**/

/* These are typical directory operations that need to be implemented */
static const struct file_operations skelfs_dir_operations = {
        .llseek = skelfs_dir_llseek,
        .read = skelfs_dir_read,
        .iterate_shared = skelfs_readdir,
        .unlocked_ioctl = skelfs_ioctl,
        .fsync = skelfs_file_sync,
        .open = skelfs_dir_open,
        .release = skelfs_dir_release
};

static const struct inode_operations skelfs_dir_inode_operations = {
        .lookup = skelfs_lookup,
        .get_link = skelfs_getlink,
        .permission = skelfs_permission,
        .get_acl = skelfs_get_acl,
        .readlink = skelfs_readlink,
        .create = skelfs_create,
        .link = skelfs_link,
        .unlink = skelfs_unlink,
        .symlink = skelfs_symlink,
        .mkdir = skelfs_mkdir,
        .rmdir = skelfs_rmdir,
        .mknod = skelfs_mknod,
        .rename = skelfs_rename,
        .setattr = skelfs_setattr,
        .getattr = skelfs_getattr,
        .listxattr = skelfs_listxattr,
        .fiemap = skelfs_fiemap
        .tmpfile = skelfs_tmpfile,
        .set_acl = skelfs_set_acl,
};
#endif  /* if 0 */
/* skelfs mount */
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
