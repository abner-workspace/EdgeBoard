`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Gitee  : https://gitee.com/abnerwork/
* Csdn   :
* Description :
*   @Create : 2019-07-22
*
*   @Modify : 2020-04-06
*           Note : KERNEL_MAX >= 2
******************************************************************************/
module scaler_lut_h
#(
    parameter PIXEL_BITWIDTH            = 8,
    parameter IMG_H_MAX                 = 1920,
    parameter IMG_H_BITWIDTH            = CLOG2(IMG_H_MAX),
    parameter KERNEL_MAX                = 4,
    parameter KERNEL_BITWIDTH           = CLOG2(KERNEL_MAX),
    parameter SF_BITWIDTH               = 24, // 24Q20
    parameter SF_INT_BITWIDTH           = 4,
    parameter SF_FRAC_BITWIDTH          = 20,
    parameter MATRIX_DELAY              = 4
)(
    input                                                   core_clk,
    input                                                   core_rst,
    input      [IMG_H_BITWIDTH-1 : 0]                       core_arg_img_src_h,
    input      [IMG_H_BITWIDTH-1 : 0]                       core_arg_img_des_h,
    input                                                   core_arg_mode,    // 0 = scaler down 1 = scaler up
    input      [SF_BITWIDTH-1 : 0]                          core_arg_hsf,     // 24Q20
    input                                                   h_start,
    output reg                                              matrix_ram_read_en,
    input                                                   matrix_ram_read_rsp_en,
    input      [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] matrix_ram_read_rsp_pixel,
    output reg                                              matrix_ram_read_done = 1'd0,
    output reg                                              m_axis_scaler_valid  = 1'd0,
    output reg [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] m_axis_scaler_pixel,
    output reg [KERNEL_BITWIDTH-1 : 0]                      m_axis_scaler_h,
    output reg                                              m_axis_scaler_done   = 1'd0
);

/*******************************************************************************
* scaler down : 12 -> 4 , ex : KERNEL_MAX = 4
* read     hold : 0 0 1 1 1  1  1  1  1  1  1  1  1   1   1   1   0   0
* read     cnt  : 0 0 0 1 2  3  4  5  6  7  8  9  10  11  12  13  14  0
* repeat_en_next: _ _ _ _ _  1  _  _  _  _  _  _  _   _   _   _   _   _
* repeat_en     : _ _ _ _ _  1  1  1  1  1  1  1  1   1   1   1   1


* read rsp hold : 0 0 1 1 1  1  1  1  1  1  1  1  1   1   0   0
* read rsp cnt  : 0 0 0 1 2  3  4  5  6  7  8  9  10  11  12  0
* sf            : 0 0 0 3 3  3  6  6  6  9  9  9  12  12  12  0    (x = 12/4)
* output en     : 0 0 0 1 0  0  1  0  0  1  0  0  1   0   0   0
*******************************************************************************/


/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam H_TOTAL_MAX      = KERNEL_MAX + IMG_H_MAX;
localparam H_TOTAL_BITWIDTH = CLOG2(H_TOTAL_MAX);
localparam H_SF_BITWIDTH    = IMG_H_BITWIDTH + SF_FRAC_BITWIDTH;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg  [15 : 0]                        ctrl_shift        = 16'd0;
wire                                 rst;
wire                                 init;
// read
wire                                 repeat_start;
wire                                 repeat_done;
reg                                  repeat_hold         = 1'd0;
reg  [IMG_H_BITWIDTH-1 : 0]          repeat_addr         = {IMG_H_BITWIDTH{1'd0}};
reg  [H_SF_BITWIDTH-1 : 0]           repeat_sf_curr      = {H_SF_BITWIDTH{1'd0}};
reg  [H_SF_BITWIDTH-1 : 0]           repeat_sf_next      = {H_SF_BITWIDTH{1'd0}};
wire [IMG_H_BITWIDTH-1 : 0]          repeat_sf_int_curr;
wire [IMG_H_BITWIDTH-1 : 0]          repeat_sf_int_next;
wire [SF_FRAC_BITWIDTH-1 : 0]        repeat_sf_frac_curr;
wire [SF_FRAC_BITWIDTH-1 : 0]        repeat_sf_frac_next;
wire                                 repeat_mode;        // 0 = Dis repeat  1 = En repeat

// read rsp
wire                                 stride_start;
wire                                 stride_done;
reg                                  stride_hold     = 1'd0;
reg  [H_SF_BITWIDTH-1 : 0]           stride_sf       = {H_SF_BITWIDTH{1'd0}};
wire [IMG_H_BITWIDTH-1 : 0]          stride_sf_int;
wire [SF_FRAC_BITWIDTH-1 : 0]        stride_sf_frac;
wire                                 stride_mode;       // 0 = Dis stride  1 = En stride
reg  [IMG_H_BITWIDTH-1 : 0]          stride_addr_in  = {IMG_H_BITWIDTH{1'd0}};
reg  [IMG_H_BITWIDTH-1 : 0]          stride_addr_out = {IMG_H_BITWIDTH{1'd0}};


wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_00;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_10;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_20;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_30;

wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_01;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_11;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_21;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_31;

wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_02;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_12;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_22;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_32;

wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_03;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_13;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_23;
wire [PIXEL_BITWIDTH-1 : 0]          info_pixel_33;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
// control
always @ (posedge core_clk) begin
    if(core_rst) begin
        ctrl_shift <= 16'd0;
    end
    else begin
        ctrl_shift <= {ctrl_shift[14:0], h_start};
    end
end

assign rst          = ctrl_shift[0] | core_rst;
generate
    if(KERNEL_MAX == 4) begin
        assign init         = ctrl_shift[1] | ctrl_shift[2] | ctrl_shift[3];
        assign repeat_start = ctrl_shift[KERNEL_MAX-1];
        assign stride_start = ctrl_shift[KERNEL_MAX+MATRIX_DELAY];
    end
endgenerate

// The repeat signal is judged by the read counter
always @ (posedge core_clk) begin
    if(rst | repeat_done) begin
        repeat_hold <= 1'd0;
    end
    else if(repeat_start) begin
        repeat_hold <= 1'd1;
    end
end

always @ (posedge core_clk) begin
    if(repeat_start | repeat_hold) begin
        repeat_addr    <= repeat_addr + 1'd1;
        repeat_sf_curr <= repeat_sf_next;
        repeat_sf_next <= repeat_sf_next + core_arg_hsf;
    end
    else begin
        repeat_addr    <= {IMG_H_BITWIDTH{1'd0}};
        repeat_sf_curr <= {H_SF_BITWIDTH{1'd0}};
        repeat_sf_next <= {H_SF_BITWIDTH{1'd0}};
    end
end

assign {repeat_sf_int_curr, repeat_sf_frac_curr} = repeat_sf_curr;
assign {repeat_sf_int_next, repeat_sf_frac_next} = repeat_sf_next;
assign repeat_mode = (repeat_sf_int_curr == repeat_sf_int_next) ? 1'd1 : 1'd0;
assign repeat_done = (repeat_addr        == core_arg_img_src_h) ? 1'd1 : 1'd0;

// read
always @ (posedge core_clk) begin
    matrix_ram_read_en   <= init | (repeat_hold & (~repeat_mode));
end

// The stride signal is judged by the read rsp counter
always @ (posedge core_clk) begin
    if(rst | stride_done) begin
        stride_hold <= 1'd0;
    end
    else if(stride_start) begin
        stride_hold <= 1'd1;
    end
end

always @ (posedge core_clk) begin
    if(stride_hold) begin
        stride_addr_in <= stride_addr_in + 1'd1;
    end
    else begin
        stride_addr_in <= {IMG_H_BITWIDTH{1'd0}};
    end
end

assign {stride_sf_int, stride_sf_frac} = stride_sf;
assign stride_mode = (stride_addr_in  <  stride_sf_int)      ? 1'd1 : 1'd0;
assign stride_done = (stride_addr_out == core_arg_img_des_h) ? 1'd1 : 1'd0;

always @ (posedge core_clk) begin
    if(rst) begin
        stride_sf           <= {H_SF_BITWIDTH{1'd0}};
        stride_addr_out     <= {IMG_H_BITWIDTH{1'd0}};
        m_axis_scaler_valid <= 1'd0;
        m_axis_scaler_pixel <= matrix_ram_read_rsp_pixel;
    end
    else if(stride_hold & (~stride_mode)) begin
        stride_sf           <= stride_sf  + core_arg_hsf;
        stride_addr_out     <= stride_addr_out + 1'd1;
        m_axis_scaler_valid <= 1'd1;
        m_axis_scaler_pixel <= matrix_ram_read_rsp_pixel;
    end
    else begin
        m_axis_scaler_valid <= 1'd0;
    end
end

always @ (posedge core_clk) begin
    matrix_ram_read_done <= m_axis_scaler_valid & stride_done;
    m_axis_scaler_done   <= m_axis_scaler_valid & stride_done;
end

generate
    if(KERNEL_MAX == 4) begin
        always @ (posedge core_clk) begin
            if(stride_hold & (~stride_mode)) begin
                if(stride_sf_frac < (2**SF_FRAC_BITWIDTH/4*1)) begin
                    m_axis_scaler_h <= 4'd0;
                end
                else if(stride_sf_frac < (2**SF_FRAC_BITWIDTH/4*2)) begin
                    m_axis_scaler_h <= 4'd1;
                end
                else if(stride_sf_frac < (2**SF_FRAC_BITWIDTH/4*3)) begin
                    m_axis_scaler_h <= 4'd2;
                end
                else begin
                    m_axis_scaler_h <= 4'd3;
                end
            end
        end
    end
endgenerate

assign {
        info_pixel_33,
        info_pixel_23,
        info_pixel_13,
        info_pixel_03,

        info_pixel_32,
        info_pixel_22,
        info_pixel_12,
        info_pixel_02,

        info_pixel_31,
        info_pixel_21,
        info_pixel_11,
        info_pixel_01,

        info_pixel_30,
        info_pixel_20,
        info_pixel_10,
        info_pixel_00
        } = m_axis_scaler_pixel;

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule