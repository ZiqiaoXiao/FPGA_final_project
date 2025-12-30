module win_display (
    input wire vga_clk,
    input wire sys_rst_n,
    input wire [9:0] vga_x,
    input wire [9:0] vga_y,
    input wire video_on,
    output reg [15:0] rgb
);

    parameter SCALE = 10;
    parameter IMG_WIDTH  = 64;
    parameter IMG_HEIGHT = 48;

    localparam DISP_W = IMG_WIDTH  * SCALE;   
    localparam DISP_H = IMG_HEIGHT * SCALE;   

	 
	 localparam X_ADJ = 144;  

	 localparam Y_ADJ = 35;  
	 localparam START_X = ((640 - DISP_W) / 2) + X_ADJ; 

	 localparam START_Y = ((480 - DISP_H) / 2) + Y_ADJ; 

    wire in_area = (vga_x >= START_X) && (vga_x < START_X + DISP_W) &&
                   (vga_y >= START_Y) && (vga_y < START_Y + DISP_H);

    wire [9:0] rel_x = vga_x - START_X;
    wire [9:0] rel_y = vga_y - START_Y;

   wire [6:0] img_x = rel_x / SCALE;
   wire [6:0] img_y = rel_y / SCALE;


    wire safe = (img_x < IMG_WIDTH) && (img_y < IMG_HEIGHT);

    wire [15:0] rom_rgb;

    win_rom rom_inst (
        .clk(vga_clk),
        .pixel_x(img_x),
        .pixel_y(img_y),
        .rgb_data(rom_rgb)
    );

    reg in_area_d, video_on_d, safe_d;
    reg [6:0] img_x_d, img_y_d;
    reg [15:0] rom_rgb_d;

    always @(posedge vga_clk) begin
        in_area_d  <= in_area;
        video_on_d <= video_on;
        safe_d     <= safe;
        img_x_d    <= img_x;
        img_y_d    <= img_y;
        rom_rgb_d  <= rom_rgb;
    end

    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            rgb <= 16'h0000;
        else if (!video_on_d)
            rgb <= 16'h0000;
        else if (in_area_d && safe_d)
            rgb <= rom_rgb_d;
        else
            rgb <= 16'h001F;
    end

endmodule
