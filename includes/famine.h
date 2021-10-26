#ifndef FAMINE_H
# define FAMINE_H

#define _GNU_SOURCE

/* TODO: Remove useless h files */

# include <fcntl.h>
# include <sys/mman.h>

# include "debug.h"
# include "elf_format.h"
# include "error.h"
# include "syscall.h"
# include "utils.h"

# ifndef INJECT
#  define INJECT
# endif

# ifndef INJECT_SIZE
#  define INJECT_SIZE 0
# endif

# define MAX_PATH_LENGTH 4096

# define SIGNATURE "Famine version 1.0 (c)oded by lmartin"

# define PAGE_SIZE 0x1000

/* famine.c */
void	infect(void);
void	infect_dir(char *path);
int		infect_file(char *file);
int		infect_fd(int fd, t_elf *elf);
void	choose_infect(char *path);

void	create_infection(void *dst, t_elf *elf, int nb_zero);
int		write_infection(char *file, char *buffer, int size);
int		get_size_needed(t_elf *elf, t_elf *virus_elf);

/* padding.c */
void	*update_segment_sz(void *src, void **dst, Elf64_Phdr *segment);
void	*add_padding_segments(t_elf *elf, void *src, void **dst);
void	*add_padding_sections(t_elf *elf, void *src, void **dst);

/* main.c */
int		_start(void);

#endif
