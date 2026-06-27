#pragma once
#include <cstdint>
#include <vector>

std::vector<uint32_t> buildAugmented(int n, const std::vector<int>& b);
std::vector<int>      solveGF2_GPU(int n, const std::vector<int>& b);
bool                  verify(int n, const std::vector<int>& b, const std::vector<int>& x);
