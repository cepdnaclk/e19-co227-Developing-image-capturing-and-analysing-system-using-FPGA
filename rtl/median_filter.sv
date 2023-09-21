`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 09/17/2023 03:30:32 PM
// Design Name: salt_and_pepper_noise_filter
// Module Name: median_filter
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices:  Altera Terasic
// Tool Versions: 
// Description: This module is used for get fine edges in the image
// 
// Dependencies: No dependencies
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module median_filter #(
        parameter   R_I = 16, C_I = 16, W_I = 8,
                    R_K = 8, C_K = 8,

        localparam  VECTOR_SIZE = C_K * R_K,
                    LEVEL = $clog2(VECTOR_SIZE),
                    DEPTH = $clog2(VECTOR_SIZE) * ($clog2(VECTOR_SIZE)+1) / 2
    )(
        input logic clk, cen,
        input logic unsigned [R_I-1:0][C_K-1:0][W_I-1:0] img,
        output logic unsigned [R_I-1:0][C_K-1:0][W_I-1:0] final_img
    );

    localparam LEAVES = 2**DEPTH;
    logic signed [W_I-1:0] tree [R_I][C_I][DEPTH+1][LEAVES];

    genvar r_i,r_k,c_i,c_k,d,a,i,k;

    for(r_i=0;r_i<R_I;r_i++)begin
		for(c_i=0;c_i<C_I;c_i++)begin					  
			for(r_k=-(R_K-1)/2;r_k<=(R_K-1)/2;r_k++)begin
				for(c_k=-(C_K-1)/2;c_k<=(C_K-1)/2;c_k++)begin
					always_ff @(posedge clk)begin
						if(cen) begin
							if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)		
								tree [r_i][c_i][0][(r_k+(R_K-1)/2)*C_K + (c_k+(C_K-1)/2)] <= (img[r_i+r_k][c_i+c_k]);
							else
								tree [r_i][c_i][0][(r_k+(R_K-1)/2)*C_K + (c_k+(C_K-1)/2)] <= '0;
						end
					end					
				end
			end		

			for(i=C_K*R_K; i<LEAVES; i++)begin			  
				always_ff @(posedge clk)begin
					if(cen) tree [r_i][c_i][0][i] <= '0;
				end
			end

            for(d=0;d<LEVEL;d++)begin
                for(a=0;a<LEVEL/(2**(d+1));a++)begin
                    for(k=0;k<=d;k++)begin
                        for(i=0;i<2**d;i++)begin
                            always_ff @(posedge clk)begin
                                if(cen) begin
                                    if(a%2=0)begin
                                        if(tree [r_i][c_i][d*(d+1)/2+k][a] > tree[r_i][c_i][d*(d+1)/2+k][])begin
                                            
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            assign final_img[r_i][c_i] = tree [r_i][c_i][DEPTH][0];

        end
    end
        

endmodule