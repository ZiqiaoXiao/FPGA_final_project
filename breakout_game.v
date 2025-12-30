`timescale 1ns / 1ps

module breakout_game(
    input clk,
    input reset,
    input bright,
    input [9:0] hCount, vCount,
    input btnL, btnR, btnU,
    input B5,
    output reg [11:0] rgb,
    output reg [9:0] ballX,
    output reg [9:0] ballY,
    output reg [7:0] score,
    output reg [1:0] lives,
    output reg ball_lost,
    output reg game_won
);

    parameter PADDLE_WIDTH = 81;
    parameter PADDLE_HEIGHT = 10;
    parameter BALL_SIZE = 6;
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter BALL_X_SPEED = 1;
    parameter BALL_Y_SPEED = 2;
    parameter PADDLE_Y = SCREEN_HEIGHT - 50;
    parameter PADDLE_SPEED = 4;

    parameter H_OFFSET = 145;
    parameter V_OFFSET = 35;

    parameter BLOCK_ROWS = 7;
    parameter BLOCK_COLS = 28;
    parameter BLOCK_WIDTH = 20;
    parameter BLOCK_HEIGHT = 20;
    parameter BLOCK_X_OFFSET = (SCREEN_WIDTH - (BLOCK_WIDTH * BLOCK_COLS)) / 2;
    parameter BLOCK_Y_OFFSET = 120;

    reg [9:0] paddleX;
    reg ballXDir;
    reg ballYDir;
    reg ball_moving;
    reg [19:0] ballSpeedCounter;
    reg [19:0] ball_delay;
    reg [3:0] paddle_speed;

    integer i, j;
    integer blocksHitThisFrame;
    reg [9:0] brickLeft, brickRight, brickTop, brickBottom;
    wire [9:0] ballLeft, ballRight, ballTop, ballBottom;

    assign ballLeft = ballX;
    assign ballRight = ballX + BALL_SIZE;
    assign ballTop = ballY;
    assign ballBottom = ballY + BALL_SIZE;

    reg [19:0] btnLCounter = 0;
    reg [19:0] btnRCounter = 0;

    reg [BLOCK_COLS-1:0] blockShape [0:BLOCK_ROWS-1];
    reg [BLOCK_COLS-1:0] blockVisible [0:BLOCK_ROWS-1];

    initial begin
        blockShape[0] = 28'b11111110_111111_010001_01100011;
        blockShape[1] = 28'b00010000_000001_010001_01010101;
        blockShape[2] = 28'b00010000_000001_010001_01010101;
        blockShape[3] = 28'b00010000_111111_010001_01001001;
        blockShape[4] = 28'b00010000_100000_010001_01000001;
        blockShape[5] = 28'b00010000_100000_010001_01000001;
        blockShape[6] = 28'b00010000_111111_011111_01000001;

        for (i = 0; i < BLOCK_ROWS; i = i + 1) begin
            for (j = 0; j < BLOCK_COLS; j = j + 1) begin
                blockVisible[i][j] = blockShape[i][j];
            end
        end
    end

    initial begin
        paddleX = (SCREEN_WIDTH - PADDLE_WIDTH) / 2;
        ballX = SCREEN_WIDTH / 2;
        ballY = SCREEN_HEIGHT / 2;
        ballXDir = 0;
        ballYDir = 0;
        ball_moving = 0;
        ball_lost = 0;
        ballSpeedCounter = 0;
        score = 0;
        lives = 3;
        game_won = 0;
        paddle_speed = 4;
        ball_delay = 20'd50000;
    end

    always @(posedge clk) begin
        if (reset) begin
            paddleX <= (SCREEN_WIDTH - PADDLE_WIDTH) / 2;
            ballX <= (SCREEN_WIDTH - BALL_SIZE) / 2;
            ballY <= PADDLE_Y - BALL_SIZE - BALL_SIZE - BALL_SIZE - 50;
            ballXDir <= 0;
            ballYDir <= 1;
            ball_moving <= 0;
            ball_lost <= 0;
            score <= 0;
            lives <= 3;
            game_won <= 0;
            for(i = 0; i < BLOCK_ROWS; i = i + 1) begin
                for (j = 0; j < BLOCK_COLS; j = j + 1) begin
                    blockVisible[i][j] <= blockShape[i][j];
                end
            end
            ballSpeedCounter <= 0;
        end
        else begin
            if (btnL) begin
                btnLCounter <= btnLCounter + 1;
                if (btnLCounter >= 20'd10000) begin
                    if (paddleX >= paddle_speed) paddleX <= paddleX - paddle_speed;
                    else paddleX <= 0;
                    btnLCounter <= 0;
                end
            end else btnLCounter <= 0;

            if (btnR) begin
                btnRCounter <= btnRCounter + 1;
                if (btnRCounter >= 20'd10000) begin
                    if (paddleX + PADDLE_WIDTH + paddle_speed < SCREEN_WIDTH)
                        paddleX <= paddleX + paddle_speed;
                    else
                        paddleX <= SCREEN_WIDTH - PADDLE_WIDTH;
                    btnRCounter <= 0;
                end
            end else btnRCounter <= 0;

            if (game_won) begin
                ball_moving <= 0;
            end else if (!ball_moving && !ball_lost) begin
                ballX <= paddleX + (PADDLE_WIDTH / 2) - (BALL_SIZE / 2);
                ballY <= PADDLE_Y - BALL_SIZE;
                if (B5) begin
                    ball_moving <= 1;
                    ballYDir <= 0;
                    ballXDir <= ballSpeedCounter[0];
                end
            end

            if (ball_moving && !ball_lost) begin
                ballSpeedCounter <= ballSpeedCounter + 1;
                if (ballSpeedCounter == ball_delay) begin
                    ballX <= ballX + (ballXDir ? BALL_X_SPEED : -BALL_X_SPEED);
                    ballY <= ballY + (ballYDir ? BALL_Y_SPEED : -BALL_Y_SPEED);

                    if (ballX <= 0) begin ballX <= 1; ballXDir <= 1; end
                    else if (ballX >= SCREEN_WIDTH - BALL_SIZE) begin ballX <= SCREEN_WIDTH - BALL_SIZE - 1; ballXDir <= 0; end

                    if (ballTop <= 1) begin ballY <= 2; ballYDir <= 1; end

                    if (ballY >= SCREEN_HEIGHT) begin
                        if (lives > 0) lives <= lives - 1;
                        if (lives == 1) ball_lost <= 1;
                        ball_moving <= 0;
                    end

                    if ((ballY+BALL_SIZE >= PADDLE_Y) && (ballY <= PADDLE_Y+PADDLE_HEIGHT) &&
                        (ballX+BALL_SIZE >= paddleX) && (ballX <= paddleX+PADDLE_WIDTH)) begin
                        ballYDir <= 0;
                        if (ballX + BALL_SIZE/2 < paddleX + PADDLE_WIDTH/3) ballXDir <= 0;
                        else if (ballX + BALL_SIZE/2 > paddleX + 2*PADDLE_WIDTH/3) ballXDir <= 1;
                    end

                    blocksHitThisFrame = 0;
                    for (i = 0; i < BLOCK_ROWS; i = i + 1) begin
                        for (j = 0; j < BLOCK_COLS; j = j + 1) begin
                            if (blockVisible[i][j]) begin
                                brickLeft = j*BLOCK_WIDTH + BLOCK_X_OFFSET;
                                brickRight = brickLeft + BLOCK_WIDTH;
                                brickTop = i*BLOCK_HEIGHT + BLOCK_Y_OFFSET;
                                brickBottom = brickTop + BLOCK_HEIGHT;

                                if (ballRight >= brickLeft && ballLeft <= brickRight &&
                                    ballBottom >= brickTop && ballTop <= brickBottom) begin
                                    blockVisible[i][j] <= 1'b0;
                                    blocksHitThisFrame = blocksHitThisFrame + 1;
                                    if ((ballBottom <= brickTop + 2) || (ballTop >= brickBottom - 2))
                                        ballYDir <= ~ballYDir;
                                    else
                                        ballXDir <= ~ballXDir;
                                end
                            end
                        end
                    end

                    score <= score + blocksHitThisFrame;
                    ballSpeedCounter <= 0;
                    
                    if (reset)
                        game_won <= 0;
                    else if (score + blocksHitThisFrame >= 10) 
                        game_won <= 1; 
                end
            end
        end
    end

    always @(*) begin
        if (~bright) begin
            rgb = 12'b0000_0000_0000;
        end else begin
            rgb = 12'b0000_0000_0000;
            for (i = 0; i < BLOCK_ROWS; i = i + 1) begin
                for (j = 0; j < BLOCK_COLS; j = j + 1) begin
                    if (blockVisible[i][j]) begin
                        if (hCount >= j*BLOCK_WIDTH + BLOCK_X_OFFSET + H_OFFSET &&
                            hCount < j*BLOCK_WIDTH + BLOCK_X_OFFSET + BLOCK_WIDTH + H_OFFSET &&
                            vCount >= i*BLOCK_HEIGHT + BLOCK_Y_OFFSET + V_OFFSET &&
                            vCount < i*BLOCK_HEIGHT + BLOCK_Y_OFFSET + BLOCK_HEIGHT + V_OFFSET) begin
                            rgb = 12'b0000_0000_1111; 
                        end
                    end
                end
            end

            if (vCount >= PADDLE_Y + V_OFFSET && vCount < PADDLE_Y + PADDLE_HEIGHT + V_OFFSET &&
                hCount >= paddleX + H_OFFSET && hCount < paddleX + PADDLE_WIDTH + H_OFFSET)
                rgb = 12'b0000_1111_0000;

            if (!ball_lost &&
                vCount >= ballY + V_OFFSET && vCount < ballY + BALL_SIZE + V_OFFSET &&
                hCount >= ballX + H_OFFSET && hCount < ballX + BALL_SIZE + H_OFFSET)
                rgb = 12'b1111_1111_1111;
        end
    end
endmodule