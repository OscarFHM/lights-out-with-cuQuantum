#include "Gaussian_elimination_cpu.h"
#include <iostream>
#include <string>
#include <chrono>
#include <print>
#include <random>
#include <vector>


using std::vector;
using ms = std::chrono::duration<double, std::milli>;
using PrintFn = void(*)(int n, int N, double elapsed, bool ok, bool solEmpty);
// using PrintFn = void(*)(int N, const Eigen::MatrixXi&, const Eigen::VectorXi&, const std::vector<int>&);

void benchmark(int n,  unsigned seed ,PrintFn PRINT);

void print(int n, int N, double elapsed, bool ok, bool solEmpty);
// void print(int N, const Eigen::MatrixXi& A, const Eigen::VectorXi& b, const std::vector<int>& sol);

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
    int N = n * n;
    Eigen::MatrixXi A = buildToggleMatrix(n);

    std::mt19937 rng(seed);
    std::uniform_int_distribution<int> dist(0, 1);

    // Generar puzzle resoluble: presionar botones al azar, calcular estado resultante
    Eigen::VectorXi toggle(N);
    Eigen::VectorXi b(N);
    for (int i = 0; i < N; i++) toggle(i) = dist(rng); // asisgnar los toggles
    //Hacer la multiplicacion b = A*x mod 2
    for (int i = 0; i < N; i++) {
        int s = 0;
        for (int j = 0; j < N; j++) s += A(i, j) * toggle(j);
        b(i) = s % 2;
    }

    auto t0  = std::chrono::high_resolution_clock::now();
    auto sol = solveGF2(A, b);
    auto t1  = std::chrono::high_resolution_clock::now();
    double elapsed = ms(t1 - t0).count();
    bool ok = !sol.empty() && verify(A, b, sol);
    
    PRINT(n, N, elapsed, ok, sol.empty());
    // PRINT(N,A,b,sol);
}

void print(int n, int N, double elapsed, bool ok, bool solEmpty) {
    if(ok) std::println("{}   {:.17}", n, elapsed );
}

// void print(int n, int N, double elapsed, bool ok, bool solEmpty) {
//     std::print("Grid {:2}×{:2}  N={:4}  Tiempo: %{:.4f} ms  Solución: {}",
//            n, n, N, elapsed, ok ? "OK" : (solEmpty ? "sin solución" : "ERROR"));
// }

// void print(int N, const Eigen::MatrixXi& A, const Eigen::VectorXi& b, const std::vector<int>& sol) {
//     for (int rr = 0; rr < N; rr++) {
//         for (int cc = 0; cc < N; cc++)
//             std::print("{:2}", A(rr, cc));
//         std::println();
//     }
//     std::println("b = ");
//     for (int rr = 0; rr < N; rr++) std::print("{} ", b(rr));
//     std::println();
//     std::println("SOLUCION = ");
//     for (int rr = 0; rr < N; rr++) std::print("{} ", sol[rr]);
//     std::println();
// }



