#pragma once
#include <Eigen/Dense>
#include <vector>

Eigen::MatrixXi buildToggleMatrix(int n);
std::vector<int> solveGF2(Eigen::MatrixXi A, Eigen::VectorXi b);
bool verify(const Eigen::MatrixXi& A, const Eigen::VectorXi& b, const std::vector<int>& x);
