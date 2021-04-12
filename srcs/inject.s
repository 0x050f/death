section.text:
	global _start:function

_start:
	call _inject ; push addr to stack

_inject:
	pop rax
	push rdx ; save register
	sub rax, 0x5

	mov rdx, [rel offset_inject]
	sub rdx, [rel vaddr]
	sub rax, rdx
	add rax, [rel entry]
	pop rdx
	jmp rax
	mov rax, 60
	mov rdx, 3
	syscall

_params:
	vaddr dq 0x0
	offset_inject dq 0x0
	entry dq 0x0
