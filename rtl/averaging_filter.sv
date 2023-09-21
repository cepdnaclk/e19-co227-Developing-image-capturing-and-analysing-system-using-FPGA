`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 09/17/2023 11:15:46 AM
// Design Name: salt_and_pepper_noise_filter
// Module Name: averaging_filter
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices:  Altera Terrasic
// Tool Versions: 
// Description: This module is used for bluring the image by using the averaging filter
// 
// Dependencies: No dependencies
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module averaging_filter #(
       parameter    R_I = 16, C_I = 16, W_I = 8,   //dimensions of input image which is padded
                    R_K = 3 , C_K = 3 , W_K = 8,   //dimentsions of the kernel
       localparam   DEPTH = $clog2(R_K * C_K),     //depth of the adding tree
                    W_F = W_I + W_K + DEPTH        // pixel size of the output image
    )(
        input  logic clk, cen,                     // clock and clock enable
        input  logic unsigned [R_I-1:0][C_I-1:0][W_I-1:0] img,            // input image
        output logic unsigned [R_I-1:0][C_I-1:0][W_I-1:0] final_img       // output image
    );
    
  	
    localparam LEAVES = 2**DEPTH;					  // number of leaves in the adding tree
    logic unsigned [W_F-1:0] tree [R_I][C_I][DEPTH+1][LEAVES];		  // adding tree declared
    logic unsigned [R_K-1:0][C_K-1:0][W_K-1:0] kernel;			  // averaging filter kernel declared

    
    genvar r_i,r_k,c_i,c_k,d,a,i;

    for(r_k=0; r_k<R_K; r_k++)begin					  // initialize the kernel
		for(c_k=0; c_k<C_K; c_k++)begin
			assign kernel[r_k][c_k] = 8'd1; 
		end
    end

    for(r_i=0;r_i<R_I;r_i++)begin
		for(c_i=0;c_i<C_I;c_i++)begin					  // for each pixel in the image
			for(r_k=-(R_K-1)/2;r_k<=(R_K-1)/2;r_k++)begin
				for(c_k=-(C_K-1)/2;c_k<=(C_K-1)/2;c_k++)begin
					always_ff @(posedge clk)begin
						if(cen) begin
							if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)		//filling the leaves of adding tree
								tree [r_i][c_i][0][(r_k+(R_K-1)/2)*C_K + (c_k+(C_K-1)/2)] <= (kernel[r_k+(R_K-1)/2][c_k+(C_K-1)/2]) * (img[r_i+r_k][c_i+c_k]);
							else
								tree [r_i][c_i][0][(r_k+(R_K-1)/2)*C_K + (c_k+(C_K-1)/2)] <= '0;
						end
					end					
				end
			end		 

			for(i=C_K*R_K; i<LEAVES; i++)begin			  // padding the addition tree leaves with zeros
				always_ff @(posedge clk)begin
					if(cen) tree [r_i][c_i][0][i] <= '0;
				end
			end

			for (d=0; d<DEPTH; d=d+1) begin				 // adding the addition tree in each level
				for (a=0; a<LEAVES/2**(d+1); a=a+1)begin
					always_ff @(posedge clk)begin
						if (cen) tree [r_i][c_i][d+1][a] <= tree [r_i][c_i][d][2*a] + tree [r_i][c_i][d][2*a+1];
					end
				end
			end
			assign final_img[r_i][c_i] = tree [r_i][c_i][DEPTH][0]/(C_K*R_K);	// final output cell

			
		end
    end
    
endmodule

