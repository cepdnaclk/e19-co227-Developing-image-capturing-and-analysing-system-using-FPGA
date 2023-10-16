`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/06/2023 02:34:51 PM
// Design Name: salt_and _pepper_noise_filter
// Module Name: axis_salt_and_pepper_filter.v
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: testbench for axis_salt_and_pepper_filter.v
// 
// Dependencies: axis_salt_and_pepper_filter.v
// 
// Additional Comments: written in system verilog
// 
//////////////////////////////////////////////////////////////////////////////////

class Random_Signal_Salt_And_Pepper;                                  //random class to generate random slave valid and master ready signals
    rand bit [7:0] signal;
endclass

class Random_Data_Salt_And_Pepper #(R_I=5, C_I=5, W_I=8);            //random class to generate random image data
    rand bit [R_I-1:0][C_I-1:0][W_I-1:0] data;
endclass

module axis_salt_and_pepper_filter_tb;

    parameter   R_I=5, C_I=5, W_I=8, R_K=3, C_K=3;                  //image dimensions

    localparam  DEPTH_AVERAGING = $clog2(R_K*C_K),                  //depth of the addition tree in averaging filter
                LATENCY_AVERAGING = DEPTH_AVERAGING + 1,            //latency of averaging filter
                LEVEL_MEDIAN = $clog2(R_K*C_K),                     //levls in bitonic sort grid in median filter
                DEPTH_MEDIAN = LEVEL_MEDIAN * (LEVEL_MEDIAN + 1)/2, //depth of the bitonic sort grid in median filter
                LATENCY_MEDIAN = DEPTH_MEDIAN + 1,                  //latency of the median filter
                LATENCY = LATENCY_AVERAGING + LATENCY_MEDIAN,       //latency of the axis salt and pepper filter

                W_F = W_I + $clog2(R_K*C_K),                        //width of the holding value in addition tree for averaging filter verification

                CLK_PERIOD = 10, NUM_EXP = 3;                       //clock period, number of experiments

    logic       clk = 0, rstn = 0;                                  //clock and reset initiated

    initial forever
        #(CLK_PERIOD/2) clk <= ~clk;                                //clock generation

    logic [R_I-1:0][C_I-1:0][W_I-1:0] s_axis_salt_and_pepper_data, m_axis_salt_and_pepper_data, final_img_exp, intmd_img_exp;
    //slave data, master data, final expected data and intermediate data
    logic s_axis_salt_and_pepper_valid = 0, m_axis_salt_and_pepper_ready;   //slave valid and master ready signals
    logic s_axis_salt_and_pepper_ready, m_axis_salt_and_pepper_valid;       //slave ready and master valid signals

    bit done, s_valid_done;                                         //done => when master ready happens after slave valid

    logic [W_F-1 : 0] val;                                          // holding value in addition for averaging filter verification

    logic unsigned [C_K*R_K-1:0][W_I-1:0] sort_vector;              //sorting vector for median filter verification
    logic unsigned [W_I-1:0] temp;                                  //tempory

    axis_salt_and_pepper_filter #(.R_I(R_I), .C_I(C_I), .W_I(W_I), .R_K(R_K), .C_K(C_K)) dut(.*);   //axis_salt_and_pepper_filter module imported

    Random_Data_Salt_And_Pepper #(.R_I(R_I), .C_I(C_I), .W_I(W_I)) S_data = new();              // random slave data class object initiated

    Random_Signal_Salt_And_Pepper S_valid = new(), M_ready = new();   //random slave valid signal and master ready class objects initiated
    
    initial begin

        $dumpfile("dump.vcd");
        $dumpvars;

        repeat(NUM_EXP) begin

            S_data.randomize();                                      //slave data randomized
            done <= 0; s_valid_done <= 0;                            //done and s_valid_done set to 0s

            @(posedge clk); #1 rstn <= 0;                            //reset before the process

            #(CLK_PERIOD);

            @(posedge clk); #1 rstn <= 1;           

            s_axis_salt_and_pepper_data <= S_data.data;

            while(!done)begin
                S_valid.randomize();                                //slave valid and master ready signals are randomized
                M_ready.randomize();
                #1 s_axis_salt_and_pepper_valid <= (S_valid.signal < 'd26);     //slave valid and master ready signals occur in 26/128 probability
                #(CLK_PERIOD * LATENCY);
                m_axis_salt_and_pepper_ready <= (M_ready.signal < 'd26);

                if(S_valid.signal < 'd26)                           //make sure master ready happen after latency time period occuring slave valid
                    s_valid_done <= 1;

                done <= s_valid_done && m_axis_salt_and_pepper_ready;
                #(CLK_PERIOD);
            end

            #(CLK_PERIOD * (LATENCY-1));

            for(int r_i=0; r_i<R_I; r_i++)begin			//calculating the expected output resulted to see whether output from rtl is same
                for(int c_i=0; c_i<C_I; c_i++)begin
                    val = 0;
                    for(int r_k=-(R_K-1)/2; r_k<=(R_K-1)/2; r_k++)begin
                        for(int c_k=-(C_K-1)/2; c_k<=(C_K-1)/2; c_k++)begin
                            if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)
                                val = val + s_axis_salt_and_pepper_data[r_i+r_k][c_i+c_k];
                        end
                    end
                    intmd_img_exp[r_i][c_i] = val/(C_K*R_K);      //expected output image
                end
            end

            for(int r_i=0; r_i<R_I; r_i++)begin			//filling the data to sorting vector
                for(int c_i=0; c_i<C_I; c_i++)begin
                    for(int r_k=-(R_K-1)/2; r_k<=(R_K-1)/2; r_k++)begin
                        for(int c_k=-(C_K-1)/2; c_k<=(C_K-1)/2; c_k++)begin
                            if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)
                                sort_vector[(r_k+(R_K-1)/2)*C_K+(c_k+(C_K-1)/2)] = intmd_img_exp[r_i+r_k][c_i+c_k];
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

            assert (m_axis_salt_and_pepper_data == final_img_exp)				//checking whether expected image and the output image is same
                $display("Output matched: %d", m_axis_salt_and_pepper_data);
            else
                $error("Output doesnt match. final_img:%d != final_img_exp:%d", m_axis_salt_and_pepper_data, final_img_exp);  
                
            s_axis_salt_and_pepper_data <= 'x;
        
        end

        $finish();

    end

endmodule