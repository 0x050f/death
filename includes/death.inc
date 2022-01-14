; SYSCALL

%define SYSCALL_WRITE			1
%define SYSCALL_OPEN			2
%define SYSCALL_CLOSE			3
%define SYSCALL_LSTAT			6
%define SYSCALL_MMAP			9
%define SYSCALL_MPROTECT		10
%define SYSCALL_MUNMAP			11
%define SYSCALL_GETPID			39
%define SYSCALL_FORK			57
%define SYSCALL_EXIT			60
%define SYSCALL_WAIT4			61
%define SYSCALL_GETDENTS		78
%define SYSCALL_GETTIMEOFDAY	96

%macro WEXITSTATUS 2
	; example WEXITSTATUS rax, status will expand to
	; mov  rax, QWORD[status]
	; and  rax, 0xFF00
	; shr  rax, 8
	mov     %1, %2
	and     %1, 0xFF00
	shr     %1, 8
%endmacro

; GETDENTS

%define D_RECLEN			16

; STAT

%define ST_MODE				24
%define ST_SIZE				48

%define S_IFMT				0o0170000

%define S_IFDIR				0o0040000
%define S_IFREG				0o0100000

; MAP

%define MAP_SHARED			1
%define MAP_PRIVATE			2

; ELF

struc ehdr
	.e_ident:		resb	16
	.e_type:		resw	1
	.e_machine:		resw	1
	.e_version:		resd	1
	.e_entry:		resq	1
	.e_phoff:		resq	1
	.e_shoff:		resq	1
	.e_flags:		resd	1
	.e_ehsize:		resw	1
	.e_phentsize:	resw	1
	.e_phnum:		resw	1
	.e_shentsize:	resw	1
	.e_shnum:		resw	1
	.e_shstrndx:	resw	1
endstruc

%define ET_EXEC				2
%define ET_DYN				3

struc phdr
	.p_type:		resd	1
	.p_flags:		resd	1
	.p_offset:		resq	1
	.p_vaddr:		resq	1
	.p_paddr		resq	1
	.p_filesz		resq	1
	.p_memsz		resq	1
	.p_align		resq	1
endstruc

%define PF_X				1
%define PT_LOAD				1
%define PT_NOTE				4

%define SIZEOF(ELF64_PHDR)	56

; PACKER

%define MAGIC_CHAR			224

; KEY

%define KEY_SIZE			512
