`timescale 1ns/1ps
/******************************************************************************
* Auther : Abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2020-03-04 22:00:00
*             Create File
*             1. imdetail = 4'd0  colour bar 1
*                         = 4'd1  colour bar 2
*                         = 4'd2  grid
*                         = 4'd3  YCBCR_RED
*                         = 4'd4  YCBCR_GREEN
*                         = 4'd5  YCBCR_BLUE
*                         = 4'd6  flow
*                         = 4'd7  noise
*                         = 4'd8  simulation
*   @Modify :
******************************************************************************/

module color_bar_imdetail
#(
    parameter VH_BITWIDTH = 13
)(
    input                          clk,
    input                          rst,
    input      [VH_BITWIDTH-1 : 0] h_active,
    input                          scan_id,
    input      [3 : 0]             imdetail,
    input                          bt1120_vs,
    input                          bt1120_hs,
    input                          bt1120_de,
    output reg                     imdetail_de,
    output     [15 : 0]            imdetail_ycbcr
);

/********************************************************************************
*
*   Define localparam
*   Y = 0.257R + 0.504G + 0.098B + 16
*   Cb = -0.148R - 0.291G + 0.439B + 128
*   Cr = 0.439R - 0.368G - 0.071B + 128
*
********************************************************************************/
`define RGB_WHITE        {8'hff, 8'hff, 8'hff}
`define RGB_YELLOW       {8'hff, 8'hff, 8'h00}
`define RGB_CYAN         {8'h00, 8'hff, 8'hff}
`define RGB_GREEN        {8'h00, 8'hff, 8'h00}
`define RGB_MAGENTA      {8'hff, 8'h00, 8'hff}
`define RGB_RED          {8'hff, 8'h00, 8'h00}
`define RGB_BLUE         {8'h00, 8'h00, 8'hff}
`define RGB_BLACK        {8'h00, 8'h00, 8'h00}

`define YCBCR_WHITE      {8'hEB, 8'h80, 8'h80}
`define YCBCR_YELLOW     {8'hD2, 8'h10, 8'h92}
`define YCBCR_CYAN       {8'hA9, 8'hA5, 8'h10}
`define YCBCR_GREEN      {8'h90, 8'h35, 8'h22}
`define YCBCR_MAGENTA    {8'h6A, 8'hCA, 8'hDD}
`define YCBCR_RED        {8'h51, 8'h5A, 8'hEF}
`define YCBCR_BLUE       {8'h28, 8'hEF, 8'h6D}
`define YCBCR_BLACK      {8'h10, 8'h80, 8'h80}

// 16 : 9 =>
// 1920 / 1080    1920 = 16*(8*5)*3        1080 = 9*(5*8)*3
// 3840 / 2160    3840 = 16*(8*5)*(3*2)    2160 = 9*(5*8)*(3*2)
// 1280 / 720     1280 = 16*(8*5)*2        1280 = 9*(5*8)*2

/********************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg [7 : 0]  max = 8'd0;
reg [3 : 0]  h_num = 5'd0; // 16
reg [7 : 0]  h_cnt = 8'd0;
reg [3 : 0]  v_num = 5'd0; // 9
reg [7 : 0]  v_cnt = 8'd0;
reg          de_hold = 1'd0;
reg          sw = 1'd1; // 1 = ycb 0 = ycr
reg [23 : 0] ycbcr;
/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
always @ (posedge clk) begin
    max <= (h_active == 13'd3840) ? (8'd240-1'd1) :
           (h_active == 13'd1920) ? (8'd120-1'd1) :
           (h_active == 13'd1280) ? (8'd80 -1'd1) : (8'd120-1'd1);
end

// de
always @ (posedge clk) begin
    if(bt1120_vs | bt1120_hs) begin
        de_hold <= 1'd0;
    end
    else if(bt1120_de) begin
        de_hold <= 1'd1;
    end
end

// v
always @ (posedge clk) begin
    if(bt1120_vs) begin
        v_cnt <= 4'd0;
    end
    else if(de_hold & bt1120_hs) begin
        if(v_cnt >= max) begin
            v_cnt <= 4'd0;
        end
        else if(scan_id) begin
            v_cnt <= v_cnt + 2'd2;
        end
        else begin
            v_cnt <= v_cnt + 1'd1;
        end
    end
end

always @ (posedge clk) begin
    if(bt1120_vs) begin
        v_num <= 4'd0;
    end
    else if(de_hold & bt1120_hs) begin
        if(v_cnt >= max) begin
            v_num <= v_num + 1'd1;
        end
    end
end

// h
always @ (posedge clk) begin
    if(bt1120_hs) begin
        h_cnt <= 4'd0;
    end
    else if(bt1120_de) begin
        if(h_cnt == max) begin
            h_cnt <= 4'd0;
        end
        else begin
            h_cnt <= h_cnt + 1'd1;
        end
    end
end

always @ (posedge clk) begin
    if(bt1120_hs) begin
        h_num <= 4'd0;
    end
    else if(bt1120_de) begin
        if(h_cnt == max) begin
            h_num <= h_num + 1'd1;
        end
    end
end

always @ (posedge clk) begin
    if(imdetail == 4'd0) begin
        case(h_num)
            4'd0  : ycbcr <= `YCBCR_WHITE  ;
            4'd1  : ycbcr <= `YCBCR_YELLOW ;
            4'd2  : ycbcr <= `YCBCR_CYAN   ;
            4'd3  : ycbcr <= `YCBCR_GREEN  ;
            4'd4  : ycbcr <= `YCBCR_MAGENTA;
            4'd5  : ycbcr <= `YCBCR_RED    ;
            4'd6  : ycbcr <= `YCBCR_BLUE   ;
            4'd7  : ycbcr <= `YCBCR_BLACK  ;

            4'd8  : ycbcr <= `YCBCR_WHITE  ;
            4'd9  : ycbcr <= `YCBCR_BLUE   ;
            4'd10 : ycbcr <= `YCBCR_RED    ;
            4'd11 : ycbcr <= `YCBCR_MAGENTA;
            4'd12 : ycbcr <= `YCBCR_GREEN  ;
            4'd13 : ycbcr <= `YCBCR_CYAN   ;
            4'd14 : ycbcr <= `YCBCR_YELLOW ;
            4'd15 : ycbcr <= `YCBCR_BLACK  ;
            default : begin end
        endcase
    end
    else if(imdetail == 4'd1) begin
        case(v_num)
            4'd0  : ycbcr <= `YCBCR_WHITE  ;
            4'd1  : ycbcr <= `YCBCR_YELLOW ;
            4'd2  : ycbcr <= `YCBCR_CYAN   ;
            4'd3  : ycbcr <= `YCBCR_GREEN  ;
            4'd4  : ycbcr <= `YCBCR_MAGENTA;
            4'd5  : ycbcr <= `YCBCR_RED    ;
            4'd6  : ycbcr <= `YCBCR_BLUE   ;
            4'd7  : ycbcr <= `YCBCR_WHITE  ;
            4'd8  : ycbcr <= `YCBCR_BLACK  ;
            default : begin end
        endcase
    end
    else if(imdetail == 4'd2) begin
        if(h_num[0] & v_num[0]) begin
            ycbcr <= `YCBCR_BLACK;
        end
        else begin
            ycbcr <= `YCBCR_WHITE;
        end
    end
    else if(imdetail == 4'd3) begin
        ycbcr <= `YCBCR_RED;
    end
    else if(imdetail == 4'd4) begin
        ycbcr <= `YCBCR_GREEN;
    end
    else if(imdetail == 4'd5) begin
        ycbcr <= `YCBCR_BLUE;
    end
    else if(imdetail == 4'd6) begin

    end
    else if(imdetail == 4'd7) begin

    end
    else begin
        ycbcr <= {v_cnt, v_num, h_num, h_cnt};
    end
end

always @ (posedge clk) begin
    imdetail_de <= bt1120_de;
end

always @ (posedge clk) begin
    if(bt1120_hs) begin
        sw <= 1'd1;
    end
    else if(imdetail_de) begin
        sw <= ~sw;
    end
end

// 1 => ycb
// 2 => ycr
assign imdetail_ycbcr = (sw == 1'd1) ? {ycbcr[23:16], ycbcr[15:8]} : {ycbcr[23:16], ycbcr[7:0]};
endmodule