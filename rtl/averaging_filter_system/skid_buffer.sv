`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Department of Computer Engineering, University of Peradeniya
// Engineer: Mahela Ekanayake, Chaminda Weerasinghe
// 
// Create Date: 09/29/2023 02:33:42 PM
// Design Name: averaging_filter_system
// Module Name: skid_buffer.sv
// Project Name: IMAGE_CAPTURING_AND_ANALYSING_SYSTEM_USING_FPGA
// Target Devices:  Altera Terasic DE2-115
// Tool Versions: Verification - Vivado 2019.2
// Description: act as a buffer in order to hold the latency in filter modules
// 
// Dependencies: none
// 
// Additional Comments: Written in System Verilog
// 
//////////////////////////////////////////////////////////////////////////////////

module skid_buffer #( parameter WIDTH = 8)(                 //specifying the width of the input and output channels
    input logic clk, rstn, s_valid, m_ready,                //clock signal, reset, slave valid and master ready initiated (input)
    input logic [WIDTH-1:0] s_data,                         //slave data channel (input)
    output logic [WIDTH-1:0] m_data,                        //master data channel output (input)
    output logic m_valid, s_ready                           //master valid and slave ready (output)
);
    enum {FULL, EMPTY} state, state_next;                   //states of the skid buffer

    always_comb begin                                       //multiplexer for switching next state
        state_next = state;                                 //In other cases, next state is the current state
        case (state)                                        
        EMPTY : if(!m_ready && s_ready && s_valid) state_next = FULL;       //But if current state is EMPTY and slave is not ready to accept data (m_ready = 0), but master is
                                                                            //ready to give data (s_valid = 1) and module is ready to accept data (s_ready = 1), set the next state to FULL to avoid overloading
        FULL : if(m_ready) state_next = EMPTY;                              //in FULL state, when slave is ready to accept data (m_ready = 1), set next state to EMPTY
        endcase                                                             
    end

    always_ff @(posedge clk)
        if (!rstn) state <= EMPTY;                              // Set the state to EMPTY when reset
        else if (m_ready || s_ready) state <= state_next;       // else set to next state in every other clock edge
        
    logic b_valid;                                              // input valid signal for buffer
    logic [WIDTH-1:0] b_data;                                   // buffer input data channel
    wire [WIDTH-1:0] m_data_next = (state == FULL) ? b_data : s_data;       // multiplexer for next master data, if state is FULL, choose buffer data, other wise slave data
    wire m_valid_next = (state == FULL) ? b_valid : s_valid;                // multiplexer for next master enable, with same conditions for master next data
    wire buffer_en = (state_next == FULL) && (state==EMPTY);                // buffer is enable to store data if next state is full but, current state is empty
    wire m_en = m_valid_next & m_ready;                                     // enable to send master data if master ready data is enabled and master next valid signal is empty.

    always_ff @(posedge clk or negedge rstn)                    
        if (!rstn) begin                                        // when reset
            s_ready <= 1;                                       // when reset, ready to accept data from master
            {m_valid, b_valid} <= '0;                           // valid signal from master set to LOW, valid signal from buffer set to LOW
        end else begin                                          // in every other case
            s_ready <= state_next == EMPTY;                     // if next state is empty, be ready to accept data from master
            if (buffer_en) b_valid <= s_valid;                  // if buffer is enabled to store data, valid signal from buffer set to valid signal come from master
            if (m_ready ) m_valid <= m_valid_next;              // if the slave is ready to accept data, set output data valid signal to m_valid_next
        end

    always_ff @(posedge clk) begin
        if (m_en) m_data <= m_data_next;                        // enable to send master data
        if (buffer_en && s_valid) b_data <= s_data;             // if buffer is enabled to store data and valid signal from master comes, store data come from master in buffer
    end

endmodule