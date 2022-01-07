#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

int			main(void)
{
	char buffer[4096];

	int fd = open("/proc/self/status", O_RDONLY);
	read(fd, &buffer, 4096);
	void *res = memmem(buffer, 4096, "TracerPid:\t0\n", 13);
	if (res)
		printf("Not traced !\n");
	else
		printf("Traced !\n");
	close(fd);
	return (0);
}
