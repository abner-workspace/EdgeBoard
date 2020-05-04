`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Gitee  : https://gitee.com/abnerwork/
* Csdn   :
* Description :
*   @Create : 2019.07.22
*
*   @Modify : 2020-04-06
*
******************************************************************************/
module scaler_stream
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
    parameter MATRIX_DELAY         = 7
)(
    input                                                           core_clk,
    input                                                           core_rst,
    input      [IMG_H_BITWIDTH-1 : 0]                               core_arg_img_src_h,
    input      [IMG_V_BITWIDTH-1 : 0]                               core_arg_img_src_v,
    input      [IMG_H_BITWIDTH-1 : 0]                               core_arg_img_des_h,
    input      [IMG_V_BITWIDTH-1 : 0]                               core_arg_img_des_v,
    input                                                           core_arg_mode,                              // 0 = scaler down 1 = scaler up
    input      [SF_BITWIDTH-1 : 0]                                  core_arg_hsf,                               // 24Q20
    input      [SF_BITWIDTH-1 : 0]                                  core_arg_vsf,                               // 24Q20
    input                                                           core_start,
// conv coef
    input       [KERNEL_COEF_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]  scaler_coef,
// matrix pixel input (Interface using ram type)
    output reg                                                      s_axis_connect_ready,
    input                                                           s_axis_connect_valid,
    output                                                          matrix_ram_read_stride,                 // stride curr line output
    output                                                          matrix_ram_read_repeat,                 // repeat curr line output
    output                                                          matrix_ram_read_en,
    input                                                           matrix_ram_read_rsp_en,
    input      [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]         matrix_ram_read_rsp_pixel,
    output                                                          matrix_ram_read_done,
// conv result output
    input                                                           m_axis_connect_ready,
    output reg                                                      m_axis_connect_valid,
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
localparam  ST_IDLE           = 0,
            ST_STATE          = 1,
            ST_CONNECT_SLAVE  = 2,
            ST_CONNECT_MASTER = 3,
            ST_PREPARE        = 4,
            ST_STREAM         = 5,
            ST_NEXT           = 6;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg  [3 : 0]                        state_curr = ST_IDLE;
reg  [3 : 0]                        state_next = ST_IDLE;
wire                                connect_ok;
wire                                scaler_lut_rst;
wire                                scaler_lut_v_start;
wire                                scaler_lut_h_start;
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
always @ (posedge core_clk) begin
    if(core_rst) begin
        state_curr <= ST_IDLE;
    end
    else begin
        state_curr <= state_next;
    end
end

always @ (*) begin
    case (state_curr)
        ST_IDLE           : begin state_next = core_start              ? ST_STATE          : state_curr; end
        ST_STATE          : begin state_next = ST_CONNECT_SLAVE;                                         end
        ST_CONNECT_SLAVE  : begin state_next = connect_ok              ? ST_CONNECT_MASTER : state_curr; end
        ST_CONNECT_MASTER : begin state_next = matrix_ram_read_stride  ? ST_NEXT           :
                                               connect_ok              ? ST_PREPARE        : state_curr; end
        ST_PREPARE        : begin state_next = ST_STREAM;                                                end
        ST_STREAM         : begin state_next = matrix_ram_read_done    ? ST_NEXT           : state_curr; end
        ST_NEXT           : begin state_next = ST_STATE;                                                 end
        default           : begin state_next = ST_IDLE; end
    endcase
end


assign scaler_lut_rst     = (state_curr == ST_IDLE);
assign scaler_lut_v_start = (state_curr == ST_STATE);
assign scaler_lut_h_start = (state_curr == ST_PREPARE);

// fsm control signal
assign connect_ok = (s_axis_connect_ready & s_axis_connect_valid) | (m_axis_connect_ready & m_axis_connect_valid);

// connect
always @ (posedge core_clk) begin
    if(state_curr == ST_CONNECT_SLAVE) begin
        if(s_axis_connect_ready & s_axis_connect_valid) begin
            s_axis_connect_ready <= 1'd0;
        end
        else begin
            s_axis_connect_ready <= 1'd1;
        end
    end
    else begin
        s_axis_connect_ready <= 1'd0;
    end
end

always @ (posedge core_clk) begin
    if(state_curr == ST_CONNECT_MASTER) begin
        if(m_axis_connect_ready & m_axis_connect_valid) begin
            m_axis_connect_valid <= 1'd0;
        end
        else if(~matrix_ram_read_stride) begin
            m_axis_connect_valid <= 1'd1;
        end
    end
    else begin
        m_axis_connect_valid <= 1'd0;
    end
end

scaler_lut #(
    .PIXEL_BITWIDTH            ( PIXEL_BITWIDTH       ),
    .IMG_H_BITWIDTH            ( IMG_H_BITWIDTH       ),
    .IMG_V_BITWIDTH            ( IMG_V_BITWIDTH       ),
    .KERNEL_MAX                ( KERNEL_MAX           ),
    .KERNEL_BITWIDTH           ( KERNEL_BITWIDTH      ),
    .KERNEL_COEF_BITWIDTH      ( KERNEL_COEF_BITWIDTH ),
    .SF_BITWIDTH               ( SF_BITWIDTH          ),
    .SF_INT_BITWIDTH           ( SF_INT_BITWIDTH      ),
    .SF_FRAC_BITWIDTH          ( SF_FRAC_BITWIDTH     ),
    .MATRIX_DELAY              ( MATRIX_DELAY         )
) inst_scaler_lut(
    .core_clk                  ( core_clk                  ),
    .core_rst                  ( scaler_lut_rst            ),
    .core_arg_img_src_h        ( core_arg_img_src_h        ),
    .core_arg_img_src_v        ( core_arg_img_src_v        ),
    .core_arg_img_des_h        ( core_arg_img_des_h        ),
    .core_arg_img_des_v        ( core_arg_img_des_v        ),
    .core_arg_mode             ( core_arg_mode             ),
    .core_arg_hsf              ( core_arg_hsf              ),
    .core_arg_vsf              ( core_arg_vsf              ),
    .scaler_coef               ( scaler_coef               ),
    .v_start                   ( scaler_lut_v_start        ),
    .h_start                   ( scaler_lut_h_start        ),
    .matrix_ram_read_stride    ( matrix_ram_read_stride    ),
    .matrix_ram_read_repeat    ( matrix_ram_read_repeat    ),
    .matrix_ram_read_en        ( matrix_ram_read_en        ),
    .matrix_ram_read_rsp_en    ( matrix_ram_read_rsp_en    ),
    .matrix_ram_read_rsp_pixel ( matrix_ram_read_rsp_pixel ),
    .matrix_ram_read_done      ( matrix_ram_read_done      ),
    .m_axis_scaler_valid       ( m_axis_scaler_valid       ),
    .m_axis_scaler_pixel       ( m_axis_scaler_pixel       ),
    .m_axis_scaler_coef_h      ( m_axis_scaler_coef_h      ),
    .m_axis_scaler_coef_v      ( m_axis_scaler_coef_v      ),
    .m_axis_scaler_done        ( m_axis_scaler_done        )
 );




function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule