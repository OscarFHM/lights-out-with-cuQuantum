CXX    = g++
NVCC   = nvcc
EIGEN  = /usr/include/eigen3

CXXFLAGS  = -O2 -std=c++23 -I$(EIGEN)
NVCCFLAGS = -O2 -std=c++23

CPU_SRC = Gaussian_elimination_cpu.cpp lights_out_cpu.cpp
GPU_SRC = Gaussian_elimination_gpu.cu  lights_out_gpu.cu

.PHONY: all cpu gpu clean

all: cpu gpu

cpu: lights_out_cpu

gpu: lights_out_gpu

lights_out_cpu: $(CPU_SRC) Gaussian_elimination_cpu.h
	$(CXX) $(CXXFLAGS) $(CPU_SRC) -o $@

lights_out_gpu: $(GPU_SRC) Gaussian_elimination_gpu.cuh
	$(NVCC) $(NVCCFLAGS) $(GPU_SRC) -o $@

clean:
	rm -f lights_out_cpu lights_out_gpu
