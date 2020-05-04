`timescale 1ns/1ps
/****************************************************************
* Auther : CYabner
* Mail   : hn.cy@foxmail.com
* Time   : 2019.02.14
* Design :
****************************************************************/
`include "filesystem_common.v"

module filesystem_model
#(
    parameter AXI_ADDR_BITWIDTH  = 32,
    parameter AXI_DATA_BITWIDTH  = 64,
    parameter AXI_LEN_BITWIDTH   = 4,
    parameter AXI_STRB_BITWIDTH  = 8
)(
    input       clk,
    input       rst,
    // Write Channel
    output                                 s_axi_awready,
    input                                  s_axi_awvalid,
    input       [AXI_ADDR_BITWIDTH-1 : 0]  s_axi_awaddr,
    input       [AXI_LEN_BITWIDTH-1 : 0]   s_axi_awlen,

    output                                 s_axi_wready,
    input                                  s_axi_wvalid,
    input       [AXI_DATA_BITWIDTH-1 : 0]  s_axi_wdata,
    input       [AXI_STRB_BITWIDTH-1 : 0]  s_axi_wstrb,
    input                                  s_axi_wlast,
    // Read Channel
    output                                 s_axi_arready,
    input                                  s_axi_arvalid,
    input       [AXI_ADDR_BITWIDTH-1 : 0]  s_axi_araddr,
    input       [AXI_LEN_BITWIDTH-1 : 0]   s_axi_arlen,

    input                                  s_axi_rready,
    output                                 s_axi_rvalid,
    output      [AXI_DATA_BITWIDTH-1 : 0]  s_axi_rdata,
    output                                 s_axi_rlast
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
reg  [7 : 0]                    file_wr_num = 8'hFF; // FF = invalid
reg  [7 : 0]                    file_rd_num = 8'hFF; // FF = invalid

wire                            file_axi_awready [`TOTAL_FILE-1 : 0];
wire                            file_axi_awvalid [`TOTAL_FILE-1 : 0];
wire [AXI_ADDR_BITWIDTH-1 : 0]  file_axi_awaddr  [`TOTAL_FILE-1 : 0];
wire [AXI_LEN_BITWIDTH-1 : 0]   file_axi_awlen   [`TOTAL_FILE-1 : 0];

wire                            file_axi_wready  [`TOTAL_FILE-1 : 0];
wire                            file_axi_wvalid  [`TOTAL_FILE-1 : 0];
wire [AXI_DATA_BITWIDTH-1 : 0]  file_axi_wdata   [`TOTAL_FILE-1 : 0];
wire [AXI_STRB_BITWIDTH-1 : 0]  file_axi_wstrb   [`TOTAL_FILE-1 : 0];
wire                            file_axi_wlast   [`TOTAL_FILE-1 : 0];

wire                            file_axi_arready [`TOTAL_FILE-1 : 0];
wire                            file_axi_arvalid [`TOTAL_FILE-1 : 0];
wire [AXI_ADDR_BITWIDTH-1 : 0]  file_axi_araddr  [`TOTAL_FILE-1 : 0];
wire [AXI_LEN_BITWIDTH-1 : 0]   file_axi_arlen   [`TOTAL_FILE-1 : 0];

wire                            file_axi_rready  [`TOTAL_FILE-1 : 0];
wire                            file_axi_rvalid  [`TOTAL_FILE-1 : 0];
wire [AXI_DATA_BITWIDTH-1 : 0]  file_axi_rdata   [`TOTAL_FILE-1 : 0];
wire                            file_axi_rlast   [`TOTAL_FILE-1 : 0];

/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
/*--------------------- Arb addr ---------------------------------*/
always @ (posedge clk) begin
    if(rst | (s_axi_wready & s_axi_wvalid & s_axi_wlast)) begin
        file_wr_num <= 8'hFF;
    end
    else if(s_axi_awvalid & (s_axi_awaddr < `FILE_0_AXI_MAX_ADDR)) begin
        file_wr_num <= 8'd0;
    end
    else if(s_axi_awvalid & (s_axi_awaddr < `FILE_1_AXI_MAX_ADDR)) begin
        file_wr_num <= 8'd1;
    end
    // else if(s_axi_awvalid & (s_axi_awaddr < `FILE_2_AXI_MAX_ADDR)) begin
    //     file_wr_num <= 8'd2;
    // end
    // else if(s_axi_awvalid & (s_axi_awaddr < `FILE_3_AXI_MAX_ADDR)) begin
    //     file_wr_num <= 8'd3;
    // end
    // else if(s_axi_awvalid & (s_axi_awaddr < `FILE_4_AXI_MAX_ADDR)) begin
    //     file_wr_num <= 8'd4;
    // end
    // else if(s_axi_awvalid & (s_axi_awaddr < `FILE_5_AXI_MAX_ADDR)) begin
    //     file_wr_num <= 8'd5;
    // end
    // else if(s_axi_awvalid & (s_axi_awaddr < `FILE_6_AXI_MAX_ADDR)) begin
    //     file_wr_num <= 8'd6;
    // end
    // else if(s_axi_awvalid & (s_axi_awaddr < `FILE_7_AXI_MAX_ADDR)) begin
    //     file_wr_num <= 8'd7;
    // end
end

