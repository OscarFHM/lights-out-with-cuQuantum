#include "Gaussian_elimination_cpu.h"
#include <cstdio>
#include <vector>

using std::vector;

// Matriz de toggles A (n² × n²) sobre GF(2)
Eigen::MatrixXi buildToggleMatrix(int n) {
    int N = n * n;
    Eigen::MatrixXi A = Eigen::MatrixXi::Zero(N, N);
    for (int rr = 0; rr < n; rr++) {
        for (int cc = 0; cc < n; cc++) {
            int k = rr * n + cc;
            A(k, k) = 1;  // auto toggle
            if (rr > 0)   A(k, k - n) = 1; //toggle casilla arriba
            if (rr < n-1) A(k, k + n) = 1; //toggle casilla abajo
            if (cc > 0)   A(k, k - 1) = 1; //toggle casilla izquierda
            if (cc < n-1) A(k, k + 1) = 1; //toggle casilla derecha
        }
    }
    return A;
}

// Eliminación gaussiana sobre GF(2) ,resuelve el sistema A*x mod 2 == b
// Devuelve el vector solución (vacío si no hay solución)
vector<int> solveGF2(Eigen::MatrixXi A, Eigen::VectorXi b) {
    int N = A.rows();
    // Matriz aumentada [A | b]
    Eigen::MatrixXi Augmented(N, N + 1);
    Augmented.leftCols(N)  = A;
    Augmented.rightCols(1) = b;

    vector<int> pivotCol(N, -1);
    int row = 0;

    for (int col = 0; (col < N) && (row < N); col++) {
        // Buscar pivote
        int pivot = -1;                       // todavía no existe pivote
        for (int r = row; r < N; r++) {
            if (Augmented(r, col)) { pivot = r; break; }  // primera fila con un 1 en esta columna
        }
        if (pivot == -1) continue;            // ninguna fila tiene 1 -> salto a la siguiente columna

        Augmented.row(row).swap(Augmented.row(pivot));    // cambiar la cfila row con la del pivote
        pivotCol[row] = col;

        // Eliminar columna (arriba y abajo)
        for (int r = 0; r < N; r++) {
            if ((r != row) && Augmented(r, col)) {   // se mira si existe algun uno en alguna otra fila
                for (int j = 0; j <= N; j++)   // se recorre dicha fila
                    Augmented(r, j) ^= Augmented(row, j);  //^= es la poeracion xor,equivalente a la suma en base 2
            }
        }
        row++;
    }

    // Verificar consistencia y extraer solución
    vector<int> xSol(N, 0);
    for (int r = 0; r < N; r++) {
        if (pivotCol[r] == -1) {
            if (Augmented(r, N)) {
                // Sistema inconsistente.
                // Se observa el vector b ,si se llega a una reduccion tipo:
                // 0 0 ... 0 0 | 1 -> 0 = 1 el sistema es inconsistente
                std::printf("SISTEMA INCONSISTENTE ; NO EXISTE SOLUCION.\n");
                return {};
            }else
            {
                continue;
            }
        }
        xSol[pivotCol[r]] = Augmented(r, N);
    }
    return xSol;
}

// Verificar: A*x mod 2 == b
bool verify(const Eigen::MatrixXi& A, const Eigen::VectorXi& b, const vector<int>& x) {
    int N = A.rows();
    for (int ii = 0; ii < N; ii++) {
        int sum = 0;
        for (int jj = 0; jj < N; jj++) sum += A(ii, jj) * x[jj];
        if (sum % 2 != b(ii)) return false;
    }
    return true;
}
