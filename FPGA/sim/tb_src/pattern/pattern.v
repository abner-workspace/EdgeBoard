`timescale 1ns/1ps
/******************************************************************************
* Auther : Abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2019-12-24 10:36:12
*             Create File
*   @Modify :
******************************************************************************/
`include "../../../fw/src/common.v"
module pattern
(
    input                          clk,
    input                          rst,
    output reg                     bt1120_f,
    output reg                     bt1120_vs,
    output reg                     bt1120_hs,
    output reg                     bt1120_de,
    output reg [15 : 0]            bt1120_ycbcr
);

/********************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam VH_BITWIDTH = 13;
/********************************************************************************
*
*   Define reg / wire
*
********************************************************************************/

wire  [7 : 0]            std;
wire  [3 : 0]            imdetail;
wire                     ce;
wire [VH_BITWIDTH-1 : 0] v_cnt;
wire [VH_BITWIDTH-1 : 0] h_cnt;
wire                     imdetail_de;
wire [15 : 0]            imdetail_ycbcr;

wire [VH_BITWIDTH-1 : 0] h_fp;
wire [VH_BITWIDTH-1 : 0] h_sync;
wire [VH_BITWIDTH-1 : 0] h_bp;
wire [VH_BITWIDTH-1 : 0] h_active;
wire [VH_BITWIDTH-1 : 0] h_total;
wire [VH_BITWIDTH-1 : 0] v_fp;
wire [VH_BITWIDTH-1 : 0] v_sync;
wire [VH_BITWIDTH-1 : 0] v_bp;
wire [VH_BITWIDTH-1 : 0] v_active;
wire [VH_BITWIDTH-1 : 0] v_total;
wire [VH_BITWIDTH-1 : 0] extra_v_sync;
wire [VH_BITWIDTH-1 : 0] extra_v_bp;
wire [VH_BITWIDTH-1 : 0] extra_v_active;
wire [VH_BITWIDTH-1 : 0] extra_v_fp;
wire [3 : 0]             size_id;          // 1080x720 1920x1080 3840x2160 ...
wire [3 : 0]             rate_id;          // P60 P59.94 P50 P30 ...
wire                     scan_id;          // 0 = P  1 = I
wire [2 : 0]             mode_id;          // 0 = HD 1 = 3G 2 = 6G ...
wire [1 : 0]             freq_id;          // 0 = 74.25 1 = 148.5 2 = 297  Just Support HDMI or BT1120 , when SDI, Parameter is invalid
wire                     frac_id;          // 0 = clk   1 = clk / 1.001    Just Support HDMI or BT1120 , when SDI, Parameter is invalid

wire                     p_bt1120_f;
wire                     p_bt1120_vs;
wire                     p_bt1120_hs;
wire                     p_bt1120_de;
wire [15 : 0]            p_bt1120_ycbcr;

wire                     i_bt1120_f;
wire                     i_bt1120_vs;
wire                     i_bt1120_hs;
wire                     i_bt1120_de;
wire [15 : 0]            i_bt1120_ycbcr;

wire                     arb_bt1120_f;
wire                     arb_bt1120_vs;
wire                     arb_bt1120_hs;
wire                     arb_bt1120_de;
wire [15 : 0]            arb_bt1120_ycbcr;

reg                      dly_bt1120_f;
reg                      dly_bt1120_vs;
reg                      dly_bt1120_hs;
reg                      dly_bt1120_de;
reg  [15 : 0]            dly_bt1120_ycbcr;

