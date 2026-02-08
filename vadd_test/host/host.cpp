#include <iostream>
#include <vector>
#include <string>

// XRT includes
#include "xrt/xrt_device.h"
#include "xrt/xrt_kernel.h"
#include "xrt/xrt_bo.h"

#define DATA_SIZE 4096

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cout << "Usage: " << argv[0] << " <xclbin>" << std::endl;
        return EXIT_FAILURE;
    }

    std::string xclbin_file = argv[1];
    int device_index = 0;

    std::cout << "Open the device " << device_index << std::endl;
    auto device = xrt::device(device_index);

    std::cout << "Load the xclbin " << xclbin_file << std::endl;
    auto uuid = device.load_xclbin(xclbin_file);

    std::cout << "Get the kernel" << std::endl;
    auto krnl = xrt::kernel(device, uuid, "vadd_pl");

    std::cout << "Allocate Buffer in Global Memory" << std::endl;
    size_t size_in_bytes = sizeof(unsigned int) * DATA_SIZE;
    auto bo_in = xrt::bo(device, size_in_bytes, krnl.group_id(0));
    auto bo_out = xrt::bo(device, size_in_bytes, krnl.group_id(1));

    // Map the contents of the buffer object into host memory
    auto bo_in_map = bo_in.map<unsigned int*>();
    auto bo_out_map = bo_out.map<unsigned int*>();

    // Create the test data
    for (int i = 0; i < DATA_SIZE; i++) {
        bo_in_map[i] = i;
        bo_out_map[i] = 0;
    }

    // Synchronize buffer content from host memory to device memory
    std::cout << "Synchronize input buffer to device memory" << std::endl;
    bo_in.sync(XCL_BO_SYNC_BO_TO_DEVICE);

    std::cout << "Execution of the kernel" << std::endl;
    auto run = krnl(bo_in, bo_out, DATA_SIZE);
    run.wait();

    // Synchronize buffer content from device memory to host memory
    std::cout << "Synchronize output buffer to host memory" << std::endl;
    bo_out.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

    // Validate our results
    int match = 0;
    for (int i = 0; i < DATA_SIZE; i++) {
        unsigned int expected = i + 1; // Kernel adds CONST_OFFSET = 1
        if (bo_out_map[i] != expected) {
            std::cout << "Error: Result mismatch at index " << i << ": expected " << expected << ", got " << bo_out_map[i] << std::endl;
            match = 1;
            break;
        }
    }

    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;

    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
