#ifndef DEBUG_H
# define DEBUG_H

# ifdef DEBUG
#  include "elf_format.h"

#  define _RED		"\e[31m"
#  define _GREEN	"\e[32m"
#  define _YELLOW	"\e[33m"
#  define _BLUE		"\e[34m"
#  define _END		"\e[0m"

#  define ALREADY_INFECTED -2

void	debug_print_error(int code, char *file);
void	debug_print_elf(t_elf *elf);
void	debug_print_args(int argc, char *argv[]);
# endif

#endif
