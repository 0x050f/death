; SYSCALL

%define SYSCALL_WRITE		1
%define SYSCALL_OPEN		2
%define SYSCALL_CLOSE		3
%define SYSCALL_STAT		4
%define SYSCALL_MMAP		9
%define SYSCALL_MUNMAP		11
%define SYSCALL_FORK		57
%define SYSCALL_EXIT		60
%define SYSCALL_GETDENTS	78

; GETDENTS

%define D_RECLEN			16

; STAT

%define ST_MODE				24
%define ST_SIZE				48

%define S_IFMT				0o0170000
%define S_IFREG				0o0100000
%define S_IFLNK				0o0120000
%define S_IFDIR				0o0040000

; ELF

%define E_TYPE				16
%define E_ENTRY				24
%define E_PHOFF				32
%define E_PHNUM				56

%define ET_EXEC				2
%define ET_DYN				3

%define P_FLAGS				4
%define	P_OFFSET			8
%define P_VADDR				16
%define	P_FILESZ			32
%define	P_MEMSZ				40

%define PF_X				1
%define PT_LOAD				1

%define SIZEOF(ELF64_PHDR)	56

; PACKER

%define MAGIC_CHAR			244
