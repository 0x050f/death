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

void	unpack(unsigned char *dst, size_t length, unsigned char *src, size_t size)
{
	size_t i = 0;
	size_t j = 0;
	while (i < size)
	{
		if (src[i] == 244) // cmp
		{
			i++;
			memcpy(&dst[j], &dst[j - src[i]], src[i + 1]); // inc then memcpy
			i++;
			j += src[i]; // add
			i++;
		}
		else
			dst[j++] = src[i++];
	}
	printf("\n======================\n");
	for (size_t i = 0; i < length; i++)
		printf("\\x%02x ", ((unsigned char *)dst)[i]);
	printf("\n======================\n");
	printf("length: %ld\n", length);
}

void	pack(void *addr, size_t size)
{
	printf("\n======================\n");
	for (size_t i = 0; i < size; i++)
		printf("\\x%02x ", ((unsigned char *)addr)[i]);
	printf("\n======================\n");
	printf("length: %ld\n", size);
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0') 

	int test[256];
	bzero(&test, 256);
	for (int a = 0; a < size; a++)
	{
		test[*(unsigned char *)(addr + a)]++;
	}

	for (int a = 0; a < 256; a++)
	{
		if (!test[a])
			printf("\\x%02x, %d, "BYTE_TO_BINARY_PATTERN"\n", a, a, BYTE_TO_BINARY(a));
	}

	unsigned char	compressed[size];
	unsigned char	*buffer = addr;
	int		size_b = 255;
	unsigned char	*dictionary = addr;

	t_data compression[size];

	size_t i = 0;
	size_t l = 0;
	size_t r = 0;
	while (i < size)
	{
		size_t len = dictionary - buffer;
		if (len > size_b)
		{
			buffer += len - size_b;
			len = dictionary - buffer;
		}
/*
		printf("\n");
		printf("len: %ld\n", len);
		if (len < 10)
		{
			printf("\n");
			printf("len: %d\n", len);
			printf("char: %d\n", *dictionary);
		}
*/
		char *ret = 0;
		char *prev_ret = 0;
		size_t k = 1;
		while (++r && k < size_b && i + k < size && (ret = (unsigned char *)memmem((void *)buffer, len, (void *)dictionary, k)))
		{
			prev_ret = ret;
//			printf("char: %d\n", *dictionary + k);
			k++;
		}
		k--;
		if (prev_ret && k >= 4)
		{
			compressed[l] = 244; // 17 not in the code and its 00010001 in binary
			l++;
			printf("(244, ");
			compressed[l] = (char)((unsigned long)dictionary - (unsigned long)prev_ret);
			l++;
			printf("%ld, ", (unsigned long)dictionary - (unsigned long)prev_ret);
			compressed[l] = k;
			l++;
			printf("%ld) ", k);
		}
		else
		{
			k = 1;
			prev_ret = dictionary;
			compressed[l++] = *dictionary;
			printf("\\x%02x ", (unsigned char)*dictionary);
		}
		dictionary += k;
		i += k;
	}
	printf("\n");
	printf("r: %ld\n", r);
	printf("l: %ld\n", l);
	printf("sizeof(t_data): %ld\n", sizeof(t_data));
	printf("previous size: %ld\n", size);
	size_t compressed_size = ++l;
	printf("new size: %ld\n", compressed_size);
	void *dst = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
	unpack(dst, size, compressed, compressed_size);

/*
	int fd = open("filea", O_CREAT | O_TRUNC | O_RDWR, 0644);
	for (size_t l = 0; l < size; l++)
		dprintf(fd, "\\x%02x\n", ((unsigned char *)addr)[l]);
	close(fd);
	fd = open("fileb", O_CREAT | O_TRUNC | O_RDWR, 0644);
	for (size_t l = 0; l < size; l++)
		dprintf(fd, "\\x%02x\n", ((unsigned char *)dst)[l]);
	close(fd);
*/

	if (!memcmp(dst, addr, size))
		printf("DIFF OK\n");
	else
		printf("DIFF KO\n");
	munmap(dst, size);
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
					void *offset = addr + shdr->sh_offset;
					void *end_offset = memmem(offset, shdr->sh_size, "\tcat\n", 5);
					end_offset += 2;
					void *start_offset = offset + 0x3c8; // _search_dir
					printf("size: %ld\n", end_offset - start_offset);
					pack(start_offset, (unsigned long)end_offset - (unsigned long)start_offset);
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
