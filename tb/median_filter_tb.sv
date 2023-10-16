`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 09/17/2023 11:19:16 PM
// Design Name: salt_and _pepper_noise_filter
// Module Name: median_filter_tb.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Testbench for median_filter.sv
// 
// Dependencies: median_filter.sv
// 
// Additional Comments: testbench to test median_filter.sv
//                      written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

module median_filter_tb;
    timeunit 1ns/1ps;

    localparam R_I = 5, C_I = 5, W_I = 8,   //input image dimensions
               R_K = 3, C_K = 3,            //kernel dimensions
               LEVEL = $clog2(R_K*C_K),     //level of filteration
               DEPTH = LEVEL * (LEVEL+1)/2, //depth of image tree
               LATENCY = DEPTH+1,           //latency of filteration
               CLK_PERIOD = 10,             //clock period
               NUM_DATA = 100;                //number of repeatitions

    typedef logic unsigned [R_I-1:0][C_I-1:0][W_I-1:0] img_t;   //image dimensions
    img_t final_img, final_img_exp, img;

    logic unsigned [C_K*R_K-1:0][W_I-1:0] sort_vector = 0;      //vector for sorting values

    logic clk=0, cen=1;                                         //clock and clock enable

    logic unsigned [W_I-1:0] temp;                              // tempary storage of data

    median_filter #(.R_I(R_I),.C_I(C_I),.W_I(W_I),              
                    .R_K(R_K),.C_K(C_K)) dut(.*);

    initial forever #(CLK_PERIOD/2) clk <= ~clk;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0,dut);

        repeat (NUM_DATA) begin

            @(posedge clk); #1

            for(int r_i=0; r_i<R_I; r_i++)begin                 //filling random data to image pixels
                for(int c_i=0; c_i<C_I; c_i++)begin
                    img[r_i][c_i] = $urandom_range(0,2**W_I-1);
                end    
            end

            for(int r_i=0; r_i<R_I; r_i++)begin			//filling the data to sorting vector
                for(int c_i=0; c_i<C_I; c_i++)begin
                    for(int r_k=-(R_K-1)/2; r_k<=(R_K-1)/2; r_k++)begin
                        for(int c_k=-(C_K-1)/2; c_k<=(C_K-1)/2; c_k++)begin
                            if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)
                                sort_vector[(r_k+(R_K-1)/2)*C_K+(c_k+(C_K-1)/2)] = img[r_i+r_k][c_i+c_k];
                            else
                                sort_vector[(r_k+(R_K-1)/2)*C_K+(c_k+(C_K-1)/2)] = 0;
                        end
                    end
                    
                    for(int i=0; i<C_K*R_K; i++)begin                   //sorting and finding the median for finding the expected median
                        for(int j=0; j<C_K*R_K-i-1; j++)begin
                            if(sort_vector[j] > sort_vector[j+1])begin
                                temp = sort_vector[j];
                                sort_vector[j] = sort_vector[j+1];
                                sort_vector[j+1] = temp;
                            end
                        end
                    end

                    final_img_exp[r_i][c_i] = sort_vector[(C_K*R_K+1)/2-1];      //expected output image, median value is mid value
                end
            end

            repeat (LATENCY) @(posedge clk); #1             //latency

            assert (final_img == final_img_exp)				//checking whether expected image and the output image is same
                $display("Output matched: %d", final_img);
            else
                $error("Output doesnt match. final_img:%d != final_img_exp:%d", final_img, final_img_exp);

            $finish();

        end
    end    


endmodule