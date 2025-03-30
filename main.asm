format ELF64 executable

STDIN_FILENO = 0
STDOUT_FILENO = 1
STDERR_FILENO = 2

SYS_write = 1
SYS_exit = 60

COROUTINES_CAPACITY = 10
STACK_CAPACITY = 4 * 1024

segment executable
print:
    mov r9, -3689348814741910323
    sub rsp, 40
    mov BYTE [rsp+31], 10
    lea rcx, [rsp+30]

.L2:
    mov rax, rdi
    lea r8, [rsp+32]
    mul r9
    mov rax, rdi
    sub r8, rcx
    shr rdx, 3
    lea rsi, [rdx+rdx*4]
    add rsi, rsi
    sub rax, rsi
    add eax, 48
    mov BYTE [rcx], al
    mov rax, rdi
    mov rdi, rdx
    mov rdx, rcx
    sub rcx, 1
    cmp rax, 9
    ja .L2
    lea rax, [rsp+32]
    mov edi, 1
    sub rdx, rax 
    xor eax, eax
    lea rsi, [rsp+32+rdx]
    mov rdx, r8
    mov rax, 1
    syscall
    add rsp, 40
    ret

counter:
    push rbp
    mov rbp, rsp 
    sub rsp, 8

    mov QWORD [rbp-8], 0 

.again:
    cmp QWORD [rbp-8], 10
    jge .over

    mov rdi, [rbp-8]
    call print
    call coroutine_yield    ; Add yield here to switch to other coroutine

    inc QWORD [rbp-8]
    jmp .again

.over:
    add rsp, 8
    pop rbp
    ret    

;; rdi - procedure to start a new coroutine
coroutine_go:
    cmp QWORD [contexts_count], COROUTINES_CAPACITY
    jge overflow_fail
    
    mov rbx, [contexts_count] ;; rbx contains index of  context we just allocated
    inc QWORD [contexts_count]

    mov rax, [stacks_end] ;; rax contains rsp of new routine

    sub QWORD [stacks_end], STACK_CAPACITY
    sub rax, 8
    mov QWORD [rax], coroutine_finish

    mov [contexts_rsp+rbx*8], rax
    mov QWORD [contexts_rbp+rbx*8], 0
    mov [contexts_rip+rbx*8], rdi

    ret
    

coroutine_init:
    cmp QWORD [contexts_count], COROUTINES_CAPACITY
    jge overflow_fail

    mov rbx, [contexts_count] ;; rbx contains index of  context we just allocated
    inc QWORD [contexts_count]

    pop rax ;; return address is in rax now

    mov [contexts_rsp+rbx*8], rsp
    mov [contexts_rbp+rbx*8], rbp
    mov [contexts_rip+rbx*8], rax

    jmp rax

coroutine_yield:
    mov rbx, [contexts_current]

    pop rax
    mov [contexts_rsp+rbx*8], rsp
    mov [contexts_rbp+rbx*8], rbp
    mov [contexts_rip+rbx*8], rax

    inc rbx
    xor rcx, rcx
    cmp rbx, [contexts_count]
    cmovge rbx, rcx
    mov [contexts_current], rbx

    mov rsp, [contexts_rsp+rbx*8]
    mov rbp, [contexts_rbp+rbx*8]
    jmp QWORD [contexts_rip+rbx*8]

coroutine_finish:
    mov rax, SYS_write
    mov rdi, STDOUT_FILENO
    mov rsi, coroutine_finish_not_implemented
    mov rdx, coroutine_finish_not_implemented_len
    syscall

    mov rax, SYS_exit
    mov rdi, 0
    syscall

entry main
main:
    call coroutine_init

    mov rdi, counter
    call coroutine_go

    mov rdi, counter
    call coroutine_go

.forever:
    call coroutine_yield
    jmp .forever

    mov rax, SYS_write
    mov rdi, STDOUT_FILENO
    mov rsi, ok
    mov rdx, ok_len
    syscall

    mov rdi, [contexts_count]
    call print

    mov rax, SYS_exit
    mov rdi, 0
    syscall

overflow_fail:
    mov rax, SYS_write
    mov rdi, STDERR_FILENO
    mov rsi, too_many_coroutines_msg
    mov rdx, too_many_coroutines_msg_len
    syscall

    mov rax, SYS_exit
    mov rdi, 69
    syscall

segment readable
too_many_coroutines_msg: db "Too many coroutines", 0, 10
too_many_coroutines_msg_len = $-too_many_coroutines_msg
ok: db "OK", 0, 10
ok_len = $-ok
coroutine_finish_not_implemented: db "Coroutine finish not implemented", 0, 10
coroutine_finish_not_implemented_len = $-coroutine_finish_not_implemented

segment readable writable
stacks_end: dq stacks + COROUTINES_CAPACITY * STACK_CAPACITY
contexts_rsp: rq COROUTINES_CAPACITY
contexts_rbp: rq COROUTINES_CAPACITY
contexts_rip: rq COROUTINES_CAPACITY
contexts_count: rq 1
contexts_current: dq 0

stacks: rb COROUTINES_CAPACITY * STACK_CAPACITY


