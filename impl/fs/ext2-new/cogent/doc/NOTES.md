* VfsInode is defined in vfs.cogent

* In the sytanx:
  | True ->

  and

  | True =>

  The one with the '=>' will generate a 'likely' macro
  and the one with '->' will generate an 'unlikely' macro

* Explanation of some acronyms used in the source
  + ac  - Functions that end with _ac are implemented in antiquoted C.
  + cg  - Functions that end with _cg are implemented in Cogent.
  + bh  - buffer head
  + sb  - super block
  + sbi - super block info (the in-memory superblock structure)
  + es  - ext2 super block (the on-disk superblock structure)
