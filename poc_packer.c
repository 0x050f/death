#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <string.h>
#include <elf.h>
#include <stdlib.h>

typedef struct	s_data // 2 bytes
{
	unsigned char identifier; //
	unsigned char d; // distance
	unsigned char l; // length
}				t_data;

void	pack(void *addr, size_t size)
{
/*
	int test[256];
	bzero(&test, 256);
	for (int a = 0; a < size; a++)
	{
		test[*(unsigned char *)(addr + a)]++;
	}

	for (int a = 0; a < 256; a++)
	{
		if (!test[a])
			printf("\\x%02x, %d\n", a, a);
	}
*/

	char	*buffer = addr;
	int		size_b = 236;
	char	*dictionary = addr;

	t_data compression[size];

	size_t i = 0;
	size_t j = 0;
	size_t l = 0;
	while (i < size)
	{
		size_t len = dictionary - buffer;
		if (len > size_b)
		{
			buffer += len - size_b;
			len = dictionary - buffer;
		}
//		printf("\n");
//		printf("len: %ld\n", len);
//		if (len < 10)
//		{
//			printf("\n");
//			printf("len: %d\n", len);
//			printf("char: %d\n", *dictionary);
//		}
		char *ret = 0;
		char *prev_ret = 0;
		size_t k = 1;
		while (k < size_b && i + k < size && buffer != dictionary && (ret = (char *)memmem((void *)buffer, len, (void *)dictionary, k)))
		{
			prev_ret = ret;
//			printf("char: %d\n", *dictionary + k);
			k++;
		}
		if (!prev_ret || k - 1 < 4)
		{
			k = 1;
			prev_ret = dictionary;
			printf("\\x%x ", (unsigned char)*dictionary);
			l++;
		}
		else
		{
			k--;
			compression[j].identifier = 237;
			compression[j].d = (char)((unsigned long)dictionary - (unsigned long)prev_ret);
			compression[j].l = k;
	//		printf("\\x%x", *(dictionary + k - 1));

			printf("(%d, %d, %d) ", compression[j].identifier,
									compression[j].d,
									compression[j].l);
	//		printf("\n");
			j++;
		}
		dictionary += k;
		i += k;
	}
	printf("\n");
	printf("l: %ld\n", l);
	printf("j: %ld\n", j);
	printf("sizeof(t_data): %ld\n", sizeof(t_data));
	printf("previous size: %ld\n", size);
	printf("new size: %ld\n", j * sizeof(t_data) + l);
}

int		get_executable(int fd, char *filename, struct stat sb)
{
	int ret;

	ret = 0;
	void *addr = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (addr)
	{
		char elf_magic[6] = "\x7f\x45\x4c\x46\x02\x00";

		if (!memcmp(addr, elf_magic, 5))
		{
			Elf64_Ehdr *ehdr = addr;
			Elf64_Shdr *shdr = (Elf64_Shdr *)(addr + ehdr->e_shoff);
			Elf64_Shdr *sh_strtab = &shdr[ehdr->e_shstrndx];
			for (int i = 0; i < ehdr->e_shnum; i++)
			{
				if (!strcmp((char *)((unsigned long)addr +
(unsigned long)sh_strtab->sh_offset + shdr->sh_name), ".text"))
				{
					printf("offset: 0x%lx\n", shdr->sh_offset);
					printf("size: 0x%lx\n", shdr->sh_size);
					pack(addr + shdr->sh_offset, shdr->sh_size);
				}
				shdr++;
			}
			ret = 1;
		}
		munmap(addr, sb.st_size);
	}
	return (ret);
}

int		main(int argc, char *argv[])
{
	int ret;

	ret = 0;
	if (argc < 2)
	{
		dprintf(STDERR_FILENO, "%s executable\n", argv[0]);
		return (1);
	}
	int fd = open(argv[1], O_RDONLY);
	if (fd > 0)
	{
		struct stat sb;
		if (!stat(argv[1], &sb) &&
((sb.st_mode & S_IFMT) == S_IFREG))
			ret = get_executable(fd, argv[1], sb);
		else
		{
			dprintf(STDERR_FILENO, "%s isn't a regular file\n", argv[1]);
			ret = 1;
		}
	}
	close(fd);
	return (ret);
}
