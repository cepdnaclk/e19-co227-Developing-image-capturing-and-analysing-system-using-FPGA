`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 09/29/2023 07:42:16 PM
// Design Name: averaging_filter_system
// Module Name: axis_averaging_filter.v
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Wraps the averaging filter and the skid buffer and makes a module
//              following AXI Stream protocol
// 
// Dependencies: skid_buffer.sv, averaging_filter.sv
// 
// Additional Comments: This is written in Old Verilog to avoid multi dimensional torques
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_averaging_filter #(
    parameter R_I=5, C_I=5, W_I=8, R_K=3, C_K=3,                    // specifying the image dimensions and kernel dimensions
              DEPTH = $clog2(R_K*C_K),                              // Depth of the addition tree
              LATENCY = DEPTH + 1)(                                 // Latency of the filter to give the output

    input                       clk, rstn,                          // clock and reset signals
    output                      s_axis_averaging_ready,             // slave ready
    input                       s_axis_averaging_valid,             // slave valid
    input  [R_I*C_I*W_I-1:0]    s_axis_averaging_data,              // slave data
    input                       m_axis_averaging_ready,             // master ready
    output                      m_axis_averaging_valid,             // master valid
    output [R_I*C_I*W_I-1:0]    m_axis_averaging_data               // master data
);  

    wire [R_I*C_I*W_I-1:0] i_data;                                  // intermediate data wire for skid buffer
    wire i_ready;                                                   // intermediate ready signal from skid buffer

    averaging_filter #(.R_I(R_I),                                   // import averaging_filter module
                       .C_I(C_I), 
                       .W_I(W_I), 
                       .R_K(R_K), 
                       .C_K(C_K))
    AVERAGING_FILTER(
        .clk(clk),
        .cen(i_ready), 
        .img(s_axis_averaging_data), 
        .final_img(i_data)
    );

    reg [LATENCY-2:0] shift;                                        // shifter is used to make the input valid signal late
    reg i_valid;                                                    // intermediate valid signal goes to skid buffer from shifter

    always @(posedge clk or negedge rstn) begin                     // latening process
        if (!rstn) {i_valid, shift} <= 0;                           
        else if(i_ready) {i_valid, shift} <= {shift, s_axis_averaging_valid};       // slave valid => shift => intermediate valid
    end
    


    skid_buffer #(.WIDTH(R_I*C_I*W_I)                               // importing skid_buffer module
    )                             
    SKID(
        .clk    (clk), .rstn(rstn),
        .s_ready(i_ready),
        .s_valid(i_valid),
        .s_data (i_data),
        .m_ready(m_axis_averaging_ready),
        .m_valid(m_axis_averaging_valid),
        .m_data (m_axis_averaging_data)
    );

    assign s_axis_averaging_ready = i_ready;                       // assign intermediate ready signal from buffer to slave ready signal of the whole system

endmodule