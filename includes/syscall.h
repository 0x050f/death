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

ssize_t	syscall_read(int fd, const void *buf, size_t count);
ssize_t	syscall_write(int fd, const void *buf, size_t count);
int		syscall_open(const char *pathname, int flags);
int		syscall_close(int fd);
int		syscall_stat(const char *pathname, struct stat *statbuf);
off_t	syscall_lseek(int fd, off_t offset, int whence);
void	*syscall_mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
int		syscall_munmap(void *addr, size_t length);
void	syscall_exit(int status);
int		syscall_getdents(unsigned int fd, struct linux_dirent *dirp, unsigned int count);

#endif
