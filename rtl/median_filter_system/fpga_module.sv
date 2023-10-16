`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/16/2023 08:47:26 AM
// Design Name: median_filter_system
// Module Name: fpga_module.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Wraps the axis_median_filter_uart_system.v
// 
// Dependencies: axis_median_filter_uart_system.v
// 
// Additional Comments: Written in SystemVerilog
// 
//////////////////////////////////////////////////////////////////////////////////

module fpga_module(
    input logic clk, rstn, rx,
    output logic tx
);

    axis_median_filter_uart_system #(
        .CLOCKS_PER_PULSE(8680),
        .BITS_PER_WORD(8),
        .R_I(7),.C_I(7),.W_I(8),.R_K(3),.C_K(3)
    )axis_median_filter_uart_system_0 (.*);

endmodule