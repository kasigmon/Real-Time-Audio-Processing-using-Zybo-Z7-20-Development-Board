# Real-Time Audio Processing using Zybo Z7-20 Development Board
_Kirk A. Sigmon - kirk.a.sigmon.th@dartmouth.edu_

![master diagram](https://github.com/kasigmon/fpga-lab-901/blob/main/figures/master_schematic.JPG?raw=true)

This repository contains a Digital Signal Processing ("DSP") circuit, implemented via the Zybo Z7-20 Field Programmable Gate Array ("FPGA") development board and using VHSIC Hardware Description Language ("VHDL") and C, that enables selective filtering of input audio data received through a first 3.5 mm audio jack and using a low pass, high pass, band pass, or band stop filter and output of that same data through a second 3.5 mm audio jack.  

**Full details regarding the design of this project, including project objectives, paper designs, RTL schematics, and testing results are detailed in [the report ENGG_463_FPGA_Lab_901_Write_Up.pdf](https://github.com/kasigmon/fpga-lab-901/blob/main/ENGG_463_FPGA_Lab_901_Write_Up.pdf).**

## Included Material

All content for this project is organized in different folders:

* The **VHDL code, AMD Vivado block diagram, Zybo Z7-20 constraints file, and hardware (including bitstream)** are available in the [/vhdl_src/](https://github.com/kasigmon/fpga-lab-901/tree/main/vhdl_src) folder.
* Testbenches for evaluating the performance of the code and block diagram are available in the [/vhdl_src/testbenches/](https://github.com/kasigmon/fpga-lab-901/tree/main/vhdl_src/testbenches) folder.
* The **C code** used for implementation using the AMD Vitis software development platform is available in the [/c_src/](https://github.com/kasigmon/fpga-lab-901/tree/main/c_src) folder.
* **Information usable to test the circuit using a Digilent Analog Discovery 3 oscilloscope** using the Waveforms application is in the [/wavegen_materials/](https://github.com/kasigmon/fpga-lab-901/tree/main/wavegen_materials) folder.

## Installation Instructions

**Instructions for Creation of Vivado Project (Optional)**
1. Instantiate a new Vivado project and import all VHD files in /vhdl_src/ as design sources and the .xdc file in /vhdl_src/.
2. Import the block design by unzipping and importing the files in blockdesign.zip.
3. Generate a wrapper for the block design and set it as the top file in the hierarchy.
4. Generate a bitstream (including running linter, running synthesis, and running the implementation).
5. Export the hardware (including the bitstream) from Vivado.

**Instructions for Execution on Zybo Z7-20 Development Board using Vitis**
1. In Vitis, instantiate new hardware using design_1_wrapper.xsa from the [/vhdl_src/](https://github.com/kasigmon/fpga-lab-901/tree/main/vhdl_src) folder.
2. Build the hardware.
3. Instantiate a new software application and import all C code from the [/c_src/](https://github.com/kasigmon/fpga-lab-901/tree/main/c_src) folder.
4. Build the software.
5. Use the "Run As -> Launch Hardware" function in Vitis.

