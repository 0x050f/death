#ifndef DEBUG_H
# define DEBUG_H

# include "elf_format.h"

# define _RED		"\e[31m"
# define _GREEN		"\e[32m"
# define _YELLOW	"\e[33m"
# define _BLUE		"\e[34m"
# define _END		"\e[0m"

void	debug_print_error(int code, char *prg, char *input);
void	debug_print_elf(t_elf *elf);
void	debug_print_args(int argc, char *argv[]);

#endif
