`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Csdn   :
* Description :
*   @Create : 2019-07-22
*
*   @Modify : 2020-04-06
*           Note : KERNEL_MAX >= 2
******************************************************************************/
module scaler_lut
#(
    parameter PIXEL_BITWIDTH       = 8,
    parameter IMG_H_BITWIDTH       = 13,
    parameter IMG_V_BITWIDTH       = 13,
    parameter KERNEL_MAX           = 4,
    parameter KERNEL_BITWIDTH      = CLOG2(KERNEL_MAX),
    parameter KERNEL_COEF_BITWIDTH = 8,  // 8Q6
    parameter SF_BITWIDTH          = 24, // 24Q20
    parameter SF_INT_BITWIDTH      = 20,
    parameter SF_FRAC_BITWIDTH     = 4,
    parameter MATRIX_DELAY         = 2
)(
    input                                                           core_clk,
    input                                                           core_rst,
    input      [IMG_H_BITWIDTH-1 : 0]                               core_arg_img_src_h,
    input      [IMG_V_BITWIDTH-1 : 0]                               core_arg_img_src_v,
    input      [IMG_H_BITWIDTH-1 : 0]                               core_arg_img_des_h,
    input      [IMG_V_BITWIDTH-1 : 0]                               core_arg_img_des_v,
    input                                                           core_arg_mode,            // 0 = scaler down 1 = scaler up
    input      [SF_BITWIDTH-1 : 0]                                  core_arg_hsf,             // 24Q20
    input      [SF_BITWIDTH-1 : 0]                                  core_arg_vsf,             // 24Q20
    input      [KERNEL_COEF_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]   scaler_coef,

    input                                                           v_start,
    input                                                           h_start,
    output                                                          matrix_ram_read_stride, // stride curr line output
    output                                                          matrix_ram_read_repeat, // repeat curr line output
    output                                                          matrix_ram_read_en,
    input                                                           matrix_ram_read_rsp_en,
    input      [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]         matrix_ram_read_rsp_pixel,
    output                                                          matrix_ram_read_done,
    output                                                          m_axis_scaler_valid,
    output     [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]         m_axis_scaler_pixel,
    output     [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]              m_axis_scaler_coef_h,
    output     [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]              m_axis_scaler_coef_v,
    output                                                          m_axis_scaler_done
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
wire [KERNEL_BITWIDTH-1 : 0] m_axis_scaler_h;
wire [KERNEL_BITWIDTH-1 : 0] m_axis_scaler_v;
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/

scaler_lut_h #(
    .PIXEL_BITWIDTH            ( PIXEL_BITWIDTH            ),
    .IMG_H_BITWIDTH            ( IMG_H_BITWIDTH            ),
    .KERNEL_MAX                ( KERNEL_MAX                ),
    .KERNEL_BITWIDTH           ( KERNEL_BITWIDTH           ),
    .SF_BITWIDTH               ( SF_BITWIDTH               ),
    .SF_INT_BITWIDTH           ( SF_INT_BITWIDTH           ),
    .SF_FRAC_BITWIDTH          ( SF_FRAC_BITWIDTH          ),
    .MATRIX_DELAY              ( MATRIX_DELAY              )
) inst_scaler_lut_h(
    .core_clk                  ( core_clk                  ),
    .core_rst                  ( core_rst                  ),
    .core_arg_img_src_h        ( core_arg_img_src_h        ),
    .core_arg_img_des_h        ( core_arg_img_des_h        ),
    .core_arg_mode             ( core_arg_mode             ), // 0 = scaler down 1 = scaler up
    .core_arg_hsf              ( core_arg_hsf              ), // 24Q20
    .h_start                   ( h_start                   ),
    .matrix_ram_read_en        ( matrix_ram_read_en        ),
    .matrix_ram_read_rsp_en    ( matrix_ram_read_rsp_en    ),
    .matrix_ram_read_rsp_pixel ( matrix_ram_read_rsp_pixel ),
    .matrix_ram_read_done      ( matrix_ram_read_done      ),
    .m_axis_scaler_valid       ( m_axis_scaler_valid       ),
    .m_axis_scaler_pixel       ( m_axis_scaler_pixel       ),
    .m_axis_scaler_h           ( m_axis_scaler_h           ),
    .m_axis_scaler_done        ( m_axis_scaler_done        )
);

scaler_lut_v #(
    .IMG_V_BITWIDTH            ( IMG_V_BITWIDTH            ),
    .KERNEL_MAX                ( KERNEL_MAX                ),
    .KERNEL_BITWIDTH           ( KERNEL_BITWIDTH           ),
    .SF_BITWIDTH               ( SF_BITWIDTH               ),
    .SF_INT_BITWIDTH           ( SF_INT_BITWIDTH           ),
    .SF_FRAC_BITWIDTH          ( SF_FRAC_BITWIDTH          )
) inst_scaler_lut_v(
    .core_clk                  ( core_clk                  ),
    .core_rst                  ( core_rst                  ),
    .core_arg_img_src_v        ( core_arg_img_src_v        ),
    .core_arg_img_des_v        ( core_arg_img_des_v        ),
    .core_arg_mode             ( core_arg_mode             ),
    .core_arg_vsf              ( core_arg_vsf              ),
    .v_start                   ( v_start                   ),
    .matrix_ram_read_stride    ( matrix_ram_read_stride    ),
    .matrix_ram_read_repeat    ( matrix_ram_read_repeat    ),
    .m_axis_scaler_v           ( m_axis_scaler_v           )
);

assign m_axis_scaler_coef_h = (m_axis_scaler_h == 0) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(0+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(0)] :
                              (m_axis_scaler_h == 1) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(1+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(1)] :
                              (m_axis_scaler_h == 2) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(2+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(2)] :
                              (m_axis_scaler_h == 3) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(3+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(3)] :
                                                    {(KERNEL_COEF_BITWIDTH*KERNEL_MAX){1'd0}};

assign m_axis_scaler_coef_v = (m_axis_scaler_v == 0) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(0+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(0)] :
                              (m_axis_scaler_v == 1) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(1+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(1)] :
                              (m_axis_scaler_v == 2) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(2+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(2)] :
                              (m_axis_scaler_v == 3) ? scaler_coef[(KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(3+1)-1 : (KERNEL_COEF_BITWIDTH*KERNEL_MAX)*(3)] :
                                                    {(KERNEL_COEF_BITWIDTH*KERNEL_MAX){1'd0}};



function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule