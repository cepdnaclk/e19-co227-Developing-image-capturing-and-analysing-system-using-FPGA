`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/05/2023 03:49:39 PM
// Design Name: salt_and _pepper_noise_filter
// Module Name: axis_median_filter_tb.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Testbench for axis_median_filter.v
// 
// Dependencies: axis_median_filter.v
// 
// Additional Comments: testbench to test axis_median_filter.v
//                      Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

class Random_Signal_Median;                                         // random class for generating random numbers between 0-127
    rand bit [7:0] signal;
endclass

class Random_Data_Median #(R_I=5, C_I=5, W_I=8);                    // random class for generating image data
    rand bit [R_I-1:0][C_I-1:0][W_I-1:0] data;
endclass

module axis_median_filter_tb;   

    parameter R_I=5, C_I=5, W_I=8, R_K=3, C_K=3;                     // Image dimensions and kernel dimensions

    localparam CLK_PERIOD = 10, NUM_EXP =3,                         // clock period and number of experiments
               LEVEL = $clog2(R_K*C_K),
               DEPTH = LEVEL * (LEVEL + 1),
               LATENCY = DEPTH + 1;                                 // latency  
    logic      clk = 0, rstn = 0;                                       // clock and reset intiating

    initial forever
        #(CLK_PERIOD/2) clk <= ~clk;                                    // clock generating

    logic [R_I-1:0][C_I-1:0][W_I-1:0] s_axis_median_data, m_axis_median_data, final_img_exp;        // slave data, master data and final expected data busses
    logic s_axis_median_valid = 0, m_axis_median_ready;                 // slave valid and master ready (input)
    logic s_axis_median_ready, m_axis_median_valid;                     // slave ready and master valid (output)

    bit done, s_valid_done;                                             //to verify master ready and slave valid operated well
                                                                        //make sure that master ready = 1 is operated after slave valid = 1
    logic unsigned [C_K*R_K-1:0][W_I-1:0] sort_vector;                  //sorting vector for verification purposes
    logic unsigned [W_I-1:0] temp;                                      //tempory value holder for verification purposes

    Random_Data_Median #(.R_I(R_I), .C_I(C_I), .W_I(W_I)) S_data = new();       //slave data object was created

    Random_Signal_Median S_valid = new(), M_ready = new();                      //slave valid and master ready signal objects were created

    axis_median_filter #(.R_I(R_I), .C_I(C_I), .W_I(W_I), .R_K(R_K), .C_K(C_K)) dut(.*);    //axis_median_filter module was imported

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars;

        repeat(NUM_EXP)begin

            S_data.randomize();                                         //randomize slave data (image data)
            done <= 0; s_valid_done <= 0;                               //initiating done and s_valid_done to 0s

            @(posedge clk); #1 rstn <=0;                                //reset process

            #(CLK_PERIOD);

            @(posedge clk); #1 rstn <= 1;

            s_axis_median_data <= S_data.data;                          //input randomized data 

            while(!done)begin
                S_valid.randomize();                                    //randomize slave valid and master ready signals
                M_ready.randomize();
                #1 s_axis_median_valid <= (S_valid.signal < 'd26);      //slave valid and master ready signals were input in a probabilty of 26/128
                #(CLK_PERIOD * LATENCY);
                m_axis_median_ready <= (M_ready.signal < 'd26);         //master ready = 1 after latency period of time spent after slave valid = 1

                if(S_valid.signal < 'd26)                               //make sure slave valid signal happens first
                    s_valid_done <= 1;

                done <= s_valid_done && m_axis_median_ready;            // done when master ready happen after slave valid
                #(CLK_PERIOD);

            end

            #(CLK_PERIOD * (LATENCY-1));

            for(int r_i=0; r_i<R_I; r_i++)begin			//filling the data to sorting vector
                for(int c_i=0; c_i<C_I; c_i++)begin
                    for(int r_k=-(R_K-1)/2; r_k<=(R_K-1)/2; r_k++)begin
                        for(int c_k=-(C_K-1)/2; c_k<=(C_K-1)/2; c_k++)begin
                            if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)
                                sort_vector[(r_k+(R_K-1)/2)*C_K+(c_k+(C_K-1)/2)] = s_axis_median_data[r_i+r_k][c_i+c_k];
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

            assert (m_axis_median_data == final_img_exp)				//checking whether expected image and the output image is same
                $display("Output matched: %d", m_axis_median_data);
            else
                $error("Output doesnt match. final_img:%d != final_img_exp:%d", m_axis_median_data, final_img_exp);  
                
            s_axis_median_data <= 'x;

        end

        $finish();

    end

endmodule