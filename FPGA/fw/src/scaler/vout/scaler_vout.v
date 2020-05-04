`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create   : 2020.04.22
*   @Modify   :
******************************************************************************/
module scaler_vout
#(
    parameter PIXEL_BITWIDTH  = 8,
    parameter PIXEL_NUM       = 1,
    parameter IMG_H_MAX       = 1920,
    parameter IMG_V_MAX       = 1080,
    parameter IMG_H_BITWIDTH  = CLOG2(IMG_H_MAX),
    parameter IMG_V_BITWIDTH  = CLOG2(IMG_V_MAX)
)(
    input                                       core_clk,
    input                                       core_rst,
    input                                       core_start,
    input      [IMG_H_BITWIDTH-1 : 0]           core_arg_img_des_h,
    input      [IMG_V_BITWIDTH-1 : 0]           core_arg_img_des_v,
    output     [PIXEL_NUM-1 : 0]                s_axis_connect_ready,
    input      [PIXEL_NUM-1 : 0]                s_axis_connect_valid,
    input      [PIXEL_NUM-1 : 0]                s_axis_core_valid,
    input      [PIXEL_NUM*PIXEL_BITWIDTH-1 : 0] s_axis_core_pixel,
    input      [PIXEL_NUM-1 : 0]                s_axis_core_done,
    input                                       m_clk,
    input                                       m_rst,
    input                                       m_start,
    input                                       m_axis_ready,
    output                                      m_axis_valid,
    output     [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0] m_axis_pixel,
    output                                      m_axis_sof,
    output                                      m_axis_eol,
    output                                      m_scaler_done
);


/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam BRAM_ADDR_BITWIDTH = 11;
localparam BRAM_DATA_BITWIDTH = 8;
localparam SW_PING = 0, SW_PONG   = 1;
localparam WFULL   = 0, WNONFULL  = 1;
localparam REMPTY  = 0, RNONEMPTY = 1;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
wire [2*PIXEL_NUM-1 : 0]                    ena  ; // seperate control
wire [BRAM_ADDR_BITWIDTH*PIXEL_NUM-1 : 0]   addra; // seperate control
wire [BRAM_DATA_BITWIDTH*PIXEL_NUM-1 : 0]   dina ; // seperate control
wire [1 : 0]                                enb  ; // common control
wire [BRAM_ADDR_BITWIDTH-1 : 0]             addrb; // common control
wire [2*BRAM_DATA_BITWIDTH*PIXEL_NUM-1 : 0] doutb; // common control

wire [1*PIXEL_NUM-1 : 0]                    wdone; // seperate control
wire [1*PIXEL_NUM-1 : 0]                    wfull;
wire                                        rdone; // common control
wire [1*PIXEL_NUM-1 : 0]                    rempty;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/

// write
genvar i;
generate
    for (i = 0; i < PIXEL_NUM; i=i+1) begin
        scaler_vout_mem #(
            .BRAM_DEEP              ( IMG_H_MAX          ),
            .BRAM_ADDR_BITWIDTH     ( BRAM_ADDR_BITWIDTH ),
            .BRAM_DATA_BITWIDTH     ( BRAM_DATA_BITWIDTH ),
            .BRAM_DELAY             ( 2                  )
        ) inst_scaler_vout_mem (
            .core_clk               ( core_clk                                                           ),
            .core_rst               ( core_rst                                                           ),
            .ena                    ( ena      [2                   *(i+1)-1 : 2                   *(i)] ),
            .addra                  ( addra    [BRAM_ADDR_BITWIDTH  *(i+1)-1 : BRAM_ADDR_BITWIDTH  *(i)] ),
            .dina                   ( dina     [BRAM_DATA_BITWIDTH  *(i+1)-1 : BRAM_DATA_BITWIDTH  *(i)] ),
            .wdone                  ( wdone    [i]                                                       ),
            .wfull                  ( wfull    [i]                                                       ),
            .enb                    ( enb                                                                ),
            .addrb                  ( addrb                                                              ),
            .doutb                  ( doutb    [BRAM_DATA_BITWIDTH*2*(i+1)-1 : BRAM_DATA_BITWIDTH*2*(i)] ),
            .rdone                  ( rdone                                                              ),
            .rempty                 ( rempty   [i]                                                       )
        );

        scaler_vout_wchn #(
            .BRAM_ADDR_BITWIDTH     ( BRAM_ADDR_BITWIDTH ),
            .BRAM_DATA_BITWIDTH     ( BRAM_DATA_BITWIDTH )
        )inst_scaler_vout_wchn(
            .core_clk               ( core_clk                                                                   ),
            .core_rst               ( core_rst                                                                   ),
            .core_start             ( core_start                                                                 ),
            .s_axis_connect_ready   ( s_axis_connect_ready [i]                                                   ),
            .s_axis_connect_valid   ( s_axis_connect_valid [i]                                                   ),
            .s_axis_core_valid      ( s_axis_core_valid    [i]                                                   ),
            .s_axis_core_pixel      ( s_axis_core_pixel    [BRAM_DATA_BITWIDTH*(i+1)-1 : BRAM_DATA_BITWIDTH*(i)] ),
            .s_axis_core_done       ( s_axis_core_done     [i]                                                   ),
            .ena                    ( ena                  [2                 *(i+1)-1 : 2                 *(i)] ),
            .addra                  ( addra                [BRAM_ADDR_BITWIDTH*(i+1)-1 : BRAM_ADDR_BITWIDTH*(i)] ),
            .dina                   ( dina                 [BRAM_DATA_BITWIDTH*(i+1)-1 : BRAM_DATA_BITWIDTH*(i)] ),
            .wdone                  ( wdone                [i]                                                   ),
            .wfull                  ( wfull                [i]                                                   )
        );
    end
endgenerate

scaler_vout_rall#(
    .PIXEL_NUM                      ( PIXEL_NUM          ),
    .BRAM_ADDR_BITWIDTH             ( BRAM_ADDR_BITWIDTH ),
    .BRAM_DATA_BITWIDTH             ( BRAM_DATA_BITWIDTH )
) inst_scaler_vout_rall(
    .core_clk                       ( core_clk           ),
    .core_rst                       ( core_rst           ),
    .core_start                     ( core_start         ),
    .core_arg_img_des_h             ( core_arg_img_des_h ),
    .core_arg_img_des_v             ( core_arg_img_des_v ),
    .enb                            ( enb                ),
    .addrb                          ( addrb              ),
    .doutb                          ( doutb              ),
    .rdone                          ( rdone              ),
    .rempty                         ( rempty             ),
    .m_clk                          ( m_clk              ),
    .m_rst                          ( m_rst              ),
    .m_axis_ready                   ( m_axis_ready       ),
    .m_axis_valid                   ( m_axis_valid       ),
    .m_axis_pixel                   ( m_axis_pixel       ),
    .m_axis_sof                     ( m_axis_sof         ),
    .m_axis_eol                     ( m_axis_eol         ),
    .m_scaler_done                  ( m_scaler_done      )
);


function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule