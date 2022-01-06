section.text:
	global _start

_params:
	entry_inject dq 0x0
	entry_prg dq 0x0

_start:
	call _print_me
	db `Hello world !\n`, 0x0

_print_me:
	pop rsi
	push rdx

	mov rdi, 1
	mov rdx, 14
	mov rax, 1
	syscall

	sub rsi, 0x5

	xor rax, rax
	cmp rax, [rel entry_inject]
	je .end

	pop rdx

	push rsi
	pop rax

	sub rax, [rel entry_inject]
	add rax, [rel entry_prg]

	jmp rax

	.end:
		pop rdx

		xor rdi, rdi
		mov rax, 60
		syscall
