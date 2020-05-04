`timescale 1ns / 1ps
/******************************************************************************
* Auther : Abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2019-12-24 10:36:12
*             Create File
*   @Modify :
******************************************************************************/

module color_bar_ctrl
#(
    parameter VH_BITWIDTH = 13
)(
    input                          clk,
    input                          rst,
    input      [VH_BITWIDTH-1 : 0] h_total,
    input      [VH_BITWIDTH-1 : 0] v_total,
    output reg                     ce,
    output reg [VH_BITWIDTH-1 : 0] h_cnt,
    output reg [VH_BITWIDTH-1 : 0] v_cnt
);

/********************************************************************************
*
*   Define localparam
*
********************************************************************************/

/********************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg [VH_BITWIDTH-1 : 0] v_total_d1 = {VH_BITWIDTH{1'd0}};  // for timing analysic
reg [VH_BITWIDTH-1 : 0] h_total_d1 = {VH_BITWIDTH{1'd0}};  // for timing analysic
reg [VH_BITWIDTH-1 : 0] v_cnt_pre  = {VH_BITWIDTH{1'd0}};  // for timing analysic
reg [VH_BITWIDTH-1 : 0] h_cnt_pre  = {VH_BITWIDTH{1'd0}};  // for timing analysic

/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/

always @ (posedge clk) begin
    v_total_d1 <= v_total - 1'd1;
    h_total_d1 <= h_total - 1'd1;
end

always @ (posedge clk) begin
    if(rst) begin
        h_cnt_pre <= h_total_d1;
    end
    else if(h_cnt_pre == h_total_d1) begin
        h_cnt_pre <= 13'd0;
    end
    else begin
        h_cnt_pre <= h_cnt_pre + 1'd1;
    end
end

always @ (posedge clk) begin
    if(rst) begin
        v_cnt_pre <= v_total_d1;
    end
    else if(h_cnt_pre == h_total_d1) begin
        if(v_cnt_pre == v_total_d1) begin
            v_cnt_pre <= 13'd0;
        end
        else begin
            v_cnt_pre <= v_cnt_pre + 1'd1;
        end
    end
end

// output cnt , delay for timing analysic
always @ (posedge clk) begin
    ce    <= 1'd1;
    v_cnt <= v_cnt_pre;
    h_cnt <= h_cnt_pre;
end

endmodule
