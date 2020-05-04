`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Description :
*   @Create : 2020.04.20
*   @Modify :
******************************************************************************/
module scaler_dsp_v
#(
    parameter PIXEL_BITWIDTH       = 8, // Int8
    parameter KERNEL_MAX           = 4,
    parameter KERNEL_COEF_BITWIDTH = 8, // Int8 8Q6
    parameter VRLT_BITWIDTH        = 18
)(
    input                                                   clk,
    input                                                   din_en,
    input   [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]         din_coef,
    input   [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]    din_pixel,
    output                                                  dout_en,
    output  [VRLT_BITWIDTH*KERNEL_MAX-1 : 0]                dout_result
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam PU_MAX = KERNEL_MAX/2;
/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
wire [PU_MAX-1 : 0] dout_en_array;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
genvar i;
generate
    for (i = 0; i < PU_MAX; i=i+1) begin
            scaler_dsp_pu #(
                .PIXEL_BITWIDTH       ( PIXEL_BITWIDTH       ),
                .KERNEL_MAX           ( KERNEL_MAX           ),
                .KERNEL_COEF_BITWIDTH ( KERNEL_COEF_BITWIDTH ),
                .VRLT_BITWIDTH        ( VRLT_BITWIDTH        )
            ) inst_scaler_dsp_pu(
                .clk                  ( clk                  ),
                .din_en               ( din_en               ),
                .din_coef             ( din_coef             ),
                .din_pixel_1          ( din_pixel     [(PIXEL_BITWIDTH*KERNEL_MAX)*(2*i+0+1)-1 : (PIXEL_BITWIDTH*KERNEL_MAX)*(2*i+0)] ),
                .din_pixel_2          ( din_pixel     [(PIXEL_BITWIDTH*KERNEL_MAX)*(2*i+1+1)-1 : (PIXEL_BITWIDTH*KERNEL_MAX)*(2*i+1)] ),
                .dout_en              ( dout_en_array [i]    ),
                .dout_result_1        ( dout_result   [VRLT_BITWIDTH              *(2*i+0+1)-1 : VRLT_BITWIDTH              *(2*i+0)] ),
                .dout_result_2        ( dout_result   [VRLT_BITWIDTH              *(2*i+1+1)-1 : VRLT_BITWIDTH              *(2*i+1)] )
            );
    end
endgenerate

assign dout_en = dout_en_array[0];


generate
    `ifdef SIM
        wire [VRLT_BITWIDTH-1 : 0] result1;
        wire [VRLT_BITWIDTH-1 : 0] result2;
        wire [VRLT_BITWIDTH-1 : 0] result3;
        wire [VRLT_BITWIDTH-1 : 0] result4;
        wire                         yes;
        assign {result4, result3, result2, result1} = dout_result;
        assign yes = (result4 == result3) & (result3 == result2) & (result2 == result1);
    `endif
endgenerate

endmodule