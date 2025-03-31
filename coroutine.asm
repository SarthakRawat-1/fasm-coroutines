format ELF64

; System call numbers and file descriptors
STDIN_FILENO = 0
STDOUT_FILENO = 1
STDERR_FILENO = 2

SYS_write = 1
SYS_exit = 60

; Configuration constants
COROUTINES_CAPACITY = 10          ; Maximum number of coroutines
STACK_CAPACITY = 4*1024          ; Size of stack for each coroutine (4KB)

;; TODO: make coroutine.o relocatable

section '.text'
;; Creates a new coroutine that starts executing the given procedure
;; Input: rdi - procedure address to start in a new coroutine
public coroutine_go
coroutine_go:
    ; Check if we haven't exceeded maximum coroutines
    cmp QWORD [contexts_count], COROUTINES_CAPACITY
    jge overflow_fail

    ; Get new coroutine index and increment count
    mov rbx, [contexts_count]     ; rbx contains the index of the
                                 ; context we just allocated
    inc QWORD [contexts_count]

    ; Setup new stack for the coroutine
    mov rax, [stacks_end]        ; rax contains the rsp of the new
                                 ; routine
    sub QWORD [stacks_end], STACK_CAPACITY
    sub rax, 8
    mov QWORD [rax], coroutine_finish  ; Push return address for when coroutine ends

    ; Save coroutine context
    mov [contexts_rsp+rbx*8], rax      ; Save stack pointer
    mov QWORD [contexts_rbp+rbx*8], 0  ; Initialize base pointer
    mov [contexts_rip+rbx*8], rdi      ; Save instruction pointer (procedure address)

    ret

;; Initializes the first coroutine (usually the main function)
;; Must be called before any other coroutine operations
public coroutine_init
coroutine_init:
    ; Check if we haven't exceeded maximum coroutines
    cmp QWORD [contexts_count], COROUTINES_CAPACITY
    jge overflow_fail

    ; Get new coroutine index and increment count
    mov rbx, [contexts_count]     
    inc QWORD [contexts_count]

    ; Save current execution context
    pop rax                       ; Get return address
    mov [contexts_rsp+rbx*8], rsp ; Save stack pointer
    mov [contexts_rbp+rbx*8], rbp ; Save base pointer
    mov [contexts_rip+rbx*8], rax ; Save instruction pointer (return address)

    jmp rax                      ; Return to caller

;; Switches execution to the next coroutine in round-robin fashion
public coroutine_yield
coroutine_yield:
    ; Get current coroutine index
    mov rbx, [contexts_current]

    ; Save current execution context
    pop rax                       ; Get return address
    mov [contexts_rsp+rbx*8], rsp ; Save stack pointer
    mov [contexts_rbp+rbx*8], rbp ; Save base pointer
    mov [contexts_rip+rbx*8], rax ; Save instruction pointer

    ; Move to next coroutine (with wraparound)
    inc rbx
    xor rcx, rcx                 ; rcx = 0
    cmp rbx, [contexts_count]
    cmovge rbx, rcx             ; If rbx >= contexts_count, rbx = 0
    mov [contexts_current], rbx

    ; Restore next coroutine's context
    mov rsp, [contexts_rsp+rbx*8] ; Restore stack pointer
    mov rbp, [contexts_rbp+rbx*8] ; Restore base pointer
    jmp QWORD [contexts_rip+rbx*8] ; Jump to saved instruction pointer

;; Called when a coroutine function returns
coroutine_finish:
    ; Print error message (TODO: implement proper cleanup)
    mov rax, SYS_write
    mov rdi, STDERR_FILENO
    mov rsi, coroutine_finish_not_implemented
    mov rdx, coroutine_finish_not_implemented_len
    syscall

    mov rax, SYS_exit
    mov rdi, 69
    syscall

;; Error handler for too many coroutines
overflow_fail:
    mov rax, SYS_write
    mov rdi, STDERR_FILENO
    mov rsi, too_many_coroutines_msg
    mov rdx, too_many_coroutines_msg_len
    syscall

    mov rax, SYS_exit
    mov rdi, 69
    syscall

section '.data'
; Error messages and other static data
too_many_coroutines_msg: db "ERROR: Too many coroutines", 0, 10
too_many_coroutines_msg_len = $-too_many_coroutines_msg
coroutine_finish_not_implemented: db "TODO: coroutine_finish is not implemented", 0, 10
coroutine_finish_not_implemented_len = $-coroutine_finish_not_implemented
ok: db "OK", 0, 10
ok_len = $-ok

; Current executing coroutine index
contexts_current: dq 0
; Points to the end of available stack space
stacks_end:       dq stacks+COROUTINES_CAPACITY*STACK_CAPACITY

section '.bss'
; Stack space for all coroutines
stacks:           rb COROUTINES_CAPACITY*STACK_CAPACITY
; Arrays storing context information for each coroutine
contexts_rsp:     rq COROUTINES_CAPACITY  ; Stack pointers
contexts_rbp:     rq COROUTINES_CAPACITY  ; Base pointers
contexts_rip:     rq COROUTINES_CAPACITY  ; Instruction pointers
public contexts_count
contexts_count:   rq 1                    ; Number of active coroutines