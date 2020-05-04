`timescale 1ns/1ps
/******************************************************************************
* Auther : Abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2019-12-24 10:36:12
*             Create File
*   @Modify :
******************************************************************************/
module color_bar_interlaced
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
    input      [VH_BITWIDTH-1 : 0] extra_v_fp,
    input      [VH_BITWIDTH-1 : 0] extra_v_sync,
    input      [VH_BITWIDTH-1 : 0] extra_v_bp,
    input      [VH_BITWIDTH-1 : 0] extra_v_active,
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
*   F0 SYNC         1
*   ||              2
*   ||              ..
*   --              ..
*   --              ..
*   F0 BP           MAX
*   --
*   --
*   **                                             ***************************
*   **                                             ***************************
*   F0 ACTIVE                                      ***********IMAGE***********
*   **                                             ***************************
*   **                                             ***************************
*   --
*   --
*   F0 FP
*   --
*   --
****************************************************************************************************
*   ||
*   ||
*   F1 SYNC
*   ||
*   ||
*   --
*   --
*   F1 BP
*   --
*   --
*   **                                            ***************************
*   **                                            ***************************
*   F1 ACTIVE                                     ***********IMAGE***********
*   **                                            ***************************
*   **                                            ***************************
*   --
*   --
*   F1 FP
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
reg  [VH_BITWIDTH-1 : 0]           h_temp1                      = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           v_temp1                      = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           v_temp2                      = {VH_BITWIDTH{1'd0}};

reg  [VH_BITWIDTH-1 : 0]           field_f0_start_point         = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           field_f1_start_point         = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_eav_point               = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sav_point               = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_active_h_start_point    = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_active_h_stop_point     = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f0_active_v_start_point = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f0_active_v_stop_point  = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f1_active_v_start_point = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f1_active_v_stop_point  = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sync_h_start_point      = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_sync_h_stop_point       = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_h_f1_half_point_point   = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f0_sync_v_start_point   = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f0_sync_v_stop_point    = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f1_sync_v_start_point   = {VH_BITWIDTH{1'd0}};
reg  [VH_BITWIDTH-1 : 0]           next_f1_sync_v_stop_point    = {VH_BITWIDTH{1'd0}};


wire                               next_eav;
wire                               next_sav;
wire                               next_active_h_start;
wire                               next_active_h_stop;
wire                               next_f0_active_v_start;
wire                               next_f0_active_v_stop;
wire                               next_f1_active_v_start;
wire                               next_f1_active_v_stop;
reg                                field = 1'd0;
reg  [3 : 0]                       eav = 4'd0;
reg  [3 : 0]                       sav = 4'd0;
reg                                active_h = 1'd0;
reg                                active_v = 1'd0;
wire                               active_enable;
reg  [19 : 0]                      ycbcr;

wire                               next_sync_h_start;
wire                               next_sync_h_stop;
wire                               next_f0_sync_v_start;
wire                               next_f0_sync_v_stop;
wire                               next_f1_sync_v_start;
wire                               next_f1_sync_v_stop;
wire                               next_h_f1_half_point;
/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
// BT1120
// BT1120
always @ (posedge clk) begin
    h_temp1 <= h_fp + h_sync;
    v_temp1 <= v_sync + v_bp;
    v_temp2 <= extra_v_sync + extra_v_bp;

    field_f0_start_point         <= {VH_BITWIDTH{1'd0}};
    field_f1_start_point         <= v_temp1 + v_active + v_fp;
    next_eav_point               <= h_total-1'd1;
    next_sav_point               <= h_temp1 + h_bp-3'd5;
    next_active_h_start_point    <= h_temp1 + h_bp-1'd1;
    next_active_h_stop_point     <= h_total-1'd1;
    next_f0_active_v_start_point <= v_temp1;
    next_f0_active_v_stop_point  <= v_temp1 + v_active;
    next_f1_active_v_start_point <= field_f1_start_point + v_temp2;
    next_f1_active_v_stop_point  <= field_f1_start_point + v_temp2  + extra_v_active;
    next_sync_h_start_point      <= h_fp    - 1'd1;
    next_sync_h_stop_point       <= h_temp1 - 1'd1;
    next_h_f1_half_point_point   <= h_total[VH_BITWIDTH-1:1] + h_fp - 1'd1;
    next_f0_sync_v_start_point   <= {VH_BITWIDTH{1'd0}};
    next_f0_sync_v_stop_point    <= v_sync;
    next_f1_sync_v_start_point   <= field_f1_start_point - 1'd1;
    next_f1_sync_v_stop_point    <= field_f1_start_point + extra_v_sync-1;
end


assign field_f0_start         = (v_cnt == field_f0_start_point        ) ? 1'd1 : 1'd0;
assign field_f1_start         = (v_cnt == field_f1_start_point        ) ? 1'd1 : 1'd0;
assign next_eav               = (h_cnt == next_eav_point              ) ? 1'd1 : 1'd0;
assign next_sav               = (h_cnt == next_sav_point              ) ? 1'd1 : 1'd0;
assign next_active_h_start    = (h_cnt == next_active_h_start_point   ) ? 1'd1 : 1'd0;
assign next_active_h_stop     = (h_cnt == next_active_h_stop_point    ) ? 1'd1 : 1'd0;
assign next_f0_active_v_start = (v_cnt == next_f0_active_v_start_point) ? 1'd1 : 1'd0;
assign next_f0_active_v_stop  = (v_cnt == next_f0_active_v_stop_point ) ? 1'd1 : 1'd0;
assign next_f1_active_v_start = (v_cnt == next_f1_active_v_start_point) ? 1'd1 : 1'd0;
assign next_f1_active_v_stop  = (v_cnt == next_f1_active_v_stop_point ) ? 1'd1 : 1'd0;
assign next_sync_h_start      = (h_cnt == next_sync_h_start_point     ) ? 1'd1 : 1'd0;
assign next_sync_h_stop       = (h_cnt == next_sync_h_stop_point      ) ? 1'd1 : 1'd0;
assign next_h_f1_half_point   = (h_cnt == next_h_f1_half_point_point  ) ? 1'd1 : 1'd0;
assign next_f0_sync_v_start   = (v_cnt == next_f0_sync_v_start_point  ) ? 1'd1 : 1'd0;
assign next_f0_sync_v_stop    = (v_cnt == next_f0_sync_v_stop_point   ) ? 1'd1 : 1'd0;
assign next_f1_sync_v_start   = (v_cnt == next_f1_sync_v_start_point  ) ? 1'd1 : 1'd0;
assign next_f1_sync_v_stop    = (v_cnt == next_f1_sync_v_stop_point   ) ? 1'd1 : 1'd0;


always @ (posedge clk) begin
    if(rst) begin
        field    <= 1'd0;
        eav      <= 4'd0;
        sav      <= 4'd0;
        active_h <= 1'd0;
        active_v <= 1'd0;
    end
    else if(ce) begin
        field <= (field_f0_start) ? 1'd0 :
                 (field_f1_start) ? 1'd1 :
                                    field;

        eav   <= {eav[2:0], next_eav};
        sav   <= {sav[2:0], next_sav};

        active_h <= (next_active_h_start) ? 1'd1 :
                    (next_active_h_stop)  ? 1'd0 :
                                            active_h;

        active_v <= (next_f0_active_v_start) ? 1'd1 :
                    (next_f0_active_v_stop)  ? 1'd0 :
                    (next_f1_active_v_start) ? 1'd1 :
                    (next_f1_active_v_stop)  ? 1'd0 :
                                            active_v;
    end
end

assign active_enable = active_h & active_v;

assign bt1120_f  = field;

always @ (posedge clk) begin
    if(next_sync_h_start) begin
        if(next_f0_sync_v_start) begin
            bt1120_vs <= 1'd1;
        end
        else if(next_f0_sync_v_stop) begin
            bt1120_vs <= 1'd0;
        end
    end
    else if(next_h_f1_half_point) begin
        if(next_f1_sync_v_start) begin
            bt1120_vs <= 1'd1;
        end
        else if(next_f1_sync_v_stop) begin
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
// F H V
always @ (*) begin
    if(eav[0] | sav[0]) begin
        ycbcr = {2{10'h3FF}};
    end
    else if(eav[1] | eav[2] | sav[1] | sav[2]) begin
        ycbcr = {2{10'h000}};
    end
    else if(eav[3]) begin
        if(field == 1'd0) begin // P
            if(active_v) begin
                ycbcr = {2{10'h274}}; // // F/V/H 1
            end
            else begin
                ycbcr = {2{10'h2D8}}; // F/V/H 3
            end
        end
        else if(field == 1'd1) begin // I
            if(active_v) begin
                ycbcr = {2{10'h368}}; // F/V/H 5
            end
            else begin
                ycbcr = {2{10'h3C4}}; // F/V/H 7
            end
        end
    end
    else if(sav[3]) begin
        if(field == 1'd0) begin
            if(active_v) begin
                ycbcr = {2{10'h200}}; // F/V/H 0
            end
            else begin
                ycbcr = {2{10'h2AC}}; // F/V/H 2
            end
        end
        else if(field == 1'd1) begin
            if(active_v) begin
                ycbcr = {2{10'h31C}}; // F/V/H 4
            end
            else begin
                ycbcr = {2{10'h3B0}}; // F/V/H 6
            end
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