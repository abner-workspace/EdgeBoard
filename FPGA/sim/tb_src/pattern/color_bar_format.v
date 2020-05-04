`timescale 1ns/1ps
/******************************************************************************
* Auther : Abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2020-03-10 10:36:12
*             Create File
*   @Modify :
******************************************************************************/

`include "../../../fw/src/common.v"

module color_bar_format #(
    parameter STD_BITWIDTH = 8,
    parameter VH_BITWIDTH  = 13
)(
    input                              clk,
    input      [STD_BITWIDTH-1 : 0]    std,
// total
    output reg [VH_BITWIDTH-1 : 0]     h_total          = 2200,
    output reg [VH_BITWIDTH-1 : 0]     v_total          = 1125,
    output reg [VH_BITWIDTH-1 : 0]     h_fp             = 88,
    output reg [VH_BITWIDTH-1 : 0]     h_sync           = 44,
    output reg [VH_BITWIDTH-1 : 0]     h_bp             = 148,
    output reg [VH_BITWIDTH-1 : 0]     h_active         = 1920,
    output reg [VH_BITWIDTH-1 : 0]     v_fp             = 4,
    output reg [VH_BITWIDTH-1 : 0]     v_sync           = 5,
    output reg [VH_BITWIDTH-1 : 0]     v_bp             = 36,
    output reg [VH_BITWIDTH-1 : 0]     v_active         = 1080,
// I just scan i support
    output reg [VH_BITWIDTH-1 : 0]     extra_v_sync     = 0,
    output reg [VH_BITWIDTH-1 : 0]     extra_v_bp       = 0,
    output reg [VH_BITWIDTH-1 : 0]     extra_v_active   = 0,
    output reg [VH_BITWIDTH-1 : 0]     extra_v_fp       = 0,
//  video Feature
    output reg [3 : 0]                 size_id          = `ARG_SIZE_1920x1080  ,    // 1080x720 1920x1080 3840x2160 ...
    output reg [3 : 0]                 rate_id          = `ARG_RATE_60FPS      ,    // P60 P59.94 P50 P30 ...
    output reg                         scan_id          = `ARG_SCAN_P          ,    // 0 = P  1 = I
    output reg [2 : 0]                 mode_id          = `ARG_MODE_3G         ,    // 0 = HD 1 = 3G 2 = 6G ...
    output reg [1 : 0]                 freq_id          = `ARG_FREQ_148M5      ,    // 0 = 74.25 1 = 148.5 2 = 297  Just Support HDMI or BT1120 , when SDI, Parameter is invalid
    output reg                         frac_id          = `ARG_FRAC_DIS             // 0 = clk   1 = clk / 1.001    Just Support HDMI or BT1120 , when SDI, Parameter is invalid
);

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
reg [STD_BITWIDTH-1 : 0]   save_std           = 8'd15;
reg [VH_BITWIDTH-1 : 0]    r_h_total          = 2200;
reg [VH_BITWIDTH-1 : 0]    r_v_total          = 1125;
reg [VH_BITWIDTH-1 : 0]    r_h_fp             = 88;
reg [VH_BITWIDTH-1 : 0]    r_h_sync           = 44;
reg [VH_BITWIDTH-1 : 0]    r_h_bp             = 148;
reg [VH_BITWIDTH-1 : 0]    r_h_active         = 1920;
reg [VH_BITWIDTH-1 : 0]    r_v_fp             = 4;
reg [VH_BITWIDTH-1 : 0]    r_v_sync           = 5;
reg [VH_BITWIDTH-1 : 0]    r_v_bp             = 36;
reg [VH_BITWIDTH-1 : 0]    r_v_active         = 1080;
reg [VH_BITWIDTH-1 : 0]    r_extra_v_sync     = 0;
reg [VH_BITWIDTH-1 : 0]    r_extra_v_bp       = 0;
reg [VH_BITWIDTH-1 : 0]    r_extra_v_active   = 0;
reg [VH_BITWIDTH-1 : 0]    r_extra_v_fp       = 0;
reg [3 : 0]                r_size_id          = `ARG_SIZE_1920x1080;
reg [3 : 0]                r_rate_id          = `ARG_RATE_60FPS;
reg                        r_scan_id          = `ARG_SCAN_P;
reg [2 : 0]                r_mode_id          = `ARG_MODE_3G;
reg [1 : 0]                r_freq_id          = `ARG_FREQ_148M5;
reg                        r_frac_id          = `ARG_FRAC_DIS;
/********************************************************************************
*
*   RTL verilog
*
********************************************************************************/
always @ (posedge clk) begin
    save_std <= std;
end

always @ (posedge clk) begin
    h_total          <= r_h_total;
    v_total          <= r_v_total;
    h_fp             <= r_h_fp;
    h_sync           <= r_h_sync;
    h_bp             <= r_h_bp;
    h_active         <= r_h_active;
    v_fp             <= r_v_fp;
    v_sync           <= r_v_sync;
    v_bp             <= r_v_bp;
    v_active         <= r_v_active;
    extra_v_sync     <= r_extra_v_sync;
    extra_v_bp       <= r_extra_v_bp;
    extra_v_active   <= r_extra_v_active;
    extra_v_fp       <= r_extra_v_fp;
    size_id          <= r_size_id;
    rate_id          <= r_rate_id;
    scan_id          <= r_scan_id;
    mode_id          <= r_mode_id;
    freq_id          <= r_freq_id;
    frac_id          <= r_frac_id;
end

always @ (posedge clk) begin
    case(save_std)
        `VID_HD_720P50:
            begin
                // Timing
                r_h_fp             <= 440                ;
                r_h_sync           <= 40                 ;
                r_h_bp             <= 220                ;
                r_h_active         <= 1280               ;
                r_h_total          <= 1980               ;
                r_v_fp             <= 5                  ;
                r_v_sync           <= 5                  ;
                r_v_bp             <= 20                 ;
                r_v_active         <= 720                ;
                r_v_total          <= 750                ;
                // Feature
                r_size_id          <= `ARG_SIZE_1280x720 ;
                r_rate_id          <= `ARG_RATE_50FPS    ;
                r_scan_id          <= `ARG_SCAN_P        ;
                r_mode_id          <= `ARG_MODE_HD       ;
                r_freq_id          <= `ARG_FREQ_74M25    ;
                r_frac_id          <= `ARG_FRAC_DIS      ;
            end
        `VID_HD_720P59_94 :
            begin
                // Timing
                r_h_fp             <= 110                ;
                r_h_sync           <= 40                 ;
                r_h_bp             <= 220                ;
                r_h_active         <= 1280               ;
                r_h_total          <= 1650               ;
                r_v_fp             <= 5                  ;
                r_v_sync           <= 5                  ;
                r_v_bp             <= 20                 ;
                r_v_active         <= 720                ;
                r_v_total          <= 750                ;
                // Feature
                r_size_id          <= `ARG_SIZE_1280x720 ;
                r_rate_id          <= `ARG_RATE_59_94FPS ;
                r_scan_id          <= `ARG_SCAN_P        ;
                r_mode_id          <= `ARG_MODE_HD       ;
                r_freq_id          <= `ARG_FREQ_74M25    ;
                r_frac_id          <= `ARG_FRAC_EN       ;
            end
        `VID_HD_720P60 :
            begin
                // Timing
                r_h_fp             <= 110                ;
                r_h_sync           <= 40                 ;
                r_h_bp             <= 220                ;
                r_h_active         <= 1280               ;
                r_h_total          <= 1650               ;
                r_v_fp             <= 5                  ;
                r_v_sync           <= 5                  ;
                r_v_bp             <= 20                 ;
                r_v_active         <= 720                ;
                r_v_total          <= 750                ;
                // Feature
                r_size_id          <= `ARG_SIZE_1280x720 ;
                r_rate_id          <= `ARG_RATE_60FPS    ;
                r_scan_id          <= `ARG_SCAN_P        ;
                r_mode_id          <= `ARG_MODE_HD       ;
                r_freq_id          <= `ARG_FREQ_74M25    ;
                r_frac_id          <= `ARG_FRAC_DIS      ;
            end
        `VID_HD_1080I50 :
            begin
                // Timing
                // H
                r_h_fp             <= 528                ;
                r_h_sync           <= 44                 ;
                r_h_bp             <= 148                ;
                r_h_active         <= 1920               ;
                r_h_total          <= 2640               ;
                // F0
                r_v_fp             <= 3                  ;
                r_v_sync           <= 5                  ;
                r_v_bp             <= 15                 ;
                r_v_active         <= 540                ;
                // F1
                r_extra_v_fp       <= 2                  ;
                r_extra_v_sync     <= 5                  ;
                r_extra_v_bp       <= 15                 ;
                r_extra_v_active   <= 540                ;
                r_v_total          <= 1125               ;
                // Feature
                r_size_id          <= `ARG_SIZE_1920x1080;
                r_rate_id          <= `ARG_RATE_50FPS    ;
                r_scan_id          <= `ARG_SCAN_I        ;
                r_mode_id          <= `ARG_MODE_HD       ;
                r_freq_id          <= `ARG_FREQ_74M25    ;
                r_frac_id          <= `ARG_FRAC_DIS      ;
            end
        `VID_HD_1080I59_94 :
            begin
                // Timing
                // H
                r_h_fp             <= 88                 ;
                r_h_sync           <= 44                 ;
                r_h_bp             <= 148                ;
                r_h_active         <= 1920               ;
                r_h_total          <= 2200               ;
                // F0
                r_v_sync           <= 5                  ;
                r_v_bp             <= 15                 ;
                r_v_active         <= 540                ;
                r_v_fp             <= 3                  ;
                // F1
                r_extra_v_sync     <= 5                  ;
                r_extra_v_bp       <= 15                 ;
                r_extra_v_active   <= 540                ;
                r_extra_v_fp       <= 2                  ;
                r_v_total          <= 1125               ;
                // Feature
                r_size_id          <= `ARG_SIZE_1920x1080;
                r_rate_id          <= `ARG_RATE_59_94FPS ;
                r_scan_id          <= `ARG_SCAN_I        ;
                r_mode_id          <= `ARG_MODE_HD       ;
                r_freq_id          <= `ARG_FREQ_74M25    ;
                r_frac_id          <= `ARG_FRAC_EN       ;
            end
        `VID_HD_1080I60 :
            begin
                // Timing
                // H
                r_h_fp             <= 88                  ;
                r_h_sync           <= 44                  ;
                r_h_bp             <= 148                 ;
                r_h_active         <= 1920                ;
                r_h_total          <= 2200                ;
                // F0
                r_v_sync            <= 5                  ;
                r_v_bp              <= 15                 ;
                r_v_active          <= 540                ;
                r_v_fp              <= 3                  ;
                // F1
                r_extra_v_sync      <= 5                  ;
                r_extra_v_bp        <= 15                 ;
                r_extra_v_active    <= 540                ;
                r_extra_v_fp        <= 2                  ;
                r_v_total           <= 1125               ;
                // Feature
                r_size_id           <= `ARG_SIZE_1920x1080;
                r_rate_id           <= `ARG_RATE_60FPS    ;
                r_scan_id           <= `ARG_SCAN_I        ;
                r_mode_id           <= `ARG_MODE_HD       ;
                r_freq_id           <= `ARG_FREQ_74M25    ;
                r_frac_id           <= `ARG_FRAC_DIS      ;
            end
        `VID_HD_1080SFP23_98 :
            begin
                // Timing
                r_h_fp               <= 638                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2750               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                // Feature
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_23_98FPS ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_EN       ;
            end
        `VID_HD_1080SFP24 :
            begin
                // Timing
                r_h_fp               <= 638                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2750               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                // Feature
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_24FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_HD_1080P23_98 :
            begin
                // Timing
                r_h_fp               <= 638                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2750               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                // Feature
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_23_98FPS ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_EN       ;
            end
        `VID_HD_1080P24 :
            begin
                // Timing
                r_h_fp               <= 638                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2750               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                // Feature
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_24FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_HD_1080P25 :
            begin
                // Timing
                r_h_fp               <= 528                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2640               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                // Feature
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_25FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_HD_1080P29_97 :
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_29_97FPS ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_EN       ;
            end
        `VID_HD_1080P30:
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_29_97FPS ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_3G_1080P50 :
            begin
                r_h_fp               <= 528                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2640               ;
                r_v_fp               <= 4                  ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_total            <= 1125               ;
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_50FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_3G       ;
                r_freq_id            <= `ARG_FREQ_148M5    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_3G_1080P59_94 :
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_fp               <= 4                  ;
                r_v_total            <= 1125               ;
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_59_94FPS ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_3G       ;
                r_freq_id            <= `ARG_FREQ_148M5    ;
                r_frac_id            <= `ARG_FRAC_EN       ;
            end
        `VID_3G_1080P60 :
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_fp               <= 4                  ;
                r_v_total            <= 1125               ;
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_60FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_3G       ;
                r_freq_id            <= `ARG_FREQ_148M5    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_6G_2160P23_98 :
            begin
                // Timing
                r_h_fp               <= 638                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2750               ;
                r_v_fp               <= 4     *2           ;
                r_v_sync             <= 5     *2           ;
                r_v_bp               <= 36    *2           ;
                r_v_active           <= 1080  *2           ;
                r_v_total            <= 1125  *2           ;
                // Feature
                r_size_id            <= `ARG_SIZE_3840x2160;
                r_rate_id            <= `ARG_RATE_23_98FPS ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_6G       ;
                r_freq_id            <= `ARG_FREQ_297M     ;
                r_frac_id            <= `ARG_FRAC_EN       ;
            end
        `VID_6G_2160P24 :
            begin
                // Timing
                r_h_fp               <= 638                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2750               ;
                r_v_fp               <= 4     *2           ;
                r_v_sync             <= 5     *2           ;
                r_v_bp               <= 36    *2           ;
                r_v_active           <= 1080  *2           ;
                r_v_total            <= 1125  *2           ;
                // Feature
                r_size_id            <= `ARG_SIZE_3840x2160;
                r_rate_id            <= `ARG_RATE_24FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_6G       ;
                r_freq_id            <= `ARG_FREQ_297M     ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_6G_2160P25 :
            begin
                // Timing
                r_h_fp               <= 528                ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2640               ;
                r_v_fp               <= 4     *2           ;
                r_v_sync             <= 5     *2           ;
                r_v_bp               <= 36    *2           ;
                r_v_active           <= 1080  *2           ;
                r_v_total            <= 1125  *2           ;
                // Feature
                r_size_id            <= `ARG_SIZE_3840x2160;
                r_rate_id            <= `ARG_RATE_25FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_6G       ;
                r_freq_id            <= `ARG_FREQ_297M     ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_6G_2160P29_97 :
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_fp               <= 4     *2           ;
                r_v_sync             <= 5     *2           ;
                r_v_bp               <= 36    *2           ;
                r_v_active           <= 1080  *2           ;
                r_v_total            <= 1125  *2           ;
                r_size_id            <= `ARG_SIZE_3840x2160;
                r_rate_id            <= `ARG_RATE_29_97FPS ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_6G       ;
                r_freq_id            <= `ARG_FREQ_297M     ;
                r_frac_id            <= `ARG_FRAC_EN       ;
            end
        `VID_6G_2160P30 :
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_fp               <= 4     *2           ;
                r_v_sync             <= 5     *2           ;
                r_v_bp               <= 36    *2           ;
                r_v_active           <= 1080  *2           ;
                r_v_total            <= 1125  *2           ;
                r_size_id            <= `ARG_SIZE_3840x2160;
                r_rate_id            <= `ARG_RATE_30FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_6G       ;
                r_freq_id            <= `ARG_FREQ_297M     ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        `VID_SIM_I :
            begin
                // Timing
                // H
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                // F0
                r_v_sync             <= 5                  ;
                r_v_bp               <= 15                 ;
                r_v_active           <= 8                  ;
                r_v_fp               <= 3                  ;
                // F1
                r_extra_v_sync       <= 5                  ;
                r_extra_v_bp         <= 15                 ;
                r_extra_v_active     <= 8                  ;
                r_extra_v_fp         <= 2                  ;
                r_v_total            <= 61                 ;
                // Feature
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_60FPS    ;
                r_scan_id            <= `ARG_SCAN_I        ;
                r_mode_id            <= `ARG_MODE_HD       ;
                r_freq_id            <= `ARG_FREQ_74M25    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;

            end
        `VID_SIM_S :
            begin

                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 10                 ;
                r_v_active           <= 48                 ;
                r_v_fp               <= 4                  ;
                r_v_total            <= 67                 ;
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_60FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_3G       ;
                r_freq_id            <= `ARG_FREQ_148M5    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;

            end
        `VID_SIM_M :
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_sync             <= 5       * 2        ;
                r_v_bp               <= 10      * 2        ;
                r_v_active           <= 48      * 2        ;
                r_v_fp               <= 4       * 2        ;
                r_v_total            <= 67      * 2        ;
                r_size_id            <= `ARG_SIZE_3840x2160;
                r_rate_id            <= `ARG_RATE_30FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_6G       ;
                r_freq_id            <= `ARG_FREQ_297M     ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
        default :
            begin
                r_h_fp               <= 88                 ;
                r_h_sync             <= 44                 ;
                r_h_bp               <= 148                ;
                r_h_active           <= 1920               ;
                r_h_total            <= 2200               ;
                r_v_sync             <= 5                  ;
                r_v_bp               <= 36                 ;
                r_v_active           <= 1080               ;
                r_v_fp               <= 4                  ;
                r_v_total            <= 1125               ;
                r_size_id            <= `ARG_SIZE_1920x1080;
                r_rate_id            <= `ARG_RATE_60FPS    ;
                r_scan_id            <= `ARG_SCAN_P        ;
                r_mode_id            <= `ARG_MODE_3G       ;
                r_freq_id            <= `ARG_FREQ_148M5    ;
                r_frac_id            <= `ARG_FRAC_DIS      ;
            end
    endcase
end


endmodule
