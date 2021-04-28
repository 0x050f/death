#ifndef SYSCALL_H
# define SYSCALL_H

# include <unistd.h>
# include <sys/stat.h>

struct				linux_dirent
{
	unsigned long	d_ino;
	unsigned long	d_off;
	unsigned short	d_reclen;
	char			d_name[];
};

int		syscall_open(const char *pathname, int flags);
int		syscall_close(int fd);
void	syscall_exit(int status);
off_t	syscall_lseek(int fd, off_t offset, int whence);
int		syscall_stat(const char *pathname, struct stat *statbuf);
int		syscall_getdents(unsigned int fd, struct linux_dirent *dirp, unsigned int count);
void	*syscall_mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
int		syscall_munmap(void *addr, size_t length);

#endif