/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
assign std      = `VID_SIM_S;
assign imdetail = 1;
color_bar_format inst_color_bar_format(
    .clk                        ( clk            ),
    .std                        ( std            ),
    .h_total                    ( h_total        ),
    .v_total                    ( v_total        ),
    .h_fp                       ( h_fp           ),
    .h_sync                     ( h_sync         ),
    .h_bp                       ( h_bp           ),
    .h_active                   ( h_active       ),
    .v_fp                       ( v_fp           ),
    .v_sync                     ( v_sync         ),
    .v_bp                       ( v_bp           ),
    .v_active                   ( v_active       ),
    .extra_v_sync               ( extra_v_sync   ),
    .extra_v_bp                 ( extra_v_bp     ),
    .extra_v_active             ( extra_v_active ),
    .extra_v_fp                 ( extra_v_fp     ),
    .size_id                    ( size_id        ),
    .rate_id                    ( rate_id        ),
    .scan_id                    ( scan_id        ),
    .mode_id                    ( mode_id        ),
    .freq_id                    ( freq_id        ),
    .frac_id                    ( frac_id        )
);

color_bar_ctrl inst_color_bar_ctrl(
    .clk                        (clk),
    .rst                        (rst),
    .h_total                    (h_total),
    .v_total                    (v_total),
    .ce                         (ce),
    .v_cnt                      (v_cnt),
    .h_cnt                      (h_cnt)
);

color_bar_progressive inst_color_bar_progressive(
    .clk                        (clk),
    .rst                        (rst),
// arg
    .h_fp                       (h_fp),
    .h_sync                     (h_sync),
    .h_bp                       (h_bp),
    .h_active                   (h_active),
    .h_total                    (h_total),
    .v_fp                       (v_fp),
    .v_sync                     (v_sync),
    .v_bp                       (v_bp),
    .v_active                   (v_active),
    .v_total                    (v_total),
// ctrl
    .ce                         (ce),
    .v_cnt                      (v_cnt),
    .h_cnt                      (h_cnt),
// output
    .bt1120_f                   (p_bt1120_f),
    .bt1120_vs                  (p_bt1120_vs),
    .bt1120_hs                  (p_bt1120_hs),
    .bt1120_de                  (p_bt1120_de),
    .bt1120_ycbcr               (p_bt1120_ycbcr)
);

color_bar_interlaced inst_color_bar_interlaced(
    .clk                        (clk),
    .rst                        (rst),
// arg
    .h_fp                       (h_fp),
    .h_sync                     (h_sync),
    .h_bp                       (h_bp),
    .h_active                   (h_active),
    .h_total                    (h_total),
    .v_fp                       (v_fp),
    .v_sync                     (v_sync),
    .v_bp                       (v_bp),
    .v_active                   (v_active),
    .v_total                    (v_total),
    .extra_v_fp                 (extra_v_fp),
    .extra_v_sync               (extra_v_sync),
    .extra_v_bp                 (extra_v_bp),
    .extra_v_active             (extra_v_active),
// ctrl
    .ce                         (ce),
    .v_cnt                      (v_cnt),
    .h_cnt                      (h_cnt),
// output
    .bt1120_f                   (i_bt1120_f),
    .bt1120_vs                  (i_bt1120_vs),
    .bt1120_hs                  (i_bt1120_hs),
    .bt1120_de                  (i_bt1120_de),
    .bt1120_ycbcr               (i_bt1120_ycbcr)
);

color_bar_imdetail inst_color_bar_imdetail(
    .clk                        (clk),
    .rst                        (rst),
    .h_active                   (h_active),
    .scan_id                    (scan_id),
    .imdetail                   (imdetail),
    .bt1120_vs                  (arb_bt1120_vs),
    .bt1120_hs                  (arb_bt1120_hs),
    .bt1120_de                  (arb_bt1120_de),
    .imdetail_de                (imdetail_de),
    .imdetail_ycbcr             (imdetail_ycbcr)
);


assign arb_bt1120_f     = (scan_id == 1'd1) ? i_bt1120_f  : p_bt1120_f;
assign arb_bt1120_vs    = (scan_id == 1'd1) ? i_bt1120_vs : p_bt1120_vs;
assign arb_bt1120_hs    = (scan_id == 1'd1) ? i_bt1120_hs : p_bt1120_hs;
assign arb_bt1120_de    = (scan_id == 1'd1) ? i_bt1120_de : p_bt1120_de;
assign arb_bt1120_ycbcr = (scan_id == 1'd1) ? i_bt1120_ycbcr : p_bt1120_ycbcr;


always @ (posedge clk) begin
    dly_bt1120_f     <= arb_bt1120_f;
    dly_bt1120_vs    <= arb_bt1120_vs;
    dly_bt1120_hs    <= arb_bt1120_hs;
    dly_bt1120_de    <= arb_bt1120_de;
    dly_bt1120_ycbcr <= arb_bt1120_ycbcr;
end

always @ (posedge clk) begin
    bt1120_f     <= dly_bt1120_f;
    bt1120_vs    <= dly_bt1120_vs;
    bt1120_hs    <= dly_bt1120_hs;
    bt1120_de    <= dly_bt1120_de;
    bt1120_ycbcr <= (imdetail_de) ? imdetail_ycbcr : dly_bt1120_ycbcr;
end


/********************************************************************************
*
*   SIM verilog
*
********************************************************************************/
// reg                               flag         = 1'd0;
// reg                               v_hold       = 1'd0;
// reg                               bt1120_hs_d1 = 1'd0;
// reg                               bt1120_hs_d2 = 1'd0;
// wire                              bt1120_hs_pos;
// wire                              bt1120_hs_neg;
// reg     [3 : 0]                   addr = 4'd0;
// integer                           fp;
// integer                           fp0;
// integer                           fp1;
// integer                           fp2;
// integer                           fp3;

// always @ (posedge clk) begin
//     {bt1120_hs_d2, bt1120_hs_d1} <= {bt1120_hs_d1, bt1120_hs};
// end

// assign bt1120_hs_pos = bt1120_hs_d1 & (~bt1120_hs_d2);
// assign bt1120_hs_neg = (~bt1120_hs_d1) & bt1120_hs_d2;

// always @ (posedge clk) begin
//     if(bt1120_hs_neg) begin
//         flag <= 1'd0;
//     end
//     else if((~bt1120_f) & bt1120_vs & bt1120_hs_pos & (~v_hold)) begin
//         flag <= 1'd1;
//     end
// end

// always @ (posedge clk) begin
//     if(flag) begin
//         v_hold <= 1'd1;
//     end
//     else if(bt1120_de) begin
//         v_hold <= 1'd0;
//     end
// end


// initial begin
//     fp0 = $fopen("pattern_0.bin", "wb");
//     fp1 = $fopen("pattern_1.bin", "wb");
//     fp2 = $fopen("pattern_2.bin", "wb");
//     fp3 = $fopen("pattern_3.bin", "wb");
// end

// always @ (posedge clk) begin
//     if(rst) begin
//         addr <= 4'd0;
//     end
//     else if(flag) begin
//         if(addr == 4'd4) begin
//             addr <= 4'd0;
//         end
//         else begin
//             addr <= addr + 1'd1;
//         end
//     end
// end

// always @ (*) begin
//     case (addr)
//         4'd0 : fp = fp0;
//         4'd1 : fp = fp1;
//         4'd2 : fp = fp2;
//         4'd3 : fp = fp3;
//     endcase
// end
// always @ (posedge clk) begin
//     if(flag) begin
//         $fseek(fp, 0 , 0);
//     end
// end


// always @ (posedge clk) begin
//     if(std == `VID_SIM_M) begin
//         if(bt1120_de) begin
//             $fwrite(fp, "%c",bt1120_ycbcr[8*1-1 : 8*0]);
//             $fwrite(fp, "%c",bt1120_ycbcr[8*2-1 : 8*1]);
//             $fwrite(fp, "%c",bt1120_ycbcr[8*1-1 : 8*0]);
//             $fwrite(fp, "%c",bt1120_ycbcr[8*2-1 : 8*1]);
//         end
//     end
//     else begin
//         if(bt1120_de) begin
//             $fwrite(fp, "%c",bt1120_ycbcr[8*1-1 : 8*0]);
//             $fwrite(fp, "%c",bt1120_ycbcr[8*2-1 : 8*1]);
//         end
//     end
// end

endmodule