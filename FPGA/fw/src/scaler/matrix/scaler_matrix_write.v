`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* QQ     : 627833006
* Mail   : hn.cy@foxmail.com
* Csdn   : https://blog.csdn.net/weixin_46718879
* Description :
*   @Create   : 2019-12-25 14:40:51
*             Line in and Matrix write
*   @Modify   : 2020-02-05 17:51:00
*             Count the current times of reading and writing ram to determine
*       whether the order has capacity to write data
******************************************************************************/

module scaler_matrix_write
#(
    parameter  KERNEL_MAX           = 4,
    parameter  KERNEL_BITWIDTH      = CLOG2(KERNEL_MAX),
    parameter  RAM_NUM              = KERNEL_MAX+1,
    parameter  RAM_NUM_BITWIDTH     = CLOG2(RAM_NUM),
    parameter  RAM_DEEP             = 3840,
    parameter  RAM_ADDR_BITWIDTH    = CLOG2(RAM_DEEP),
    parameter  RAM_DATA_BITWIDTH    = 8
)(
    input                                        s_clk,
    input                                        s_rst,
    input                                        s_start,
    output reg                                   s_axis_connect_ready = 1'd0,
    input                                        s_axis_connect_valid,
    input                                        s_axis_img_valid,
    input      [RAM_DATA_BITWIDTH-1 : 0]         s_axis_img_pixel,
    input                                        s_axis_img_done,
    output reg [RAM_NUM-1 : 0]                   ram_ena,
    output reg [RAM_NUM-1 : 0]                   ram_wea,
    output reg [RAM_ADDR_BITWIDTH-1 : 0]         ram_addra,
    output reg [RAM_DATA_BITWIDTH-1 : 0]         ram_dina,
    output                                       ram_write_done,
    output     [RAM_NUM_BITWIDTH-1 : 0]          ram_write_num,
    input                                        ram_read_done,
    input      [RAM_NUM_BITWIDTH-1 : 0]          ram_read_num
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam  ST_IDLE    = 0,
            ST_WAIT    = 1,
            ST_CONNECT = 2,
            ST_STREAM  = 3,
            ST_NEXT    = 4;

`define  NON_FULL    (1'd0)
`define      FULL    (1'd1)

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg  [3 : 0] state_curr = ST_IDLE;
reg  [3 : 0] state_next = ST_IDLE;

reg  [RAM_NUM_BITWIDTH-1 : 0]               ram_sel            = {RAM_NUM_BITWIDTH{1'd0}};
reg  [RAM_ADDR_BITWIDTH-1 : 0]              ram_cnt            = {RAM_ADDR_BITWIDTH{1'd0}};
wire                                        ram_state_full;
reg  [RAM_NUM_BITWIDTH-1 : 0]               ram_space          = {RAM_NUM_BITWIDTH{1'd0}};
reg  [5 : 0]                                ram_write_done_dly = 6'd0;
reg  [1 : 0]                                ram_read_done_dly  = 2'd0;
wire                                        connect_ok;
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
always @ (posedge s_clk) begin
    if(s_rst) begin
        state_curr <= ST_IDLE;
    end
    else begin
        state_curr <= state_next;
    end
end

always @ (*) begin
    case (state_curr)
        ST_IDLE    : begin state_next = (s_start)                     ? ST_WAIT          : state_curr; end
        ST_WAIT    : begin state_next = (ram_state_full == `NON_FULL) ? ST_CONNECT       : state_curr; end
        ST_CONNECT : begin state_next = (connect_ok)                  ? ST_STREAM        : state_curr; end
        ST_STREAM  : begin state_next = (s_axis_img_done)             ? ST_NEXT          : state_curr; end
        ST_NEXT    : begin state_next = ST_WAIT;                                                       end
    endcase
end

/*----------------------------------------------------------------------------*/
/* ST_WAIT_NON_FULL */
/* ram wr and rd control*/
always @ (posedge s_clk) begin
    ram_write_done_dly <= {ram_write_done_dly[4:0], s_axis_img_done};
    ram_read_done_dly  <= {ram_read_done_dly[0],    ram_read_done};
end

assign ram_write_done = | ram_write_done_dly;
assign ram_write_num  = {RAM_NUM_BITWIDTH{1'd0}} + 1'd1;

// Judge full status according to wr_h_num and rd_h_num
// Similar to the FIFO
always @ (posedge s_clk) begin
    if(state_curr == ST_IDLE) begin
        ram_space <= {RAM_NUM_BITWIDTH{1'd0}};
    end
    else if((ram_write_done_dly == 6'd1) & (ram_read_done_dly == 2'd1)) begin
        ram_space <= ram_space + ram_write_num - ram_read_num;
    end
    else if((ram_write_done_dly == 6'd1) & (ram_read_done_dly != 2'd1)) begin
        ram_space <= ram_space + ram_write_num;
    end
    else if((ram_write_done_dly != 6'd1) & (ram_read_done_dly == 2'd1)) begin
        ram_space <= ram_space - ram_read_num;
    end
end

assign ram_state_full = (ram_space == RAM_NUM) ? `FULL : `NON_FULL;

/*----------------------------------------------------------------------------*/
/* ST_CONNECT */
always @ (posedge s_clk) begin
    if(state_curr == ST_CONNECT) begin
        if(s_axis_connect_ready & s_axis_connect_valid) begin
            s_axis_connect_ready <= 1'd0;
        end
        else begin
            s_axis_connect_ready <= 1'd1;
        end
    end
    else begin
        s_axis_connect_ready <= 1'd0;
    end
end

assign connect_ok = s_axis_connect_ready & s_axis_connect_valid;
/*----------------------------------------------------------------------------*/
/* ST_STREAM */
always @ (posedge s_clk) begin
    if(state_curr == ST_IDLE) begin
        ram_sel <= {RAM_NUM_BITWIDTH{1'd0}};
    end
    else if(s_axis_img_done) begin
        if(ram_sel == KERNEL_MAX) begin
            ram_sel <= {RAM_NUM_BITWIDTH{1'd0}};
        end
        else begin
            ram_sel <= ram_sel + 1'd1;
        end
    end
end

/* write matrix ram */
genvar j;
generate
    for (j = 0; j < RAM_NUM; j = j + 1) begin
        always @ (posedge s_clk) begin
            if(s_axis_img_valid & (j == ram_sel)) begin
                ram_ena [j] <= 1'd1;
                ram_wea [j] <= 1'd1;
            end
            else begin
                ram_ena [j] <= 1'd0;
                ram_wea [j] <= 1'd0;
            end
        end
    end
endgenerate

always @ (posedge s_clk) begin
    if(state_curr == ST_WAIT) begin
        ram_cnt   <= {RAM_ADDR_BITWIDTH{1'd0}};
        ram_addra <= {RAM_ADDR_BITWIDTH{1'd0}};
        ram_dina  <= {RAM_DATA_BITWIDTH{1'd0}};
    end
    else if(s_axis_img_valid) begin
        ram_cnt   <= ram_cnt + 1'd1;
        ram_addra <= ram_cnt;
        ram_dina  <= s_axis_img_pixel;
    end
end

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule
