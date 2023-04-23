# dupe-utils

## dupelist

    dupelist [<dir> ...]

`dupelist` searches for regular files in one or more directory trees
and outputs their pathnames, device and inode numbers, file sizes, and
modification times.

If you supply one or more directories, `dupelist` will search for
files in those directories.

If you do not supply any directory arguments, `dupelist` will find
files in the current working directory.

## dedupesize

    dedupesize <file> ...
    dedupesize <dir> ...
    dedupesize -                # read from standard input
    dedupesize .                # current working directory tree
    dedupesize                  # no arguments; read from stdin

`dedupesize` looks for duplicate files by checking their sizes first,
then reading their contents.

If `dedupesize` finds two or more files hard-linked together, it will
treat those files as a single file.  If `dedupesize` chooses one of
those files for removal, it will remove all the other hard links too.

`dedupesize` prefers to keep files whose names are earlier in
lexicographic order.
