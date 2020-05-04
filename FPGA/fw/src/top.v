`timescale 1ns/1ps
/******************************************************************************
* Auther : CY
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2019-12-24 10:36:12
*           1.Create Project
*   @Modify By CY : 2019-12-24 10:40:08
*           1.Change GP HP define
*******************************************************************************/
`include "common.v"
module top(

);

/******************************************************************************
*
*   Define localparam
*
*******************************************************************************/
`define   GP_S_AXI_NUM           2
`define   GP_M_AXI_NUM           2
`define   HP_S_AXI_NUM           4
// S AXI GP
parameter GP_S_AXI_ID_BITWIDTH       = 12;
parameter GP_S_AXI_ADDR_BITWIDTH     = 32;
parameter GP_S_AXI_LEN_BITWIDTH      = 4;
parameter GP_S_AXI_SIZE_BITWIDTH     = 3;
parameter GP_S_AXI_BURST_BITWIDTH    = 2;
parameter GP_S_AXI_LOCK_BITWIDTH     = 2;
parameter GP_S_AXI_CACHE_BITWIDTH    = 4;
parameter GP_S_AXI_PROT_BITWIDTH     = 3;
parameter GP_S_AXI_QOS_BITWIDTH      = 4;
parameter GP_S_AXI_RESP_BITWIDTH     = 2;
parameter GP_S_AXI_DATA_BITWIDTH     = 32;
parameter GP_S_AXI_STRB_BITWIDTH     = GP_S_AXI_DATA_BITWIDTH/8;
// M AXI GP
parameter GP_M_AXI_ID_BITWIDTH       = 12;
parameter GP_M_AXI_ADDR_BITWIDTH     = 32;
parameter GP_M_AXI_LEN_BITWIDTH      = 4;
parameter GP_M_AXI_SIZE_BITWIDTH     = 3;
parameter GP_M_AXI_BURST_BITWIDTH    = 2;
parameter GP_M_AXI_LOCK_BITWIDTH     = 2;
parameter GP_M_AXI_CACHE_BITWIDTH    = 4;
parameter GP_M_AXI_PROT_BITWIDTH     = 3;
parameter GP_M_AXI_QOS_BITWIDTH      = 4;
parameter GP_M_AXI_RESP_BITWIDTH     = 2;
parameter GP_M_AXI_DATA_BITWIDTH     = 32;
parameter GP_M_AXI_STRB_BITWIDTH     = GP_M_AXI_DATA_BITWIDTH/8;
// S AXI HP
parameter HP_S_AXI_ID_BITWIDTH       = 12;
parameter HP_S_AXI_ADDR_BITWIDTH     = 32;
parameter HP_S_AXI_LEN_BITWIDTH      = 4;
parameter HP_S_AXI_SIZE_BITWIDTH     = 3;
parameter HP_S_AXI_BURST_BITWIDTH    = 2;
parameter HP_S_AXI_LOCK_BITWIDTH     = 2;
parameter HP_S_AXI_CACHE_BITWIDTH    = 4;
parameter HP_S_AXI_PROT_BITWIDTH     = 3;
parameter HP_S_AXI_QOS_BITWIDTH      = 4;
parameter HP_S_AXI_RESP_BITWIDTH     = 2;
parameter HP_S_AXI_DATA_BITWIDTH     = 64;
parameter HP_S_AXI_STRB_BITWIDTH     = HP_S_AXI_DATA_BITWIDTH/8;

/******************************************************************************
*
*   Define reg / wire
*
*******************************************************************************/
wire                                 PS_CLK;
wire                                 PS_RST;
wire    [GP_S_AXI_ID_BITWIDTH-1 : 0] GP_S_AXI_awid    [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_ADDR_BITWIDTH-1 : 0] GP_S_AXI_awaddr  [`GP_S_AXI_NUM-1 : 0];
wire   [GP_S_AXI_LEN_BITWIDTH-1 : 0] GP_S_AXI_awlen   [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_SIZE_BITWIDTH-1 : 0] GP_S_AXI_awsize  [`GP_S_AXI_NUM-1 : 0];
wire [GP_S_AXI_BURST_BITWIDTH-1 : 0] GP_S_AXI_awburst [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_LOCK_BITWIDTH-1 : 0] GP_S_AXI_awlock  [`GP_S_AXI_NUM-1 : 0];
wire [GP_S_AXI_CACHE_BITWIDTH-1 : 0] GP_S_AXI_awcache [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_PROT_BITWIDTH-1 : 0] GP_S_AXI_awprot  [`GP_S_AXI_NUM-1 : 0];
wire   [GP_S_AXI_QOS_BITWIDTH-1 : 0] GP_S_AXI_awqos   [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_awvalid [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_awready [`GP_S_AXI_NUM-1 : 0];
wire    [GP_S_AXI_ID_BITWIDTH-1 : 0] GP_S_AXI_wid     [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_DATA_BITWIDTH-1 : 0] GP_S_AXI_wdata   [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_STRB_BITWIDTH-1 : 0] GP_S_AXI_wstrb   [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_wlast   [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_wvalid  [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_wready  [`GP_S_AXI_NUM-1 : 0];
wire    [GP_S_AXI_ID_BITWIDTH-1 : 0] GP_S_AXI_bid     [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_RESP_BITWIDTH-1 : 0] GP_S_AXI_bresp   [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_bvalid  [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_bready  [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_PROT_BITWIDTH-1 : 0] GP_S_AXI_arprot  [`GP_S_AXI_NUM-1 : 0];
wire    [GP_S_AXI_ID_BITWIDTH-1 : 0] GP_S_AXI_arid    [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_ADDR_BITWIDTH-1 : 0] GP_S_AXI_araddr  [`GP_S_AXI_NUM-1 : 0];
wire   [GP_S_AXI_LEN_BITWIDTH-1 : 0] GP_S_AXI_arlen   [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_SIZE_BITWIDTH-1 : 0] GP_S_AXI_arsize  [`GP_S_AXI_NUM-1 : 0];
wire [GP_S_AXI_BURST_BITWIDTH-1 : 0] GP_S_AXI_arburst [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_LOCK_BITWIDTH-1 : 0] GP_S_AXI_arlock  [`GP_S_AXI_NUM-1 : 0];
wire [GP_S_AXI_CACHE_BITWIDTH-1 : 0] GP_S_AXI_arcache [`GP_S_AXI_NUM-1 : 0];
wire   [GP_S_AXI_QOS_BITWIDTH-1 : 0] GP_S_AXI_arqos   [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_arvalid [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_arready [`GP_S_AXI_NUM-1 : 0];
wire    [GP_S_AXI_ID_BITWIDTH-1 : 0] GP_S_AXI_rid     [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_DATA_BITWIDTH-1 : 0] GP_S_AXI_rdata   [`GP_S_AXI_NUM-1 : 0];
wire  [GP_S_AXI_RESP_BITWIDTH-1 : 0] GP_S_AXI_rresp   [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_rlast   [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_rvalid  [`GP_S_AXI_NUM-1 : 0];
wire                                 GP_S_AXI_rready  [`GP_S_AXI_NUM-1 : 0];

wire    [GP_M_AXI_ID_BITWIDTH-1 : 0] GP_M_AXI_awid    [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_ADDR_BITWIDTH-1 : 0] GP_M_AXI_awaddr  [`GP_M_AXI_NUM-1 : 0];
wire   [GP_M_AXI_LEN_BITWIDTH-1 : 0] GP_M_AXI_awlen   [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_SIZE_BITWIDTH-1 : 0] GP_M_AXI_awsize  [`GP_M_AXI_NUM-1 : 0];
wire [GP_M_AXI_BURST_BITWIDTH-1 : 0] GP_M_AXI_awburst [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_LOCK_BITWIDTH-1 : 0] GP_M_AXI_awlock  [`GP_M_AXI_NUM-1 : 0];
wire [GP_M_AXI_CACHE_BITWIDTH-1 : 0] GP_M_AXI_awcache [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_PROT_BITWIDTH-1 : 0] GP_M_AXI_awprot  [`GP_M_AXI_NUM-1 : 0];
wire   [GP_M_AXI_QOS_BITWIDTH-1 : 0] GP_M_AXI_awqos   [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_awvalid [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_awready [`GP_M_AXI_NUM-1 : 0];
wire    [GP_M_AXI_ID_BITWIDTH-1 : 0] GP_M_AXI_wid     [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_DATA_BITWIDTH-1 : 0] GP_M_AXI_wdata   [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_STRB_BITWIDTH-1 : 0] GP_M_AXI_wstrb   [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_wlast   [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_wvalid  [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_wready  [`GP_M_AXI_NUM-1 : 0];
wire    [GP_M_AXI_ID_BITWIDTH-1 : 0] GP_M_AXI_bid     [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_RESP_BITWIDTH-1 : 0] GP_M_AXI_bresp   [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_bvalid  [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_bready  [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_PROT_BITWIDTH-1 : 0] GP_M_AXI_arprot  [`GP_M_AXI_NUM-1 : 0];
wire    [GP_M_AXI_ID_BITWIDTH-1 : 0] GP_M_AXI_arid    [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_ADDR_BITWIDTH-1 : 0] GP_M_AXI_araddr  [`GP_M_AXI_NUM-1 : 0];
wire   [GP_M_AXI_LEN_BITWIDTH-1 : 0] GP_M_AXI_arlen   [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_SIZE_BITWIDTH-1 : 0] GP_M_AXI_arsize  [`GP_M_AXI_NUM-1 : 0];
wire [GP_M_AXI_BURST_BITWIDTH-1 : 0] GP_M_AXI_arburst [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_LOCK_BITWIDTH-1 : 0] GP_M_AXI_arlock  [`GP_M_AXI_NUM-1 : 0];
wire [GP_M_AXI_CACHE_BITWIDTH-1 : 0] GP_M_AXI_arcache [`GP_M_AXI_NUM-1 : 0];
wire   [GP_M_AXI_QOS_BITWIDTH-1 : 0] GP_M_AXI_arqos   [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_arvalid [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_arready [`GP_M_AXI_NUM-1 : 0];
wire    [GP_M_AXI_ID_BITWIDTH-1 : 0] GP_M_AXI_rid     [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_DATA_BITWIDTH-1 : 0] GP_M_AXI_rdata   [`GP_M_AXI_NUM-1 : 0];
wire  [GP_M_AXI_RESP_BITWIDTH-1 : 0] GP_M_AXI_rresp   [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_rlast   [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_rvalid  [`GP_M_AXI_NUM-1 : 0];
wire                                 GP_M_AXI_rready  [`GP_M_AXI_NUM-1 : 0];

wire    [HP_S_AXI_ID_BITWIDTH-1 : 0] HP_S_AXI_awid    [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_ADDR_BITWIDTH-1 : 0] HP_S_AXI_awaddr  [`HP_S_AXI_NUM-1 : 0];
wire   [HP_S_AXI_LEN_BITWIDTH-1 : 0] HP_S_AXI_awlen   [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_SIZE_BITWIDTH-1 : 0] HP_S_AXI_awsize  [`HP_S_AXI_NUM-1 : 0];
wire [HP_S_AXI_BURST_BITWIDTH-1 : 0] HP_S_AXI_awburst [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_LOCK_BITWIDTH-1 : 0] HP_S_AXI_awlock  [`HP_S_AXI_NUM-1 : 0];
wire [HP_S_AXI_CACHE_BITWIDTH-1 : 0] HP_S_AXI_awcache [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_PROT_BITWIDTH-1 : 0] HP_S_AXI_awprot  [`HP_S_AXI_NUM-1 : 0];
wire   [HP_S_AXI_QOS_BITWIDTH-1 : 0] HP_S_AXI_awqos   [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_awvalid [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_awready [`HP_S_AXI_NUM-1 : 0];
wire    [HP_S_AXI_ID_BITWIDTH-1 : 0] HP_S_AXI_wid     [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_DATA_BITWIDTH-1 : 0] HP_S_AXI_wdata   [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_STRB_BITWIDTH-1 : 0] HP_S_AXI_wstrb   [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_wlast   [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_wvalid  [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_wready  [`HP_S_AXI_NUM-1 : 0];
wire    [HP_S_AXI_ID_BITWIDTH-1 : 0] HP_S_AXI_bid     [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_RESP_BITWIDTH-1 : 0] HP_S_AXI_bresp   [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_bvalid  [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_bready  [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_PROT_BITWIDTH-1 : 0] HP_S_AXI_arprot  [`HP_S_AXI_NUM-1 : 0];
wire    [HP_S_AXI_ID_BITWIDTH-1 : 0] HP_S_AXI_arid    [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_ADDR_BITWIDTH-1 : 0] HP_S_AXI_araddr  [`HP_S_AXI_NUM-1 : 0];
wire   [HP_S_AXI_LEN_BITWIDTH-1 : 0] HP_S_AXI_arlen   [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_SIZE_BITWIDTH-1 : 0] HP_S_AXI_arsize  [`HP_S_AXI_NUM-1 : 0];
wire [HP_S_AXI_BURST_BITWIDTH-1 : 0] HP_S_AXI_arburst [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_LOCK_BITWIDTH-1 : 0] HP_S_AXI_arlock  [`HP_S_AXI_NUM-1 : 0];
wire [HP_S_AXI_CACHE_BITWIDTH-1 : 0] HP_S_AXI_arcache [`HP_S_AXI_NUM-1 : 0];
wire   [HP_S_AXI_QOS_BITWIDTH-1 : 0] HP_S_AXI_arqos   [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_arvalid [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_arready [`HP_S_AXI_NUM-1 : 0];
wire    [HP_S_AXI_ID_BITWIDTH-1 : 0] HP_S_AXI_rid     [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_DATA_BITWIDTH-1 : 0] HP_S_AXI_rdata   [`HP_S_AXI_NUM-1 : 0];
wire  [HP_S_AXI_RESP_BITWIDTH-1 : 0] HP_S_AXI_rresp   [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_rlast   [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_rvalid  [`HP_S_AXI_NUM-1 : 0];
wire                                 HP_S_AXI_rready  [`HP_S_AXI_NUM-1 : 0];

reg                                  clk = 0;
reg                                  rst = 1;
wire                                 pattern_m_axis_ready;
wire                                 pattern_m_axis_valid;
wire  [7 : 0]                        pattern_m_axis_data;
wire                                 pattern_m_axis_sof;
wire                                 pattern_m_axis_eof;
wire                                 pattern_m_axis_eol;
always #1 clk = ~clk;
reg       start = 0;
initial begin
    rst = 1;
    #100;
    rst = 0;

    #100 ;
    @ (posedge clk)  start <= 1'd0;
    @ (posedge clk)  start <= 1'd1;
    @ (posedge clk)  start <= 1'd1;
    @ (posedge clk)  start <= 1'd1;
    @ (posedge clk)  start <= 1'd1;
    @ (posedge clk)  start <= 1'd1;
    @ (posedge clk)  start <= 1'd0;
end

/******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/


image_pattern inst_image_pattern(
    .clk                     (clk),
    .rst                     (rst),
    .m_axis_ready            (pattern_m_axis_ready),
    .m_axis_valid            (pattern_m_axis_valid),
    .m_axis_data             (pattern_m_axis_data),
    .m_axis_sof              (pattern_m_axis_sof),
    .m_axis_eof              (pattern_m_axis_eof),
    .m_axis_eol              (pattern_m_axis_eol)
);

scaler inst_scaler(
    .s_clk                          (clk),
    .s_rst                          (rst),
    .s_axis_ready                   (pattern_m_axis_ready),
    .s_axis_valid                   (pattern_m_axis_valid),
    .s_axis_pixel                   (pattern_m_axis_data),
    .s_axis_sof                     (pattern_m_axis_sof),
    .s_axis_eol                     (pattern_m_axis_eol),
    .m_clk                          (clk),
    .m_rst                          (rst),
    .m_axis_ready                   (1),
    .m_axis_valid                   (),
    .m_axis_pixel                   (),
    .m_axis_sof                     (),
    .m_axis_eol                     (),
    .core_clk                       (clk),
    .core_rst                       (rst),
    .start                          (start)
);


endmodule
