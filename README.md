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

## hardlinkfast

`hardlinkfast` is the quicker hard link remover.

`hardlinkfast` searches for regular files with more than one link in
the supplied directories or the current working directory.

While searching for files, it checks each file's hard-link count and
if it is two or greater, removes the link.  `hardlinkfast` will never
remove a filename that's an only link.  (Assuming the file does not
change in the brief amount of time between when it checks the number
of hard links on the file and when it deletes the link.)

`hardlinkfast` does not guarantee an order in which files are found.

`hardlinkfast` is primarily a directory cleanup tool.  It does a
depth-first file search, meaning it operates on the files within a
directory then the directory itself.  If it removes all the files
in a directory it will remove that directory.

`hardlinkfast` works best if you have a large number of backups with
files not having changed hard-linked together.
