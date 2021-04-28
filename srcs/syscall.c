#include "syscall.h"

int		syscall_open(const char *pathname, int flags)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 2\n"
			"syscall\n"
			".att_syntax prefix\n");
}

int		syscall_close(int fd)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 3\n"
			"syscall\n"
			".att_syntax prefix\n");
}

void	syscall_exit(int status)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 60\n"
			"syscall\n"
			".att_syntax prefix\n");
}

off_t	syscall_lseek(int fd, off_t offset, int whence)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 8\n"
			"syscall\n"
			".att_syntax prefix\n");
}

int		syscall_stat(const char *pathname, struct stat *statbuf)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 4\n"
			"syscall\n"
			".att_syntax prefix\n");
}

int		syscall_getdents(unsigned int fd, struct linux_dirent *dirp, unsigned int count)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 78\n"
			"syscall\n"
			".att_syntax prefix\n");
}

void	*syscall_mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)
{
	asm (".intel_syntax noprefix\n"
			"mov r10, rcx\n"
			"mov rax, 9\n"
			"syscall\n"
			".att_syntax prefix\n");
}

int		syscall_munmap(void *addr, size_t length)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 11\n"
			"syscall\n"
			".att_syntax prefix\n");
}
