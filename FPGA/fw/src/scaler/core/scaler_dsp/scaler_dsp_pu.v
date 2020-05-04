`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Description :
*   @Create : 2020.04.20
*   @Modify :
******************************************************************************/
module scaler_dsp_pu
#(
    parameter PIXEL_BITWIDTH       = 8, // Int8
    parameter KERNEL_MAX           = 4,
    parameter KERNEL_COEF_BITWIDTH = 8, // Int8 8Q6
    parameter VRLT_BITWIDTH        = 18
)(
    input                                                       clk,
    input                                                       din_en,
    input       [KERNEL_MAX*KERNEL_COEF_BITWIDTH-1 : 0]         din_coef,
    input       [KERNEL_MAX*PIXEL_BITWIDTH-1 : 0]               din_pixel_1,
    input       [KERNEL_MAX*PIXEL_BITWIDTH-1 : 0]               din_pixel_2,
    output                                                      dout_en,
    output      [VRLT_BITWIDTH-1 : 0]                           dout_result_1,
    output      [VRLT_BITWIDTH-1 : 0]                           dout_result_2
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam MULT_BITWIDTH = PIXEL_BITWIDTH + KERNEL_COEF_BITWIDTH;
/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
wire        [KERNEL_MAX*1-1 : 0]                       dsp_dout_en;
wire signed [KERNEL_MAX*MULT_BITWIDTH-1 : 0]           dsp_dout_ab;
wire signed [KERNEL_MAX*MULT_BITWIDTH-1 : 0]           dsp_dout_db;
reg                                                    com_1_en = 1'd0;
reg                                                    com_2_en = 1'd0;
reg  signed [MULT_BITWIDTH+1-1 : 0]                    ab_1_1;
reg  signed [MULT_BITWIDTH+1-1 : 0]                    ab_1_2;
reg  signed [MULT_BITWIDTH+2-1 : 0]                    ab_2;
reg  signed [MULT_BITWIDTH+1-1 : 0]                    db_1_1;
reg  signed [MULT_BITWIDTH+1-1 : 0]                    db_1_2;
reg  signed [MULT_BITWIDTH+2-1 : 0]                    db_2;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
genvar i;
generate
    for (i = 0; i < KERNEL_MAX; i=i+1) begin
        dsp_mux inst_dsp_mux(
            .clk       ( clk ),
            .din_en    ( din_en                                                                ),
            .din_a     ( din_pixel_1 [PIXEL_BITWIDTH      *(i+1)-1 : PIXEL_BITWIDTH      *(i)] ), // pixel 1
            .din_b     ( din_coef    [KERNEL_COEF_BITWIDTH*(i+1)-1 : KERNEL_COEF_BITWIDTH*(i)] ), // coef
            .din_d     ( din_pixel_2 [PIXEL_BITWIDTH      *(i+1)-1 : PIXEL_BITWIDTH      *(i)] ), // pixel 2
            .dout_en   ( dsp_dout_en [i]                                                       ),
            .dout_ab   ( dsp_dout_ab [MULT_BITWIDTH       *(i+1)-1 : MULT_BITWIDTH       *(i)] ),
            .dout_db   ( dsp_dout_db [MULT_BITWIDTH       *(i+1)-1 : MULT_BITWIDTH       *(i)] )
        );
    end
endgenerate


always @ (posedge clk) begin
    {com_2_en, com_1_en} <= {com_1_en, dsp_dout_en[0]};
    if(dsp_dout_en[0]) begin
        ab_1_1 <=   dsp_dout_ab [MULT_BITWIDTH*(0+1)-1 : MULT_BITWIDTH*(0)] +
                    dsp_dout_ab [MULT_BITWIDTH*(1+1)-1 : MULT_BITWIDTH*(1)] ;

        ab_1_2 <=   dsp_dout_ab [MULT_BITWIDTH*(2+1)-1 : MULT_BITWIDTH*(2)] +
                    dsp_dout_ab [MULT_BITWIDTH*(3+1)-1 : MULT_BITWIDTH*(3)] ;

        db_1_1 <=   dsp_dout_db [MULT_BITWIDTH*(0+1)-1 : MULT_BITWIDTH*(0)] +
                    dsp_dout_db [MULT_BITWIDTH*(1+1)-1 : MULT_BITWIDTH*(1)] ;

        db_1_2 <=   dsp_dout_db [MULT_BITWIDTH*(2+1)-1 : MULT_BITWIDTH*(2)] +
                    dsp_dout_db [MULT_BITWIDTH*(3+1)-1 : MULT_BITWIDTH*(3)] ;
    end

    if(com_1_en) begin
        ab_2   <= ab_1_1 + ab_1_2;
        db_2   <= db_1_1 + db_1_2;
    end
end

assign dout_en       = com_2_en;
assign dout_result_1 = ab_2;
assign dout_result_2 = db_2;


generate
    `ifdef SIM
        wire signed [VRLT_BITWIDTH+2-1 : 0]    result_1;
        wire signed [VRLT_BITWIDTH+2-1 : 0]    result_2;

        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_a_d1;
        reg  signed [KERNEL_COEF_BITWIDTH-1 : 0] dsp_din_b_d1;
        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_d_d1;

        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_a_d2;
        reg  signed [KERNEL_COEF_BITWIDTH-1 : 0] dsp_din_b_d2;
        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_d_d2;

        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_a_d3;
        reg  signed [KERNEL_COEF_BITWIDTH-1 : 0] dsp_din_b_d3;
        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_d_d3;

        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_a_d4;
        reg  signed [KERNEL_COEF_BITWIDTH-1 : 0] dsp_din_b_d4;
        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_d_d4;

        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_a_d5;
        reg  signed [KERNEL_COEF_BITWIDTH-1 : 0] dsp_din_b_d5;
        reg  signed [PIXEL_BITWIDTH-1 : 0]       dsp_din_d_d5;

        reg                                      err_ab  = 1'd0;
        reg                                      err_db  = 1'd0;

        always @ (posedge clk) begin
            dsp_din_a_d1 <= din_pixel_1  [PIXEL_BITWIDTH      *1-1 : PIXEL_BITWIDTH      *0];
            dsp_din_b_d1 <= din_coef     [KERNEL_COEF_BITWIDTH*1-1 : KERNEL_COEF_BITWIDTH*0];
            dsp_din_d_d1 <= din_pixel_2  [KERNEL_COEF_BITWIDTH*1-1 : KERNEL_COEF_BITWIDTH*0];

            dsp_din_a_d2 <= dsp_din_a_d1;
            dsp_din_b_d2 <= dsp_din_b_d1;
            dsp_din_d_d2 <= dsp_din_d_d1;

            dsp_din_a_d3 <= dsp_din_a_d2;
            dsp_din_b_d3 <= dsp_din_b_d2;
            dsp_din_d_d3 <= dsp_din_d_d2;

            dsp_din_a_d4 <= dsp_din_a_d3;
            dsp_din_b_d4 <= dsp_din_b_d3;
            dsp_din_d_d4 <= dsp_din_d_d3;

            dsp_din_a_d5 <= dsp_din_a_d4;
            dsp_din_b_d5 <= dsp_din_b_d4;
            dsp_din_d_d5 <= dsp_din_d_d4;

        end

        assign result_1 = dsp_din_a_d5 * dsp_din_b_d5 * 4;
        assign result_2 = dsp_din_d_d5 * dsp_din_b_d5 * 4;

        always @ (posedge clk) begin
            err_ab  <= (result_1 != ab_2);
            err_db  <= (result_2 != db_2);
        end
    `endif
endgenerate

endmodule