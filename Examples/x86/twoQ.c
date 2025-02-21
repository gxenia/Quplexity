#include <stdio.h>
#include <xmmintrin.h>
#include <math.h>

extern void _PX(double *qubit);
extern void _PY(double *qubit);
extern void _PZ(double *qubit);
extern void _H(double *qubit);
extern void _CNOT(double *tensor);
extern void _CCNOT(double *q1, double *q2, double *q3);
extern void _CZ(double *qc, double *qt);

static inline double* init(double ar, double ai, double br, double bi) {
    double* q = _mm_malloc(4 * sizeof(double), 16);
    q[0] = ar;  // alpha real
    q[1] = ai;  // alpha imag
    q[2] = br;  // beta real
    q[3] = bi;  // beta imag
    return q;
}

void print_qubit(const char* label, double* q) {
    printf("%s: %lf + %lfi, %lf + %lfi\n", label, q[0], q[1], q[2], q[3]);
}

double* tensor_product(double* q1, double* q2) {
    double* q = _mm_malloc(8 * sizeof(double), 16);
    q[0] = q1[0]*q2[0] - q1[1]*q2[1];
    q[1] = q1[0]*q2[1] + q1[1]*q2[0];
    q[2] = q1[0]*q2[2] - q1[1]*q2[3];
    q[3] = q1[0]*q2[3] + q1[1]*q2[2];
    q[4] = q1[2]*q2[0] - q1[3]*q2[1];
    q[5] = q1[2]*q2[1] + q1[3]*q2[0];
    q[6] = q1[2]*q2[2] - q1[3]*q2[3];
    q[7] = q1[2]*q2[3] + q1[3]*q2[2];
    return q;
}

void print2qubits(const char* label, double* q) {
    printf("%s: %lf + %lfi, %lf + %lfi, %lf + %lfi, %lf + %lfi\n", label, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]);
}

int main() {
    double* q1 = init(1.0, 0.0, 0.0, 0.0); // |0⟩ state
    _H(q1);
    print_qubit("Qubit1: ", q1);

    double* q2 = init(1.0, 0.0, 0.0, 0.0); // |0> state
    
    double* q = tensor_product(q1, q2);
    print2qubits("Before CNOT: ", q);
    _CNOT(q);
    print2qubits("After CNOT: ", q);

    return 0;
}

