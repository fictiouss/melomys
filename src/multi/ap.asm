; => Taken from baremetal by return infinity

BITS 16

init_smp_ap:

	; Check boot method of bsp
	; Enable a20 gate
skip_a20_ap:

	; Switch to 32-bit protected mode
	lgdt [cs:GDTR32]

	mov eax, cr0
	or al, 1
	mov cr0, eax

	jmp 8:startap32

align 16


; 32 bit mode
BITS 32

startap32:
	mov eax, 16
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	xor esi, esi
	xor edi, edi
	xor ebp, ebp

	mov esp, 0x7000 ; temp stack for ap init

	; Load 64-bit gdt
	lgdt [GDTR64]

	; Enable pae + paging bits
	mov eax, cr4
	or eax, 0x000000B0
	mov cr4, eax

	; Set pml4 table
	mov eax, 0x00002008
	mov cr3, eax

	; Enable long mode
	mov ecx, 0xC0000080
	rdmsr
	or eax, 0x101
	wrmsr

	; Turn on paging
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax

	jmp SYS64_CODE_SEL:startap64

align 16


; The next are 64 bit mode
BITS 64

startap64:
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	xor esi, esi
	xor edi, edi
	xor ebp, ebp
	xor esp, esp

	xor r8, r8
	xor r9, r9
	xor r10, r10
	xor r11, r11
	xor r12, r12
	xor r13, r13
	xor r14, r14
	xor r15, r15

	mov ax, 0x10

	; set segment regs (legacy stuff, maybe not needed in long mode)
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax

	; setup per-cpu stack
	mov rsi, [p_LocalAPICAddress]
	add rsi, 0x20
	lodsd
	shr rax, 24
	shl rax, 10
	add rax, 0x90000
	mov rsp, rax

	lgdt [GDTR64]
	lidt [IDTR64]

	call init_cpu

	sti
	jmp ap_sleep

align 16

ap_sleep:
	hlt
	jmp ap_sleep

; eof