always @ (posedge clk) begin
    if(rst | (s_axi_rready & s_axi_rvalid & s_axi_rlast)) begin
        file_rd_num <= 8'hFF;
    end
    else if(s_axi_arvalid & (s_axi_araddr < `FILE_0_AXI_MAX_ADDR)) begin
        file_rd_num <= 8'd0;
    end
    else if(s_axi_arvalid & (s_axi_araddr < `FILE_1_AXI_MAX_ADDR)) begin
        file_rd_num <= 8'd1;
    end
    // else if(s_axi_arvalid & (s_axi_araddr < `FILE_2_AXI_MAX_ADDR)) begin
    //     file_rd_num <= 8'd2;
    // end
    // else if(s_axi_arvalid & (s_axi_araddr < `FILE_3_AXI_MAX_ADDR)) begin
    //     file_rd_num <= 8'd3;
    // end
    // else if(s_axi_arvalid & (s_axi_araddr < `FILE_4_AXI_MAX_ADDR)) begin
    //     file_rd_num <= 8'd4;
    // end
    // else if(s_axi_arvalid & (s_axi_araddr < `FILE_5_AXI_MAX_ADDR)) begin
    //     file_rd_num <= 8'd5;
    // end
    // else if(s_axi_arvalid & (s_axi_araddr < `FILE_6_AXI_MAX_ADDR)) begin
    //     file_rd_num <= 8'd6;
    // end
    // else if(s_axi_arvalid & (s_axi_araddr < `FILE_7_AXI_MAX_ADDR)) begin
    //     file_rd_num <= 8'd7;
    // end
end

/*--------------------- Write Channel ---------------------------------*/
assign s_axi_awready = (file_wr_num == 8'hFF) ? 1'd0 : file_axi_awready[file_wr_num] ;
assign s_axi_wready  = (file_wr_num == 8'hFF) ? 1'd0 : file_axi_wready[file_wr_num] ;

generate
    genvar a;
    for (a = 0; a < `TOTAL_FILE; a = a + 1) begin
        /*--------------------- write addr ---------------------------------*/
        assign file_axi_awvalid[a] = (a == file_wr_num) ? s_axi_awvalid : 1'd0;
        assign file_axi_awaddr [a] = (a == file_wr_num) ? s_axi_awaddr  : {AXI_ADDR_BITWIDTH{1'd0}};
        assign file_axi_awlen  [a] = (a == file_wr_num) ? s_axi_awlen   : {AXI_LEN_BITWIDTH{1'd0}};
        /*--------------------- write data ---------------------------------*/
        assign file_axi_wvalid [a] = (a == file_wr_num) ? s_axi_wvalid  : 1'd0;
        assign file_axi_wdata  [a] = (a == file_wr_num) ? s_axi_wdata   : {AXI_DATA_BITWIDTH{1'd0}};
        assign file_axi_wstrb  [a] = (a == file_wr_num) ? s_axi_wstrb   : {AXI_STRB_BITWIDTH{1'd0}};
        assign file_axi_wlast  [a] = (a == file_wr_num) ? s_axi_wlast   : 1'd0;
    end
endgenerate

/*--------------------- Read Channel ---------------------------------*/
assign s_axi_arready = (file_rd_num == 8'hFF) ? 1'd0 : file_axi_arready[file_rd_num] ;

generate
    genvar b;
    for (b = 0; b < `TOTAL_FILE; b = b + 1) begin
        /*--------------------- read addr ---------------------------------*/
        assign file_axi_arvalid[b] = (b == file_rd_num) ? s_axi_arvalid : 1'd0;
        assign file_axi_araddr [b] = (b == file_rd_num) ? s_axi_araddr  : {AXI_ADDR_BITWIDTH{1'd0}};
        assign file_axi_arlen  [b] = (b == file_rd_num) ? s_axi_arlen   : {AXI_LEN_BITWIDTH{1'd0}};
        /*--------------------- read data ---------------------------------*/
        assign file_axi_rready [b] = (b == file_rd_num) ? s_axi_rready  : 1'd0;
    end
endgenerate

assign s_axi_rvalid = (file_rd_num == 8'hFF) ? 1'd0                      : file_axi_rvalid[file_rd_num];
assign s_axi_rdata  = (file_rd_num == 8'hFF) ? {AXI_ADDR_BITWIDTH{1'd0}} : file_axi_rdata [file_rd_num] ;
assign s_axi_rlast  = (file_rd_num == 8'hFF) ? 1'd0                      : file_axi_rlast [file_rd_num] ;

generate
    genvar i;
    for (i = 0; i < `TOTAL_FILE; i = i + 1) begin : file
        filesystem_operate #(
            .FILE_ID            (i),
            .AXI_ADDR_BITWIDTH  (AXI_ADDR_BITWIDTH),
            .AXI_DATA_BITWIDTH  (AXI_DATA_BITWIDTH),
            .AXI_LEN_BITWIDTH   (AXI_LEN_BITWIDTH),
            .AXI_STRB_BITWIDTH  (AXI_STRB_BITWIDTH)
            ) inst_filesystem_operate (
            .clk                (clk),
            .rst                (rst),
            .s_axi_awready      (file_axi_awready[i]),
            .s_axi_awvalid      (file_axi_awvalid[i]),
            .s_axi_awaddr       (file_axi_awaddr [i]),
            .s_axi_awlen        (file_axi_awlen  [i]),
            .s_axi_wready       (file_axi_wready [i]),
            .s_axi_wvalid       (file_axi_wvalid [i]),
            .s_axi_wdata        (file_axi_wdata  [i]),
            .s_axi_wstrb        (file_axi_wstrb  [i]),
            .s_axi_wlast        (file_axi_wlast  [i]),
            .s_axi_arready      (file_axi_arready[i]),
            .s_axi_arvalid      (file_axi_arvalid[i]),
            .s_axi_araddr       (file_axi_araddr [i]),
            .s_axi_arlen        (file_axi_arlen  [i]),
            .s_axi_rready       (file_axi_rready [i]),
            .s_axi_rvalid       (file_axi_rvalid [i]),
            .s_axi_rdata        (file_axi_rdata  [i]),
            .s_axi_rlast        (file_axi_rlast  [i])
        );
    end
endgenerate


endmodule