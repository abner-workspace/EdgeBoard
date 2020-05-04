`timescale 1ns / 1ps
/****************************************************************
*   Auther : chengyang
*   Mail   : hn.cy@foxmail.com
*   Time   : 2019.09.06
*   Design :
*   Description :
*        PS write pL register
*    and PS read  PL register
*    Don't support busrt len, per transfer len = 1
****************************************************************/

module config_pl_register
#(
    parameter  GP_ID_BITWIDTH                 = 4,
    parameter  GP_ADDR_BITWIDTH               = 32,
    parameter  GP_LEN_BITWIDTH                = 8,
    parameter  GP_SIZE_BITWIDTH               = 3,
    parameter  GP_BURST_BITWIDTH              = 2,
    parameter  GP_LOCK_BITWIDTH               = 1,
    parameter  GP_CACHE_BITWIDTH              = 4,
    parameter  GP_PROT_BITWIDTH               = 3,
    parameter  GP_QOS_BITWIDTH                = 4,
    parameter  GP_RESP_BITWIDTH               = 2,
    parameter  GP_DATA_BITWIDTH               = 32,
    parameter  GP_STRB_BITWIDTH               = GP_DATA_BITWIDTH/8,
    parameter  REGISTER_BASEADDR              = 32'h0000_0000
)(
    input                                       sys_clk,
    input                                       sys_rst,

    input       [GP_ID_BITWIDTH-1 : 0]          s_axi_awid,
    input       [GP_ADDR_BITWIDTH-1 : 0]        s_axi_awaddr,
    input       [GP_LEN_BITWIDTH-1 : 0]         s_axi_awlen,
    input       [GP_SIZE_BITWIDTH-1 : 0]        s_axi_awsize,
    input       [GP_BURST_BITWIDTH-1 : 0]       s_axi_awburst,
    input       [GP_LOCK_BITWIDTH-1 : 0]        s_axi_awlock,
    input       [GP_CACHE_BITWIDTH-1 : 0]       s_axi_awcache,
    input       [GP_PROT_BITWIDTH-1 : 0]        s_axi_awprot,
    input       [GP_QOS_BITWIDTH-1 : 0]         s_axi_awqos,
    input                                       s_axi_awvalid,
    output reg                                  s_axi_awready = 1'd0,
    input       [GP_ID_BITWIDTH-1 : 0]          s_axi_wid,
    input       [GP_DATA_BITWIDTH-1 : 0]        s_axi_wdata,
    input       [GP_STRB_BITWIDTH-1 : 0]        s_axi_wstrb,
    input                                       s_axi_wlast,
    input                                       s_axi_wvalid,
    output reg                                  s_axi_wready = 1'd0,
    output reg  [GP_ID_BITWIDTH-1 : 0]          s_axi_bid = {GP_ID_BITWIDTH{1'd0}},
    output reg  [GP_RESP_BITWIDTH-1 : 0]        s_axi_bresp = {GP_RESP_BITWIDTH{1'd0}},
    output reg                                  s_axi_bvalid = 1'd0,
    input                                       s_axi_bready,
    input       [GP_PROT_BITWIDTH-1 : 0]        s_axi_arprot,
    input       [GP_ID_BITWIDTH-1 : 0]          s_axi_arid,
    input       [GP_ADDR_BITWIDTH-1 : 0]        s_axi_araddr,
    input       [GP_LEN_BITWIDTH-1 : 0]         s_axi_arlen,
    input       [GP_SIZE_BITWIDTH-1 : 0]        s_axi_arsize,
    input       [GP_BURST_BITWIDTH-1 : 0]       s_axi_arburst,
    input       [GP_LOCK_BITWIDTH-1 : 0]        s_axi_arlock,
    input       [GP_CACHE_BITWIDTH-1 : 0]       s_axi_arcache,
    input       [GP_QOS_BITWIDTH-1 : 0]         s_axi_arqos,
    input                                       s_axi_arvalid,
    output reg                                  s_axi_arready = 1'd0,
    output reg  [GP_ID_BITWIDTH-1 : 0]          s_axi_rid,
    output reg  [GP_DATA_BITWIDTH-1 : 0]        s_axi_rdata,
    output reg  [GP_RESP_BITWIDTH-1 : 0]        s_axi_rresp,
    output reg                                  s_axi_rlast,
    output reg                                  s_axi_rvalid = 1'd0,
    input                                       s_axi_rready,
// register
    output reg                                  upload_result_next = 1'd0,
    input                                       upload_result_en,
    input       [31 : 0]                        upload_result_addr,
    input       [31 : 0]                        upload_result_nbyte,
    output reg  [31 : 0]                        update_status,
    input       [31 : 0]                        set_arg_std,
    output reg                                  platform_init_done = 1'd0,
    output reg  [7 : 0]                         sdi_sync_std = 8'hFF,
    input       [31 : 0]                        sys_uhdsdi_status,
    output reg                                  sys_uhdsdi_soft_rst = 1'd0,
    output reg                                  sys_hdmi_soft_rst   = 1'd0,
    output reg  [31 : 0]                        sys_device_id1          = 32'hFFFF_FFFF,
    output reg  [31 : 0]                        sys_device_id2          = 32'hFFFF_FFFF,
    output reg  [31 : 0]                        sys_device_id3          = 32'hFFFF_FFFF,
    output reg  [31 : 0]                        sys_device_id4          = 32'hFFFF_FFFF,
    output reg  [31 : 0]                        sys_device_arg1         = 32'h0000_0000,
    input       [12*8-1 : 0]                    sys_device_mac

);

/***********************************************************************************************************************
*
*   Define reg / wire
*
***********************************************************************************************************************/
reg                           write_done = 1'd0;
reg                           write_addr_en = 1'd0;
reg  [GP_ADDR_BITWIDTH-1 : 0] write_addr = {GP_ADDR_BITWIDTH{1'd0}};
wire                          write_data_en;
reg  [GP_ID_BITWIDTH-1 : 0]   write_id = {GP_ID_BITWIDTH{1'd0}};
reg  [GP_DATA_BITWIDTH-1 : 0] write_data = {GP_DATA_BITWIDTH{1'd0}};
reg                           read_done = 1'd0;
reg                           read_addr_en = 1'd0;
reg  [GP_ADDR_BITWIDTH-1 : 0] read_addr = {GP_ADDR_BITWIDTH{1'd0}};
reg  [GP_ID_BITWIDTH-1 : 0]   read_id = {GP_ID_BITWIDTH{1'd0}};
reg                           read_data_en = 1'd0;
reg  [GP_DATA_BITWIDTH-1 : 0] read_data = {GP_DATA_BITWIDTH{1'd0}};

/*-------------------------------- -------------------------------- -------------------------------- ------------
*
*                             Register List Var
*
-------------------------------- -------------------------------- -------------------------------- ------------ */

/************************************************************************************************************************
*
*   RTL verilog
*
************************************************************************************************************************/
/*-------------------------------- -------------------------------- -------------------------------- ------------
*
*                             Code Change Region
*
-------------------------------- -------------------------------- -------------------------------- ------------ */
always @ (posedge sys_clk) begin
    if(write_data_en) begin
        case (write_addr)
            32'd4*3  : begin upload_result_next <= s_axi_wdata[0];  end    // down
            32'd4*5  : begin platform_init_done <= s_axi_wdata[0];  end
            32'd4*6  : begin update_status      <= s_axi_wdata;     end
            32'd4*7  : begin sdi_sync_std       <= s_axi_wdata[7:0];end
            32'd4*9  : begin sys_uhdsdi_soft_rst<= s_axi_wdata[0];  end
            32'd4*10 : begin sys_hdmi_soft_rst  <= s_axi_wdata[0];  end
            32'd4*11 : begin sys_device_id1     <= s_axi_wdata;     end
            32'd4*12 : begin sys_device_id2     <= s_axi_wdata;     end
            32'd4*13 : begin sys_device_id3     <= s_axi_wdata;     end
            32'd4*14 : begin sys_device_id4     <= s_axi_wdata;     end
            32'd4*15 : begin sys_device_arg1    <= s_axi_wdata;     end
            default  : begin end
        endcase
    end
    else begin
        upload_result_next <= 1'd0;
    end

    case(read_addr)
        32'd4*0  : begin s_axi_rdata <= {31'd0,upload_result_en};    end  // up
        32'd4*1  : begin s_axi_rdata <= upload_result_addr;          end
        32'd4*2  : begin s_axi_rdata <= upload_result_nbyte;         end
        32'd4*3  : begin s_axi_rdata <= 32'd0;                       end  // down
        32'd4*4  : begin s_axi_rdata <= set_arg_std;                 end
        32'd4*5  : begin s_axi_rdata <= {31'd0, platform_init_done}; end
        32'd4*6  : begin s_axi_rdata <= update_status;               end
        32'd4*7  : begin s_axi_rdata <= {24'd0, sdi_sync_std};       end
        32'd4*8  : begin s_axi_rdata <= sys_uhdsdi_status;           end
        32'd4*9  : begin s_axi_rdata <= {31'd0, sys_uhdsdi_soft_rst};end
        32'd4*10 : begin s_axi_rdata <= {31'd0, sys_hdmi_soft_rst};  end
        32'd4*11 : begin s_axi_rdata <= sys_device_id1 ;             end
        32'd4*12 : begin s_axi_rdata <= sys_device_id2 ;             end
        32'd4*13 : begin s_axi_rdata <= sys_device_id3 ;             end
        32'd4*14 : begin s_axi_rdata <= sys_device_id4 ;             end
        32'd4*15 : begin s_axi_rdata <= sys_device_arg1;             end
        32'd4*16 : begin s_axi_rdata <= sys_device_mac[32*1-1 : 32*0]; end  // mac
        32'd4*17 : begin s_axi_rdata <= sys_device_mac[32*2-1 : 32*1]; end  // mac
        32'd4*18 : begin s_axi_rdata <= sys_device_mac[32*3-1 : 32*2]; end  // mac

        default  : begin s_axi_rdata <= 32'd0;                       end
    endcase
end

/********************************************************************************************************************/













/*-------------------------------- -------------------------------- -------------------------------- -----------
*
*                                                           AXI OPERATE
*
-------------------------------- -------------------------------- -------------------------------- ----------- */
/*-------------------------------- WRITE -------------------------------*/
// write addr
always @ (posedge sys_clk) begin
    if(sys_rst | (s_axi_awready & s_axi_awvalid)) begin
        s_axi_awready <= 1'd0;
    end
    else if(write_done) begin
        s_axi_awready <= 1'd1;
    end
end

always @ (posedge sys_clk) begin
    if(s_axi_awready & s_axi_awvalid) begin
        write_id <= s_axi_awid;
    end
end

always @ (posedge sys_clk) begin
    write_addr_en <= s_axi_awready & s_axi_awvalid;
    if(s_axi_awready & s_axi_awvalid) begin
        write_addr <= s_axi_awaddr - REGISTER_BASEADDR;
    end
    else if(s_axi_wready & s_axi_wvalid) begin
        write_addr <= write_addr + GP_STRB_BITWIDTH;
    end
end

// write data
always @ (posedge sys_clk) begin
    if(sys_rst) begin
        s_axi_wready <= 1'd0;
    end
    else if(write_addr_en) begin
        s_axi_wready <= 1'd1;
    end
    else if(s_axi_wready & s_axi_wvalid & s_axi_wlast) begin
        s_axi_wready <= 1'd0;
    end
end

assign write_data_en = s_axi_wready & s_axi_wvalid;

// write resp
always @ (posedge sys_clk) begin
    if(sys_rst) begin
        s_axi_bvalid <= 1'd0;
    end
    else if(s_axi_wready & s_axi_wvalid & s_axi_wlast) begin
        s_axi_bid <= write_id;
        s_axi_bresp <= {GP_RESP_BITWIDTH{1'd0}};
        s_axi_bvalid <= 1'd1;
    end
    else if(s_axi_bready & s_axi_bvalid) begin
        s_axi_bvalid <= 1'd0;
    end
end

always @ (posedge sys_clk) begin
    write_done <= sys_rst | (s_axi_bready & s_axi_bvalid);
end


/*-------------------------------- READ  -------------------------------*/
// read addr
always @ (posedge sys_clk) begin
    if(sys_rst | (s_axi_arready & s_axi_arvalid)) begin
        s_axi_arready <= 1'd0;
    end
    else if(read_done) begin
        s_axi_arready <= 1'd1;
    end
end

always @ (posedge sys_clk) begin
    if(s_axi_arready & s_axi_arvalid) begin
        read_id <= s_axi_arid;
    end
end

always @ (posedge sys_clk) begin
    read_addr_en <= s_axi_arready & s_axi_arvalid;
    if(s_axi_arready & s_axi_arvalid) begin
        read_addr <= s_axi_araddr - REGISTER_BASEADDR;
    end
    else if(s_axi_rready & s_axi_rvalid) begin
        read_addr <= read_addr + GP_STRB_BITWIDTH;
    end
end

always @ (posedge sys_clk) begin
    if(sys_rst) begin
        s_axi_rvalid <= 1'd0;
    end
    else if(read_addr_en) begin
        s_axi_rvalid <= 1'd1;
        s_axi_rid <= read_id;
        s_axi_rresp <= {GP_RESP_BITWIDTH{1'd0}};
        s_axi_rlast <= 1'd1;
    end
    else if(s_axi_rready & s_axi_rvalid) begin
        s_axi_rvalid <= 1'd0;
    end
end

always @ (posedge sys_clk) begin
    read_done <= sys_rst | (s_axi_rready & s_axi_rvalid & s_axi_rlast);
end


endmodule
