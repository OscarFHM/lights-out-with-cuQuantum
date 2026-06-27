#include "Gaussian_elimination_gpu.cuh"
#include <cuda_runtime.h>
#include <cstdint>
#include <vector>

using std::vector;

// ---------------------------------------------------------------------------
// Kernel: XOR condicional de filas – paraleliza la eliminación gaussiana
// Cada hilo corresponde a una fila; si el bit pivote está activo, hace XOR
// con la fila pivote.
// ---------------------------------------------------------------------------
__global__ void xorRowsKernel(uint32_t* mat, int nRows, int nWords,
                               int pivotRow, int pivotWordIdx, uint32_t pivotMask) {
    int row = blockIdx.x * blockDim.x + threadIdx.x;  // cada hilo es una fila
    if (row >= nRows || row == pivotRow) return;       // ignorar fila pivote
    if (!(mat[row * nWords + pivotWordIdx] & pivotMask)) return; // bit pivote = 0, nada que hacer
    for (int w = 0; w < nWords; w++)                   // XOR palabra a palabra (32 cols por instrucción)
        mat[row * nWords + w] ^= mat[pivotRow * nWords + w];
}

// ---------------------------------------------------------------------------
// Construcción de la matriz aumentada [A|b] empaquetada en uint32_t
// ---------------------------------------------------------------------------
vector<uint32_t> buildAugmented(int n, const vector<int>& b) {
    int N      = n * n;
    int nCols  = N + 1;               // N columnas de A + 1 columna de b
    int nWords = (nCols + 31) / 32;   // palabras uint32_t por fila (ceil)
    vector<uint32_t> mat(N * nWords, 0);

    auto writeBit = [&](int row, int COL) {
        mat[row * nWords + COL / 32] |= (1u << (COL % 32));
    };

    for (int rr = 0; rr < n; rr++) {
        for (int cc = 0; cc < n; cc++) {
            int k = rr * n + cc;
            writeBit(k, k);
            if (rr > 0)   writeBit(k, k - n); // casilla arriba
            if (rr < n-1) writeBit(k, k + n); // casilla abajo
            if (cc > 0)   writeBit(k, k - 1); // casilla izquierda
            if (cc < n-1) writeBit(k, k + 1); // casilla derecha
            if (b[k]) writeBit(k, N);          
        }
    }
    return mat;
}

// ---------------------------------------------------------------------------
// Eliminación gaussiana GF(2): pivoteo en CPU, eliminación de filas en GPU
// ---------------------------------------------------------------------------
vector<int> solveGF2_GPU(int n, const vector<int>& b) {
    int N      = n * n;
    int nWords = (N + 1 + 31) / 32;

    auto Augmented = buildAugmented(n, b);

    uint32_t* d_mat; // puntero a la vRAM
    cudaMalloc(&d_mat, N * nWords * sizeof(uint32_t)); // se aparta memoria vRAM del tamaño de la matriz aumentada
    cudaMemcpy(d_mat, Augmented.data(), N * nWords * sizeof(uint32_t),
               cudaMemcpyHostToDevice);    // se pasa memoria del host a la GPU

    vector<int>      pivotCol(N, -1);
    vector<uint32_t> rowBuf(nWords);
    int ROW = 0;

    for (int COL = 0; (COL < N) && (ROW < N); COL++) {
        // Buscar pivote: leer filas de GPU a CPU hasta encontrar un 1
        int pivot = -1;
        for (int r = ROW; r < N; r++) {
            cudaMemcpy(rowBuf.data(), d_mat + r * nWords,
                       nWords * sizeof(uint32_t), cudaMemcpyDeviceToHost);      // se hace una copia de la vRAM al host
            if (rowBuf[COL / 32] & (1u << (COL % 32))) { pivot = r; break; }    // se hace una operacion bit a bit para escoger la fila pivote
        }
        if (pivot == -1) continue;

        // Intercambiar filas pivote y ROW en GPU
        if (pivot != ROW) {
            vector<uint32_t> tmp(nWords), tmp2(nWords);
            cudaMemcpy(tmp.data(),  d_mat + ROW   * nWords,
                       nWords * sizeof(uint32_t), cudaMemcpyDeviceToHost);
            cudaMemcpy(tmp2.data(), d_mat + pivot * nWords,
                       nWords * sizeof(uint32_t), cudaMemcpyDeviceToHost);
            cudaMemcpy(d_mat + ROW   * nWords, tmp2.data(),
                       nWords * sizeof(uint32_t), cudaMemcpyHostToDevice);
            cudaMemcpy(d_mat + pivot * nWords, tmp.data(),
                       nWords * sizeof(uint32_t), cudaMemcpyHostToDevice);
        }

        pivotCol[ROW] = COL;
        //---------------------------------------------------------------------
        // Eliminar columna en paralelo (GPU)
        //---------------------------------------------------------------------
        int      threads      = 256;    //numero de threads
        int      blocks       = (N + threads - 1) / threads;    //numero de bloques
        int      pivotWordIdx = COL / 32;       // palabra en donde esta la columna
        uint32_t pivotMask    = 1u << (COL % 32);
        xorRowsKernel <<<blocks, threads>>> (d_mat, N, nWords, ROW, pivotWordIdx, pivotMask);
        cudaDeviceSynchronize();
        ROW++;
    }

    cudaMemcpy(Augmented.data(), d_mat, N * nWords * sizeof(uint32_t),
               cudaMemcpyDeviceToHost);
    cudaFree(d_mat);

    // Extraer solución de la forma escalonada reducida
    vector<int> x(N, 0);
    for (int r = 0; r < N; r++) {
        if (pivotCol[r] == -1) {
            if (Augmented[r * nWords + N / 32] & (1u << (N % 32))) return {};
            continue;
        }
        x[pivotCol[r]] = (Augmented[r * nWords + N / 32] >> (N % 32)) & 1;
    }
    return x;
}

// ---------------------------------------------------------------------------
// Verificación: A*x mod 2 == b
// ---------------------------------------------------------------------------
bool verify(int n, const vector<int>& b, const vector<int>& x) {
    int N      = n * n;
    int nWords = (N + 1 + 31) / 32;
    auto A = buildAugmented(n, vector<int>(N, 0));
    for (int i = 0; i < N; i++) {
        int s = 0;
        for (int j = 0; j < N; j++) {
            if (A[i * nWords + j / 32] & (1u << (j % 32))) s ^= x[j];
        }
        if (s != b[i]) return false;
    }
    return true;
}
