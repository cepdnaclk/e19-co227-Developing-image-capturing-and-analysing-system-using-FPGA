`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 09/17/2023 03:30:32 PM
// Design Name: salt_and_pepper_noise_filter
// Module Name: median_filter.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: This module is used for get fine edges in the image using median filter
// 
// Dependencies: No dependencies
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

module median_filter #(
        parameter   R_I = 16, C_I = 16, W_I = 8,		//Image size
                    R_K = 3, C_K = 3,					//Kernel size

        localparam  VECTOR_SIZE = C_K * R_K,			//Size of the vector to put kernel data
                    LEVEL = $clog2(VECTOR_SIZE),		//levels of bitonic sort
                    DEPTH = LEVEL * (LEVEL+1) / 2		//depth of the bitonic sort tree
    )(
        input logic clk, cen,							//clock and clock enable
        input logic unsigned [R_I-1:0][C_I-1:0][W_I-1:0] img,				//input image
        output logic unsigned [R_I-1:0][C_I-1:0][W_I-1:0] final_img			//output filtered image
    );

    localparam LEAVES = 2**LEVEL;											//number of leaves in the bitonic sort tree
    logic signed [W_I-1:0] tree [R_I][C_I][DEPTH+1][LEAVES];				//bitonic sort tree

    genvar r_i,r_k,c_i,c_k,l,a,i,j,k;

    for(r_i=0;r_i<R_I;r_i++)begin											
		for(c_i=0;c_i<C_I;c_i++)begin					  					//for each leave in the tree
			for(r_k=-(R_K-1)/2;r_k<=(R_K-1)/2;r_k++)begin
				for(c_k=-(C_K-1)/2;c_k<=(C_K-1)/2;c_k++)begin
					always_ff @(posedge clk)begin
						if(cen) begin
							if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)				// input kernel data to leaves
								tree [r_i][c_i][0][(r_k+(R_K-1)/2)*C_K + (c_k+(C_K-1)/2)] <= (img[r_i+r_k][c_i+c_k]);
							else
								tree [r_i][c_i][0][(r_k+(R_K-1)/2)*C_K + (c_k+(C_K-1)/2)] <= '0;
						end
					end					
				end
			end		

			for(i=VECTOR_SIZE; i<LEAVES; i++)begin							// padding rest of the leaves in the tree  
				always_ff @(posedge clk)begin
					if(cen) tree [r_i][c_i][0][i] <= '0;
				end
			end

            for(l=0;l<LEVEL;l++)begin									   // parallel bitonic sort
				for(a=0;a<LEAVES/(2**(l+1));a++)begin
					for(i=0;i<=l;i++)begin
			 			for(j=0;j<2**i;j++)begin
			 				for(k=0;k<(2**(l-i));k++)begin
			 					always_ff @(posedge clk)begin
			 						if(cen) begin
										if(($unsigned(tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))])<$unsigned(tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))+(2**(l-i))])) && !(a%2) || ($unsigned(tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))])>$unsigned(tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))+(2**(l-i))])) && a%2)begin
											tree[r_i][c_i][l*(l+1)/2+i+1][k+j*(2**(l-i+1))+a*(2**(l+1))] <= tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))+(2**(l-i))];
											tree[r_i][c_i][l*(l+1)/2+i+1][k+j*(2**(l-i+1))+a*(2**(l+1))+(2**(l-i))] <= tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))];
										end
										else begin
											tree[r_i][c_i][l*(l+1)/2+i+1][k+j*(2**(l-i+1))+a*(2**(l+1))] <= tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))];
											tree[r_i][c_i][l*(l+1)/2+i+1][k+j*(2**(l-i+1))+a*(2**(l+1))+(2**(l-i))] <= tree[r_i][c_i][l*(l+1)/2+i][k+j*(2**(l-i+1))+a*(2**(l+1))+(2**(l-i))];
										end
			 						end
			 					end
			 				end
			 			end
			 		end
			    end
			end

            assign final_img[r_i][c_i] = tree [r_i][c_i][DEPTH][(VECTOR_SIZE+1)/2-1];		//obtain the final median value

        end
    end
endmodule