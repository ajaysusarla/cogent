/*
 * Copyright 2017, NICTA
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(NICTA_GPL)
 */
/*
 * abstract.h
 * This file contains the abstract data type definitions.
 */

#ifndef _ABSTRACT_H
#define _ABSTRACT_H

#include <linux_hdrs.h>                /* In cogent/plat/linux/ */
#include <ext2fs.h>

#include "abstract_vfs.h"

#include <c/linux/abstract-defns.h> /* In lib gum */

/* The Global State */
struct _State {
        struct semaphore iop_lock;
        void *priv;
};

typedef struct _State SysState;
typedef struct _State ExState;

/**
 * VfsSuperBlockAbstract - The Abstract Super Block Structure
 **/
struct _VfsSuperBlockAbstract {
        void *data;
        struct super_block *sb;
};

typedef struct _VfsSuperBlockAbstract VfsSuperBlockAbstract;

/**
 * VfsInodeAbstract - The Abstract Inode Structure.
 *
 * This is the current filesystem's inode data in memory. This has the
 * `struct inode` and additional data that each filesystem needs to have.
 **/
struct _VfsInodeAbstract {
        struct inode vfs_inode;
#ifdef CONFIG_QUOTA
        struct dquot *i_dquot[MAXQUOTAS];
#endif  /* CONFIG_QUOTA */
};

typedef struct _VfsInodeAbstract VfsInodeAbstract;

/*
  To Preserve linearity, the following fields are moved out of Ext2SbInfo
  record, defined in super.cogent, as the fields point to same block of
  memory.
 */
typedef struct {
        struct buffer_head *s_sbh;
        struct ext2fs_super_block *s_es;
        struct buffer_head **s_group_desc;
} Ext2SBnBHAbstractType;

/*
  The following types are aliases(sort of) for various entries in the superblock
  structure. Because of the lack of support for C arrays in Cogent, we need to
  pack them in structures.
 */
typedef struct _type_uuid { __u8 data[16]; } TypeUUID;
typedef struct _type_s_volume_name { char s_volume_name[16]; } TypeVolumeName;
typedef struct _type_s_last_mounted { char s_last_mounted[64]; }  TypeLastMounted;
typedef struct _type_s_hash_seed { __u32 data[4]; } TypeSHashSeed;
typedef struct _type_s_reserved { __u32 data[190]; } TypeSReserved;


typedef struct user_namespace UserNameSpace;
typedef uid_t UID;
typedef gid_t GID;
typedef loff_t LOFF;
typedef void CVoid;

/* Wrapper state, that needs to be carried around in addition the
   FS State(filesystem state)
*/
/*
struct WrapperState {
        void *priv;
        struct semaphore iop_lock;
        struct super_block *sb;
};

typedef struct WrapperState ExState;*/ /* External State */
/* typedef struct WrapperState SkelfsState; */


/* Abstract inode structure */
/*
struct VfsInodeAbstract {
        struct inode inode;

        struct inode_operations inodeops;
        struct cogent_inode_operations cogent_inodeops;

        struct file_operations fileops;
        struct cogent_file_operations cogent_fileops;
};

typedef struct VfsInodeAbstract VfsInodeAbstract;
*/

/* typedefs for convenience. TODO: Cleanup???*/
/*
typedef struct dir_context OSDirContext;
typedef struct buffer_head OSBuffer;
typedef struct page OSPage;
typedef struct page OSPageBuffer;
typedef struct address_space VfsMemoryMap;
typedef struct ubi_volume_desc UbiVol;

typedef void File;
typedef void VfsStat;
typedef void VfsIattr;
*/

#define likely(x)       __builtin_expect(!!(x), 1)
#define unlikely(x)     __builtin_expect(!!(x), 0)


#endif  /* _ABSTRACT_H */
