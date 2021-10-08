#include "famine.h"

void	print_color(char *color, char *str)
{
	syscall_write(STDOUT_FILENO, color, ft_strlen(color));
	syscall_write(STDOUT_FILENO, str, ft_strlen(str));
	syscall_write(STDOUT_FILENO, _END, ft_strlen(_END));
}

char	*ft_basename(char *prg)
{
	char	*tmp;
	char	*ptr;

	ptr = prg;
	while (tmp = ft_memmem(ptr, ft_strlen(ptr), "/", 1))
		ptr = tmp;
	return (ptr);
}

void	debug_print_error(int code, char *file)
{
	print_color(_RED, file);
	ft_putstr(": ");
	switch (code)
	{
		case CORRUPTED_FILE:
			ft_putstr("Corrupted file");
			break;
		case ALREADY_INFECTED:
			ft_putstr("Already infected");
			break;
		default:
			ft_putstr("Error");
	}
	ft_putstr("\n");
}

#  define _DIR		1
#  define _LOCK		2
#  define _FILE		3
#  define _LOCK_W	4
#  define _UNKNOW	5

void	debug_print_file_type(char *path, int type)
{
	ft_putstr(path);
	if (type == _DIR)
		ft_putstr(" 📁\n");
	else if (type == _LOCK)
		ft_putstr(" 🔒\n");
	else if (type == _FILE)
		ft_putstr(" 📄\n");
	else if (type == _LOCK_W)
		ft_putstr(" 🔏\n");
	else if (type == _UNKNOW)
		ft_putstr(" ❓\n");
}

void	debug_print_elf(t_elf *elf)
{
	char	*name_params[] = {"filename", "addr", "size", "entry", "header", "segments", "sections", "pt_load", "text_section"};
	unsigned long params[] = {(unsigned long)elf->header,
							(unsigned long)elf->segments,
							(unsigned long)elf->sections,
							(unsigned long)elf->pt_load,
							(unsigned long)elf->text_section};

	ft_putstr("--------------> ");
	print_color(_YELLOW, "ELF");
	ft_putstr(" <----------------\n");
	for (int i = 0; i < 8; i++)
	{
		print_color(_YELLOW, name_params[i]);
		ft_putstr(":");
		if (ft_strlen(name_params[i]) + 1 < 8)
			ft_putstr("	");
		ft_putstr("	");
		switch (i) {
			case 0: 
				ft_putstr(elf->filename);
				break;
			case 1:
				ft_putstr("0x");
				ft_puthexa((unsigned long)elf->addr);
				break;
			case 2:
				ft_putnbr(elf->size);
				break;
			case 3:
				ft_putstr("0x");
				ft_puthexa((unsigned long)elf->header->e_entry);
				break;
			default:
				ft_putstr("0x");
				ft_puthexa(params[i - 4] - (unsigned long)elf->addr);
		}
		ft_putstr("\n");
		if (i == 2)
			ft_putstr("- - - - - - - - - - - - - - - - - - -\n");
	}
	ft_putstr("-------------------------------------\n");
}

void	debug_print_args(int argc, char *argv[])
{
	int			i;

	ft_putstr("--------------> ");
	print_color(_YELLOW, "ARGS");
	ft_putstr(" <---------------\n");
	print_color(_YELLOW, "argc");
	ft_putstr(":		");
	ft_putnbr(argc);
	ft_putstr("\n");
	for (i = 0; argv[i]; i++)
	{
		print_color(_YELLOW, "argv[");
		ft_putnbr(i);
		print_color(_YELLOW, "]");
		ft_putstr(":	`");
		ft_putstr(argv[i]);
		ft_putstr("`\n");
	}
	ft_putstr("-------------------------------------\n");
}
