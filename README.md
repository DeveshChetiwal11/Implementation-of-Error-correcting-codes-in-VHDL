# Error Correction Codes in VHDL
This repository contains the VHDL implementations of various error-correction codes, including Hamming Code, Hadamard Code, and Reed-Solomon Code, developed as part of my project. The project is focused on designing, simulating, and performing hardware implementations of these codes on FPGA boards to improve data integrity and error detection/correction in communication systems.

# Project Overview
Error-correction codes are essential in digital communication to ensure the reliability of data transmitted over noisy channels. This project involves the design and hardware implementation of multiple error-correction schemes using VHDL. Each code provides different levels of error correction and detection, making them suitable for various applications.

The project is divided into the following key tasks:

VHDL Implementation: Development of encoders and decoders for each error-correction code using VHDL.
Hardware Implementation: Synthesis and implementation of these designs on FPGA boards to validate their functionality in practical environments.
Features
Hamming Code

Encoder: Generates codewords containing n bits, where k are data bits and n-k are parity bits.
Decoder: Capable of single-bit error correction and two-bit error detection, using a simple parity-based correction mechanism.
Hardware Tested: Successfully implemented and tested on FPGA boards.
Hadamard Code

Encoder: Produces codewords of n bits, consisting of k message bits and n-k parity bits.
Decoder: Provides error correction for up to (n−1)/2 bits, leveraging the properties of Hadamard matrices.
Hardware Tested: Implemented and verified on FPGA hardware.
Reed-Solomon Code

Encoder: Generates n-symbol codewords from k data symbols, with n-k parity symbols for correcting burst errors.
Decoder: Corrects up to (n−k)/2 symbol errors, making it effective for correcting multiple-bit errors.
Hardware Tested: Successfully implemented and validated on FPGA boards.

# Tools & Technologies
VHDL: Used for designing the encoders and decoders.
Intel Quartus: FPGA design tools for simulation, synthesis, and hardware implementation.
FPGA Boards: Implementation was tested on FPGA development boards like the DE10-Lite.
