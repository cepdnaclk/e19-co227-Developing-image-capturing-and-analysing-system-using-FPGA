`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 10/14/2023 10:43:11 PM
// Design Name: salt_and _pepper_noise_filter
// Module Name: uart_tx.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices: Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: convert AXI Stream data to UART tx data and output URAT tx data
// 
// Dependencies: none
// 
// Additional Comments: Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_tx #(

    parameter R_I = 7, C_I = 7, W_I = 8,                            //dimensions of output image data
              CLOCKS_PER_PULSE = 4,                                 // clock rate/baud rate
              BITS_PER_WORD    = 8,                                 // bits per word

    localparam W_OUT = R_I*C_I*W_I,                                 // output word size
               NUM_WORDS = W_OUT/BITS_PER_WORD,                     // number of words
               PACKET_SIZE      = BITS_PER_WORD+5                   // output packet size
)(
    input logic clk, rstn, s_valid,                                 // clock, reset, slave valid signals
    input logic [NUM_WORDS-1:0][BITS_PER_WORD-1:0] s_data,          // slave data (input data)
    output logic tx, s_ready                                        // output tx, slave ready data
);

    localparam END_BITS = PACKET_SIZE-BITS_PER_WORD-1;              // ending bits for padding the output data packet
    logic [NUM_WORDS-1:0][PACKET_SIZE-1:0] s_packets;               // output packet with original dimensions
    logic [NUM_WORDS*PACKET_SIZE-1:0] m_packets;                    // one singal array wich is going to be shifted

    genvar n;

    for(n=0; n<NUM_WORDS; n=n+1)
        assign s_packets[n] = {~(END_BITS'(0)), s_data[n], 1'b0};   // padding the output data packet

    assign tx = m_packets[0];                                       // set the tx as the first of the data shifting array

    logic [$clog2(NUM_WORDS*PACKET_SIZE)-1:0] c_pulses;             // pulse count
    logic [$clog2(CLOCKS_PER_PULSE)     -1:0] c_clocks;             // clock count

    enum {IDLE, SEND} state;                                        // states of the state machine

    always_ff @(posedge clk or negedge rstn) begin                  // state machine

        if(!rstn) begin                                             // reset
            state <= IDLE;                                          // state set to IDLE
            m_packets <= '1;                                        // set all the output data packet to 1s (helps for padding purposes)
            {c_pulses, c_clocks} <= 0;                              // set pulse count and clock count to 0s
        end else
            case (state)                                            // state switching
                IDLE :  if(s_valid) begin                           // if slave valid signal comes
                            state <= SEND;                          // state set to SEND
                            m_packets <= s_packets;                 // output packets converted to transferrable output packets
                        end

                SEND :  if (c_clocks == CLOCKS_PER_PULSE-1) begin   // if clock count reach the CLOCKS_PER_PULSE
                            c_clocks <= 0;                          // set to 0

                            if(c_pulses == NUM_WORDS*PACKET_SIZE-1)begin    // if number of bits reach the full amount
                                c_pulses <= 0;                              // set to 0
                                m_packets <= '1;                            // set m_packets to 1 back
                                state <= IDLE;                              // set state to IDLE
                            end else begin
                                c_pulses <= c_pulses + 1;                   // else keep bit count incrementing
                                m_packets <= (m_packets >> 1);              // keep data packet shifting
                            end
                        end else c_clocks <= c_clocks + 1;                  // increment clock count
            endcase
    end

    assign s_ready = (state == IDLE);                                       // slave ready if state is IDLE
endmodule