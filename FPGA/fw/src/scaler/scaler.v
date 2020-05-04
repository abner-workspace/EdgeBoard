`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Gitee  : https://gitee.com/abnerwork/
* Description :
*   @Create : 2019.07.22
*       Support YUV420 YUV422 RGB888 YUV444
*       Support arbitrary resolution
*       Support Kerner = [4,4]
*       Support MAX Number of Phase  = 4
*       Process Core Clk Freq >= float(out_w/in_w) *
*                                round_up(out_h/in_h) * 1.2 *
*                                Pixel Clk Freq
******************************************************************************/
module scaler
#(
    parameter PIXEL_BITWIDTH        = 8,
    parameter PIXEL_NUM             = 1,
    parameter IMG_H_MAX             = 1920,
    parameter IMG_V_MAX             = 1080,
    parameter IMG_H_BITWIDTH        = CLOG2(IMG_H_MAX),
    parameter IMG_V_BITWIDTH        = CLOG2(IMG_V_MAX),
    parameter PAD_MAX               = 2,
    parameter PAD_BITWIDTH          = CLOG2(PAD_MAX),
    parameter KERNEL_MAX            = 4,
    parameter KERNEL_BITWIDTH       = CLOG2(KERNEL_MAX),
    parameter KERNEL_COEF_BITWIDTH  = 8,  // 8Q6
    parameter SF_BITWIDTH           = 24, // 24Q20
    parameter SF_INT_BITWIDTH       = 4,
    parameter SF_FRAC_BITWIDTH      = 20
)(
    input                                                           s_clk,          // Image Input
    input                                                           s_rst,          // Image Input
    output                                                          s_axis_ready,   // Image Input
    input                                                           s_axis_valid,   // Image Input
    input       [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0]                    s_axis_pixel,   // Image Input
    input                                                           s_axis_sof,     // Image Input
    input                                                           s_axis_eol,     // Image Input
    input                                                           m_clk,          // Image Output
    input                                                           m_rst,          // Image Output
    input                                                           m_axis_ready,   // Image Output
    output                                                          m_axis_valid,   // Image Output
    output      [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0]                    m_axis_pixel,   // Image Output
    output                                                          m_axis_sof,     // Image Output
    output                                                          m_axis_eol,     // Image Output
    // proc
    input                                                           core_clk,       // Proc Core
    input                                                           core_rst,       // Proc Core
    input                                                           start
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam MATRIX_DELAY = 4;
/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
/* arg */
wire                                                   s_rst_all;
wire [IMG_H_BITWIDTH-1 : 0]                            s_arg_img_src_h;
wire [IMG_V_BITWIDTH-1 : 0]                            s_arg_img_src_v;
wire                                                   s_start;

wire                                                   m_rst_all;
wire [IMG_H_BITWIDTH-1 : 0]                            m_arg_img_des_h;
wire [IMG_V_BITWIDTH-1 : 0]                            m_arg_img_des_v;
wire                                                   m_start;
wire                                                   m_scaler_done;

wire                                                   core_rst_all;
wire [IMG_H_BITWIDTH-1 : 0]                            core_arg_img_src_h;
wire [IMG_V_BITWIDTH-1 : 0]                            core_arg_img_src_v;
wire [IMG_H_BITWIDTH-1 : 0]                            core_arg_img_des_h;
wire [IMG_V_BITWIDTH-1 : 0]                            core_arg_img_des_v;
wire                                                   core_arg_mode;
wire [SF_BITWIDTH-1 : 0]                               core_arg_hsf;
wire [SF_BITWIDTH-1 : 0]                               core_arg_vsf;
wire                                                   core_start;
wire [KERNEL_COEF_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]scaler_coef;
/* image_line_in */
wire                                                   vin_axis_connect_ready;
wire                                                   vin_axis_connect_valid;
wire                                                   vin_axis_img_valid;
wire [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0]                  vin_axis_img_pixel;
wire                                                   vin_axis_img_done;
/* matrix_engine */
wire                                                   matrix_ram_m_axis_connect_ready;
wire                                                   matrix_ram_m_axis_connect_valid;
wire                                                   matrix_ram_read_stride;
wire                                                   matrix_ram_read_repeat;
wire                                                   matrix_ram_read_en;
wire                                                   matrix_ram_read_rsp_en;
wire [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]      matrix_ram_read_rsp_pixel;
wire                                                   matrix_ram_read_done;
/* conv_engine */
wire                                                   core_m_axis_connect_ready;
wire                                                   core_m_axis_connect_valid;
wire                                                   m_axis_core_valid;
wire [PIXEL_BITWIDTH-1 : 0]                            m_axis_core_pixel;
wire                                                   m_axis_core_done;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
scaler_ctrl #(
    .IMG_H_MAX                      ( IMG_H_MAX            ),
    .IMG_V_MAX                      ( IMG_V_MAX            ),
    .IMG_H_BITWIDTH                 ( IMG_H_BITWIDTH       ),
    .IMG_V_BITWIDTH                 ( IMG_V_BITWIDTH       ),
    .PAD_MAX                        ( PAD_MAX              ),
    .PAD_BITWIDTH                   ( PAD_BITWIDTH         ),
    .KERNEL_MAX                     ( KERNEL_MAX           ),
    .KERNEL_BITWIDTH                ( KERNEL_BITWIDTH      ),
    .KERNEL_COEF_BITWIDTH           ( KERNEL_COEF_BITWIDTH ),
    .SF_BITWIDTH                    ( SF_BITWIDTH          ),
    .SF_INT_BITWIDTH                ( SF_INT_BITWIDTH      ),
    .SF_FRAC_BITWIDTH               ( SF_FRAC_BITWIDTH     )
) inst_scaler_ctrl(
    .s_clk                          ( s_clk                ),
    .s_rst                          ( s_rst                ),
    .s_rst_all                      ( s_rst_all            ),
    .s_arg_img_src_h                ( s_arg_img_src_h      ),
    .s_arg_img_src_v                ( s_arg_img_src_v      ),
    .s_start                        ( s_start              ),

    .m_clk                          ( m_clk                ),
    .m_rst                          ( m_rst                ),
    .m_rst_all                      ( m_rst_all            ),
    .m_arg_img_des_h                ( m_arg_img_des_h      ),
    .m_arg_img_des_v                ( m_arg_img_des_v      ),
    .m_start                        ( m_start              ),

    .core_clk                       ( core_clk             ),
    .core_rst                       ( core_rst             ),
    .core_rst_all                   ( core_rst_all         ),
    .core_arg_img_src_h             ( core_arg_img_src_h   ),
    .core_arg_img_src_v             ( core_arg_img_src_v   ),
    .core_arg_img_des_h             ( core_arg_img_des_h   ),
    .core_arg_img_des_v             ( core_arg_img_des_v   ),
    .core_arg_mode                  ( core_arg_mode        ),
    .core_arg_hsf                   ( core_arg_hsf         ),
    .core_arg_vsf                   ( core_arg_vsf         ),
    .core_start                     ( core_start           ),

    .scaler_coef                    ( scaler_coef          ),

    .start                          ( start                )
);

scaler_vin #(
    .PIXEL_BITWIDTH                 ( PIXEL_BITWIDTH               ),
    .PIXEL_NUM                      ( PIXEL_NUM                    ),
    .IMG_H_MAX                      ( IMG_H_MAX                    ),
    .IMG_V_MAX                      ( IMG_V_MAX                    ),
    .IMG_H_BITWIDTH                 ( IMG_H_BITWIDTH               ),
    .IMG_V_BITWIDTH                 ( IMG_V_BITWIDTH               ),
    .PAD_MAX                        ( PAD_MAX                      ),
    .PAD_BITWIDTH                   ( PAD_BITWIDTH                 )
) inst_scaler_vin (
    .s_clk                          ( s_clk                        ),
    .s_rst                          ( s_rst_all                    ),
    .s_arg_img_src_v                ( s_arg_img_src_v              ),
    .s_arg_img_src_h                ( s_arg_img_src_h              ),
    .s_start                        ( s_start                      ),

    .s_axis_ready                   ( s_axis_ready                 ),
    .s_axis_valid                   ( s_axis_valid                 ),
    .s_axis_pixel                   ( s_axis_pixel                 ),
    .s_axis_sof                     ( s_axis_sof                   ),
    .s_axis_eol                     ( s_axis_eol                   ),

    .m_axis_connect_ready           ( vin_axis_connect_ready       ),
    .m_axis_connect_valid           ( vin_axis_connect_valid       ),
    .m_axis_img_valid               ( vin_axis_img_valid           ),
    .m_axis_img_pixel               ( vin_axis_img_pixel           ),
    .m_axis_img_done                ( vin_axis_img_done            )
);

scaler_matrix #(
    .PIXEL_BITWIDTH                 ( PIXEL_BITWIDTH                  ),
    .IMG_H_MAX                      ( IMG_H_MAX                       ),
    .IMG_V_MAX                      ( IMG_V_MAX                       ),
    .IMG_H_BITWIDTH                 ( IMG_H_BITWIDTH                  ),
    .IMG_V_BITWIDTH                 ( IMG_V_BITWIDTH                  ),
    .KERNEL_MAX                     ( KERNEL_MAX                      ),
    .KERNEL_BITWIDTH                ( KERNEL_BITWIDTH                 ),
    .MATRIX_DELAY                   ( MATRIX_DELAY                    )
)inst_scaler_matrix (
    .s_clk                          ( s_clk                           ),
    .s_rst                          ( s_rst_all                       ),
    .s_start                        ( s_start                         ),
    .s_axis_connect_ready           ( vin_axis_connect_ready          ),
    .s_axis_connect_valid           ( vin_axis_connect_valid          ),
    .s_axis_img_valid               ( vin_axis_img_valid              ),
    .s_axis_img_pixel               ( vin_axis_img_pixel              ),
    .s_axis_img_done                ( vin_axis_img_done               ),
    .core_clk                       ( core_clk                        ),
    .core_rst                       ( core_rst_all                    ),
    .core_start                     ( core_start                      ),
    .m_axis_connect_ready           ( matrix_ram_m_axis_connect_ready ),
    .m_axis_connect_valid           ( matrix_ram_m_axis_connect_valid ),
    .matrix_ram_read_stride         ( matrix_ram_read_stride          ),
    .matrix_ram_read_repeat         ( matrix_ram_read_repeat          ),
    .matrix_ram_read_en             ( matrix_ram_read_en              ),
    .matrix_ram_read_rsp_en         ( matrix_ram_read_rsp_en          ),
    .matrix_ram_read_rsp_pixel      ( matrix_ram_read_rsp_pixel       ),
    .matrix_ram_read_done           ( matrix_ram_read_done            )
);


scaler_core #(
    .PIXEL_BITWIDTH                 ( PIXEL_BITWIDTH                  ),
    .IMG_H_MAX                      ( IMG_H_MAX                       ),
    .IMG_V_MAX                      ( IMG_V_MAX                       ),
    .IMG_H_BITWIDTH                 ( IMG_H_BITWIDTH                  ),
    .IMG_V_BITWIDTH                 ( IMG_V_BITWIDTH                  ),
    .KERNEL_MAX                     ( KERNEL_MAX                      ),
    .KERNEL_BITWIDTH                ( KERNEL_BITWIDTH                 ),
    .KERNEL_COEF_BITWIDTH           ( KERNEL_COEF_BITWIDTH            ),
    .SF_BITWIDTH                    ( SF_BITWIDTH                     ),
    .SF_INT_BITWIDTH                ( SF_INT_BITWIDTH                 ),
    .SF_FRAC_BITWIDTH               ( SF_FRAC_BITWIDTH                ),
    .MATRIX_DELAY                   ( MATRIX_DELAY                    )
) inst_scaler_core (
    .core_clk                       ( core_clk                        ),
    .core_rst                       ( core_rst_all                    ),
    .core_arg_img_src_h             ( core_arg_img_src_h              ),
    .core_arg_img_src_v             ( core_arg_img_src_v              ),
    .core_arg_img_des_h             ( core_arg_img_des_h              ),
    .core_arg_img_des_v             ( core_arg_img_des_v              ),
    .core_arg_mode                  ( core_arg_mode                   ), // 0 = scaler down 1 = scaler up
    .core_arg_hsf                   ( core_arg_hsf                    ),
    .core_arg_vsf                   ( core_arg_vsf                    ),
    .core_start                     ( core_start                      ),
// conv coef
    .scaler_coef                    ( scaler_coef                     ),
// matrix pixel input (Interface using ram type)
    .s_axis_connect_ready           ( matrix_ram_m_axis_connect_ready ),
    .s_axis_connect_valid           ( matrix_ram_m_axis_connect_valid ),
    .matrix_ram_read_stride         ( matrix_ram_read_stride          ),   // stride curr line output
    .matrix_ram_read_repeat         ( matrix_ram_read_repeat          ),   // repeat curr line output
    .matrix_ram_read_en             ( matrix_ram_read_en              ),
    .matrix_ram_read_rsp_en         ( matrix_ram_read_rsp_en          ),
    .matrix_ram_read_rsp_pixel      ( matrix_ram_read_rsp_pixel       ),
    .matrix_ram_read_done           ( matrix_ram_read_done            ),
// conv result output
    .m_axis_connect_ready           ( core_m_axis_connect_ready       ),
    .m_axis_connect_valid           ( core_m_axis_connect_valid       ),
    .m_axis_core_valid              ( m_axis_core_valid               ),
    .m_axis_core_pixel              ( m_axis_core_pixel               ),
    .m_axis_core_done               ( m_axis_core_done                )
);

scaler_vout #(
    .PIXEL_BITWIDTH                 ( PIXEL_BITWIDTH                  ),
    .PIXEL_NUM                      ( PIXEL_NUM                       ),
    .IMG_H_MAX                      ( IMG_H_MAX                       ),
    .IMG_V_MAX                      ( IMG_V_MAX                       ),
    .IMG_H_BITWIDTH                 ( IMG_H_BITWIDTH                  ),
    .IMG_V_BITWIDTH                 ( IMG_V_BITWIDTH                  )
) inst_scaler_vout (
    .core_clk                       ( core_clk                        ),
    .core_rst                       ( core_rst_all                    ),
    .core_start                     ( core_start                      ),
    .core_arg_img_des_h             ( core_arg_img_des_h              ),
    .core_arg_img_des_v             ( core_arg_img_des_v              ),
    .s_axis_connect_ready           ( core_m_axis_connect_ready       ),
    .s_axis_connect_valid           ( core_m_axis_connect_valid       ),
    .s_axis_core_valid              ( m_axis_core_valid               ),
    .s_axis_core_pixel              ( m_axis_core_pixel               ),
    .s_axis_core_done               ( m_axis_core_done                ),
    .m_clk                          ( m_clk                           ),
    .m_rst                          ( m_rst_all                       ),
    .m_start                        ( m_start                         ),
    .m_axis_ready                   ( m_axis_ready                    ),
    .m_axis_valid                   ( m_axis_valid                    ),
    .m_axis_pixel                   ( m_axis_pixel                    ),
    .m_axis_sof                     ( m_axis_sof                      ),
    .m_axis_eol                     ( m_axis_eol                      ),
    .m_scaler_done                  ( m_scaler_done                   )
);

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction


endmodule