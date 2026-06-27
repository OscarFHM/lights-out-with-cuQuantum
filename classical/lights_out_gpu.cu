#include "Gaussian_elimination_gpu.cuh"
#include <iostream>
#include <string>
#include <chrono>
#include <print>
#include <random>
#include <vector>

using std::vector;
using ms = std::chrono::duration<double, std::milli>;
using PrintFn = void(*)(int n, int N, double elapsed, bool ok, bool solEmpty);
// using PrintFn = void(*)(int n, int N, const std::vector<uint32_t>& matA,const std::vector<int>& b,std::vector<int>& sol);


void benchmark(int n,  unsigned seed ,PrintFn PRINT);

// void print(int n, int N, double elapsed, bool ok, bool solEmpty);
void print(int N,int nWords, const std::vector<uint32_t>& matA,const std::vector<int>& b,std::vector<int>& sol);

int main(int argc,char* argv []) {
    if (argc < 3) {
        std::println("Faltan parametros");
        return 1;
    }
    int n = std::stoi(argv[1]); 
    int m = std::stoi(argv[2]);
    if (n <= 0 || m<= 0) {
        std::println("valores incorrectos");
        return 1;
    }
    // std::println("-----------------Lights Out {}X{}-----------------",n,n);
    for (int ii=0;ii<m;ii++) 
        benchmark(n, 42u + static_cast<unsigned>(ii)+static_cast<unsigned>(n), print);
    
    return 0;
}

void benchmark(int n,  unsigned seed ,PrintFn PRINT) {
    int N      = n * n;
    int nWords = (N + 1 + 31) / 32;
    std::mt19937 rng(seed);
    std::uniform_int_distribution<int> dist(0, 1);

    // Generar puzzle resoluble: presses aleatorios → b = A * presses mod 2
    vector<int> presses(N), b(N, 0);
    for (int i = 0; i < N; i++) presses[i] = dist(rng);

    auto tmpA = buildAugmented(n, vector<int>(N, 0));
    for (int i = 0; i < N; i++) {
        int s = 0;
        for (int j = 0; j < N; j++) {
            if (tmpA[i * nWords + j / 32] & (1u << (j % 32))) s ^= presses[j];
        }
        b[i] = s & 1;
    }

    auto t0  = std::chrono::high_resolution_clock::now();
    auto sol = solveGF2_GPU(n, b);
    auto t1  = std::chrono::high_resolution_clock::now();
    double elapsed = ms(t1 - t0).count();
    bool ok = !sol.empty() && verify(n, b, sol);

    PRINT(n, N, elapsed, ok, sol.empty());
    // PRINT(N,nWords,tmpA,b,sol);
}

void print(int n, int N, double elapsed, bool ok, bool solEmpty) {
    if(ok) std::println("{}   {:.17}", n, elapsed );
}

// void print(int n, int N, double elapsed, bool ok, bool solEmpty) {
//     std::print("Grid {:2}×{:2}  N={:4}  Tiempo: %{:.4f} ms  Solución: {}\n",
//            n, n, N, elapsed, ok ? "OK" : (solEmpty ? "sin solución" : "ERROR"));
// }

// void print(int N,int nWords, const std::vector<uint32_t>& matA,const std::vector<int>& b,std::vector<int>& sol) {
//     // -------- imprimir matriz A-------------------
//     for (int rr  = 0;rr < N; rr++){
//         for (int cc  = 0;cc < N; cc++){
//             int bit = (matA[rr * nWords + cc / 32] >> (cc % 32)) & 1u;
//             std::print("{:2}",bit);
//         }
//         std::println();
//     }
//     std::println("b = ");
//     for (int rr = 0; rr < N; rr++) std::print("{} ", b[rr]);
//     std::println("SOLUCION = ");

//     for (int rr = 0; rr < N; rr++) std::print("{} ", sol[rr]);
// }

