#include "famine.h"

void	print_color(const char *color, const char *str)
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

void	debug_print_error(int code, const char *file)
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
		case NOT_ELF:
			ft_putstr("Not an ELF file");
			break;
		case TOO_BIG:
			ft_putstr("Payload is too big");
			break;
		default:
			ft_putstr("Error");
	}
	ft_putstr("\n");
}

void	debug_print_file_type(const char *path, int type)
{
	char *strings[] =
	{
		(char[7]){' ', 0xf0, 0x9f, 0x93, 0x81,'\n','\0'}, // 📁
		(char[7]){' ', 0xf0, 0x9f, 0x94, 0x92,'\n','\0'}, // 🔒
		(char[7]){' ', 0xf0, 0x9f, 0x93, 0x84,'\n','\0'}, // 📄
		(char[7]){' ', 0xf0, 0x9f, 0x94, 0x8f,'\n','\0'}, // 🔏
		(char[6]){' ', 0xe2, 0x9d, 0x93, '\n','\0'} // ❓
	};
	ft_putstr(path);
	ft_putstr(strings[type]);
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
