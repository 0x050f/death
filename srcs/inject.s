section.text:
	global _start:function

_start:
	call _inject ; push addr to stack

_inject:
	pop rax
	sub rax, 0x5

	mov rdx, [rel offset_inject]
	sub rdx, [rel vaddr]
	sub rax, rdx
	add rax, [rel entry]
	pop rdx
	jmp rax

_params:
	vaddr dq 0x0
	offset_inject dq 0x0
	entry dq 0x0
