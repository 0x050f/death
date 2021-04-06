#include "famine.h"

int			check_file(void *addr)
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

void	moving_through_path(char *path)
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

int		main(void)
{
	moving_through_path("/tmp/test");
	moving_through_path("/tmp/test2");
	return (0);
}
