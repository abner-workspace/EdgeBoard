`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Description :
*   @Create : 2019.07.22
*
*   @Modify : 2020-04-06
******************************************************************************/
module scaler_dsp
#(
    parameter PIXEL_BITWIDTH       = 8,
    parameter KERNEL_MAX           = 4,
    parameter KERNEL_COEF_BITWIDTH = 8  // 8Q6
)(
    input                                                   core_clk,
    input                                                   core_rst,
    input                                                   s_axis_scaler_valid,
    input      [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] s_axis_scaler_pixel,
    input      [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]      s_axis_scaler_coef_h,
    input      [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]      s_axis_scaler_coef_v,
    input                                                   s_axis_scaler_done,
    output                                                  m_axis_core_valid,
    output     [PIXEL_BITWIDTH-1 : 0]                       m_axis_core_pixel,
    output                                                  m_axis_core_done
);

/*******************************************************************************
* bicubic:
*   out(1,1) = v(1, KERNEL_MAX) * in(KERNEL_MAX, KERNEL_MAX) * h(KERNEL_MAX, 1)
*
********************************************************************************/

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam VRLT_BITWIDTH = PIXEL_BITWIDTH + KERNEL_COEF_BITWIDTH + KERNEL_MAX/2;
localparam HRLT_BITWIDTH = 48;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
wire                                         vout_en;
wire [VRLT_BITWIDTH*KERNEL_MAX-1 : 0]        vout_vrlt;
wire [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0] s_axis_scaler_coef_h_d3;
wire [HRLT_BITWIDTH-1 : 0]                   vout_hrlt;
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/

scaler_dsp_v #(
    .PIXEL_BITWIDTH         ( PIXEL_BITWIDTH         ),
    .KERNEL_MAX             ( KERNEL_MAX             ),
    .KERNEL_COEF_BITWIDTH   ( KERNEL_COEF_BITWIDTH   ),
    .VRLT_BITWIDTH          ( VRLT_BITWIDTH          )
)inst_scaler_dsp_v(
    .clk                    ( core_clk               ),
    .din_en                 ( s_axis_scaler_valid    ),
    .din_coef               ( s_axis_scaler_coef_v   ),
    .din_pixel              ( s_axis_scaler_pixel    ),
    .dout_en                ( vout_en                ),
    .dout_result            ( vout_vrlt              )
);

scaler_dsp_h #(
    .KERNEL_MAX             ( KERNEL_MAX             ),
    .KERNEL_COEF_BITWIDTH   ( KERNEL_COEF_BITWIDTH   ),
    .VRLT_BITWIDTH          ( VRLT_BITWIDTH          ),
    .HRLT_BITWIDTH          ( HRLT_BITWIDTH          )
)inst_scaler_dsp_h(
    .clk                    ( core_clk               ),
    .din_en                 ( vout_en                ),
    .din_coef               ( s_axis_scaler_coef_h_d3),
    .din_vrlt               ( vout_vrlt              ),
    .dout_en                ( m_axis_core_valid      ),
    .dout_hrlt              ( vout_hrlt              )
);

shift_delay #(
    .DELAY                  ( 5                               ),
    .BITWIDTH               ( KERNEL_COEF_BITWIDTH*KERNEL_MAX )
) inst_shift_delay_data(
    .clk                    ( core_clk                        ),
    .i                      ( s_axis_scaler_coef_h            ),
    .o                      ( s_axis_scaler_coef_h_d3         )
);

shift_delay #(
    .DELAY                  ( 10 ),
    .BITWIDTH               ( 1  )
) inst_shift_delay_ctrl(
    .clk                    ( core_clk                       ),
    .i                      ( s_axis_scaler_done             ),
    .o                      ( m_axis_core_done               )
);

assign m_axis_core_pixel = vout_hrlt[19:12];

generate
    `ifdef SIM
        wire [VRLT_BITWIDTH-1 : 0] vrlt0;
        wire [VRLT_BITWIDTH-1 : 0] vrlt1;
        wire [VRLT_BITWIDTH-1 : 0] vrlt2;
        wire [VRLT_BITWIDTH-1 : 0] vrlt3;

        reg  signed [10*PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] pixel ;
        reg  signed [10*KERNEL_COEF_BITWIDTH*KERNEL_MAX     -1 : 0] coef_h;
        reg  signed [10*KERNEL_COEF_BITWIDTH*KERNEL_MAX     -1 : 0] coef_v;
        wire signed [29 : 0]                                        rlt;

        wire signed [PIXEL_BITWIDTH-1       : 0] pixel00;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel10;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel20;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel30;

        wire signed [PIXEL_BITWIDTH-1       : 0] pixel01;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel11;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel21;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel31;

        wire signed [PIXEL_BITWIDTH-1       : 0] pixel02;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel12;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel22;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel32;

        wire signed [PIXEL_BITWIDTH-1       : 0] pixel03;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel13;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel23;
        wire signed [PIXEL_BITWIDTH-1       : 0] pixel33;

        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] v0;
        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] v1;
        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] v2;
        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] v3;

        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] h0;
        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] h1;
        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] h2;
        wire signed [KERNEL_COEF_BITWIDTH-1 : 0] h3;

        reg                                      err;

        always @ (posedge core_clk) begin
            pixel  <= {pixel [(9*PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX)-1 : 0], s_axis_scaler_pixel };
            coef_h <= {coef_h[(9*KERNEL_COEF_BITWIDTH*KERNEL_MAX     )-1 : 0], s_axis_scaler_coef_h};
            coef_v <= {coef_v[(9*KERNEL_COEF_BITWIDTH*KERNEL_MAX     )-1 : 0], s_axis_scaler_coef_v};
        end


        assign {pixel33,
                pixel23,
                pixel13,
                pixel03,

                pixel32,
                pixel22,
                pixel12,
                pixel02,

                pixel31,
                pixel21,
                pixel11,
                pixel01,

                pixel30,
                pixel20,
                pixel10,
                pixel00} = pixel [(10*PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX)-1 : (9*PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX)];

        assign {v3,
                v2,
                v1,
                v0} = coef_v[(10*KERNEL_COEF_BITWIDTH*KERNEL_MAX)-1 : (9*KERNEL_COEF_BITWIDTH*KERNEL_MAX)];

        assign {h3,
                h2,
                h1,
                h0} = coef_h[(10*KERNEL_COEF_BITWIDTH*KERNEL_MAX)-1 : (9*KERNEL_COEF_BITWIDTH*KERNEL_MAX)];

        assign rlt = (v3 * pixel30 +
                      v2 * pixel20 +
                      v1 * pixel10 +
                      v0 * pixel00  ) * h0 +
                     (v3 * pixel31 +
                      v2 * pixel21 +
                      v1 * pixel11 +
                      v0 * pixel01  ) * h1 +
                     (v3 * pixel32 +
                      v2 * pixel22 +
                      v1 * pixel12 +
                      v0 * pixel02  ) * h2 +
                     (v3 * pixel33 +
                      v2 * pixel23 +
                      v1 * pixel13 +
                      v0 * pixel03  ) * h3;

        assign {vrlt3,
                vrlt2,
                vrlt1,
                vrlt0} = vout_vrlt;

        always @ (posedge core_clk) begin
            err <= ($signed(rlt) == $signed(vout_hrlt)) ? 1'd0 : 1'd1;
        end
    `endif
endgenerate

endmodule