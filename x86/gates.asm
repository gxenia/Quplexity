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
  const dq 1.0, -1.0
 align 16
  negOne_one dq -1.0, 1.0
 align 16
  const_negOne dq -1.0, -1.0

section .text
  global _PX
  global _PX_basic
  global _PZ
  global _PZ_basic
  global _PY
  global _H
  global _H_basic
  global _CNOT
  global _CCNOT
  global _CZ

_PX:
  MOVAPD XMM0, [RDI]       ; XMM0 = (alpha_real, alpha_imag)
  MOVAPD XMM1, [RDI + 16]  ; XMM1 = (beta_real, beta_imag)
  ; Applying Pauli-X Quantum Gate
  MOVAPD [RDI], XMM1
  MOVAPD [RDI+16], XMM0
  RET

_PX_basic:
  ; Pauli-X Quantum Gate
  ; Load qubit
  MOVAPD XMM0, [RDI]       ; The "high" half of XMM0 contains qubit[0], the "low" half contains qubit[1]

  ; Perform Pauli-X operation (swapping elements)
  ; qubit[0] = qubit[1], qubit[1] = qubit[0]
  SHUFPD XMM0, XMM0, 01b
  MOVAPD [RDI], XMM0        ; Store qubit[0] into XMM1

  RET

_PZ:
  MOVAPD XMM0, [RDI+16] ; XMM1 = (beta_real, beta_imag) 
  MULPD XMM0, [const_negOne]; Applying Pauli-Z
  MOVAPD [RDI+16], XMM0
  RET

_PZ_basic:
  ; Pauli-Z Quantum Gate
  ; Load qubit
  MOVAPD XMM0, [RDI]       ; The "high" half of XMM0 contains qubit[0], the "low" half contains qubit[1]

  ; Pauli-Z matrix elements
  ; [ 1.0,  0.0 ] * [ a ]
  ; [ 0.0, -1.0 ] * [ b ]

  MULPD XMM0, [const]
  MOVAPD [RDI], XMM0

  RET

_PY:
  MOVAPD XMM0, [RDI]       ; XMM0 = (α_real, α_imag)
  MOVAPD XMM1, [RDI + 16]  ; XMM1 = (β_real, β_imag)

  SHUFPD XMM1, XMM1, 01b
  MULPD  XMM1, [const] 

  SHUFPD XMM0, XMM0, 01b 
  MULPD  XMM0, [negOne_one]

  MOVAPD [RDI], XMM1
  MOVAPD [RDI + 16], XMM0

  RET

_H:
  MOVAPD XMM0, [RDI]       ; XMM0 = (alphaα_real, α_imag)
  MOVAPD XMM1, [RDI + 16]  ; XMM1 = (betaβ_real, β_imag)

  MOVAPD XMM2, XMM0
  ADDPD XMM2, XMM1

  SUBPD XMM0, XMM1   

  ; Scale both results by 1/sqrt(2)
  MULPD XMM2, [sqrt2_inv]
  MULPD XMM0, [sqrt2_inv]

  MOVAPD [RDI], XMM2       
  MOVAPD [RDI + 16], XMM0

  RET

_H_basic:
  MOVAPD XMM0, [RDI]       ; xmm0 = [ q[0], q[1] ]
  
  MOVAPD XMM1, XMM0
  MULPD XMM1, [const] ; xmm1 = [ q[0], -q[1] ]
  HADDPD XMM0, XMM1; xmm0 = [ q[0] + q[1], q[0] - q[1] ]
  MULPD XMM0, [sqrt2_inv]
  MOVAPD [RDI], XMM0

  RET


_CNOT:
; checking wheter the control qubit is in the |1> state ([0.0, 1.0])
  MOVAPD XMM0, [RDI]
  CMPPD XMM0, [one_state], 0; testing for equality
  PTEST XMM0, XMM0; if not equal -> XMM0 = 0x0000...
  JZ ret               
  
  MOVAPD XMM1, [RSI]; target qubit
  SHUFPD XMM1, XMM1, 01b
  MOVAPD [RSI], XMM1

ret: RET

_CCNOT:
  ; Load control qubit 1
  MOVAPD XMM0, [RDI]
  CMPPD XMM0, [one_state], 0; testing for equality
  PTEST XMM0, XMM0; if not equal -> XMM0 = 0x0000... 
  JZ retcc

  ; Load control qubit 2
  MOVAPD XMM0, [RSI]
  CMPPD XMM0, [one_state], 0
  PTEST XMM0, XMM0
  JZ retcc

  ; Both control qubits are in |1⟩ state, apply Pauli-X (flip) to qubit 3
  ; Load qubit 3 (target qubit)
  MOVAPD XMM0, [RDX]

  ; Pauli-X gate: swap the values of qubit 3 (target qubit)
  SHUFPD XMM0, XMM0, 01b  

  ; Store the flipped values back to the target qubit memory
  MOVAPD [RDX], XMM0 

retcc:  RET

_CZ:
  ; Load control qubit
  MOVAPD XMM0, [RDI]
  CMPPD XMM0, [one_state], 0; testing for equality
  PTEST XMM0, XMM0; if not equal -> XMM0 = 0x0000...
  JZ retz

  ; Load target qubit - since the control is |1> we apply Pauli Z
  MOVAPD XMM0, [RSI]
  MULPD XMM0, [const]
  MOVAPD [RSI], XMM0

retz:  RET


ZERO:
  ; No change to target qubit if control qubits are not both in |1⟩ state
  RET
