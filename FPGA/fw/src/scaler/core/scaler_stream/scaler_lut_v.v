`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* QQ     : 627833006
* Mail   : hn.cy@foxmail.com
* Csdn   : https://blog.csdn.net/weixin_46718879
* Description :
*   @Create : 2019-07-22
*
*   @Modify : 2020-04-06
*           Note : KERNEL_MAX >= 2
******************************************************************************/
module scaler_lut_v
#(
    parameter IMG_V_MAX        = 1080,
    parameter IMG_V_BITWIDTH   = CLOG2(IMG_V_MAX),
    parameter KERNEL_MAX       = 4,
    parameter KERNEL_BITWIDTH  = CLOG2(KERNEL_MAX),
    parameter SF_BITWIDTH      = 24, // 24Q20
    parameter SF_INT_BITWIDTH  = 4,
    parameter SF_FRAC_BITWIDTH = 20
)(
    input                              core_clk,
    input                              core_rst,
    input      [IMG_V_BITWIDTH-1 : 0]  core_arg_img_src_v,
    input      [IMG_V_BITWIDTH-1 : 0]  core_arg_img_des_v,
    input                              core_arg_mode,         // 0 = scaler down 1 = scaler up
    input      [SF_BITWIDTH-1 : 0]     core_arg_vsf,          // 24Q20
    input                              v_start,
    output reg                         matrix_ram_read_stride = 1'd0,
    output reg                         matrix_ram_read_repeat = 1'd0,
    output reg [KERNEL_BITWIDTH-1 : 0] m_axis_scaler_v        = {KERNEL_BITWIDTH{1'd0}}
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam V_SF_BITWIDTH = IMG_V_BITWIDTH + SF_FRAC_BITWIDTH;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg                           v_start_d1    = 1'd0; // delay for v_start
reg  [IMG_V_BITWIDTH-1 : 0]   v_cnt_curr    = {IMG_V_BITWIDTH{1'd0}};
reg  [IMG_V_BITWIDTH-1 : 0]   v_cnt_next    = {IMG_V_BITWIDTH{1'd0}};
reg  [V_SF_BITWIDTH-1 : 0]    vsf_addr_curr = {V_SF_BITWIDTH{1'd0}};
reg  [V_SF_BITWIDTH-1 : 0]    vsf_addr_next = {V_SF_BITWIDTH{1'd0}};
wire [IMG_V_BITWIDTH-1 : 0]   vsf_int_curr;
wire [IMG_V_BITWIDTH-1 : 0]   vsf_int_next;
wire [SF_FRAC_BITWIDTH-1 : 0] vsf_frac_curr;
wire [SF_FRAC_BITWIDTH-1 : 0] vsf_frac_next;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
/*******************************************************************************
* scaler down : 12 -> 4
* v cnt : 0 1 2 3 4 5 6 7 8 9 10 11
* stride: 0 1 1 0 1 1 0 1 1 0 1  1
* repeat: 0 0 0 0 0 0 0 0 0 0 0  0
* output: 0 * * 3 * * 6 * * 9 *  *
*
* scaler up : 4 -> 12
* v cnt : 0 0 0  1  1  1  2  2  2  3  3  3
* v addr: 0 x 2x 3x 4x 5x 6x 7x 8x 9x 10x 11x   (x = 4/12)
* stride: 0 0 0  0  0  0  0  0  0  0  0  0
* repeat: 1 1 0  1  1  0  1  1  0  1  1  0
* output: 0 0 0  1  1  1  2  2  2  3  3  3
********************************************************************************/

always @ (posedge core_clk) begin
    v_start_d1 <= v_start;
end

always @ (posedge core_clk) begin
    if(core_rst) begin
        v_cnt_curr <= {IMG_V_BITWIDTH{1'd0}};
        v_cnt_next <= {IMG_V_BITWIDTH{1'd0}};
    end
    else if(v_start & (~matrix_ram_read_repeat)) begin
        v_cnt_curr <= v_cnt_next;
        v_cnt_next <= v_cnt_next + 1'd1;
    end
end

always @ (posedge core_clk) begin
    if(core_rst) begin
        vsf_addr_curr <= {V_SF_BITWIDTH{1'd0}};
        vsf_addr_next <= {V_SF_BITWIDTH{1'd0}};
    end
    else if(v_start & (~matrix_ram_read_stride)) begin
        vsf_addr_curr <= vsf_addr_next;
        vsf_addr_next <= vsf_addr_next + core_arg_vsf;
    end
end

assign {vsf_int_curr, vsf_frac_curr} = vsf_addr_curr;
assign {vsf_int_next, vsf_frac_next} = vsf_addr_next;

always @ (posedge core_clk) begin
    if(core_rst) begin
        matrix_ram_read_stride <= 1'd0;
        matrix_ram_read_repeat <= 1'd0;
    end
    else if(v_start_d1) begin
        matrix_ram_read_repeat <= (vsf_int_next < v_cnt_curr); // scaler up
        matrix_ram_read_stride <= (vsf_int_curr > v_cnt_curr); // scaler down
    end
end

generate
    if(KERNEL_MAX == 4) begin
        always @ (posedge core_clk) begin
            if(v_start_d1) begin
                if(vsf_frac_curr < (2**SF_FRAC_BITWIDTH/4*1)) begin
                    m_axis_scaler_v <= 4'd0;
                end
                else if(vsf_frac_curr < (2**SF_FRAC_BITWIDTH/4*2)) begin
                    m_axis_scaler_v <= 4'd1;
                end
                else if(vsf_frac_curr < (2**SF_FRAC_BITWIDTH/4*3)) begin
                    m_axis_scaler_v <= 4'd2;
                end
                else begin
                    m_axis_scaler_v <= 4'd3;
                end
            end
        end
    end
endgenerate

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule