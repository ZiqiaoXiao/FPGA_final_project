`timescale 1ns / 1ps

module breakout_fsm(
    input clk,
    input reset_btn,    
    input start_btn, 
    input game_over_signal, 
    input game_won_signal,  
    
    output reg [1:0] state, 
    output reg game_reset,  
    output reg win_latch
);

    localparam S_START = 2'b00;
    localparam S_GAME  = 2'b01;
    localparam S_END   = 2'b10;

    reg [1:0] next_state;

    initial begin
        state = S_START;
        win_latch = 0;
    end
     
    always @(posedge clk) begin
        if (reset_btn) begin
            state <= S_START;
            win_latch <= 0;
        end 
        else begin
            state <= next_state;
            if (game_won_signal)
                win_latch <= 1;
            if (state == S_START) 
                win_latch <= 0;
        end
    end

    always @(*) begin
        next_state = state;
        game_reset = 1'b0; 

        case (state)
            S_START: begin
                game_reset = 1'b1; 
                if (start_btn) begin
                    next_state = S_GAME;
                end
            end

            S_GAME: begin
                game_reset = 1'b0; 
                if (game_over_signal || win_latch) begin
                    next_state = S_END;
                end
            end

            S_END: begin
                game_reset = 1'b0; 
                if (start_btn) begin
                    next_state = S_START; 
                end
            end
            
            default: next_state = S_START;
        endcase
    end
endmodule