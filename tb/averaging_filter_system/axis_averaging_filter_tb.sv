`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/02/2023 07:40:09 PM
// Design Name: averaging_filter_system
// Module Name: axis_averaging_filter_tb.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: Testbench for axis_averaging_filter.v
// 
// Dependencies: axis_averaging_filter.v
// 
// Additional Comments: testbench to test axis_averaging_filter.v
//                      Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

class Random_Signal_Averaging;                                                    // random class for generating random numbers between 0-127
    rand bit [7:0] signal;
endclass

class Random_Data_Averaging #(R_I=5, C_I=5, W_I=8);                              // random class to generate random images 
    rand bit [R_I-1:0][C_I-1:0][W_I-1:0] data;
endclass

module axis_averaging_filter_tb;

    parameter R_I=5, C_I=5, W_I=8, R_K=3, C_K=3;                                    // Image dimensions and kernel dimensions

    localparam CLK_PERIOD = 10, NUM_EXP = 3, LATENCY = $clog2(R_K*C_K) + 1,         // clock period, number of experiments to do and latency
               W_F= W_I + $clog2(R_K*C_K);                                          // dimension of holding value
    logic      clk=0, rstn=0;                                                       // clock and reset

    initial forever 
        #(CLK_PERIOD/2) clk <= ~clk;                                  // clock generation

    
    logic [R_I-1:0][C_I-1:0][W_I-1:0] s_axis_averaging_data, m_axis_averaging_data, final_img_exp;      // slave data, master data and expected final image
    logic s_axis_averaging_valid = 0, m_axis_averaging_ready;                                           // slave valid, master ready (inputs)
    logic s_axis_averaging_ready, m_axis_averaging_valid;                                               // slave ready and master valid (outputs)
    


    bit done, s_valid_done;                                         // to verify whether master ready and slave valid has occured
                                                                    // done when master ready is 1 after slave_valid_done is 1
                                                                    // s_valid_done when slave valid is 1
    logic [W_F-1:0] val;                                            // holding value for averaging filter

    axis_averaging_filter #(.R_I(R_I), .C_I(C_I), .W_I(W_I), .R_K(R_K), .C_K(C_K)) dut(.*);             // import axis_averaging_filter

    Random_Signal_Averaging S_valid = new(), M_ready = new();                 // create objects for slave valid and master ready for random values

    Random_Data_Averaging #(.R_I(R_I), .C_I(C_I), .W_I(W_I))  S_data = new();                                     // create and object for random image generation

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars;

        repeat(NUM_EXP)begin

            S_data.randomize();                                     // randomization
            done <= 0; s_valid_done <= 0;                           // initializing at the begining of the experiment

            @(posedge clk); #1 rstn <= 0;                           // reset

            #(CLK_PERIOD);

            @(posedge clk); #1 rstn <= 1;

            s_axis_averaging_data <= S_data.data;                   // input randomized image data

            while(!done)begin
                S_valid.randomize();                               // randomize signals
                M_ready.randomize();
                #1 s_axis_averaging_valid <= (S_valid.signal < 'd26);       // signal with a probability of 26/128
                #(CLK_PERIOD * LATENCY);                                    
                m_axis_averaging_ready <= (M_ready.signal < 'd26);          //master ready = 1 after latency period of time spent after slave valid = 1

                if(S_valid.signal < 'd26)                          // make sure slave valid happen before master ready
                    s_valid_done <= 1;

                done <= s_valid_done && m_axis_averaging_ready;
                #(CLK_PERIOD);
            end

            #(CLK_PERIOD * (LATENCY-1));

            for(int r_i=0; r_i<R_I; r_i++)begin			//calculating the expected output resulted to see whether output from rtl is same
                for(int c_i=0; c_i<C_I; c_i++)begin
                    val = 0;
                    for(int r_k=-(R_K-1)/2; r_k<=(R_K-1)/2; r_k++)begin
                        for(int c_k=-(C_K-1)/2; c_k<=(C_K-1)/2; c_k++)begin
                            if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)
                                val = val + s_axis_averaging_data[r_i+r_k][c_i+c_k];
                        end
                    end
                    final_img_exp[r_i][c_i] = val/(C_K*R_K);      //expected output image
                end
            end

            assert (m_axis_averaging_data == final_img_exp)				//checking whether expected image and the output image is same
                $display("Output matched: %d", m_axis_averaging_data);
            else
                $error("Output doesnt match. final_img:%d != final_img_exp:%d", m_axis_averaging_data, final_img_exp);  

            s_axis_averaging_data <= 'x;
        end

        $finish();

    end

endmodule