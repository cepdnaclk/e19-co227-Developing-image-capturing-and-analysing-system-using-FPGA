`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/06/2023 12:21:49 PM
// Design Name: salt_and _pepper_noise_filter
// Module Name: axis_salt_and_pepper_filter.v
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Wraps the axis averaging filter and the axis median filter and makes a module
//              following AXI Stream protocol
// 
// Dependencies: axis_averaging_filter.v, axis_median_filter.v
// 
// Additional Comments: This is written in Old Verilog to avoid multi dimensional torques
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_salt_and_pepper_filter #(

    parameter R_I=5, C_I=5, W_I=8, R_K=3, C_K=3)(                       //image dimensions

    input                       clk, rstn,                              //clock and reset                          
    output                      s_axis_salt_and_pepper_ready,           //slave ready
    input                       s_axis_salt_and_pepper_valid,           //slave valid
    input [R_I*C_I*W_I -1:0]    s_axis_salt_and_pepper_data,            //slave data
    input                       m_axis_salt_and_pepper_ready,           //master ready
    output                      m_axis_salt_and_pepper_valid,           //master valid
    output [R_I*C_I*W_I -1:0]   m_axis_salt_and_pepper_data             //master data
);

    wire                        i_valid;                                //intermediate valid signal
    wire                        i_ready;                                //intermediate ready signal
    wire [R_I*C_I*W_I -1:0]       i_data;                               //intermediate data

    axis_averaging_filter #(.R_I(R_I),                                  //import axis_averaging_filter
                            .C_I(C_I),
                            .W_I(W_I),
                            .R_K(R_K),
                            .C_K(C_K))
    AXIS_AVERAGING_FILTER(
        .clk(clk),
        .rstn(rstn),
        .s_axis_averaging_ready(s_axis_salt_and_pepper_ready),
        .s_axis_averaging_valid(s_axis_salt_and_pepper_valid),
        .s_axis_averaging_data(s_axis_salt_and_pepper_data),
        .m_axis_averaging_ready(i_ready),
        .m_axis_averaging_valid(i_valid),
        .m_axis_averaging_data(i_data)
    );

    axis_median_filter #(.R_I(R_I),                                     //import axis_median_filter
                            .C_I(C_I),
                            .W_I(W_I),
                            .R_K(R_K),
                            .C_K(C_K))
    AXIS_MEDIAN_FILTER(
        .clk(clk),
        .rstn(rstn),
        .s_axis_median_ready(i_ready),
        .s_axis_median_valid(i_valid),
        .s_axis_median_data(i_data),
        .m_axis_median_ready(m_axis_salt_and_pepper_ready),
        .m_axis_median_valid(m_axis_salt_and_pepper_valid),
        .m_axis_median_data(m_axis_salt_and_pepper_data)
    );

endmodule