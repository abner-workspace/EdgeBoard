`timescale 1ns/1ps
/******************************************************************************
* Auther:abner
* E-mail:hn.cy@foxmail.com
* Description :
*   @Create   : 2020-1-3 13:50:59
*               The data is input in columns to form a square matrix output
******************************************************************************/

module scaler_matrix_combine
#(
    parameter  KERNEL_MAX           = 4,
    parameter  KERNEL_BITWIDTH      = CLOG2(KERNEL_MAX),
    parameter  RAM_NUM              = KERNEL_MAX+1,
    parameter  RAM_NUM_BITWIDTH     = CLOG2(RAM_NUM),
    parameter  RAM_DATA_BITWIDTH    = 8
)(
    input                                                      core_clk,
    input                                                      core_rst,
    output reg [RAM_NUM-1 : 0]                                 ram_sel                   = {RAM_NUM{1'd0}},
    input                                                      ram_read_rsp_en,
    input      [RAM_DATA_BITWIDTH*RAM_NUM-1 : 0]               ram_read_rsp_data,
    input                                                      matrix_ram_read_repeat,
    input                                                      matrix_ram_read_done,
    output reg                                                 matrix_ram_read_rsp_en    = 1'd0,
    output reg [RAM_DATA_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] matrix_ram_read_rsp_pixel = {(RAM_DATA_BITWIDTH*KERNEL_MAX*KERNEL_MAX){1'd0}}
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
/* matrix in pixel and column format */
reg  [RAM_NUM_BITWIDTH-1 : 0]               sel_0     = {RAM_NUM_BITWIDTH{1'd0}};
reg  [RAM_NUM_BITWIDTH-1 : 0]               sel_1     = {RAM_NUM_BITWIDTH{1'd0}};
reg  [RAM_NUM_BITWIDTH-1 : 0]               sel_2     = {RAM_NUM_BITWIDTH{1'd0}};
reg  [RAM_NUM_BITWIDTH-1 : 0]               sel_3     = {RAM_NUM_BITWIDTH{1'd0}};

wire [RAM_DATA_BITWIDTH-1 : 0]              reorder_pixel_0;
wire [RAM_DATA_BITWIDTH-1 : 0]              reorder_pixel_1;
wire [RAM_DATA_BITWIDTH-1 : 0]              reorder_pixel_2;
wire [RAM_DATA_BITWIDTH-1 : 0]              reorder_pixel_3;

/* column pixel sel */
reg  [RAM_NUM_BITWIDTH-1 : 0]               v_cnt = {RAM_NUM_BITWIDTH{1'd0}};

wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_00;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_10;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_20;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_30;

wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_01;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_11;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_21;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_31;

wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_02;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_12;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_22;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_32;

wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_03;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_13;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_23;
wire [RAM_DATA_BITWIDTH-1 : 0]              info_pixel_33;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
/* ram sel */
always @ (posedge core_clk) begin
    if(core_rst) begin
        v_cnt <= {RAM_NUM_BITWIDTH{1'd0}};
    end
    else if((~matrix_ram_read_repeat) & matrix_ram_read_done) begin
        if(v_cnt == KERNEL_MAX) begin
            v_cnt <= {RAM_NUM_BITWIDTH{1'd0}};
        end
        else begin
            v_cnt <= v_cnt + 1'd1;
        end
    end
end

generate
    if(KERNEL_MAX == 4) begin
        always @ (posedge core_clk) begin
            case (v_cnt)
                4'd0 :
                    begin
                        ram_sel        <= 5'b0_1111;
                        sel_0          <= 4'd0;
                        sel_1          <= 4'd1;
                        sel_2          <= 4'd2;
                        sel_3          <= 4'd3;
                    end
                4'd1 :
                    begin
                        ram_sel        <= 5'b1_1110;
                        sel_0          <= 4'd1;
                        sel_1          <= 4'd2;
                        sel_2          <= 4'd3;
                        sel_3          <= 4'd4;
                    end
                4'd2 :
                    begin
                        ram_sel        <= 5'b1_1101;
                        sel_0          <= 4'd2;
                        sel_1          <= 4'd3;
                        sel_2          <= 4'd4;
                        sel_3          <= 4'd0;
                    end
                4'd3 :
                    begin
                        ram_sel        <= 5'b1_1011;
                        sel_0          <= 4'd3;
                        sel_1          <= 4'd4;
                        sel_2          <= 4'd0;
                        sel_3          <= 4'd1;
                    end
                4'd4 :
                    begin
                        ram_sel        <= 5'b1_0111;
                        sel_0          <= 4'd4;
                        sel_1          <= 4'd0;
                        sel_2          <= 4'd1;
                        sel_3          <= 4'd2;
                    end
                default :
                    begin
                        ram_sel        <= 5'b0_0000;
                        sel_0          <= {RAM_NUM_BITWIDTH{1'd1}};
                        sel_1          <= {RAM_NUM_BITWIDTH{1'd1}};
                        sel_2          <= {RAM_NUM_BITWIDTH{1'd1}};
                        sel_3          <= {RAM_NUM_BITWIDTH{1'd1}};
                    end
            endcase
        end
    end
endgenerate

/* reorder pixel ata */
assign reorder_pixel_0 =(sel_0 == 4'd0) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*1-1 : RAM_DATA_BITWIDTH*0] :
                        (sel_0 == 4'd1) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*2-1 : RAM_DATA_BITWIDTH*1] :
                        (sel_0 == 4'd2) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*3-1 : RAM_DATA_BITWIDTH*2] :
                        (sel_0 == 4'd3) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*4-1 : RAM_DATA_BITWIDTH*3] :
                        (sel_0 == 4'd4) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*5-1 : RAM_DATA_BITWIDTH*4] :
                        {RAM_DATA_BITWIDTH{1'd0}};

assign reorder_pixel_1 =(sel_1 == 4'd0) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*1-1 : RAM_DATA_BITWIDTH*0] :
                        (sel_1 == 4'd1) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*2-1 : RAM_DATA_BITWIDTH*1] :
                        (sel_1 == 4'd2) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*3-1 : RAM_DATA_BITWIDTH*2] :
                        (sel_1 == 4'd3) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*4-1 : RAM_DATA_BITWIDTH*3] :
                        (sel_1 == 4'd4) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*5-1 : RAM_DATA_BITWIDTH*4] :
                        {RAM_DATA_BITWIDTH{1'd0}};

assign reorder_pixel_2 =(sel_2 == 4'd0) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*1-1 : RAM_DATA_BITWIDTH*0] :
                        (sel_2 == 4'd1) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*2-1 : RAM_DATA_BITWIDTH*1] :
                        (sel_2 == 4'd2) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*3-1 : RAM_DATA_BITWIDTH*2] :
                        (sel_2 == 4'd3) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*4-1 : RAM_DATA_BITWIDTH*3] :
                        (sel_2 == 4'd4) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*5-1 : RAM_DATA_BITWIDTH*4] :
                        {RAM_DATA_BITWIDTH{1'd0}};

assign reorder_pixel_3 =(sel_3 == 4'd0) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*1-1 : RAM_DATA_BITWIDTH*0] :
                        (sel_3 == 4'd1) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*2-1 : RAM_DATA_BITWIDTH*1] :
                        (sel_3 == 4'd2) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*3-1 : RAM_DATA_BITWIDTH*2] :
                        (sel_3 == 4'd3) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*4-1 : RAM_DATA_BITWIDTH*3] :
                        (sel_3 == 4'd4) ? ram_read_rsp_data[RAM_DATA_BITWIDTH*5-1 : RAM_DATA_BITWIDTH*4] :
                        {RAM_DATA_BITWIDTH{1'd0}};

always @ (posedge core_clk) begin
    matrix_ram_read_rsp_en    <= ram_read_rsp_en;
    matrix_ram_read_rsp_pixel <= {
                                    reorder_pixel_3, reorder_pixel_2, reorder_pixel_1, reorder_pixel_0,
                                    matrix_ram_read_rsp_pixel[RAM_DATA_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : RAM_DATA_BITWIDTH*4]
                                  };
end

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
        } = matrix_ram_read_rsp_pixel;

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule