; © Jacob Liam Gill 2025. All rights reserved. **DO NOT REMOVE THIS LINE.**
; Quplexity MUST be credited in the project you use it in either throughout documentation and/or in the code base. **DO NOT REMOVE THIS LINE.**

; I'm striving to make the code for Quplexity as readable as possible.
; If you would like to contribute or contact me for any other reason please don't hesitate to email me: jacobygill@outlook.com
; Or DM/friend request me on Discord: @bixel0

section .data
  align 16
  sqrt2_inv dq 0.7071067811865475, 0.7071067811865475  ; 1/sqrt(2)
  align 16
  one_state dq 0.0, 1.0
  align 16 
  const dq 1.0, -1.0   ; For (basic) Pauli-Z and controlled-Z gates (flip the second component)
  align 16
  neg_imag dq 0.0, -1.0, 1.0, 0.0   ; For multiplying by -i and i in Pauli-Y gate
  one dq 1.0
  zero dq 0.0
  align 16
  negOne_one dq -1.0, 1.0
  align 16
  const_negOne dq -1.0, -1.0



section .text
  global _QuantumCircuit
  global _PX
  global _PZ
  global _PY
  global _H
  global _H_basic
  global _CNOT
  global _CCNOT
  global _CZ


_QuantumCircuit:
  xor rdx, rdx                  ; rdx = loop counter (qubit index)
  shl rdi, 5                    ; rdi = num_of_qubits * 32 (each qubit is 4 doubles = 32 bytes)

  movq xmm0, qword [one]        ; Load 1.0 into xmm0 (a_real)
  movq xmm1, qword [zero]       ; Load 0.0 into xmm1 (a_imag)
  movq xmm2, qword [zero]       ; Load 0.0 into xmm2 (b_real)
  movq xmm3, qword [zero]       ; Load 0.0 into xmm3 (b_imag)

init_loop:
  cmp rdx, rdi                  ; Compare index with end
  jge done                      ; If rdx >= num_of_qubits * 32, exit

  lea rax, [rsi + rdx]          ; rax = qubits + rdx
  movaps [rax], xmm0            ; Store (1.0, 0.0)
  movaps [rax + 16], xmm2       ; Store (0.0, 0.0)

  add rdx, 32                   ; Move to next qubit (4 doubles = 32 bytes)
  jmp init_loop                 ; Repeat

done:
  ret

_PX:
  ; Pauli-X Quantum Gate: applies the Pauli X on the input qubit described by two complex numbers
  MOVAPD XMM0, [RDI] 		; XMM0 = (alpha_real, alpha_imag)
  MOVAPD XMM1, [RDI + 16]	; XMM1 = (beta_real, beta_imag)
  MOVAPD [RDI], XMM1		; Switch
  MOVAPD [RDI+16], XMM0
  RET

_PX_basic:
  ; Pauli-X Quantum Gate: applies the Pauli X on the input qubit described by two real numbers
  MOVAPD XMM0, [RDI]		; XMM0 = [q[0], q[1]]
  SHUFPD XMM0, XMM0, 01b	; XMM0 = [q[1], q[0]]
  MOVAPD [RDI], XMM0		; Store back and return
  RET

_PZ:
  ; Pauli-Z Quantum Gate: applies the Pauli Z on the input qubit described by two complex numbers
  MOVAPD XMM0, [RDI+16]  	; XMM0 = (beta_real, beta_imag) 
  MULPD XMM0, [const_negOne] 	; XMM0 = (-beta_real, -beta_imag)
  MOVAPD [RDI+16], XMM0		; Store back and return
  RET

_PZ_basic:
  ; Pauli-Z Quantum Gate: applies the Pauli Z on the input qubit described by two real numbers
  MOVAPD XMM0, [RDI]		; XMM0 = [q[0], q[1]]
  MULPD XMM0, [const]		; XMM0 = [q[0], -q[1]]
  MOVAPD [RDI], XMM0		; Store back and return
  RET

_PY:
  ; Pauli-Y Quantum Gate: applies the Pauli Y on the input qubit described by two complex numbers
  MOVAPD XMM0, [RDI]       	; XMM0 = (alpha_real, alpha_imag)
  MOVAPD XMM1, [RDI + 16]  	; XMM1 = (beta_real, beta_imag)

  ; After Pauli-Y: qubit = [ (beta_imag, -beta_real), (-alpha_imag, alpha_real) ]  

  SHUFPD XMM1, XMM1, 01b	; XMM1 = (beta_imag, beta_real)
  MULPD  XMM1, [const] 		; XMM1 = (beta_imag, -beta_real)

  SHUFPD XMM0, XMM0, 01b 	; XMM0 = (alpha_imag, alpha_real)
  MULPD  XMM0, [negOne_one]	; XMM0 = (-alpha_imag, alpha_real)

  MOVAPD [RDI], XMM1		; Store back and return
  MOVAPD [RDI + 16], XMM0
  RET

_H:
  ; Hadamard Quantum Gate: applies Hadamard on the input qubit described by two complex numbers
  MOVAPD XMM0, [RDI]       	; XMM0 = (alpha_real, alpha_imag)
  MOVAPD XMM1, [RDI + 16]  	; XMM1 = (beta_real, beta_imag)

  ; After Hadamad: qubit = [ (alpha_real + beta_real, alpha_imag + beta_imag), (alpha_real - beta_real, alpha_imag - beta_imag) ]

  MOVAPD XMM2, XMM0		; XMM2 = (alpha_real, alpha_imag)
  ADDPD XMM2, XMM1		; XMM2 = (alpha_real + beta_real, alpha_imag + beta_imag)

  SUBPD XMM0, XMM1		; XMM0 = (alpha_real - beta_real, alpha_imag - beta_imag)

  MULPD XMM2, [sqrt2_inv]	; Scale both results by 1/sqrt(2)
  MULPD XMM0, [sqrt2_inv]

  MOVAPD [RDI], XMM2		; Store back and return
  MOVAPD [RDI + 16], XMM0
  RET

_H_basic:
  ; Hadamard Quantum Gate: applies Hadamard on the input qubit described by two real numbers
  MOVAPD XMM0, [RDI]		; XMM0 = [q[0], q[1]]
  MOVAPD XMM1, XMM0
  MULPD XMM1, [const] 		; XMM1 = [q[0], -q[1]]
  HADDPD XMM0, XMM1		; XMM0 = [q[0] + q[1], q[0] - q[1]]
  MULPD XMM0, [sqrt2_inv]	; Scale by 1/sqrt(2)
  MOVAPD [RDI], XMM0		; Store back and return
  RET

_CNOT:
  ; *TO BE APPLIED ON THE ALREADY COMPUTED TENSOR PRODUCT*
  ; CNOT: loads the last two couples of the tensor product and switches
  MOVAPD XMM0, [RDI+32]		; XMM0 = [tensor[4], tensor[5]]
  MOVAPD XMM1, [RDI+48]		; XMM1 = [tensor[6], tensor[7]]
  MOVAPD [RDI+32], XMM1		; Store back and return
  MOVAPD [RDI+48], XMM0
retcn: RET

_CCNOT:
  ; Controlled-Controlled-NOT Gate (Toffoli gate)
  MOVAPD XMM0, [RDI]            ; Load control qubit 1
  CMPPD XMM0, [one_state], 0    ; Compare control qubit 1 with |1>
  PTEST XMM0, XMM0              ; Test if zero
  JZ retcc                      ; If not |1>, return

  MOVAPD XMM0, [RSI]            ; Load control qubit 2
  CMPPD XMM0, [one_state], 0    ; Compare control qubit 2 with |1>
  PTEST XMM0, XMM0              ; Test if zero
  JZ retcc                      ; If not |1>, return

  MOVAPD XMM0, [RDX]            ; Load target qubit
  SHUFPD XMM0, XMM0, 01b        ; Swap target qubit
  MOVAPD [RDX], XMM0            ; Store flipped target qubit back
retcc: RET

_CZ:
  ; Controlled-Z Gate
  MOVAPD XMM0, [RDI]            ; Load control qubit
  CMPPD XMM0, [one_state], 0    ; Compare control qubit with |1>
  PTEST XMM0, XMM0              ; Test if zero
  JZ retz                       ; If not |1>, return

  MOVAPD XMM0, [RSI]            ; Load target qubit
  MULPD XMM0, [const]           ; Apply Pauli-Z gate (flip the phase of qubit[1])
  MOVAPD [RSI], XMM0            ; Store updated target qubit back
retz: RET

ZERO:
  ; No change to target qubit if control qubits are not both in |1⟩ state
  RET
