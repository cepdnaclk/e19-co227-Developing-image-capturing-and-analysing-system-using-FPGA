`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/15/2023 11:11:16 PM
// Design Name: median_filter_system
// Module Name: axis_salt_and_pepper_uart_system_tb.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: This is the testbench for the axis_salt_and_pepper_uart_system.v
// 
// Dependencies: axis_median_filter_uart_system.v
// 
// Additional Comments: testbench for the axis_median_filter_uart_system.v
//                      Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

class Random_Data_SNPUART #(R_I=7, C_I=7, W_I=8);                              // random class to generate random images 
    rand bit [R_I-1:0][C_I-1:0][W_I-1:0] data;
endclass

module axis_median_filter_uart_system_tb;

    parameter  R_I = 7, C_I = 7, W_I = 8, R_K = 3, C_K = 3,                   // image dimensions and kernel dimensions
               CLOCKS_PER_PULSE = 4,                                          // clock speed of FPGA/ baud rate
               BITS_PER_WORD = 8;

    localparam  W_F = W_I + $clog2(R_K*C_K),                                  //width of the holding value in addition tree for averaging filter verification

                CLK_PERIOD = 10, NUM_EXP = 3,                                 //clock period, number of experiments
                W_OUT = R_I*C_I*W_I,                                          // size of the word out
                NUM_WORDS = W_OUT/BITS_PER_WORD,                              // number of words in the word out
                PACKET_SIZE = BITS_PER_WORD + 5;                              // size of a single packet

    logic   clk = 0, rstn = 0, rx = 1, tx;                                    
    logic   [R_I-1:0][C_I-1:0][W_I-1:0] img_data, final_img_exp; 
    logic   [NUM_WORDS-1:0][BITS_PER_WORD-1:0] img_data_word_form, rx_data;
    logic   [BITS_PER_WORD+2-1:0] packet;
    logic   [BITS_PER_WORD-1:0] rx_word;

    logic [W_F-1 : 0] val;                                                   

    logic unsigned [C_K*R_K-1:0][W_I-1:0] sort_vector;                       
    logic unsigned [W_I-1:0] temp;

    initial forever                                                           //clock generation
        #(CLK_PERIOD/2) clk <= ~clk;

    axis_median_filter_uart_system #(                                       //import axis_salt_and_pepper_uart_system.v
                .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE),
                .BITS_PER_WORD(BITS_PER_WORD),
                .R_I(R_I),
                .C_I(C_I),
                .W_I(W_I),
                .R_K(R_K),
                .C_K(C_K)
    )dut(.*);

    Random_Data_SNPUART #(.R_I(R_I),.C_I(C_I),.W_I(W_I)) Snpuart_data = new();  //create object from the random data generation class

    //driver and expected output generator
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        repeat(2) @(posedge clk) #1;
        rstn = 1;
        repeat(5) @(posedge clk) #1;

        repeat(10) begin
            Snpuart_data.randomize();
            img_data <= Snpuart_data.data;
            @(posedge clk);
            img_data_word_form <= img_data;
            #1;

            for(int iw=0; iw<NUM_WORDS; iw=iw+1)begin                          // for each word
                packet = {1'b1, img_data_word_form[iw], 1'b0};                 // padding the transferrable data packet

                repeat($urandom_range(1,20)) @(posedge clk);

                for(int ib=0; ib<BITS_PER_WORD+2; ib=ib+1)                     //sending the packet bit by bit
                    repeat(CLOCKS_PER_PULSE) begin                             // for every clock per bit
                        #1 rx <= packet[ib];                                   // transfer bit to rx
                        @(posedge clk);
                    end
            end

            #(CLK_PERIOD);

            for(int r_i=0; r_i<R_I; r_i++)begin			                //filling the data to sorting vector
                for(int c_i=0; c_i<C_I; c_i++)begin
                    for(int r_k=-(R_K-1)/2; r_k<=(R_K-1)/2; r_k++)begin
                        for(int c_k=-(C_K-1)/2; c_k<=(C_K-1)/2; c_k++)begin
                            if(r_i+r_k>=0 && r_i+r_k<R_I && c_i+c_k>=0 && c_i+c_k<C_I)
                                sort_vector[(r_k+(R_K-1)/2)*C_K+(c_k+(C_K-1)/2)] = img_data[r_i+r_k][c_i+c_k];
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

            repeat ($urandom_range(1,100)) @(posedge clk);                      // random delay

        end

        $finish();
    end

    //monitor
    initial forever begin

        rx_data <= 'x;

        for(int iw=0; iw<NUM_WORDS; iw=iw+1)begin                               // for each word
            wait(!tx);                                                          // wait until tx set to 0

            repeat(CLOCKS_PER_PULSE/2) @(posedge clk);                          // go to the middle of the start bit pulse logic 0

            for(int ib=0; ib<BITS_PER_WORD; ib=ib+1)begin                       // for each bit in the word
                repeat (CLOCKS_PER_PULSE) @(posedge clk);                       // pulse after pulse
                rx_word[ib] = tx;                                               // extracting bit by bit from the word
            end
            rx_data[iw] = rx_word;                                              // fill word by word

            for(int ib=0; ib<PACKET_SIZE-BITS_PER_WORD-1; ib=ib+1)begin         //checking whether last bits are 1s 
                repeat(CLOCKS_PER_PULSE) @(posedge clk);
                assert (tx==1) else $error("Incorrect end bits");
            end
        end

        assert (rx_data == final_img_exp)				                        //checking whether expected image and the output image is same
                $display("Output matched: %d", rx_data);
            else
                $error("Output doesnt match. final_img:%d != final_img_exp:%d", rx_data, final_img_exp);
    end

endmodule