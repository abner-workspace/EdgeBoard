`timescale 1ns / 1ps
/****************************************************************
*   Auther : chengyang
*   Mail   : hn.cy@foxmail.com
*   Time   : 2018.08.19
*   Design : axi3_master_rd
*   Description :
*
****************************************************************/

module axi_write #(
    parameter AXI_ID_BITWIDTH           = 4,
    parameter AXI_ADDR_BITWIDTH         = 30,
    parameter AXI_LEN_BITWIDTH          = 8,
    parameter AXI_SIZE_BITWIDTH         = 3,
    parameter AXI_BURST_BITWIDTH        = 2,
    parameter AXI_LOCK_BITWIDTH         = 1,
    parameter AXI_CACHE_BITWIDTH        = 4,
    parameter AXI_PROT_BITWIDTH         = 3,
    parameter AXI_QOS_BITWIDTH          = 4,
    parameter AXI_RESP_BITWIDTH         = 2,
    parameter AXI_DATA_BITWIDTH         = 128,
    parameter AXI_STRB_BITWIDTH         = AXI_DATA_BITWIDTH/8,
    parameter BURST_MAX                 = 256,                     // 16 or 256
    parameter ID                        = 0
)(
    input                                            sys_clk,
    input                                            sys_rst,
    output reg                                       write_cmd_done = 1'd0,
    input                                            write_cmd_start,
    input           [AXI_ADDR_BITWIDTH-1 : 0]        write_cmd_addr,
    input           [AXI_ADDR_BITWIDTH-1 : 0]        write_cmd_len,
    output                                           write_axis_ready,
    input                                            write_axis_valid,
    input           [AXI_DATA_BITWIDTH-1 : 0]        write_axis_data,
    input           [AXI_STRB_BITWIDTH-1 : 0]        write_axis_strb,
    input                                            write_axis_last,
// read addr channal
    output          [AXI_ID_BITWIDTH-1 : 0]          m_axi_awid,
    output reg      [AXI_ADDR_BITWIDTH-1 : 0]        m_axi_awaddr = {AXI_ADDR_BITWIDTH{1'd0}},
    output reg      [AXI_LEN_BITWIDTH-1 : 0]         m_axi_awlen = {AXI_LEN_BITWIDTH{1'd0}},
    output          [AXI_SIZE_BITWIDTH-1 : 0]        m_axi_awsize,
    output          [AXI_BURST_BITWIDTH-1 : 0]       m_axi_awburst,
    output          [AXI_LOCK_BITWIDTH-1 : 0]        m_axi_awlock,
    output          [AXI_CACHE_BITWIDTH-1 : 0]       m_axi_awcache,
    output          [AXI_PROT_BITWIDTH-1 : 0]        m_axi_awprot,
    output          [AXI_QOS_BITWIDTH-1 : 0]         m_axi_awqos,
    output reg                                       m_axi_awvalid = 1'd0,
    input                                            m_axi_awready,
    output          [AXI_ID_BITWIDTH-1 : 0]          m_axi_wid,
    output          [AXI_DATA_BITWIDTH-1 : 0]        m_axi_wdata,
    output          [AXI_STRB_BITWIDTH-1 : 0]        m_axi_wstrb,
    output                                           m_axi_wlast,
    output                                           m_axi_wvalid,
    input                                            m_axi_wready,
    input           [AXI_ID_BITWIDTH-1 : 0]          m_axi_bid,
    input           [AXI_RESP_BITWIDTH-1 : 0]        m_axi_bresp,
    input                                            m_axi_bvalid,
    output                                           m_axi_bready
);

/********************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam  DATA_BYTE_LOG2          = CLOG2(AXI_DATA_BITWIDTH/8)-1;
localparam  BOUNDARY_4KB            = 4*1024*8/AXI_DATA_BITWIDTH;
localparam  BOUNDARY_4KB_BITWIDTH   = CLOG2(BOUNDARY_4KB);
localparam  BURST_MAX_BITWIDTH      = CLOG2(BURST_MAX)-1;

/********************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg                             transfer_start        = 1'd0;
reg                             transfer_done         = 1'd0;
reg                             transfer_addr_ok      = 1'd0;
reg                             transfer_data_ok      = 1'd0;
reg                             transfer_resp_ok      = 1'd0;
reg  [3 : 0]                    hold                  = 4'd0;    // calcu axi addr delay

reg                             target_enable         = 1'd0;
reg  [AXI_ADDR_BITWIDTH-1 : 0]  target_addr           = {(AXI_ADDR_BITWIDTH){1'd0}};
reg  [AXI_ADDR_BITWIDTH-1 : 0]  target_len            = {(AXI_ADDR_BITWIDTH){1'd0}};
reg  [AXI_LEN_BITWIDTH : 0]     calc_delat            = {(AXI_LEN_BITWIDTH + 1){1'd0}};
reg  [AXI_LEN_BITWIDTH : 0]     calc_len              = {(AXI_LEN_BITWIDTH + 1){1'd0}};
reg                             first_transfer_enable = 1'd0;
reg                             transfer_data_enable  = 1'd0;
reg  [AXI_LEN_BITWIDTH-1 : 0]   transfer_len          = {(AXI_LEN_BITWIDTH){1'd0}};
reg  [AXI_LEN_BITWIDTH-1 : 0]   transfer_cnt          = {(AXI_LEN_BITWIDTH){1'd0}};
wire                            wlast;

/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
always @ (posedge sys_clk) begin
    if(sys_rst | transfer_done) begin
        write_cmd_done <= 1'd1;
    end
    else if(write_cmd_done & write_cmd_start) begin
        write_cmd_done <= 1'd0;
    end
end

always @ (posedge sys_clk) begin
    transfer_start <= write_cmd_done & write_cmd_start;
end

/*--------------------------------FSM Control Signal-------------------------------------*/
always @ (posedge sys_clk) begin
    if(sys_rst) begin
        hold <= 4'b0000;
    end
    else if(transfer_start | transfer_addr_ok) begin
        hold <= 4'b0001;
    end
    else begin
        hold <= {hold[2:0], 1'd0};
    end
end

always @ (posedge sys_clk) begin
    transfer_addr_ok <= m_axi_awready & m_axi_awvalid;
    transfer_data_ok <= m_axi_wready  & m_axi_wvalid & m_axi_wlast;
    transfer_resp_ok <= m_axi_bready  & m_axi_bvalid;
    transfer_done    <= write_axis_ready & write_axis_valid & write_axis_last;
end

/*--------------------------------Calculate Addr and Len-------------------------------------*/
always @ (posedge sys_clk) begin
    if(write_cmd_start && write_cmd_done) begin
        target_addr <= {write_cmd_addr[AXI_ADDR_BITWIDTH-1 : 0+DATA_BYTE_LOG2],{DATA_BYTE_LOG2{1'd0}}};
        target_len  <=  write_cmd_len;
    end
    else if(transfer_addr_ok) begin
        target_addr <= target_addr + {calc_len, {DATA_BYTE_LOG2{1'd0}}};
        target_len  <= target_len  - calc_len;
    end
end

// hold == 4'b0001
always @ (posedge sys_clk) begin
    if(BURST_MAX <= BOUNDARY_4KB) begin
        calc_delat <= BURST_MAX    - target_addr[DATA_BYTE_LOG2 + BURST_MAX_BITWIDTH - 1 : DATA_BYTE_LOG2];
    end
    else begin
        calc_delat <= BOUNDARY_4KB - target_addr[DATA_BYTE_LOG2 + BOUNDARY_4KB_BITWIDTH - 1 : DATA_BYTE_LOG2];
    end
end

// hold == 4'b0010
always @ (posedge sys_clk) begin
    if(calc_delat < target_len) begin
        calc_len <= calc_delat;
    end
    else begin
        calc_len <= target_len;
    end
end

// hold == 4'b0100
always @ (posedge sys_clk) begin
    target_enable <= (target_len == {AXI_ADDR_BITWIDTH{1'd0}}) ? 1'd0 : 1'd1;
end

/*-------------------------------- axi interface addr parameter -------------------------------------*/
always @ (posedge sys_clk) begin
    if(sys_rst) begin
        m_axi_awvalid <= 1'd0;
    end
    else if(m_axi_awready & m_axi_awvalid) begin
        m_axi_awvalid <= 1'd0;
    end
    else if(target_enable & hold[3]) begin
        m_axi_awvalid <= 1'd1;
        m_axi_awaddr  <= target_addr;
        m_axi_awlen   <= calc_len - 1'd1;
    end
end

/*-------------------------------- axi interface data parameter -------------------------------------*/
always @ (posedge sys_clk) begin
    if(sys_rst | transfer_start) begin
        first_transfer_enable <= 1'd1;
    end
    else if(hold[3]) begin
        first_transfer_enable <= 1'd0;
    end
end

always @ (posedge sys_clk) begin
    if(first_transfer_enable & hold[3]) begin
        transfer_len <= calc_len - 1'd1;
    end
    else if(m_axi_wready & m_axi_wvalid & m_axi_wlast) begin
        transfer_len <= (BURST_MAX <= BOUNDARY_4KB) ? (BURST_MAX - 1'd1) : (BOUNDARY_4KB - 1'd1);
    end
end

always @ (posedge sys_clk) begin
    if(sys_rst | transfer_start) begin
        transfer_cnt <= {(AXI_LEN_BITWIDTH){1'd0}};
    end
    else if(m_axi_wready & m_axi_wvalid) begin
        if(m_axi_wlast) begin
            transfer_cnt <= {(AXI_LEN_BITWIDTH){1'd0}};
        end
        else begin
            transfer_cnt <= transfer_cnt + 1'd1;
        end
    end
end

assign wlast = (transfer_cnt == transfer_len) ? 1'd1 : 1'd0;

always @ (posedge sys_clk) begin
    if(sys_rst | transfer_start | (write_axis_ready & write_axis_valid & write_axis_last)) begin
        transfer_data_enable <= 1'd0;
    end
    else if(transfer_addr_ok) begin
        transfer_data_enable <= 1'd1;
    end
end

// AXI3 WRITE DATA CHANNAL
assign write_axis_ready = transfer_data_enable & m_axi_wready;
assign m_axi_wvalid     = transfer_data_enable & write_axis_valid;
assign m_axi_wdata      = write_axis_data;
assign m_axi_wstrb      = write_axis_strb;
assign m_axi_wlast      = wlast | write_axis_last;

assign m_axi_bready     = 1'd1;

// default value
// ST_AXI
assign m_axi_awid    = {AXI_ID_BITWIDTH{1'd0}} + ID;

assign m_axi_awsize  = (AXI_DATA_BITWIDTH == 32)  ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b010 :          // 4 BYTE
                       (AXI_DATA_BITWIDTH == 64)  ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b011 :          // 8 BYTE
                       (AXI_DATA_BITWIDTH == 128) ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b100 :          // 16 BYTE
                       (AXI_DATA_BITWIDTH == 256) ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b101 :          // 32 BYTE
                       (AXI_DATA_BITWIDTH == 512) ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b110 :          // 64 BYTE
                       (AXI_DATA_BITWIDTH == 1024)? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b101 : {AXI_SIZE_BITWIDTH{1'd0}} + 3'b100;  // 128 BYTE
assign m_axi_awburst = {AXI_BURST_BITWIDTH{1'd0}} + 1'd1;      // INCR
assign m_axi_awlock  = {AXI_LOCK_BITWIDTH{1'd0}};
assign m_axi_awcache = {AXI_CACHE_BITWIDTH{1'd0}} + 4'b0011;   // {WA,RA,C,B} = Cannot tell cache and cannot cache
assign m_axi_awprot  = {AXI_PROT_BITWIDTH{1'd0}};
assign m_axi_awqos   = {AXI_QOS_BITWIDTH{1'd0}};
assign m_axi_wid     = {AXI_ID_BITWIDTH{1'd0}} + ID;

function integer CLOG2;
    input integer value;
    begin
        for(CLOG2 = 0; value > 0; CLOG2 = CLOG2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

// (* MARK_DEBUG="true", dont_touch="true"*)reg transfer_done_ila = 1'd0;
// always @ (posedge sys_clk) begin
//     if(sys_rst | transfer_start) begin
//         transfer_done_ila <= 1'd0;
//     end
//     else if(transfer_done) begin
//         transfer_done_ila <= 1'd1;
//     end
// end

// (* MARK_DEBUG="true", dont_touch="true"*)reg [AXI_ADDR_BITWIDTH-1 : 0]        write_num = {AXI_ADDR_BITWIDTH{1'd0}};
// always @ (posedge sys_clk) begin
//     if(sys_rst | transfer_start) begin
//         write_num <= {AXI_ADDR_BITWIDTH{1'd0}};
//     end
//     else if(write_axis_valid & write_axis_ready) begin
//         write_num <= write_num + 1'd1;
//     end
// end

// (* MARK_DEBUG="true", dont_touch="true"*)reg addr_err = 1'd0;
// always @ (posedge sys_clk) begin
//     if(m_axi_awready & m_axi_awvalid & (m_axi_awaddr < 32'h1000_0000)) begin
//         addr_err <= 1'd1;
//     end
// end

endmodule
