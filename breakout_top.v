`timescale 1ns / 1ps

module breakout_top(
    input ClkPort,
    input BtnC, BtnL, BtnR, BtnU,
    input shoot, 
    output hSync, vSync,
    output [3:0] vgaR, vgaG, vgaB
);
    
    wire bright;
    wire [9:0] hCount, vCount;
    wire [11:0] rgb_game;     
    reg  [11:0] rgb_final;    
    
    wire ball_lost;
    wire [7:0] score;
    wire [1:0] lives;
    wire game_won;

    wire [1:0] current_state;
    wire game_reset_sig;
    wire win_latch;
     
    wire BtnC_db, BtnU_db, BtnL_db, BtnR_db, Shoot_db;

    Button_Debounce dbC (.clk(ClkPort), .rst_n(1'b1), .button_in(BtnC), .button_out(BtnC_db));
    Button_Debounce dbU (.clk(ClkPort), .rst_n(1'b1), .button_in(BtnU), .button_out(BtnU_db));
    Button_Debounce dbL (.clk(ClkPort), .rst_n(1'b1), .button_in(BtnL), .button_out(BtnL_db));
    Button_Debounce dbR (.clk(ClkPort), .rst_n(1'b1), .button_in(BtnR), .button_out(BtnR_db));
    Button_Debounce dbShoot (.clk(ClkPort), .rst_n(1'b1), .button_in(shoot), .button_out(Shoot_db));

    wire fsm_reset_btn = ~BtnC_db;
    wire fsm_start_btn = ~BtnU_db;
    wire Right = ~BtnR_db;
    wire Left  = ~BtnL_db;
    wire Shoot = ~Shoot_db;

    localparam S_START = 2'b00;
    localparam S_GAME  = 2'b01;
    localparam S_END   = 2'b10;

    display_controller dc(
        .clk(ClkPort),
        .hSync(hSync),
        .vSync(vSync),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount)
    );
    
    breakout_fsm fsm_inst (
        .clk(ClkPort),
        .reset_btn(fsm_reset_btn),
        .start_btn(fsm_start_btn),
        .game_over_signal(lives == 0), 
        .game_won_signal(game_won),    
        .state(current_state),
        .game_reset(game_reset_sig),
        .win_latch(win_latch) 
    );

    breakout_game game(
        .clk(ClkPort),
        .reset(game_reset_sig),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount),
        .btnL(Left),
        .btnR(Right),
        .btnU(1'b0),
        .B5(Shoot),
        .rgb(rgb_game),
        .ball_lost(ball_lost),
        .score(score),
        .lives(lives),
        .ballX(), .ballY(),
        .game_won(game_won)
    );
     
    wire [15:0] rgb_start_raw;
    wire [11:0] rgb_start;
    wire [15:0] rgb_end_raw;
    wire [11:0] rgb_end;
    wire [15:0] rgb_win_raw;
    wire [11:0] rgb_win;

    assign rgb_start = { rgb_start_raw[15:12], rgb_start_raw[10:7], rgb_start_raw[4:1] };
    assign rgb_end = { rgb_end_raw[15:12], rgb_end_raw[10:7], rgb_end_raw[4:1] };
    assign rgb_win  = { rgb_win_raw[15:12],  rgb_win_raw[10:7], rgb_win_raw[4:1] };

    emoji_display end_page(
        .vga_clk(ClkPort),
        .video_on(bright),
        .vga_x(hCount),
        .vga_y(vCount),
        .rgb(rgb_end_raw),
        .sys_rst_n(~game_reset_sig)
    );
     
    start_display start_page(
        .vga_clk(ClkPort),
        .video_on(bright),
        .vga_x(hCount),
        .vga_y(vCount),
        .rgb(rgb_start_raw),
        .sys_rst_n(game_reset_sig)
    );

    win_display win_page(
        .vga_clk(ClkPort),
        .video_on(bright),
        .vga_x(hCount),
        .vga_y(vCount),
        .rgb(rgb_win_raw),
        .sys_rst_n(win_latch)
    );
     
    wire [15:0] rgb_heart3_raw, rgb_heart2_raw, rgb_heart1_raw;
    wire [11:0] rgb_heart3,    rgb_heart2,    rgb_heart1;

    assign rgb_heart3 = { rgb_heart3_raw[15:12], rgb_heart3_raw[10:7], rgb_heart3_raw[4:1] };
    assign rgb_heart2 = { rgb_heart2_raw[15:12], rgb_heart2_raw[10:7], rgb_heart2_raw[4:1] };
    assign rgb_heart1 = { rgb_heart1_raw[15:12], rgb_heart1_raw[10:7], rgb_heart1_raw[4:1] };

    heart3_display heart3(
        .vga_clk(ClkPort),
        .video_on(bright),
        .vga_x(hCount),
        .vga_y(vCount),
        .rgb(rgb_heart3_raw),
        .sys_rst_n(1'b1)
    );

    heart2_display heart2(
        .vga_clk(ClkPort),
        .video_on(bright),
        .vga_x(hCount),
        .vga_y(vCount),
        .rgb(rgb_heart2_raw),
        .sys_rst_n(1'b1)
    );

    heart1_display heart1(
        .vga_clk(ClkPort),
        .video_on(bright),
        .vga_x(hCount),
        .vga_y(vCount),
        .rgb(rgb_heart1_raw),
        .sys_rst_n(1'b1)
    );

    always @(*) begin
        rgb_final = 12'h000;
        if (bright) begin
            case (current_state)
                S_START: begin
                    rgb_final = rgb_start;
                end
                S_GAME: begin
                    rgb_final = rgb_game;
                    if (bright) begin
                        case (lives)
                            3: if (rgb_heart3 != 12'h000) rgb_final = rgb_heart3;
                            2: if (rgb_heart2 != 12'h000) rgb_final = rgb_heart2;
                            1: if (rgb_heart1 != 12'h000) rgb_final = rgb_heart1;
                        endcase
                    end
                end
                S_END: begin
                    if (win_latch)
                        rgb_final = rgb_win;
                    else
                        rgb_final = rgb_end;
                end
                default: rgb_final = 12'h000;
            endcase
        end
    end

    assign vgaR = rgb_final[11:8];
    assign vgaG = rgb_final[7:4];
    assign vgaB = rgb_final[3:0];

endmodule

module Button_Debounce #(
    parameter MAX_COUNT = 20'd10000
)(
    input wire clk,
    input wire rst_n,
    input wire button_in,
    output reg button_out
);

    reg [19:0] count;
    reg button_sync0, button_sync1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_sync0 <= 0;
            button_sync1 <= 0;
        end else begin
            button_sync0 <= button_in;
            button_sync1 <= button_sync0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_out <= 0;
            count <= 0;
        end else begin
            if (button_sync1 != button_out) begin
                if (count == MAX_COUNT) begin
                    button_out <= button_sync1;
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
            end else begin
                count <= 0;
            end
        end
    end

endmodule