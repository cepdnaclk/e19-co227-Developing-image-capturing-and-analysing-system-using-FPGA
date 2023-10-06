`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/05/2023 03:33:28 PM
// Design Name: salt_and _pepper_noise_filter
// Module Name: axis_median_filter.v
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Wraps the median filter and the skid buffer and makes a module
//              following AXI Stream protocol
// 
// Dependencies: skid_buffer.sv, median_filter.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: This is written in Old Verilog to avoid multi dimensional torques
// 
//////////////////////////////////////////////////////////////////////////////////


module axis_median_filter #(
    parameter R_I=5, C_I=5, W_I=8, R_K=3, C_K=3,                    // specifying the image dimensions and kernel dimensions
              LEVEL = $clog2(R_K*C_K),                              
              DEPTH = LEVEL * (LEVEL + 1)/2,                        // Depth of the bitonic sort grid
              LATENCY = DEPTH + 1)(                                 // Latency of the filter to give the output

    input                       clk, rstn,                          // clock and reset signals
    output                      s_axis_median_ready,             // slave ready
    input                       s_axis_median_valid,             // slave valid
    input  [R_I*C_I*W_I-1:0]    s_axis_median_data,              // slave data
    input                       m_axis_median_ready,             // master ready
    output                      m_axis_median_valid,             // master valid
    output [R_I*C_I*W_I-1:0]    m_axis_median_data               // master data
);  

    wire [R_I*C_I*W_I-1:0] i_data;                                  // intermediate data wire for skid buffer
    wire i_ready;                                                   // intermediate ready signal from skid buffer

    median_filter #(.R_I(R_I),                                   // import median_filter module
                       .C_I(C_I), 
                       .W_I(W_I), 
                       .R_K(R_K), 
                       .C_K(C_K))
    MEDIAN_FILTER(
        .clk(clk),
        .cen(i_ready), 
        .img(s_axis_median_data), 
        .final_img(i_data)
    );

    reg [LATENCY-2:0] shift;                                        // shifter is used to make the input valid signal late
    reg i_valid;                                                    // intermediate valid signal goes to skid buffer from shifter

    always @(posedge clk or negedge rstn) begin                     // latening process
        if (!rstn) {i_valid, shift} <= 0;                           
        else if(i_ready) {i_valid, shift} <= {shift, s_axis_median_valid};       // slave valid => shift => intermediate valid
    end
    


    skid_buffer #(.WIDTH(R_I*C_I*W_I)                               // importing skid_buffer module
    )                             
    SKID(
        .clk(clk), .rstn(rstn),
        .s_ready(i_ready),
        .s_valid(i_valid),
        .s_data (i_data),
        .m_ready(m_axis_median_ready),
        .m_valid(m_axis_median_valid),
        .m_data (m_axis_median_data)
    );

    assign s_axis_median_ready = i_ready;                       // assign intermediate ready signal from buffer to slave ready signal of the whole system

endmodule