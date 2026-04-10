; => Taken from baremetal os by return infinity

init_smp:
	; check if smp is enabled
	cmp byte [cfg_smpinit], 1
	jne noMP

	; start ap's one by one
	xor eax, eax
	xor edx, edx
	mov rsi, [p_LocalAPICAddress]
	mov eax, [rsi+0x20]
	shr rax, 24
	mov dl, al

	mov esi, IM_DetectedCoreIDs
	xor eax, eax
	xor ecx, ecx
	mov cx, [p_cpu_detected]

smp_send_INIT:
	cmp cx, 0
	je smp_send_INIT_done
	lodsb

	cmp al, dl
	je smp_send_INIT_skipcore

	; send init ipi
	mov rdi, [p_LocalAPICAddress]
	shl eax, 24
	mov dword [rdi+0x310], eax
	mov eax, 0x00004500
	mov dword [rdi+0x300], eax

smp_send_INIT_verify:
	mov eax, [rdi+0x300]
	bt eax, 12
	jc smp_send_INIT_verify

smp_send_INIT_skipcore:
	dec cl
	jmp smp_send_INIT

smp_send_INIT_done:

	; small wait before sipi
	mov eax, 500
	call os_hpet_delay

	mov esi, IM_DetectedCoreIDs
	xor ecx, ecx
	mov cx, [p_cpu_detected]

smp_send_SIPI:
	cmp cx, 0
	je smp_send_SIPI_done
	lodsb

	cmp al, dl
	je smp_send_SIPI_skipcore

	; send startup ipi
	mov rdi, [p_LocalAPICAddress]
	shl eax, 24
	mov dword [rdi+0x310], eax
	mov eax, 0x00004608
	mov dword [rdi+0x300], eax

smp_send_SIPI_verify:
	mov eax, [rdi+0x300]
	bt eax, 12
	jc smp_send_SIPI_verify

smp_send_SIPI_skipcore:
	dec cl
	jmp smp_send_SIPI

smp_send_SIPI_done:

	; wait for ap boot
	mov eax, 10000
	call os_hpet_delay

noMP:
	; get bsp apic id
	xor eax, eax
	mov rsi, [p_LocalAPICAddress]
	add rsi, 0x20
	lodsd
	shr rax, 24
	mov [p_BSP], eax

	; rough cpu speed calc
	cpuid
	xor edx, edx
	xor eax, eax
	rdtsc
	push rax
	mov rax, 1024
	call os_hpet_delay
	rdtsc
	pop rdx
	sub rax, rdx
	xor edx, edx
	mov rcx, 1024
	div rcx
	mov [p_cpu_speed], ax

	ret

; eof
