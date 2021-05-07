#ifndef ELF_FORMAT_H
# define ELF_FORMAT_H

# include <elf.h>

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

int		init_elf(t_elf *elf, void *addr, long size);
int		check_magic_elf(void *addr);

#endif
