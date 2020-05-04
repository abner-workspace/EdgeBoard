`timescale 1ns / 1ps
/****************************************************************
*   Auther : chengyang
*   Mail   : hn.cy@foxmail.com
*   Time   : 2018.08.19
*   Design : axi3_master_rd
*   Description :
*
****************************************************************/

module axi_read #(
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
    input                                          sys_clk,
    input                                          sys_rst,
    output reg                                     read_cmd_done = 1'd0,   //  read  channal    IDLE
    input                                          read_cmd_start,         //  read  channal    start
    input           [AXI_ADDR_BITWIDTH-1 : 0]      read_cmd_addr,          //  read  channal    baseaddr
    input           [AXI_ADDR_BITWIDTH-1 : 0]      read_cmd_len,           //  read  channal    len
    input                                          read_axis_ready,        //  read axis
    output                                         read_axis_valid,        //  read axis
    output          [AXI_DATA_BITWIDTH-1 : 0]      read_axis_data,         //  read axis
    output                                         read_axis_last,
// read addr channal
    output          [AXI_ID_BITWIDTH-1 : 0]        m_axi_arid,
    output reg      [AXI_ADDR_BITWIDTH-1 : 0]      m_axi_araddr = {AXI_ADDR_BITWIDTH{1'd0}},
    output reg      [AXI_LEN_BITWIDTH-1 : 0]       m_axi_arlen = {AXI_LEN_BITWIDTH{1'd0}},
    output          [AXI_SIZE_BITWIDTH-1 : 0]      m_axi_arsize,
    output          [AXI_BURST_BITWIDTH-1 : 0]     m_axi_arburst,
    output          [AXI_LOCK_BITWIDTH-1 : 0]      m_axi_arlock,
    output          [AXI_CACHE_BITWIDTH-1 : 0]     m_axi_arcache,
    output          [AXI_PROT_BITWIDTH-1 : 0]      m_axi_arprot,
    output          [AXI_QOS_BITWIDTH-1 : 0]       m_axi_arqos,
    output reg                                     m_axi_arvalid = 1'd0,
    input                                          m_axi_arready,

    input            [AXI_ID_BITWIDTH-1 : 0]       m_axi_rid,
    input            [AXI_DATA_BITWIDTH-1 : 0]     m_axi_rdata,
    input            [AXI_RESP_BITWIDTH-1 : 0]     m_axi_rresp,
    input                                          m_axi_rlast,
    input                                          m_axi_rvalid,
    output                                         m_axi_rready
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
reg                             done                  = 1'd0;    // write done
reg  [3 : 0]                    hold                  = 4'd0;    // calcu axi addr delay

reg                             target_enable         = 1'd0;
reg  [AXI_ADDR_BITWIDTH-1 : 0]  target_addr           = {(AXI_ADDR_BITWIDTH){1'd0}};
reg  [AXI_ADDR_BITWIDTH-1 : 0]  target_len            = {(AXI_ADDR_BITWIDTH){1'd0}};
reg  [AXI_LEN_BITWIDTH : 0]     calc_delat            = {(AXI_LEN_BITWIDTH +1){1'd0}};
reg  [AXI_LEN_BITWIDTH : 0]     calc_len              = {(AXI_LEN_BITWIDTH +1){1'd0}};
reg  [AXI_ADDR_BITWIDTH-1 : 0]  transfer_total        = {(AXI_ADDR_BITWIDTH){1'd0}};
reg  [AXI_ADDR_BITWIDTH-1 : 0]  transfer_total_cnt    = {(AXI_ADDR_BITWIDTH){1'd0}};
wire                            rlast;

/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
always @ (posedge sys_clk) begin
    if(sys_rst | transfer_done) begin
        read_cmd_done <= 1'd1;
    end
    else if(read_cmd_done & read_cmd_start) begin
        read_cmd_done <= 1'd0;
    end
end

always @ (posedge sys_clk) begin
    transfer_start <= read_cmd_done & read_cmd_start;
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
    transfer_addr_ok <= m_axi_arready & m_axi_arvalid;
    transfer_data_ok <= m_axi_rready  & m_axi_rvalid & m_axi_rlast;
    transfer_done    <= read_axis_ready & read_axis_valid & read_axis_last;
end

/*--------------------------------Calculate Addr and Len-------------------------------------*/
always @ (posedge sys_clk) begin
    if(read_cmd_start && read_cmd_done) begin
        target_addr <= {read_cmd_addr[AXI_ADDR_BITWIDTH-1 : 0+DATA_BYTE_LOG2],{DATA_BYTE_LOG2{1'd0}}};
        target_len  <=  read_cmd_len;
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
        m_axi_arvalid <= 1'd0;
    end
    else if(m_axi_arready & m_axi_arvalid) begin
        m_axi_arvalid <= 1'd0;
    end
    else if(target_enable & hold[3]) begin
        m_axi_arvalid <= 1'd1;
        m_axi_araddr  <= target_addr;
        m_axi_arlen   <= calc_len - 1'd1;
    end
end

/*-------------------------------- axi interface data parameter -------------------------------------*/
always @ (posedge sys_clk) begin
    if(transfer_start) begin
        transfer_total <= target_len - 1'd1;
    end
end

always @ (posedge sys_clk) begin
    if(sys_rst | transfer_start) begin
        transfer_total_cnt <= {AXI_ADDR_BITWIDTH{1'd0}};
    end
    else if(m_axi_rready & m_axi_rvalid) begin
        transfer_total_cnt <= transfer_total_cnt + 1'd1;
    end
end

assign rlast = (transfer_total_cnt == transfer_total) ? 1'd1 : 1'd0;

assign m_axi_rready    = read_axis_ready;
assign read_axis_valid = m_axi_rvalid;
assign read_axis_data  = m_axi_rdata;
assign read_axis_last  = rlast;

// default value
// ST_AXI
assign m_axi_arid    = ID;
assign m_axi_arsize  = (AXI_DATA_BITWIDTH == 32)  ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b010 :          // 4 BYTE
                       (AXI_DATA_BITWIDTH == 64)  ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b011 :          // 8 BYTE
                       (AXI_DATA_BITWIDTH == 128) ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b100 :          // 16 BYTE
                       (AXI_DATA_BITWIDTH == 256) ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b101 :          // 32 BYTE
                       (AXI_DATA_BITWIDTH == 512) ? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b110 :          // 64 BYTE
                       (AXI_DATA_BITWIDTH == 1024)? {AXI_SIZE_BITWIDTH{1'd0}} + 3'b101 : {AXI_SIZE_BITWIDTH{1'd0}} + 3'b100;  // 128 BYTE
assign m_axi_arburst = {AXI_BURST_BITWIDTH{1'd0}} + 1'd1;     // INCR
assign m_axi_arlock  = {AXI_LOCK_BITWIDTH{1'd0}};
assign m_axi_arcache = {AXI_CACHE_BITWIDTH{1'd0}}  + 4'b0011;   // {WA,RA,C,B} = Cannot tell cache and cannot cache
assign m_axi_arprot  = {AXI_PROT_BITWIDTH{1'd0}};
assign m_axi_arqos   = {AXI_QOS_BITWIDTH{1'd0}};

function integer CLOG2;
    input integer value;
    begin
        for(CLOG2 = 0; value > 0; CLOG2 = CLOG2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

endmodule
