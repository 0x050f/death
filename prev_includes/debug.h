#ifndef DEBUG_H
# define DEBUG_H

# ifdef DEBUG
#  include "elf_format.h"
#  include "error.h"

#  define _RED		"\e[31m"
#  define _GREEN	"\e[32m"
#  define _YELLOW	"\e[33m"
#  define _BLUE		"\e[34m"
#  define _END		"\e[0m"

#  define _DIR		0
#  define _LOCK		1
#  define _FILE		2
#  define _LOCK_W	3
#  define _UNKNOW	4

void	debug_print_error(int code, const char *file);
void	debug_print_file_type(const char *path, int type);
void	debug_print_elf(t_elf *elf);
# endif

#endif
