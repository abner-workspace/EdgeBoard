`timescale 1ns / 1ps
/****************************************************************
*   Auther : chengyang
*   Mail   : hn.cy@foxmail.com
*   Time   : 2018.10.13
*   Design :
*   Description :
****************************************************************/

module axi_arb_interface #(
    parameter  AXI_ID_BITWIDTH     = 4,
    parameter  AXI_ADDR_BITWIDTH   = 30,
    parameter  AXI_LEN_BITWIDTH    = 8,               // 1+N     = Lne
    parameter  AXI_SIZE_BITWIDTH   = 3,               // 2^N     = Byte
    parameter  AXI_BURST_BITWIDTH  = 2,               // 2'b01   = ADDR INCR
    parameter  AXI_LOCK_BITWIDTH   = 1,               // 0
    parameter  AXI_CACHE_BITWIDTH  = 4,               // 4'b0011 = {WA,RA,C,B} = Cannot tell cache and cannot cache
    parameter  AXI_PROT_BITWIDTH   = 3,               // 0
    parameter  AXI_QOS_BITWIDTH    = 4,               // 0
    parameter  AXI_RESP_BITWIDTH   = 2,
    parameter  AXI_DATA_BITWIDTH   = 128,
    parameter  AXI_STRB_BITWIDTH   = AXI_DATA_BITWIDTH/8,
    parameter  BURST_MAX           = 256,             // 16 or 256
    parameter  ARB_NUM             = 1,
    parameter  ID                  = 0
    )(
    input   sys_clk,
    input   sys_rst,
    // write
    output  [ARB_NUM*1-1 : 0]                 write_cmd_done,
    input   [ARB_NUM*1-1 : 0]                 write_cmd_start,
    input   [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] write_cmd_addr,
    input   [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] write_cmd_len,
    output  [ARB_NUM*1-1 : 0]                 write_axis_ready,
    input   [ARB_NUM*1-1 : 0]                 write_axis_valid,
    input   [ARB_NUM*AXI_DATA_BITWIDTH-1 : 0] write_axis_data,
    input   [ARB_NUM*AXI_STRB_BITWIDTH-1 : 0] write_axis_strb,
    input   [ARB_NUM*1-1 : 0]                 write_axis_last,
    // read
    output  [ARB_NUM*1-1 : 0]                 read_cmd_done,
    input   [ARB_NUM*1-1 : 0]                 read_cmd_start,
    input   [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] read_cmd_addr,
    input   [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] read_cmd_len,
    input   [ARB_NUM*1-1 : 0]                 read_axis_ready,
    output  [ARB_NUM*1-1 : 0]                 read_axis_valid,
    output  [ARB_NUM*AXI_DATA_BITWIDTH-1 : 0] read_axis_data,
    output  [ARB_NUM*1-1 : 0]                 read_axis_last,
    // interface
    output  [AXI_ID_BITWIDTH-1 : 0]           m_axi_awid,
    output  [AXI_ADDR_BITWIDTH-1 : 0]         m_axi_awaddr,
    output  [AXI_LEN_BITWIDTH-1 : 0]          m_axi_awlen,
    output  [AXI_SIZE_BITWIDTH-1 : 0]         m_axi_awsize,
    output  [AXI_BURST_BITWIDTH-1 : 0]        m_axi_awburst,
    output  [AXI_LOCK_BITWIDTH-1 : 0]         m_axi_awlock,
    output  [AXI_CACHE_BITWIDTH-1 : 0]        m_axi_awcache,
    output  [AXI_PROT_BITWIDTH-1 : 0]         m_axi_awprot,
    output  [AXI_QOS_BITWIDTH-1 : 0]          m_axi_awqos,
    output                                    m_axi_awvalid,
    input                                     m_axi_awready,
    output  [AXI_ID_BITWIDTH-1 : 0]           m_axi_wid,
    output  [AXI_DATA_BITWIDTH-1 : 0]         m_axi_wdata,
    output  [AXI_STRB_BITWIDTH-1 : 0]         m_axi_wstrb,
    output                                    m_axi_wlast,
    output                                    m_axi_wvalid,
    input                                     m_axi_wready,
    input   [AXI_ID_BITWIDTH-1 : 0]           m_axi_bid,
    input   [AXI_RESP_BITWIDTH-1 : 0]         m_axi_bresp,
    input                                     m_axi_bvalid,
    output                                    m_axi_bready,
    output  [AXI_ID_BITWIDTH-1 : 0]           m_axi_arid,
    output  [AXI_ADDR_BITWIDTH-1 : 0]         m_axi_araddr,
    output  [AXI_LEN_BITWIDTH-1 : 0]          m_axi_arlen,
    output  [AXI_SIZE_BITWIDTH-1 : 0]         m_axi_arsize,
    output  [AXI_BURST_BITWIDTH-1 : 0]        m_axi_arburst,
    output  [AXI_LOCK_BITWIDTH-1 : 0]         m_axi_arlock,
    output  [AXI_CACHE_BITWIDTH-1 : 0]        m_axi_arcache,
    output  [AXI_PROT_BITWIDTH-1 : 0]         m_axi_arprot,
    output  [AXI_QOS_BITWIDTH-1 : 0]          m_axi_arqos,
    output                                    m_axi_arvalid,
    input                                     m_axi_arready,
    input   [AXI_ID_BITWIDTH-1 : 0]           m_axi_rid,
    input   [AXI_DATA_BITWIDTH-1 : 0]         m_axi_rdata,
    input   [AXI_RESP_BITWIDTH-1 : 0]         m_axi_rresp,
    input                                     m_axi_rlast,
    input                                     m_axi_rvalid,
    output                                    m_axi_rready
);

wire                           arb_write_cmd_done;      //  write  channal    IDLE
wire                           arb_write_cmd_start;     //  write  channal    start
wire [AXI_ADDR_BITWIDTH-1 : 0] arb_write_cmd_addr;      //  write  channal    baseaddr
wire [AXI_ADDR_BITWIDTH-1 : 0] arb_write_cmd_len;       //  write  channal    size
wire                           arb_write_axis_ready;    //  write  axis
wire                           arb_write_axis_valid;    //  write  axis
wire [AXI_DATA_BITWIDTH-1 : 0] arb_write_axis_data;     //  write  axis
wire [AXI_STRB_BITWIDTH-1 : 0] arb_write_axis_strb;     //  write  axis
wire                           arb_write_axis_last;
// READ -------------------------------------------------------------------------------
wire                           arb_read_cmd_done;      //  read  channal    IDLE
wire                           arb_read_cmd_start;     //  read  channal    start
wire [AXI_ADDR_BITWIDTH-1 : 0] arb_read_cmd_addr;      //  read  channal    baseaddr
wire [AXI_ADDR_BITWIDTH-1 : 0] arb_read_cmd_len;       //  read  channal    size
wire                           arb_read_axis_ready;    //  read  axis
wire                           arb_read_axis_valid;    //  read  axis
wire [AXI_DATA_BITWIDTH-1 : 0] arb_read_axis_data;     //  read  axis
wire                           arb_read_axis_last;

/****************************************************************
*
*   WRITE DDR
*
****************************************************************/
generate
    if(ARB_NUM == 1) begin
        assign write_cmd_done        = arb_write_cmd_done;
        assign arb_write_cmd_start   = write_cmd_start;
        assign arb_write_cmd_addr    = write_cmd_addr;
        assign arb_write_cmd_len     = write_cmd_len;
        assign write_axis_ready      = arb_write_axis_ready;
        assign arb_write_axis_valid  = write_axis_valid;
        assign arb_write_axis_data   = write_axis_data;
        assign arb_write_axis_strb   = write_axis_strb;
        assign arb_write_axis_last   = write_axis_last;
    end
    else begin
        axi_write_arb #(
            .AXI_ADDR_BITWIDTH      (AXI_ADDR_BITWIDTH),
            .AXI_DATA_BITWIDTH      (AXI_DATA_BITWIDTH),
            .AXI_STRB_BITWIDTH      (AXI_STRB_BITWIDTH),
            .ARB_NUM                (ARB_NUM)
            ) inst_axi_write_arb (
            .sys_clk                (sys_clk),
            .sys_rst                (sys_rst),
            .write_cmd_done         (write_cmd_done),
            .write_cmd_start        (write_cmd_start),
            .write_cmd_addr         (write_cmd_addr),
            .write_cmd_len          (write_cmd_len),
            .write_axis_ready       (write_axis_ready),
            .write_axis_valid       (write_axis_valid),
            .write_axis_data        (write_axis_data),
            .write_axis_strb        (write_axis_strb),
            .write_axis_last        (write_axis_last),

            .arb_write_cmd_done     (arb_write_cmd_done),
            .arb_write_cmd_start    (arb_write_cmd_start),
            .arb_write_cmd_addr     (arb_write_cmd_addr),
            .arb_write_cmd_len      (arb_write_cmd_len),
            .arb_write_axis_ready   (arb_write_axis_ready),
            .arb_write_axis_valid   (arb_write_axis_valid),
            .arb_write_axis_data    (arb_write_axis_data),
            .arb_write_axis_strb    (arb_write_axis_strb),
            .arb_write_axis_last    (arb_write_axis_last)
        );
   end
endgenerate

axi_write #(
    .AXI_ID_BITWIDTH        (AXI_ID_BITWIDTH),
    .AXI_ADDR_BITWIDTH      (AXI_ADDR_BITWIDTH),
    .AXI_LEN_BITWIDTH       (AXI_LEN_BITWIDTH),
    .AXI_SIZE_BITWIDTH      (AXI_SIZE_BITWIDTH),
    .AXI_BURST_BITWIDTH     (AXI_BURST_BITWIDTH),
    .AXI_LOCK_BITWIDTH      (AXI_LOCK_BITWIDTH),
    .AXI_CACHE_BITWIDTH     (AXI_CACHE_BITWIDTH),
    .AXI_PROT_BITWIDTH      (AXI_PROT_BITWIDTH),
    .AXI_QOS_BITWIDTH       (AXI_QOS_BITWIDTH),
    .AXI_RESP_BITWIDTH      (AXI_RESP_BITWIDTH),
    .AXI_DATA_BITWIDTH      (AXI_DATA_BITWIDTH),
    .AXI_STRB_BITWIDTH      (AXI_STRB_BITWIDTH),
    .BURST_MAX              (BURST_MAX),
    .ID                     (ID)
    ) inst_axi_write (
    .sys_clk                (sys_clk),
    .sys_rst                (sys_rst),
    .write_cmd_done         (arb_write_cmd_done),
    .write_cmd_start        (arb_write_cmd_start),
    .write_cmd_addr         (arb_write_cmd_addr),
    .write_cmd_len          (arb_write_cmd_len),
    .write_axis_ready       (arb_write_axis_ready),
    .write_axis_valid       (arb_write_axis_valid),
    .write_axis_data        (arb_write_axis_data),
    .write_axis_strb        (arb_write_axis_strb),
    .write_axis_last        (arb_write_axis_last),
// write addr channal
    .m_axi_awid             (m_axi_awid),
    .m_axi_awaddr           (m_axi_awaddr),
    .m_axi_awlen            (m_axi_awlen),
    .m_axi_awsize           (m_axi_awsize),
    .m_axi_awburst          (m_axi_awburst),
    .m_axi_awlock           (m_axi_awlock),
    .m_axi_awcache          (m_axi_awcache),
    .m_axi_awprot           (m_axi_awprot),
    .m_axi_awqos            (m_axi_awqos),
    .m_axi_awvalid          (m_axi_awvalid),
    .m_axi_awready          (m_axi_awready),
// write data channl
    .m_axi_wid              (m_axi_wid),
    .m_axi_wdata            (m_axi_wdata),
    .m_axi_wstrb            (m_axi_wstrb),
    .m_axi_wlast            (m_axi_wlast),
    .m_axi_wvalid           (m_axi_wvalid),
    .m_axi_wready           (m_axi_wready),
// write response channal
    .m_axi_bid              (m_axi_bid),
    .m_axi_bresp            (m_axi_bresp),
    .m_axi_bvalid           (m_axi_bvalid),
    .m_axi_bready           (m_axi_bready)
);

/****************************************************************
*
*   READ DDR
*
****************************************************************/
generate
    if(ARB_NUM == 1) begin
        assign read_cmd_done        = arb_read_cmd_done;
        assign arb_read_cmd_start   = read_cmd_start;
        assign arb_read_cmd_addr    = read_cmd_addr;
        assign arb_read_cmd_len     = read_cmd_len;
        assign arb_read_axis_ready  = read_axis_ready;
        assign read_axis_valid      = arb_read_axis_valid;
        assign read_axis_data       = arb_read_axis_data;
        assign read_axis_last       = arb_read_axis_last;
    end
    else begin
        axi_read_arb #(
            .AXI_ADDR_BITWIDTH      (AXI_ADDR_BITWIDTH),
            .AXI_DATA_BITWIDTH      (AXI_DATA_BITWIDTH),
            .ARB_NUM                (ARB_NUM)
            ) inst_axi_read_arb (
            .sys_clk                (sys_clk),
            .sys_rst                (sys_rst),
            .read_cmd_done          (read_cmd_done),
            .read_cmd_start         (read_cmd_start),
            .read_cmd_addr          (read_cmd_addr),
            .read_cmd_len           (read_cmd_len),
            .read_axis_ready        (read_axis_ready),
            .read_axis_valid        (read_axis_valid),
            .read_axis_data         (read_axis_data),
            .read_axis_last         (read_axis_last),
            .arb_read_cmd_done      (arb_read_cmd_done),
            .arb_read_cmd_start     (arb_read_cmd_start),
            .arb_read_cmd_addr      (arb_read_cmd_addr),
            .arb_read_cmd_len       (arb_read_cmd_len),
            .arb_read_axis_ready    (arb_read_axis_ready),
            .arb_read_axis_valid    (arb_read_axis_valid),
            .arb_read_axis_data     (arb_read_axis_data),
            .arb_read_axis_last     (arb_read_axis_last)
        );
   end
endgenerate

axi_read #(
    .AXI_ID_BITWIDTH        (AXI_ID_BITWIDTH),
    .AXI_ADDR_BITWIDTH      (AXI_ADDR_BITWIDTH),
    .AXI_LEN_BITWIDTH       (AXI_LEN_BITWIDTH),
    .AXI_SIZE_BITWIDTH      (AXI_SIZE_BITWIDTH),
    .AXI_BURST_BITWIDTH     (AXI_BURST_BITWIDTH),
    .AXI_LOCK_BITWIDTH      (AXI_LOCK_BITWIDTH),
    .AXI_CACHE_BITWIDTH     (AXI_CACHE_BITWIDTH),
    .AXI_PROT_BITWIDTH      (AXI_PROT_BITWIDTH),
    .AXI_QOS_BITWIDTH       (AXI_QOS_BITWIDTH),
    .AXI_RESP_BITWIDTH      (AXI_RESP_BITWIDTH),
    .AXI_DATA_BITWIDTH      (AXI_DATA_BITWIDTH),
    .AXI_STRB_BITWIDTH      (AXI_STRB_BITWIDTH),
    .BURST_MAX              (BURST_MAX),
    .ID                     (ID)
    ) inst_axi_read (
    .sys_clk                (sys_clk),
    .sys_rst                (sys_rst),
    .read_cmd_done          (arb_read_cmd_done),
    .read_cmd_start         (arb_read_cmd_start),
    .read_cmd_addr          (arb_read_cmd_addr),
    .read_cmd_len           (arb_read_cmd_len),
    .read_axis_ready        (arb_read_axis_ready),
    .read_axis_valid        (arb_read_axis_valid),
    .read_axis_data         (arb_read_axis_data),
    .read_axis_last         (arb_read_axis_last),
// read addr channl
    .m_axi_arid             (m_axi_arid),
    .m_axi_araddr           (m_axi_araddr),
    .m_axi_arlen            (m_axi_arlen),
    .m_axi_arsize           (m_axi_arsize),
    .m_axi_arburst          (m_axi_arburst),
    .m_axi_arlock           (m_axi_arlock),
    .m_axi_arcache          (m_axi_arcache),
    .m_axi_arprot           (m_axi_arprot),
    .m_axi_arqos            (m_axi_arqos),
    .m_axi_arvalid          (m_axi_arvalid),
    .m_axi_arready          (m_axi_arready),
// read data channl
    .m_axi_rid              (m_axi_rid),
    .m_axi_rdata            (m_axi_rdata),
    .m_axi_rresp            (m_axi_rresp),
    .m_axi_rlast            (m_axi_rlast),
    .m_axi_rvalid           (m_axi_rvalid),
    .m_axi_rready           (m_axi_rready)
);



endmodule
