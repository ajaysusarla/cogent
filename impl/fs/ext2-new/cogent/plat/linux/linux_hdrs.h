/*
 * Copyright 2017, NICTA
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(NICTA_GPL)
 */

#ifndef _LINUX_HDRS_H
#define _LINUX_HDRS_H

/*
 * Linux headers have to be included only if __KERNEL__ is defined because
 * Cogent's C parser does not support all gcc extensions in Linux headers.
 */
#ifdef __KERNEL__
#include <linux/list.h>
#include <asm/div64.h>
#include <linux/statfs.h>
#include <linux/fs.h>
#include <linux/err.h>
#include <linux/slab.h>
#include <linux/vmalloc.h>
#include <linux/mtd/ubi.h>
#include <linux/pagemap.h>
#include <linux/backing-dev.h>
#include <linux/crc32.h>
#include <linux/ctype.h>
#include <linux/buffer_head.h>
#include <linux/semaphore.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/namei.h>
#include <linux/seq_file.h>
#include <linux/mount.h>
#include <linux/posix_acl.h>
#include <linux/uio.h>
#include <linux/mpage.h>
#include <linux/quota.h>
#include <linux/version.h>
#include <linux/blockgroup_lock.h>
#include <linux/quotaops.h>
#include <linux/mbcache.h>
#include <linux/parser.h>
#endif  /* __KERNEL__ */

#endif            /* _LINUX_HDRS_H */
