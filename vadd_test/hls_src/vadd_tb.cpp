#include <iostream>
#include <vector>
#include <cstdlib>

// Must match the value in your kernel source
#define CONST_OFFSET 1
#define TEST_SIZE 4096

// Forward declaration of the top-level kernel function
// Ensure this signature matches your kernel's extern "C" block perfectly
extern "C" void vadd_pl(unsigned int* in, unsigned int* out, int size);

int main() {
    // 1. Setup Data Sizes
    int size = TEST_SIZE;
    std::cout << "Starting Test Bench with size: " << size << std::endl;

    // 2. Allocate Host Memory
    // Using std::vector ensures automatic memory management (no malloc/free leaks)
    std::vector<unsigned int> source_in(size);
    std::vector<unsigned int> source_hw_results(size); // To store HLS output
    std::vector<unsigned int> source_sw_results(size); // To store CPU reference

    // 3. Initialize Input and Compute Software Reference (Golden Data)
    for (int i = 0; i < size; i++) {
        source_in[i] = i; // Assign sample data (0, 1, 2...)
        
        // Calculate the expected result purely in software
        source_sw_results[i] = source_in[i] + CONST_OFFSET;
        
        // Initialize HW results to zero to ensure we are reading fresh data
        source_hw_results[i] = 0;
    }

    // 4. Run the HLS Kernel
    // In C-Simulation, this runs as a normal C function.
    // In Co-Simulation, the HLS tool uses this to drive the RTL.
    vadd_pl(source_in.data(), source_hw_results.data(), size);

    // 5. Verify Results
    int error_count = 0;
    for (int i = 0; i < size; i++) {
        if (source_hw_results[i] != source_sw_results[i]) {
            std::cout << "Error found @ " << i << std::endl;
            std::cout << "  Input: " << source_in[i] << std::endl;
            std::cout << "  Expected (SW): " << source_sw_results[i] << std::endl;
            std::cout << "  Actual (HW):   " << source_hw_results[i] << std::endl;
            error_count++;
            
            // Stop after a few errors to avoid spamming the console
            if (error_count > 10) break; 
        }
    }

    // 6. Report Pass/Fail
    if (error_count == 0) {
        std::cout << "---------------------------------------------" << std::endl;
        std::cout << "TEST PASSED" << std::endl;
        std::cout << "---------------------------------------------" << std::endl;
        return 0; // Return 0 indicates success to the build system
    } else {
        std::cout << "---------------------------------------------" << std::endl;
        std::cout << "TEST FAILED with " << error_count << " errors" << std::endl;
        std::cout << "---------------------------------------------" << std::endl;
        return 1; // Return non-zero indicates failure
    }
}