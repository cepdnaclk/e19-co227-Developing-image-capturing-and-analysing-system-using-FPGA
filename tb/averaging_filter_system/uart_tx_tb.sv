`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/14/2023 11:11:16 PM
// Design Name: averaging_filter_system
// Module Name: uart_tx_tb.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: This is the testbench for the uart_tx.sv
// 
// Dependencies: uart_tx.sv
// 
// Additional Comments: testbench for the uart_tx.sv
//                      Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

class Random_Data_UART_TX #(NUM_WORDS = 5, BITS_PER_WORD = 5);                              // random class to generate random output image data
    rand bit [NUM_WORDS-1:0][BITS_PER_WORD-1:0] data;
endclass

module uart_tx_tb;

    localparam  CLOCKS_PER_PULSE = 4,                                                       // clock rate / baud rate
                R_I = 7, C_I = 7, W_I = 8,                                                  // output image dimensions
                W_OUT = R_I*C_I*W_I,                                                        // word out
                BITS_PER_WORD = 8,                                                          // bits per word
                PACKET_SIZE = BITS_PER_WORD + 5,                                            // packet size after padding
                NUM_WORDS = W_OUT/BITS_PER_WORD,                                            // number of words output
                CLK_PERIOD = 10;                                                            // clock period

    logic clk=0, rstn=0, tx, s_valid=0, s_ready;                                            // clock, reset, slave valid set to 0s
    logic [NUM_WORDS-1:0][BITS_PER_WORD-1:0] s_data, rx_data;                               // slave data, extrated from the output data
    logic [BITS_PER_WORD-1:0] rx_word;                                                      // output data word store

    initial forever #(CLK_PERIOD/2) clk <= !clk;                                            // clock generator

    uart_tx #(                                                                              // import uart_tx module
        .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE), .BITS_PER_WORD(BITS_PER_WORD),
        .R_I(R_I), .C_I(C_I), .W_I(W_I)) dut(.*);

    Random_Data_UART_TX #(.NUM_WORDS(NUM_WORDS),.BITS_PER_WORD(BITS_PER_WORD)) Uart_tx_data = new();

    //driver
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        #20 rstn = 1; repeat(5) @(posedge clk) #1;                                          // reset

        repeat(10) begin
            Uart_tx_data.randomize();                                                       // randomize input image data
            repeat($urandom_range(1,20)) @(posedge clk);                                    // random delay
            wait(s_ready);                                                                  // wait until slave ready signal comes

            @(posedge clk) #1 s_data = Uart_tx_data.data; s_valid = 1;                      // set slave valid to 1
            @(posedge clk) #1 s_valid = 0;                                                  // set slave valid to 0
            wait(s_ready);                                                                  // wait until slave ready signal comes
        end
        $finish();
    end
    
    //monitor
    initial forever begin

        rx_data <= 'x;
        
        for(int iw=0; iw<NUM_WORDS; iw=iw+1)begin                                           // for each word

            wait(!tx);                                                                      // wait until tx set to 0

            repeat(CLOCKS_PER_PULSE/2) @(posedge clk);                                      // go to the middle of the start bit pulse logic 0

            for(int ib=0; ib<BITS_PER_WORD; ib=ib+1)begin                                   // for each bit in the word
                repeat (CLOCKS_PER_PULSE) @(posedge clk);                                   // pulse after pulse
                rx_word[ib] = tx;                                                           // extracting bit by bit from the word
            end
            rx_data[iw] = rx_word;                                                          // fill word by word

            for(int ib=0; ib<PACKET_SIZE-BITS_PER_WORD-1; ib=ib+1)begin                     // checking whether ending bits of the word are 1s
                repeat(CLOCKS_PER_PULSE) @(posedge clk);
                assert (tx==1) else $error("Incorrect end bits");
            end
        end

        assert(rx_data == s_data) $display("OK, %b", rx_data);                              // checking whether input data and output data are same
        else $error("Sent %b, got %b", s_data, rx_data);
    end

    int bits;                                                                               // counting total number of bits from packet to packet
    initial forever begin
        bits = 0;
        wait(!tx);
        for(int n=0; n<PACKET_SIZE; n++)begin
            bits += 1;
            repeat (CLOCKS_PER_PULSE) @(posedge clk);
        end
    end

endmodule