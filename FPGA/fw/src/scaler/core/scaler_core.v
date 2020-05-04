`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Description :
*   @Create : 2019.07.22
*
*   @Modify : 2020-04-06
******************************************************************************/
module scaler_core
#(
    parameter PIXEL_BITWIDTH       = 8,
    parameter IMG_H_MAX            = 3840,
    parameter IMG_V_MAX            = 2160,
    parameter IMG_H_BITWIDTH       = CLOG2(IMG_H_MAX),
    parameter IMG_V_BITWIDTH       = CLOG2(IMG_V_MAX),
    parameter KERNEL_MAX           = 4,
    parameter KERNEL_BITWIDTH      = CLOG2(KERNEL_MAX),
    parameter KERNEL_COEF_BITWIDTH = 8,  // 8Q6
    parameter SF_BITWIDTH          = 24, // 24Q20
    parameter SF_INT_BITWIDTH      = 20,
    parameter SF_FRAC_BITWIDTH     = 4,
    parameter MATRIX_DELAY         = 4
)(
    input                                                   core_clk,
    input                                                   core_rst,
    input      [IMG_H_BITWIDTH-1 : 0]                       core_arg_img_src_h,
    input      [IMG_V_BITWIDTH-1 : 0]                       core_arg_img_src_v,
    input      [IMG_H_BITWIDTH-1 : 0]                       core_arg_img_des_h,
    input      [IMG_V_BITWIDTH-1 : 0]                       core_arg_img_des_v,
    input                                                   core_arg_mode,                  // 0 = scaler down 1 = scaler up
    input      [SF_BITWIDTH-1 : 0]                          core_arg_hsf,
    input      [SF_BITWIDTH-1 : 0]                          core_arg_vsf,
    input                                                   core_start,
// conv coef
    input      [KERNEL_COEF_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] scaler_coef,
// matrix pixel input (Interface using ram type)
    output                                                  s_axis_connect_ready,
    input                                                   s_axis_connect_valid,
    output                                                  matrix_ram_read_stride,    // stride curr line output
    output                                                  matrix_ram_read_repeat,    // repeat curr line output
    output                                                  matrix_ram_read_en,
    input                                                   matrix_ram_read_rsp_en,
    input      [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] matrix_ram_read_rsp_pixel,
    output                                                  matrix_ram_read_done,
// conv result output
    input                                                   m_axis_connect_ready,
    output                                                  m_axis_connect_valid,
    output                                                  m_axis_core_valid,
    output     [PIXEL_BITWIDTH-1 : 0]                       m_axis_core_pixel,
    output                                                  m_axis_core_done
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
// conv result output

wire                                              m_axis_scaler_valid;
wire [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] m_axis_scaler_pixel;
wire [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]      m_axis_scaler_coef_h;
wire [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]      m_axis_scaler_coef_v;
wire                                              m_axis_scaler_done;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/

scaler_stream #(
    .PIXEL_BITWIDTH            ( PIXEL_BITWIDTH            ),
    .IMG_H_MAX                 ( IMG_H_MAX                 ),
    .IMG_V_MAX                 ( IMG_V_MAX                 ),
    .IMG_H_BITWIDTH            ( IMG_H_BITWIDTH            ),
    .IMG_V_BITWIDTH            ( IMG_V_BITWIDTH            ),
    .KERNEL_MAX                ( KERNEL_MAX                ),
    .KERNEL_BITWIDTH           ( KERNEL_BITWIDTH           ),
    .KERNEL_COEF_BITWIDTH      ( KERNEL_COEF_BITWIDTH      ),
    .SF_BITWIDTH               ( SF_BITWIDTH               ),
    .SF_INT_BITWIDTH           ( SF_INT_BITWIDTH           ),
    .SF_FRAC_BITWIDTH          ( SF_FRAC_BITWIDTH          ),
    .MATRIX_DELAY              ( MATRIX_DELAY              )
) inst_scaler_stream(
    .core_clk                  ( core_clk                  ),
    .core_rst                  ( core_rst                  ),
    .core_arg_img_src_h        ( core_arg_img_src_h        ),
    .core_arg_img_src_v        ( core_arg_img_src_v        ),
    .core_arg_img_des_h        ( core_arg_img_des_h        ),
    .core_arg_img_des_v        ( core_arg_img_des_v        ),
    .core_arg_mode             ( core_arg_mode             ),
    .core_arg_hsf              ( core_arg_hsf              ),
    .core_arg_vsf              ( core_arg_vsf              ),
    .core_start                ( core_start                ),
    .scaler_coef               ( scaler_coef               ),
    .s_axis_connect_ready      ( s_axis_connect_ready      ),
    .s_axis_connect_valid      ( s_axis_connect_valid      ),
    .matrix_ram_read_stride    ( matrix_ram_read_stride    ),
    .matrix_ram_read_repeat    ( matrix_ram_read_repeat    ),
    .matrix_ram_read_en        ( matrix_ram_read_en        ),
    .matrix_ram_read_rsp_en    ( matrix_ram_read_rsp_en    ),
    .matrix_ram_read_rsp_pixel ( matrix_ram_read_rsp_pixel ),
    .matrix_ram_read_done      ( matrix_ram_read_done      ),
    .m_axis_connect_ready      ( m_axis_connect_ready      ),
    .m_axis_connect_valid      ( m_axis_connect_valid      ),
    .m_axis_scaler_valid       ( m_axis_scaler_valid       ),
    .m_axis_scaler_pixel       ( m_axis_scaler_pixel       ),
    .m_axis_scaler_coef_h      ( m_axis_scaler_coef_h      ),
    .m_axis_scaler_coef_v      ( m_axis_scaler_coef_v      ),
    .m_axis_scaler_done        ( m_axis_scaler_done        )
);


scaler_dsp inst_scaler_dsp(
    .core_clk                  ( core_clk               ),
    .core_rst                  ( core_rst               ),
    .s_axis_scaler_valid       ( m_axis_scaler_valid    ),
    .s_axis_scaler_pixel       ( m_axis_scaler_pixel    ),
    .s_axis_scaler_coef_h      ( m_axis_scaler_coef_h   ),
    .s_axis_scaler_coef_v      ( m_axis_scaler_coef_v   ),
    .s_axis_scaler_done        ( m_axis_scaler_done     ),
    .m_axis_core_valid         ( m_axis_core_valid      ),
    .m_axis_core_pixel         ( m_axis_core_pixel      ),
    .m_axis_core_done          ( m_axis_core_done       )
);

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule