#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <string.h>
#include <elf.h>

typedef struct	s_data // 3 bytes
{
	unsigned char d; // distance
	unsigned char l; // length
	char c; // char
}				t_data;

void	pack(void *addr, size_t size)
{
	char	*buffer = addr;
	int		size_b = 256;
	char	*dictionary = addr;

	t_data compression[size];

	size_t i = 0;
	size_t j = 0;
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
		char distance;
		char length;
		char c;
		char *ret = 0;
		char *prev_ret = 0;
		size_t k = 0;
		while (k < size_b && i + k < size && (ret = (char *)memmem((void *)buffer, len, (void *)dictionary, k)))
		{
			prev_ret = ret;
			k++;
		}
		if (!prev_ret && i + k == size)
			printf("hello !\n");
//		printf("dictionary 0x%lx\n", (unsigned long)dictionary);
//		printf("prev_ret 0x%lx\n", (unsigned long)prev_ret);
		k--;
		compression[j].d = (char)((unsigned long)dictionary - (unsigned long)prev_ret);
		compression[j].l = k;
		compression[j].c = *(prev_ret + k + 1);
//		printf("%p\n", prev_ret);
//		printf("%p\n", dictionary);
		printf("(%d, %d, %d) ", compression[j].d,
								compression[j].l,
								compression[j].c);
		dictionary += k + 1;
		i += k + 1;
		j++;
	}
	printf("\n");
	printf("j: %ld\n", j);
	printf("sizeof(t_data): %ld\n", sizeof(t_data));
	printf("previous size: %ld\n", size);
	printf("new size: %ld\n", j * sizeof(t_data));
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
