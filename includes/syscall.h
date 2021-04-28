#ifndef SYSCALL_H
# define SYSCALL_H

#include <unistd.h>

typedef struct		s_linux_dirent
{
	unsigned long	d_ino;
	unsigned long	d_off;
	unsigned short	d_reclen;
	char			d_name[];
}					t_linux_dirent;

#endif
