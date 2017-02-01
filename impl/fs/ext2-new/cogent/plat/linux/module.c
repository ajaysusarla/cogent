/*
 * Copyright 2017, NICTA
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(NICTA_GPL)
 *
 * Portions of this code are copied from `linux/fs/ext2/super.c` and belong to
 * their respected copyright holders. The original copyright header follows:
 *
 *  linux/fs/ext2/super.c
 *
 * Copyright (C) 1992, 1993, 1994, 1995
 * Remy Card (card@masi.ibp.fr)
 * Laboratoire MASI - Institut Blaise Pascal
 * Universite Pierre et Marie Curie (Paris VI)
 *
 *  from
 *
 *  linux/fs/minix/inode.c
 *
 *  Copyright (C) 1991, 1992  Linus Torvalds
 *
 *  Big-endian to little-endian byte-swapping/bitmaps by
 *        David S. Miller (davem@caip.rutgers.edu), 1995
 *
 */

#include <linux_hdrs.h>

#include <abstract.h>

/* Global variables */
static struct kmem_cache *ext2_inode_cachep;

/* Cogent generated C code */
#include <generated.c>
#include <plat/linux/common_pp_inferred.c>
#include <plat/linux/bufferhead_pp_inferred.c>
#include <plat/linux/linux_api_pp_inferred.c>
#include <plat/linux/ext2fs_pp_inferred.c>
#include <plat/linux/alloc_pp_inferred.c>
#include <plat/linux/super_pp_inferred.c>
#include <plat/linux/inode_pp_inferred.c>
#include <plat/linux/xattr_pp_inferred.c>


/* Superblock Operations */
static const struct super_operations ext2_sops = {
        .alloc_inode = ext2fs_alloc_inode,
        .destroy_inode = ext2fs_destroy_inode,
        .write_inode = ext2fs_write_inode,
        .evict_inode = ext2fs_evict_inode,
        .put_super = ext2fs_put_super,
        .sync_fs = ext2fs_sync_fs,
        .freeze_fs = ext2fs_freeze_fs,
        .unfreeze_fs = ext2fs_unfreeze_fs,
        .statfs = ext2fs_statfs,
        .remount_fs = ext2fs_remount_fs,
        .show_options = ext2fs_show_options,
#ifdef CONFIG_QUOTA
        .quota_read = ext2fs_quota_read,
        .quota_write = ext2fs_quota_write,
        .get_dquots = ext2fs_get_dquots,
#endif  /* CONFIG_QUOTA */
};

static void init_once(void *object)
{
        VfsInode *ai = (VfsInode *)object;
        /* TODO: Lock!!! */
        inode_init_once(&ai->vfs.vfs_inode);
}

static int __init init_inodecache(void)
{
        unsigned long flags;

#if LINUX_VERSION_CODE < KERNEL_VERSION(4,20,0)
        flags = SLAB_RECLAIM_ACCOUNT | SLAB_MEM_SPREAD;
#else
        flags = SLAB_RECLAIM_ACCOUNT | SLAB_MEM_SPREAD | SLAB_ACCOUNT;
#endif

        ext2_inode_cachep = kmem_cache_create("ext2_inode_cache",
                                              sizeof(VfsInode), 0,
                                              flags,
                                              init_once);

        if (ext2_inode_cachep == NULL)
                return -ENOMEM;

        return 0;
}

static void destroy_inodecache(void)
{
        rcu_barrier();
        kmem_cache_destroy(ext2_inode_cachep);
}

static struct dentry *ext2fs_mount(struct file_system_type *fs_type, int flags,
                                   const char *dev_name, void *data)
{
        return mount_bdev(fs_type, flags, dev_name, data, ext2fs_fill_super);
}

static void kill_ext2fs_super(struct super_block *sb)
{
        kill_block_super(sb);
}


static struct file_system_type ext2_fs_type = {
        .owner    = THIS_MODULE,
        .name     = "ext2fs",
        .mount    = ext2fs_mount,  /* no lock */
        .kill_sb  = kill_ext2fs_super,
        .fs_flags = FS_REQUIRES_DEV,
};

static int __init ext2fs_init(void)
{
        int err;

        err = init_inodecache();
        if (err)
                return err;

        err = register_filesystem(&ext2_fs_type);
        if (err)
                goto out;

        return 0;

out:
        destroy_inodecache();
        return err;
}

static void __exit ext2fs_exit(void)
{
        unregister_filesystem(&ext2_fs_type);
        destroy_inodecache();
}


module_init(ext2fs_init);
module_exit(ext2fs_exit);

MODULE_LICENSE("GPL");
MODULE_VERSION(__stringify(EXT2FS_VERSION));
MODULE_AUTHOR("Trustworthy Systems @ Data61.");
MODULE_DESCRIPTION("EXTFS - ext2 file system implementation in Cogent");
