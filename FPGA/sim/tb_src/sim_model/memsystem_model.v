`timescale 1ns / 1ps
/****************************************************************
* Auther : CYabner
* Mail   : 627833006@qq.com
* Time   : 2018.11.08
* Design :
* Description :
*       Based on seperate sync
****************************************************************/

module memsystem_model #(
    parameter  AXI_ID_BITWIDTH                 = 4,
    parameter  AXI_ADDR_BITWIDTH               = 30,
    parameter  AXI_LEN_BITWIDTH                = 8,
    parameter  AXI_SIZE_BITWIDTH               = 3,
    parameter  AXI_BURST_BITWIDTH              = 2,
    parameter  AXI_LOCK_BITWIDTH               = 1,
    parameter  AXI_CACHE_BITWIDTH              = 4,
    parameter  AXI_PROT_BITWIDTH               = 3,
    parameter  AXI_QOS_BITWIDTH                = 4,
    parameter  AXI_RESP_BITWIDTH               = 2,
    parameter  AXI_DATA_BITWIDTH               = 64,
    parameter  AXI_STRB_BITWIDTH               = AXI_DATA_BITWIDTH/8
)(
    output                                       sys_clk,
    output                                       sys_rst,
    // Slave Interface Write Address Ports
    // Slave Interface Write Data Ports
    // Slave Interface Write Response Ports
    // Slave Interface Read Address Ports
    // Slave Interface Read Data Ports
    input       [AXI_ID_BITWIDTH-1 : 0]          s_axi_awid    ,
    input       [AXI_ADDR_BITWIDTH-1 : 0]        s_axi_awaddr  ,
    input       [AXI_LEN_BITWIDTH-1 : 0]         s_axi_awlen   ,
    input       [AXI_SIZE_BITWIDTH-1 : 0]        s_axi_awsize  ,
    input       [AXI_BURST_BITWIDTH-1 : 0]       s_axi_awburst ,
    input       [AXI_LOCK_BITWIDTH-1 : 0]        s_axi_awlock  ,
    input       [AXI_CACHE_BITWIDTH-1 : 0]       s_axi_awcache ,
    input       [AXI_PROT_BITWIDTH-1 : 0]        s_axi_awprot  ,
    input       [AXI_QOS_BITWIDTH-1 : 0]         s_axi_awqos   ,
    input                                        s_axi_awvalid ,
    output                                       s_axi_awready ,

    input       [AXI_ID_BITWIDTH-1 : 0]          s_axi_wid     ,
    input       [AXI_DATA_BITWIDTH-1 : 0]        s_axi_wdata   ,
    input       [AXI_STRB_BITWIDTH-1 : 0]        s_axi_wstrb   ,
    input                                        s_axi_wlast   ,
    input                                        s_axi_wvalid  ,
    output                                       s_axi_wready  ,

    output      [AXI_ID_BITWIDTH-1 : 0]          s_axi_bid     ,
    output      [AXI_RESP_BITWIDTH-1 : 0]        s_axi_bresp   ,
    output reg                                   s_axi_bvalid  ,
    input                                        s_axi_bready  ,

    input       [AXI_PROT_BITWIDTH-1 : 0]        s_axi_arprot  ,
    input       [AXI_ID_BITWIDTH-1 : 0]          s_axi_arid    ,
    input       [AXI_ADDR_BITWIDTH-1 : 0]        s_axi_araddr  ,
    input       [AXI_LEN_BITWIDTH-1 : 0]         s_axi_arlen   ,
    input       [AXI_SIZE_BITWIDTH-1 : 0]        s_axi_arsize  ,
    input       [AXI_BURST_BITWIDTH-1 : 0]       s_axi_arburst ,
    input       [AXI_LOCK_BITWIDTH-1 : 0]        s_axi_arlock  ,
    input       [AXI_CACHE_BITWIDTH-1 : 0]       s_axi_arcache ,
    input       [AXI_QOS_BITWIDTH-1 : 0]         s_axi_arqos   ,
    input                                        s_axi_arvalid ,
    output                                       s_axi_arready ,
    output      [AXI_ID_BITWIDTH-1 : 0]          s_axi_rid     ,
    output      [AXI_DATA_BITWIDTH-1 : 0]        s_axi_rdata   ,
    output      [AXI_RESP_BITWIDTH-1 : 0]        s_axi_rresp   ,
    output                                       s_axi_rlast   ,
    output                                       s_axi_rvalid  ,
    input                                        s_axi_rready
);

reg clk = 0;
reg rst = 1;

always #2.5 clk = ~clk;
initial begin
    repeat(10) @ (posedge clk) rst <= 1'd1;
    repeat(10) @ (posedge clk) rst <= 1'd0;
end

assign sys_clk = clk;
assign sys_rst = rst;

assign s_axi_bid    = s_axi_wid;
assign s_axi_bresp  = {AXI_RESP_BITWIDTH{1'd0}};

assign s_axi_rid   = s_axi_bid;
assign s_axi_rresp = {AXI_RESP_BITWIDTH{1'd0}};

always @ (posedge clk) begin
    if(rst) begin
        s_axi_bvalid <= 1'd0;
    end
    else if(s_axi_wready & s_axi_wvalid & s_axi_wlast) begin
        s_axi_bvalid <= 1'd1;
    end
    else if(s_axi_bready & s_axi_bvalid) begin
        s_axi_bvalid <= 1'd0;
    end
end

filesystem_model #(
    .AXI_ADDR_BITWIDTH      (AXI_ADDR_BITWIDTH),
    .AXI_DATA_BITWIDTH      (AXI_DATA_BITWIDTH),
    .AXI_LEN_BITWIDTH       (AXI_LEN_BITWIDTH),
    .AXI_STRB_BITWIDTH      (AXI_STRB_BITWIDTH)
    ) inst_FileSystem_Model (
    .clk                    (clk),
    .rst                    (rst),
    .s_axi_awready          (s_axi_awready),
    .s_axi_awvalid          (s_axi_awvalid),
    .s_axi_awaddr           (s_axi_awaddr),
    .s_axi_awlen            (s_axi_awlen),
    .s_axi_wready           (s_axi_wready),
    .s_axi_wvalid           (s_axi_wvalid),
    .s_axi_wdata            (s_axi_wdata),
    .s_axi_wstrb            (s_axi_wstrb),
    .s_axi_wlast            (s_axi_wlast),
    .s_axi_arready          (s_axi_arready),
    .s_axi_arvalid          (s_axi_arvalid),
    .s_axi_araddr           (s_axi_araddr),
    .s_axi_arlen            (s_axi_arlen),
    .s_axi_rready           (s_axi_rready),
    .s_axi_rvalid           (s_axi_rvalid),
    .s_axi_rdata            (s_axi_rdata),
    .s_axi_rlast            (s_axi_rlast)
);

endmodule