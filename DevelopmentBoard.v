`timescale 1ns / 1ns

module DevelopmentBoard(
    input wire clk,
    input wire reset, B2, B3, B4, B5,
    output wire h_sync, v_sync,
    output wire [15:0] rgb,
    output wire led1, led2, led3, led4, led5
);

    wire [3:0] vgaR, vgaG, vgaB;
    wire [11:0] rgb_12bit;
    wire ball_lost;
    wire [7:0] score;
    wire [1:0] lives;
    wire game_won;
    
    reg [23:0] clk_counter;
    always @(posedge clk) begin
        clk_counter <= clk_counter + 1;
    end

    breakout_top breakout_game (
        .ClkPort(clk),
        .BtnC(reset),
        .BtnL(B3),
        .BtnR(B4),
        .BtnU(B2),
        .shoot(B5),
        .hSync(h_sync),
        .vSync(v_sync),
        .vgaR(vgaR),
        .vgaG(vgaG), 
        .vgaB(vgaB)
    );

    assign rgb_12bit = {vgaR, vgaG, vgaB};
    assign rgb = {
        rgb_12bit[11:8], rgb_12bit[11:9],
        rgb_12bit[7:4], rgb_12bit[7:5],  
        rgb_12bit[3:0], rgb_12bit[3]
    };

    assign led1 = clk_counter[23];
    assign led2 = h_sync;
    assign led3 = v_sync;
    assign led4 = (lives > 0);
    assign led5 = |rgb;

endmodule