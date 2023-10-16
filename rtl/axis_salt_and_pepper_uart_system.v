`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/15/2023 04:01:39 AM
// Design Name: salt_and _pepper_noise_filter
// Module Name: axis_salt_and_pepper_uart_system.v
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Wraps the axis_salt_and_pepper_filter and uart rx and tx transmission modules
// 
// Dependencies: axis_salt_and_pepper_filter.v, uart_rx.sv, uart_tx.sv
// 
// Additional Comments: This is written in Old Verilog to avoid multi dimensional torques
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_salt_and_pepper_uart_system #(

    parameter R_I=7, C_I=7, W_I=8, R_K=3, C_K=3,                                    // dimensions of input image and kernel
              CLOCKS_PER_PULSE = 4,                                                 // clock speed of FPGA / baud rate
              BITS_PER_WORD    = 8,                                                 // bits per word
              W_OUT = R_I*C_I*W_I,                                                  // total word size processed
              NUM_WORDS = W_OUT/BITS_PER_WORD   )(                                  // number of words

    input     clk, rstn,rx,                                                         // clock, reset, rx
    output    tx                                                                    // tx
);

    wire m_valid,m_ready;                                                           // master valid, ready signals
    wire [W_OUT-1:0] m_data;                                                        // master data 

    wire s_valid,s_ready;                                                           // slave valid signal
    wire [W_OUT-1:0] s_data;                                                        // slave data

    axis_salt_and_pepper_filter #(.R_I(R_I),                                        // import axis_salt_and_pepper_filter.v module
                                  .C_I(C_I),
                                  .W_I(W_I),
                                  .R_K(R_K),
                                  .C_K(C_K))
    AXIS_SALT_AND_PEPPER_FILTER(
        .clk(clk), .rstn(rstn),
        .s_axis_salt_and_pepper_ready(m_ready),
        .s_axis_salt_and_pepper_valid(m_valid),
        .s_axis_salt_and_pepper_data(m_data),
        .m_axis_salt_and_pepper_ready(s_ready),
        .m_axis_salt_and_pepper_valid(s_valid),
        .m_axis_salt_and_pepper_data(s_data)
    );

    uart_rx #(.BITS_PER_WORD(BITS_PER_WORD),                                        // import uart_rx module
              .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE),
              .R_I(R_I),
              .C_I(C_I),
              .W_I(W_I))
    UART_RX (.m_data(m_data),
             .m_valid(m_valid),
             .clk(clk),
             .rstn(rstn),
             .rx(rx));

    uart_tx #(.BITS_PER_WORD(BITS_PER_WORD),                                        // import uart_tx module
              .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE),
              .R_I(R_I),
              .C_I(C_I),
              .W_I(W_I))
    UART_TX (.s_data(s_data),
             .s_valid(s_valid),
             .s_ready(s_ready),
             .clk(clk),
             .rstn(rstn),
             .tx(tx));


endmodule