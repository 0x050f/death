#include "famine.h"

void	debug_print_error(int code, char *prg, char *input)
{
	if (!code)
		fprintf(stderr, "%s%s%s: %s%s%s: %s\n", _RED, basename(prg), _END, _RED, input , _END, strerror(errno));
	else if (code == CORRUPTED_FILE)
		fprintf(stderr, "%s%s%s: %s%s%s: %s\n", _RED, basename(prg), _END, _RED, input, _END, "Corrupted file");

}

void	debug_print_elf(t_elf *elf)
{
	printf("--------------> %sELF%s <----------------\n", _YELLOW, _END);
	printf("%sfilename%s:	%s\n", _YELLOW, _END, elf->filename);
	printf("%saddr%s:		%p\n", _YELLOW, _END, elf->addr);
	printf("%ssize%s:		%ld\n", _YELLOW, _END, elf->size);
	printf("- - - - - - - - - - - - - - - - - - -\n");
	printf("%sheader%s:		0x%lx\n", _YELLOW, _END, (unsigned long)elf->header - (unsigned long)elf->addr);
	printf("%ssegments%s:	0x%lx\n", _YELLOW, _END, (unsigned long)elf->segments - (unsigned long)elf->addr);
	printf("%ssections%s:	0x%lx\n", _YELLOW, _END, (unsigned long)elf->sections - (unsigned long)elf->addr);
	printf("%spt_load%s:	0x%lx\n", _YELLOW, _END, (unsigned long)elf->pt_load - (unsigned long)elf->addr);
	printf("%stext_section%s:	0x%lx\n", _YELLOW, _END, (unsigned long)elf->text_section - (unsigned long)elf->addr);
	printf("-------------------------------------\n");
}

void	debug_print_args(int argc, char *argv[])
{
	int			i;

	printf("--------------> %sARGS%s <---------------\n", _YELLOW, _END);
	printf("%sargc%s:		%d\n", _YELLOW, _END, argc);
	for (i = 0; argv[i]; i++)
		printf("%sargv[%d]%s:	`%s`\n", _YELLOW, i, _END, argv[i]);
	printf("-------------------------------------\n");
}
