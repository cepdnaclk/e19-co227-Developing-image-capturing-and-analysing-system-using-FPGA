`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/12/2023 10:39:25 AM
// Design Name: median_filter_system
// Module Name: uart_rx.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: recieving of UART serial data and convert it into AXI Stream data
// 
// Dependencies: none
// 
// Additional Comments: Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_rx #(
    parameter   CLOCKS_PER_PULSE = 4,                               // clock speed of FPGA/Baud rate
                BITS_PER_WORD    = 8,                               // number of bits in a word
                R_I = 7, C_I = 7, W_I = 8,                          // dimensions of an input image data
    localparam  W_OUT = R_I*C_I*W_I                                 // dimensions output imgae data
)(
    input logic clk, rstn, rx,                                      // clock, reset and receiver input 
    output logic m_valid,                                           // master valid signal
    output logic [W_OUT-1:0] m_data                                 // master data signal
);
    localparam NUM_WORDS = W_OUT/BITS_PER_WORD;                     // Number of words going to process
    enum {IDLE, START, DATA, END1} state;                           // state of machine

    logic [$clog2(CLOCKS_PER_PULSE)-1:0] c_clocks;                  // number of clocks counter
    logic [$clog2(BITS_PER_WORD)-1:0] c_bits;                       // number of bits counter
    logic [$clog2(NUM_WORDS)-1:0] c_words;                          // number of words counter

    always_ff @(posedge clk or negedge rstn) begin                  // state machine
        if(!rstn) begin
            {c_words, c_bits, c_clocks, m_valid, m_data} <= '0;     // reset words counter, bits counter, clock counter, master valid signal and master data signal
            state <= IDLE;                                          // state set to IDLE at reset
        end else begin                                              // when not reseting
            m_valid <= 0;                                           // master valid signal set to 0
            case (state)                                            // state switching
                IDLE :  if(rx == 0)                                 // 
                            state <= START;                         // switch to START state, at start bit, logic 0
                START : if(c_clocks == CLOCKS_PER_PULSE/2-1) begin  // switching to the middle of the bit
                            state <= DATA;                          // switching to the DATA state
                            c_clocks <= 0;                          // clock count set to 0
                        end else
                            c_clocks <= c_clocks + 1;               // increment clock count at each posedge
                DATA :  if(c_clocks == CLOCKS_PER_PULSE-1)begin     // end of 1 bit
                            c_clocks <= 0;                          // set clock count to 0
                            m_data <= {rx,m_data[W_OUT-1:1]};       // shifting the m_data and insert rx data

                            if(c_bits == BITS_PER_WORD-1)begin      // end of 1 word
                                state <= END1;                      // set state to END1
                                c_bits <= 0;                        // bits count set to 0

                                if(c_words == NUM_WORDS-1)begin     // end of word count
                                    m_valid <= 1;                   // master valid signal on
                                    c_words <= 0;                   // set word count to 0
                                end else c_words <= c_words + 1;    // increment word count
                            end else c_bits <=  c_bits + 1;         // increment bit count
                        end else c_clocks <= c_clocks + 1;          // increment clock count
                END1 :  if(c_clocks == CLOCKS_PER_PULSE-1)begin     // end of the clock count until the end bit
                            state <= IDLE;                          // state set to IDLE back
                            c_clocks <= 0;                          // clock count set to 0
                        end else
                            c_clocks <= c_clocks + 1;               // clock count incremented
            endcase
        end
    end

endmodule
