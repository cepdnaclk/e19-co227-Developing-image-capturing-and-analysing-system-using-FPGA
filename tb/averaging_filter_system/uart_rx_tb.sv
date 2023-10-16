`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/12/2023 07:43:34 PM
// Design Name: averaging_filter_system
// Module Name: uart_rx_tb.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: This is the testbench for the uart_rx.sv
// 
// Dependencies: uart_rx.sv
// 
// Additional Comments: testbench for the uart_rx.sv
//                      Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

class Random_Data_UART_RX #(NUM_WORDS = 5, BITS_PER_WORD = 5);                             // random class to generate random data
    rand bit [NUM_WORDS-1:0][BITS_PER_WORD-1:0] data;   
endclass

module uart_rx_tb;

    localparam CLOCKS_PER_PULSE = 4,                                                       // clock rate / baud rate                                  
               R_I = 7, C_I = 7, W_I = 8,                                                  // dimensions of the image data
               BITS_PER_WORD = 8,                                                          // number of bits in a word
               W_OUT = R_I*C_I*W_I,                                                        // word out
               NUM_WORDS = W_OUT/BITS_PER_WORD,                                            // number of words
               CLK_PERIOD = 10;                                                            // clock period, 1ns

    logic clk=0, rstn=0, rx=1, m_valid;                                                    // set clock = 0, rest neg = 0, rx = 1
    logic [NUM_WORDS-1:0][BITS_PER_WORD-1:0] m_data, data;                                 // m_data for output, data for macking transferrable padded packets
    logic [BITS_PER_WORD+2-1:0] packet;                                                    // transferrable padded packets

    initial forever #(CLK_PERIOD/2) clk <= !clk;                                           // clock generation

    uart_rx #(                                                                             // initiating uart_rx module
        .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE),                                               
        .BITS_PER_WORD(BITS_PER_WORD),
        .R_I(R_I),
        .C_I(C_I),
        .W_I(W_I)
    )dut(.*);

    Random_Data_UART_RX #(.NUM_WORDS(NUM_WORDS),.BITS_PER_WORD(BITS_PER_WORD)) Uart_data = new();   // creating object from the random data generating class


    // driver
    initial begin                                                                         
        $dumpfile("dump.vcd"); $dumpvars;
        repeat(2) @(posedge clk) #1;
        rstn = 1;                                                                          // reset 
        repeat(5) @(posedge clk) #1;

        repeat(10) begin

            Uart_data.randomize();                                                         // randomize input data

            data <= Uart_data.data;

            #1;

            for(int iw=0; iw<NUM_WORDS; iw=iw+1)begin                                     // for each word
                packet = {1'b1, data[iw], 1'b0};                                          // padding the transferrable data packet

                repeat ($urandom_range(1,20)) @(posedge clk);                             // random delay

                for(int ib=0; ib<BITS_PER_WORD+2; ib=ib+1)                                // for each bit in a packet
                    repeat(CLOCKS_PER_PULSE) begin                                        // for every clock per bit
                        #1 rx <= packet[ib];                                              // transfer bit to rx
                        @(posedge clk);
                    end
            end
            repeat ($urandom_range(1,100)) @(posedge clk);                                // random delay
        end
        $finish();
    end

    //monitor
    initial forever @(posedge clk)                                                       // checking for every clock
        if(m_valid)                                                                      // if master valid signal comes
            assert (m_data == data) $display("OK, %b", m_data);                          // check whether master data is equal to the data
        else $error("Sent %b, got %b", data, m_data);                                    

    //bits counter
    int bits;
    initial forever begin
        bits = 0;
        wait(!rx);                                                                       // wait until the start bit logic 0
        for (int n=0; n<BITS_PER_WORD+2; n++)begin                                       // count every bit in a word
            bits = bits+1;
            repeat (CLOCKS_PER_PULSE) @(posedge clk);
        end
    end
    
endmodule