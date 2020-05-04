`timescale 1ns/1ps
/******************************************************************************
* Auther : Abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2019-12-24 10:36:12
*             Create File
*   @Modify :
******************************************************************************/
module color_bar_progressive
#(
    parameter VH_BITWIDTH = 13
)(
    input                          clk,
    input                          rst,
// arg
    input      [VH_BITWIDTH-1 : 0] h_fp,
    input      [VH_BITWIDTH-1 : 0] h_sync,
    input      [VH_BITWIDTH-1 : 0] h_bp,
    input      [VH_BITWIDTH-1 : 0] h_active,
    input      [VH_BITWIDTH-1 : 0] h_total,
    input      [VH_BITWIDTH-1 : 0] v_fp,
    input      [VH_BITWIDTH-1 : 0] v_sync,
    input      [VH_BITWIDTH-1 : 0] v_bp,
    input      [VH_BITWIDTH-1 : 0] v_active,
    input      [VH_BITWIDTH-1 : 0] v_total,
// ctrl
    input                          ce,
    input      [VH_BITWIDTH-1 : 0] v_cnt,
    input      [VH_BITWIDTH-1 : 0] h_cnt,
// output
    output                         bt1120_f,
    output reg                     bt1120_vs = 1'd0,
    output reg                     bt1120_hs = 1'd0,
    output                         bt1120_de,
    output     [15 : 0]            bt1120_ycbcr
);

/************************************************************************************************************************
*   <BT1120 Timing Description>
*
*   <EAV>                                    <SAV>
*    -----FP-----||||||||SYNC||||||||------BP-----**********ACTIVE*********
*   ||      h_cnt :  0 1 2 3 ..... MAX
*   ||      v_cnt : 0
*   SYNC            1
*   ||              2
*   ||              ..
*   --              ..
*   --              ..
*   BP              MAX
*   --
*   --
*   **                                           ***************************
*   **                                           ***************************
*   ACTIVE                                       ***********IMAGE***********
*   **                                           ***************************
*   **                                           ***************************
*   --
*   --
*   FP
*   --
*   --
************************************************************************************************************************/

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
// generate BT1120 var
reg  [VH_BITWIDTH-1 : 0]           h_temp1                   = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           h_temp2                   = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_eav_point            = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sav_point            = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_active_h_start_point = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_active_h_stop_point  = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_active_v_start_point = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_active_v_stop_point  = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sync_h_start_point   = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sync_h_stop_point    = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sync_v_start_point   = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sync_v_stop_point    = {VH_BITWIDTH{1'd0}};

wire                               next_eav;
wire                               next_sav;
wire                               next_active_h_start;
wire                               next_active_h_stop;
wire                               next_active_v_start;
wire                               next_active_v_stop;
reg  [3 : 0]                       eav      = 4'd0;
reg  [3 : 0]                       sav      = 4'd0;
reg                                active_h = 1'd0;
reg                                active_v = 1'd0;
wire                               active_enable;

wire                               next_sync_h_start;
wire                               next_sync_h_stop;
wire                               next_sync_v_start;
wire                               next_sync_v_stop;

reg  [19 : 0]                      ycbcr;
/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
// BT1120 var
always @ (posedge clk) begin
    h_temp1                   <= h_fp + h_sync;
    h_temp2                   <= h_temp1 + h_bp;
    next_eav_point            <= h_total-1'd1;
    next_sav_point            <= h_temp2-3'd5;
    next_active_h_start_point <= h_temp2-1'd1;
    next_active_h_stop_point  <= h_total-1'd1;
    next_active_v_start_point <= v_sync +v_bp;
    next_active_v_stop_point  <= v_total-v_fp;
    next_sync_h_start_point   <= h_fp-1'd1;
    next_sync_h_stop_point    <= h_temp1-1'd1;
    next_sync_v_start_point   <= {VH_BITWIDTH{1'd0}};
    next_sync_v_stop_point    <= v_sync;
end

assign next_eav                = (h_cnt == next_eav_point            ) ? 1'd1 : 1'd0;
assign next_sav                = (h_cnt == next_sav_point            ) ? 1'd1 : 1'd0;
assign next_active_h_start     = (h_cnt == next_active_h_start_point ) ? 1'd1 : 1'd0;
assign next_active_h_stop      = (h_cnt == next_active_h_stop_point  ) ? 1'd1 : 1'd0;
assign next_active_v_start     = (v_cnt == next_active_v_start_point ) ? 1'd1 : 1'd0;
assign next_active_v_stop      = (v_cnt == next_active_v_stop_point  ) ? 1'd1 : 1'd0;
assign next_sync_h_start       = (h_cnt == next_sync_h_start_point   ) ? 1'd1 : 1'd0;
assign next_sync_h_stop        = (h_cnt == next_sync_h_stop_point    ) ? 1'd1 : 1'd0;
assign next_sync_v_start       = (v_cnt == next_sync_v_start_point   ) ? 1'd1 : 1'd0;
assign next_sync_v_stop        = (v_cnt == next_sync_v_stop_point    ) ? 1'd1 : 1'd0;

always @ (posedge clk) begin
    if(rst) begin
        eav      <= 4'd0;
        sav      <= 4'd0;
        active_h <= 1'd0;
        active_v <= 1'd0;
    end
    else if(ce) begin
        eav <= {eav[2:0], next_eav};
        sav <= {sav[2:0], next_sav};
        active_h <= (next_active_h_start) ? 1'd1 :
                    (next_active_h_stop)  ? 1'd0 :
                                            active_h;
        active_v <= (next_active_v_start) ? 1'd1 :
                    (next_active_v_stop)  ? 1'd0 :
                                            active_v;
    end
end

assign active_enable = active_h & active_v;

// bt1120
assign bt1120_f = 1'd0;

always @ (posedge clk) begin
    if(next_sync_h_start) begin
        if(next_sync_v_start) begin
            bt1120_vs <= 1'd1;
        end
        else if(next_sync_v_stop) begin
            bt1120_vs <= 1'd0;
        end
    end
end

always @ (posedge clk) begin
    if(next_sync_h_start) begin
        bt1120_hs <= 1'd1;
    end
    else if(next_sync_h_stop) begin
        bt1120_hs <= 1'd0;
    end
end

assign bt1120_de = active_enable;

// ycbcr => F H V
always @ (*) begin
    if(eav[0] | sav[0]) begin
        ycbcr = {2{10'h3FF}};
    end
    else if(eav[1] | eav[2] | sav[1] | sav[2]) begin
        ycbcr = {2{10'h000}};
    end
    else if(eav[3]) begin
        if(active_v) begin
            ycbcr = {2{10'h274}};
        end
        else begin
            ycbcr = {2{10'h2D8}};
        end
    end
    else if(sav[3]) begin
        if(active_v) begin
            ycbcr = {2{10'h200}};
        end
        else begin
            ycbcr = {2{10'h2AC}};
        end
    end
    else if(active_enable) begin
        ycbcr = {8'hAA,2'h0, 8'hAA,2'h0};
    end
    else begin
        ycbcr = {8'h80,2'h0, 8'h20,2'h0};
    end
end

// output
assign bt1120_ycbcr = {ycbcr[19:12], ycbcr[9:2]};

endmodule
