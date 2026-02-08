# Makefile for XRT Native Host Application (Cross-Compilation)

# Check if environment is sourced
ifeq ($(SYSROOT),)
$(error SYSROOT is not set. Please source the Petalinux environment setup script first)
endif

# Host compiler
CXX := $(GCC)

# Host sources
HOST_SRC := host.cpp
HOST_EXE := host_app

# Include and Lib paths
INCLUDES := -I$(SYSROOT)/usr/include/xrt -I$(SYSROOT)/usr/include
LIBS := -L$(SYSROOT)/usr/lib -lxrt_coreutil -pthread

# Compiler flags
CXXFLAGS := -Wall -O3 -std=c++17 --sysroot=$(SYSROOT) $(INCLUDES)

.PHONY: all clean

all: $(HOST_EXE)

$(HOST_EXE): $(HOST_SRC)
	$(CXX) $(CXXFLAGS) $(HOST_SRC) -o $(HOST_EXE) $(LIBS)

clean:
	rm -f $(HOST_EXE)
