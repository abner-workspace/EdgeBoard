`timescale 1 ns / 1ps

/****************************************************************
*   Auther : chengyang
*   Mail   : hn.cy@foxmail.com
*   Time   : 2018.08.19
*   Design : axi_master_rd_arb
*   Description :
*
*
****************************************************************/
module axi_read_arb #(
    parameter AXI_ADDR_BITWIDTH         = 29,
    parameter AXI_DATA_BITWIDTH         = 128,
    parameter ARB_NUM                   = 3
)(
    input                                        sys_clk,
    input                                        sys_rst,
// -------------------------------------------------------------------------------
    // read
    output reg [ARB_NUM*1-1 : 0]                 read_cmd_done = 1'd0,
    input      [ARB_NUM*1-1 : 0]                 read_cmd_start,
    input      [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] read_cmd_addr,
    input      [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] read_cmd_len,
    input      [ARB_NUM*1-1 : 0]                 read_axis_ready,
    output     [ARB_NUM*1-1 : 0]                 read_axis_valid,
    output     [ARB_NUM*AXI_DATA_BITWIDTH-1 : 0] read_axis_data,
    output     [ARB_NUM*1-1 : 0]                 read_axis_last,
// -------------------------------------------------------------------------------
    input                                        arb_read_cmd_done,           //  read  channal    IDLE
    output reg                                   arb_read_cmd_start,          //  read  channal    start
    output reg [AXI_ADDR_BITWIDTH-1 : 0]         arb_read_cmd_addr,           //  read  channal    baseaddr
    output reg [AXI_ADDR_BITWIDTH-1 : 0]         arb_read_cmd_len,            //  read  channal    size
    output                                       arb_read_axis_ready,        //  read axis
    input                                        arb_read_axis_valid,        //  read axis
    input      [AXI_DATA_BITWIDTH-1 : 0]         arb_read_axis_data,         //  read axis
    input                                        arb_read_axis_last          //  read axis
);

reg        run                   = 1'd0;
wire       hold;
reg [3:0]  hold_num              = 4'd0;
reg [3:0]  run_num               = 4'hF; // F = invalid
wire       start;
wire       done;
reg        arb_read_cmd_done_d1  = 1'd0;

always @ (posedge sys_clk) begin
    if(sys_rst) begin
        hold_num <= 4'd0;
    end
    else if((~run) & (~hold)) begin
        if(hold_num == (ARB_NUM-1)) begin
            hold_num <= 4'd0;
        end
        else begin
            hold_num <= hold_num + 1'd1;
        end
    end
end

assign hold = (read_cmd_start[hold_num] == 1'd1) ? 1'd1 : 1'd0;

always @ (posedge sys_clk) begin
    if(sys_rst | done) begin
        run <= 1'd0;
    end
    else if(hold == 1'd1) begin
        run <= 1'd1;
    end
end

assign start = hold & (~run);
generate
    genvar i;
    for (i = 0; i < ARB_NUM; i = i + 1) begin
        always @ (posedge sys_clk) begin
            if(sys_rst) begin
                read_cmd_done[i] <= 1'd0;
            end
            else if(i == hold_num) begin
                if(start) begin
                    read_cmd_done[i] <= 1'd1;
                end
                else if(read_cmd_start[i] & read_cmd_done[i]) begin
                    read_cmd_done[i] <= 1'd0;
                end
            end
            else begin
                read_cmd_done[i] <= 1'd0;
            end
        end
    end
endgenerate


// arb read cmd
always @(posedge sys_clk) begin
    if(sys_rst) begin
        arb_read_cmd_start <= 1'd0;
    end
    else if(run) begin
        if(arb_read_cmd_start & arb_read_cmd_done) begin
            arb_read_cmd_start <= 1'd0;
        end
        else if(hold_num == 4'd0) begin
            if(read_cmd_start[0] & read_cmd_done[0]) begin
                arb_read_cmd_start <= 1'd1;
                arb_read_cmd_addr  <= read_cmd_addr[AXI_ADDR_BITWIDTH*1-1:AXI_ADDR_BITWIDTH*0];
                arb_read_cmd_len   <= read_cmd_len [AXI_ADDR_BITWIDTH*1-1:AXI_ADDR_BITWIDTH*0];
            end
        end
        else if(hold_num == 4'd1) begin
            if(read_cmd_start[1] & read_cmd_done[1]) begin
                arb_read_cmd_start <= 1'd1;
                arb_read_cmd_addr  <= read_cmd_addr[AXI_ADDR_BITWIDTH*2-1:AXI_ADDR_BITWIDTH*1];
                arb_read_cmd_len   <= read_cmd_len [AXI_ADDR_BITWIDTH*2-1:AXI_ADDR_BITWIDTH*1];
            end
        end
        // else if(hold_num == 4'd2) begin
        //     if(read_cmd_start[2] & read_cmd_done[2]) begin
        //         arb_read_cmd_start <= 1'd1;
        //         arb_read_cmd_addr  <= read_cmd_addr[AXI_ADDR_BITWIDTH*3-1:AXI_ADDR_BITWIDTH*2];
        //         arb_read_cmd_len   <= read_cmd_len [AXI_ADDR_BITWIDTH*3-1:AXI_ADDR_BITWIDTH*2];
        //     end
        // end
        else begin
            arb_read_cmd_start <= 1'd0;
        end
    end
end

always @(posedge sys_clk) begin
    arb_read_cmd_done_d1 <= arb_read_cmd_done;
end

assign done = arb_read_cmd_done & (~arb_read_cmd_done_d1);

always @(posedge sys_clk) begin
    if(sys_rst) begin
        run_num <= 4'hF;
    end
    else if(start) begin
        run_num <= hold_num;
    end
    else if(done) begin
        run_num <= 4'hF;
    end
end

// arb read data
assign arb_read_axis_ready = (run_num == 4'd0) ? read_axis_ready[0] :
                             (run_num == 4'd1) ? read_axis_ready[1] :
                             // (run_num == 4'd2) ? read_axis_ready[2] :
                             1'd0;

generate
    genvar j;
    for (j = 0; j < ARB_NUM; j = j + 1)
    begin
        assign read_axis_valid[j]                                = (j == run_num) ? arb_read_axis_valid : 1'd0;

        assign read_axis_data[AXI_DATA_BITWIDTH*(j+1)-1:AXI_DATA_BITWIDTH*j] = arb_read_axis_data[AXI_DATA_BITWIDTH-1 : 0];

        assign read_axis_last[j]                                 = (j == run_num) ? arb_read_axis_last : 1'd0;
    end
endgenerate


endmodule
