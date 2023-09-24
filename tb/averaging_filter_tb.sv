`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 09/17/2023 07:40:09 PM
// Design Name: salt_and _pepper_noise_filter
// Module Name: averaging_filter_tb.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices:  Altera Terasic
// Tool Versions: 
// Description: Testbench for averaging_filter.sv
// 
// Dependencies: averaging_filter.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: testbench to test averaging_filter.sv
// 
//////////////////////////////////////////////////////////////////////////////////


module averaging_filter_tb;
    timeunit 1ns/1ps;
    
    localparam R_I = 5, C_I = 5, W_I = 8,			//input image dimensions
               R_K = 3 , C_K = 3 , W_K = 8,			//kernel dimensions
               DEPTH = $clog2(R_K * C_K),     			//depth of the adding tree
               LATENCY = DEPTH + 1,				//latency in adding and multiplications
               CLK_PERIOD = 10,					//clock period
               NUM_DATA = 100,					//number of repetitions of the test bench
	           W_F = W_I + W_K + DEPTH;				//pixel size of a career value
               
    
    typedef logic unsigned [R_I-1:0][C_I-1:0][W_I-1:0] img_t;	//image dimensions
    img_t final_img, final_img_exp, img; 

    logic unsigned [R_K-1:0][C_K-1:0][W_K-1:0] kernel;		//kernel dimensions

    logic unsigned [W_F-1:0] val = '0;				//career value
               
    logic clk=0, cen=1; 					//clock and clock enable
          
    averaging_filter #(.R_I(R_I),.C_I(C_I),.W_I(W_I),
                       .R_K(R_K),.C_K(C_K),.W_K(W_K)) dut(.*);
    
    initial forever #(CLK_PERIOD/2) clk <= ~clk;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0,dut);
        
        repeat (NUM_DATA) begin
            
            @(posedge clk); #1
            
            for(int r_i=0; r_i<R_I; r_i++)begin			//random intensity values for image
                for(int c_i=0; c_i<C_I; c_i++)begin
                    img[r_i][c_i] = $urandom_range(0, 2**W_I-1);
                end
            end

            for(int r_k=0; r_k<R_K; r_k++)begin			//initialize the kernel
                for(int c_k=0; c_k<C_K; c_k++)begin
                    kernel[r_k][c_k] = 8'd1;
                end
            end
                
            for(int r_i=0; r_i<R_I; r_i++)begin			//calculating the expected output resulted to see whether output from rtl is same
                for(int c_i=0; c_i<C_I; c_i++)begin
                    val = 0;
                    for(int r_k=-(R_K-1)/2; r_k<=(R_K-1)/2; r_k++)begin
                        for(int c_k=-(C_K-1)/2; c_k<=(C_K-1)/2; c_k++)begin
                            if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)
                                val = val + img[r_i+r_k][c_i+c_k] * kernel[r_k+(R_K-1)/2][c_k+(C_K-1)/2];
                        end
                    end
                    final_img_exp[r_i][c_i] = val/(C_K*R_K);      //expected output image
                end
            end

            repeat (LATENCY) @(posedge clk); #1				//simulating the latency

            
            assert (final_img == final_img_exp)				//checking whether expected image and the output image is same
                $display("Output matched: %d", final_img);
            else
                $error("Output doesnt match. final_img:%d != final_img_exp:%d", final_img, final_img_exp);
                
            $finish;         
        end
    end


endmodule

