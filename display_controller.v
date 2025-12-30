`timescale 1ns / 1ps

module display_controller(
    input clk,
    output hSync, vSync,
    output reg bright,
    output reg [9:0] hCount, 
    output reg [9:0] vCount
    );

    parameter H_ACTIVE = 640;
    parameter H_FRONT_PORCH = 16;
    parameter H_SYNC_PULSE = 96;
    parameter H_BACK_PORCH = 48;
    parameter H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;

    parameter V_ACTIVE = 480;
    parameter V_FRONT_PORCH = 10;
    parameter V_SYNC_PULSE = 2;
    parameter V_BACK_PORCH = 33;
    parameter V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    reg clk25;
    reg clk_div;

    initial begin
        clk25 = 0;
        clk_div = 0;
        hCount = 0;
        vCount = 0;
    end

    always @(posedge clk) begin
        clk_div <= ~clk_div; 
        clk25 <= clk_div;
    end

    always @(posedge clk25) begin
        if (hCount < H_TOTAL - 1)
            hCount <= hCount + 1;
        else begin
            hCount <= 0;
            if (vCount < V_TOTAL - 1)
                vCount <= vCount + 1;
            else
                vCount <= 0;
        end
    end

    assign hSync = (hCount < H_SYNC_PULSE);
    assign vSync = (vCount < V_SYNC_PULSE);

    always @(posedge clk25) begin
        bright <= (hCount >= (H_SYNC_PULSE + H_BACK_PORCH)) && 
                  (hCount < (H_SYNC_PULSE + H_BACK_PORCH + H_ACTIVE)) &&
                  (vCount >= (V_SYNC_PULSE + V_BACK_PORCH)) && 
                  (vCount < (V_SYNC_PULSE + V_BACK_PORCH + V_ACTIVE));
    end

endmodule