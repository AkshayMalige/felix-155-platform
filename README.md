# Felix-155 Platform Generation

This project provides the infrastructure to generate a custom XPFM platform for the Versal XCVP1552 FPGA.

## Base Platform
The hardware XSA for this platform is defined by the `base_platform/top_hw_hwemu.xsa` file.

## Linux Image Generation
To build the Linux components, navigate to the `versal_linux` directory and run:
```bash
./build_versal_linux.sh -n my_foe_flx -x ../base_platform/top_hw_hwemu.xsa
```

## Software Components
After building Linux, the resulting files are organized in the `versal_linux/my_foe_flx/sw` folder.

## Platform Generation (XPFM)
To generate the final `.xpfm` platform file, use the provided Python script with Vitis:
```bash
vitis -s generate_platform.py
```

## Usage
Once the XPFM is generated, you can build applications, such as a `vadd` template project, targeting this platform.



#include <stdint.h>
#include <hls_stream.h>

#define DATA_SIZE 4096
#define CONST_OFFSET 1  // The constant value to add

// TRIPCOUNT identifier
const int c_size = DATA_SIZE;

// Function 1: Read Memory -> Stream
static void read_input(unsigned int* in, hls::stream<unsigned int>& inStream, int size) {
mem_rd:
    for (int i = 0; i < size; i++) {
#pragma HLS LOOP_TRIPCOUNT min = c_size max = c_size
        inStream << in[i];
    }
}

// Function 2: Stream -> Add Constant -> Stream
static void compute_add(hls::stream<unsigned int>& inStream,
                        hls::stream<unsigned int>& outStream,
                        int size) {
execute:
    for (int i = 0; i < size; i++) {
#pragma HLS LOOP_TRIPCOUNT min = c_size max = c_size
        unsigned int val = inStream.read();
        outStream << (val + CONST_OFFSET);
    }
}

// Function 3: Stream -> Write Memory
static void write_result(unsigned int* out, hls::stream<unsigned int>& outStream, int size) {
mem_wr:
    for (int i = 0; i < size; i++) {
#pragma HLS LOOP_TRIPCOUNT min = c_size max = c_size
        out[i] = outStream.read();
    }
}

extern "C" {
/*
    Simplified VADD: Read -> Add Offset -> Write
    Arguments:
        in   (input)  --> Input Vector
        out  (output) --> Output Vector
        size (input)  --> Size of Vector
*/
void vadd(unsigned int* in, unsigned int* out, int size) {
    // Define internal streams
    static hls::stream<unsigned int> inStream("input_stream");
    static hls::stream<unsigned int> outStream("output_stream");
    
    // Stream depth pragmas (optional but good practice for dataflow)
    #pragma HLS STREAM variable=inStream depth=32
    #pragma HLS STREAM variable=outStream depth=32

    // AXI Master Interfaces (Data)
    // Mapping both to gmem0. You can separate them (e.g., out to gmem1) if you have multiple banks.
    #pragma HLS INTERFACE m_axi port = in bundle = gmem0
    #pragma HLS INTERFACE m_axi port = out bundle = gmem0

    // AXI Lite Interfaces (Control) - REQUIRED for Vitis/XRT
    #pragma HLS INTERFACE s_axilite port = in bundle = control
    #pragma HLS INTERFACE s_axilite port = out bundle = control
    #pragma HLS INTERFACE s_axilite port = size bundle = control
    #pragma HLS INTERFACE s_axilite port = return bundle = control

    #pragma HLS dataflow
    read_input(in, inStream, size);
    compute_add(inStream, outStream, size);
    write_result(out, outStream, size);
}
}