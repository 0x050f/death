#ifndef FAMINE_H
# define FAMINE_H

#define _GNU_SOURCE

# include <dirent.h>
# include <errno.h>
# include <fcntl.h>
# include <libgen.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <sys/mman.h>
# include <sys/stat.h>
# include <unistd.h>

# include "debug.h"
# include "elf_format.h"
# include "syscall.h"
# include "utils.h"

# ifndef INJECT
#  define INJECT
# endif

# ifndef INJECT_SIZE
#  define INJECT_SIZE 0
# endif

# define SIGNATURE "Famine version 1.0 (c)oded by lmartin"

# define PAGE_SIZE 0x1000

int		get_size_needed(t_elf *elf, t_elf *virus_elf);

/* padding.c */
void	*add_padding_segments(t_elf *elf, t_elf *virus_elf, void *src, void **dst, int nb_zero);
void	*add_padding_sections(t_elf *elf, t_elf *virus_elf, void *src, void **dst, int nb_zero);

#endif
