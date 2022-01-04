section.text:
	global _start

_start:
	call _print_me
	db `Hello world !\n`, 0x0

_print_me:
	pop rsi
	mov rdi, 1
	mov rdx, 14
	mov rax, 1
	syscall

	xor rdi, rdi
	mov rax, 60
	syscall
