import dir from require 'posix.dirent'
import stat, mkdir, S_IFMT, S_IFBLK, S_IFCHR, S_IFDIR, S_IFIFO, S_IFLINK, S_IFREG, S_IFSOCK from require 'posix.sys.stat'
import band, btest from require 'moonbuild.compat.bit'
import concat from table

{
	dir: dir

	attributes: (path) ->
		st = stat path
		return nil unless st
		mode = st.st_mode
		{
			mode: do
				ty = band mode, S_IFMT
				switch ty
					when S_IFREG  then 'file'
					when S_IFDIR  then 'directory'
					when S_IFLINK then 'link'
					when S_IFSOCK then 'socket'
					when S_IFIFO  then 'named pipe'
					when S_IFCHR  then 'char device'
					when S_IFBLK  then 'block device'
					else               'other'

			permissions: do
				_suid = btest mode, 2048
				_sgid = btest mode, 1024
				_stic = btest mode, 512
				_ur   = btest mode, 256
				_uw   = btest mode, 128
				_ux   = btest mode, 64
				_gr   = btest mode, 32
				_gw   = btest mode, 16
				_gx   = btest mode, 8
				_or   = btest mode, 4
				_ow   = btest mode, 2
				_ox   = btest mode, 1
				concat {
					_ur and 'r' or '-'
					_uw and 'w' or '-'
					_suid and 's' or (_ux and 'x' or '-')
					_gr and 'r' or '-'
					_gw and 'w' or '-'
					_sgid and 's' or (_gx and 'x' or '-')
					_or and 'r' or '-'
					_ow and 'w' or '-'
					_stic and 't' or (_ox and 'x' or '-')
				}

			dev:          st.st_dev
			ino:          st.st_ino
			nlink:        st.st_nlink
			uid:          st.st_uid
			gid:          st.st_gid
			rdev:         st.st_rdev
			access:       st.st_atime
			modification: st.st_mtime
			change:       st.st_ctime
			size:         st.st_size
			blocks:       st.st_blocks
			blksize:      st.st_blksize
		}

	mkdir: (path) ->
		ok, err = mkdir path
		error "Failed to mkdir #{path}: #{err}" unless ok
}
