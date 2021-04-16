#include <unistd.h>

#define _unused __attribute__ ((unused))

inline int		__open(_unused const char *pathname, _unused int flags)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 2\n"
			"syscall\n"
			".att_syntax prefix\n");
}

inline int		__close(_unused int fd)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 3\n"
			"syscall\n"
			".att_syntax prefix\n");
}

void			__exit(_unused int status)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 60\n"
			"syscall\n"
			".att_syntax prefix\n");
}

inline void		*__mmap(_unused void *addr, _unused size_t length,
_unused int prot, _unused int flags, _unused int fd, _unused off_t offset)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 9\n"
			"syscall\n"
			".att_syntax prefix\n");
}

inline int		__munmap(_unused void *addr, _unused size_t length)
{
	asm (".intel_syntax noprefix\n"
			"mov rax, 11\n"
			"syscall\n"
			".att_syntax prefix\n");
}
