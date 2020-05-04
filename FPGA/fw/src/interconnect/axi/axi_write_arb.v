`timescale 1 ns / 1ps
/****************************************************************
*   Auther : chengyang
*   Mail   : hn.cy@foxmail.com
*   Time   : 2018.08.19
*   Design : axi_master_wr_arb
*   Description :
****************************************************************/

module axi_write_arb #(
    parameter AXI_ADDR_BITWIDTH = 29,
    parameter AXI_DATA_BITWIDTH = 128,
    parameter AXI_STRB_BITWIDTH = 16,
    parameter ARB_NUM           = 3
)(
    input                                        sys_clk,
    input                                        sys_rst,
    // -------------------------------------------------------------------------------
    output reg [ARB_NUM*1-1 : 0]                 write_cmd_done = {ARB_NUM{1'd0}},                //  write  channal    IDLE
    input      [ARB_NUM*1-1 : 0]                 write_cmd_start,                                 //  write  channal    start
    input      [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] write_cmd_addr,                                  //  write  channal    baseaddr
    input      [ARB_NUM*AXI_ADDR_BITWIDTH-1 : 0] write_cmd_len,                                   //  write  channal    size
    output     [ARB_NUM*1-1 : 0]                 write_axis_ready,                                //  write axis
    input      [ARB_NUM*1-1 : 0]                 write_axis_valid,                                //  write axis
    input      [ARB_NUM*AXI_DATA_BITWIDTH-1 : 0] write_axis_data,                                 //  write axis
    input      [ARB_NUM*AXI_STRB_BITWIDTH-1 : 0] write_axis_strb,                                 //  write axis
    input      [ARB_NUM*1-1 : 0]                 write_axis_last,                                 //  write axis
    // -------------------------------------------------------------------------------
    input                                        arb_write_cmd_done,                              //  write  channal    IDLE
    output reg                                   arb_write_cmd_start = 1'd0,                      //  write  channal    start
    output reg [AXI_ADDR_BITWIDTH-1 : 0]         arb_write_cmd_addr = {AXI_ADDR_BITWIDTH{1'd0}},  //  write  channal    baseaddr
    output reg [AXI_ADDR_BITWIDTH-1 : 0]         arb_write_cmd_len = {AXI_ADDR_BITWIDTH{1'd0}},   //  write  channal    size
    input                                        arb_write_axis_ready,                            //  write axis
    output                                       arb_write_axis_valid,                            //  write axis
    output     [AXI_DATA_BITWIDTH-1 : 0]         arb_write_axis_data,                             //  write axis
    output     [AXI_STRB_BITWIDTH-1 : 0]         arb_write_axis_strb,                             //  write axis
    output                                       arb_write_axis_last                              //  write axis
);

reg        run                   = 1'd0;
wire       hold;
reg [3:0]  hold_num              = 4'd0;
reg [3:0]  run_num               = 4'hF; // F = invalid
wire       start;
wire       done;
reg        arb_write_cmd_done_d1 = 1'd0;
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

assign hold = (write_cmd_start[hold_num] == 1'd1) ? 1'd1 : 1'd0;

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
                write_cmd_done[i] <= 1'd0;
            end
            else if(i == hold_num) begin
                if(start) begin
                    write_cmd_done[i] <= 1'd1;
                end
                else if(write_cmd_start[i] & write_cmd_done[i]) begin
                    write_cmd_done[i] <= 1'd0;
                end
            end
            else begin
                write_cmd_done[i] <= 1'd0;
            end
        end
    end
endgenerate

// arb write cmd
always @(posedge sys_clk) begin
    if(sys_rst) begin
        arb_write_cmd_start <= 1'd0;
    end
    else if(run) begin
        if(arb_write_cmd_start & arb_write_cmd_done) begin
            arb_write_cmd_start <= 1'd0;
        end
        else if(hold_num == 4'd0) begin
            if(write_cmd_start[0] & write_cmd_done[0]) begin
                arb_write_cmd_start <= 1'd1;
                arb_write_cmd_addr  <= write_cmd_addr[AXI_ADDR_BITWIDTH*1-1:AXI_ADDR_BITWIDTH*0];
                arb_write_cmd_len   <= write_cmd_len [AXI_ADDR_BITWIDTH*1-1:AXI_ADDR_BITWIDTH*0];
            end
        end
        else if(hold_num == 4'd1) begin
            if(write_cmd_start[1] & write_cmd_done[1]) begin
                arb_write_cmd_start <= 1'd1;
                arb_write_cmd_addr  <= write_cmd_addr[AXI_ADDR_BITWIDTH*2-1:AXI_ADDR_BITWIDTH*1];
                arb_write_cmd_len   <= write_cmd_len [AXI_ADDR_BITWIDTH*2-1:AXI_ADDR_BITWIDTH*1];
            end
        end
        // else if(hold_num == 4'd2) begin
        //     if(write_cmd_start[2] & write_cmd_done[2]) begin
        //         arb_write_cmd_start <= 1'd1;
        //         arb_write_cmd_addr  <= write_cmd_addr[AXI_ADDR_BITWIDTH*3-1:AXI_ADDR_BITWIDTH*2];
        //         arb_write_cmd_len   <= write_cmd_len [AXI_ADDR_BITWIDTH*3-1:AXI_ADDR_BITWIDTH*2];
        //     end
        // end
        else begin
            arb_write_cmd_start <= 1'd0;
        end
    end
end

always @(posedge sys_clk) begin
    arb_write_cmd_done_d1 <= arb_write_cmd_done;
end

assign done = arb_write_cmd_done & (~arb_write_cmd_done_d1);

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

// arb write data

assign arb_write_axis_data  = (run_num == 4'd0) ? write_axis_data[AXI_DATA_BITWIDTH*1-1:AXI_DATA_BITWIDTH*0]  :
                              (run_num == 4'd1) ? write_axis_data[AXI_DATA_BITWIDTH*2-1:AXI_DATA_BITWIDTH*1]  :
                              // (hold_num == 4'd2) ? write_axis_data[AXI_DATA_BITWIDTH*3-1:AXI_DATA_BITWIDTH*2]  :
                              {AXI_DATA_BITWIDTH{1'd0}};

assign arb_write_axis_strb  = (run_num == 4'd0) ? write_axis_strb[AXI_STRB_BITWIDTH*1-1:AXI_STRB_BITWIDTH*0]  :
                              (run_num == 4'd1) ? write_axis_strb[AXI_STRB_BITWIDTH*2-1:AXI_STRB_BITWIDTH*1]  :
                              // (hold_num == 4'd2) ? write_axis_strb[AXI_STRB_BITWIDTH*3-1:AXI_STRB_BITWIDTH*2]  :
                              {AXI_STRB_BITWIDTH{1'd0}};

assign arb_write_axis_valid = (run_num == 4'd0) ? write_axis_valid[0] :
                              (run_num == 4'd1) ? write_axis_valid[1] :
                              // (run_num == 4'd2) ? write_axis_valid[2] :
                              1'd0 ;

assign arb_write_axis_last  = (run_num == 4'd0) ? write_axis_last[0] :
                              (run_num == 4'd1) ? write_axis_last[1] :
                              // (run_num == 4'd2) ? write_axis_last[2] :
                              1'd0 ;

generate
    genvar j;
    for (j = 0; j < ARB_NUM; j = j + 1)
    begin
        assign write_axis_ready[j] = (j == run_num) ? arb_write_axis_ready : 1'd0;
    end
endgenerate


endmodule