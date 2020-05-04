`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Description :
*   @Create : 2020.04.20
*   @Modify :
******************************************************************************/
module scaler_dsp_h
#(
    parameter KERNEL_MAX           = 4,
    parameter KERNEL_COEF_BITWIDTH = 8, // Int8 8Q6
    parameter VRLT_BITWIDTH        = 18,
    parameter HRLT_BITWIDTH        = 48
)(
    input                                                      clk,
    input                                                      din_en,
    input      [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]         din_coef,
    input      [VRLT_BITWIDTH*KERNEL_MAX-1 : 0]                din_vrlt,
    output                                                     dout_en,
    output     [HRLT_BITWIDTH-1 : 0]                           dout_hrlt
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
// DSP = A*B+C
// A_BITWIDTH = 18
// B_BITWIDTH = 8
// C_BITWIDTH = 48
// OUTPUT     = FULL
// Tier_B5    = EN
// Tier_C6    = EN
wire [KERNEL_MAX-1 : 0]                       dsp_en;
wire [VRLT_BITWIDTH*KERNEL_MAX-1 : 0]         dsp_a;
wire [KERNEL_COEF_BITWIDTH*KERNEL_MAX-1 : 0]  dsp_b;
wire [HRLT_BITWIDTH*KERNEL_MAX-1 : 0]         dsp_c;
wire [HRLT_BITWIDTH*KERNEL_MAX-1 : 0]         dsp_p;
reg  [1 : 0]                                  dly = 2'd0;
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
genvar i;
generate
    for (i = 0; i < KERNEL_MAX; i=i+1) begin
        shift_delay #(
            .DELAY    ( i ),
            .BITWIDTH ( 1+KERNEL_COEF_BITWIDTH+VRLT_BITWIDTH )
        ) inst_shift_delay(
            .clk      ( clk ),
            .i        ( {
                            din_en,
                            din_vrlt [VRLT_BITWIDTH       *(i+1)-1 : VRLT_BITWIDTH       *(i)],
                            din_coef [KERNEL_COEF_BITWIDTH*(i+1)-1 : KERNEL_COEF_BITWIDTH*(i)]
                        }),
            .o        ( {
                            dsp_en   [i],
                            dsp_a    [VRLT_BITWIDTH       *(i+1)-1 : VRLT_BITWIDTH       *(i)],
                            dsp_b    [KERNEL_COEF_BITWIDTH*(i+1)-1 : KERNEL_COEF_BITWIDTH*(i)]
                        })
        );

        // DSP48 INT8 Mux: p = a * b + c
        // Pipleline Options = Expert
        // Tier : B5 C6
        // Control prots = CE_Global
        // Input Port Properties = A18 B8 C48
        // Output Port Properties = Full Precision(48)
        // Delay      = 2
        ip_scaler_dsp_h ip_scaler_dsp_h (
            .CLK( clk          ),  // input wire CLK
            .CE ( dsp_en [i]   ),
            .A  ( dsp_a  [VRLT_BITWIDTH       *(i+1)-1 : VRLT_BITWIDTH       *(i)] ),      // input  wire [17 : 0] A
            .B  ( dsp_b  [KERNEL_COEF_BITWIDTH*(i+1)-1 : KERNEL_COEF_BITWIDTH*(i)] ),      // input  wire [7 : 0]  B
            .C  ( dsp_c  [HRLT_BITWIDTH       *(i+1)-1 : HRLT_BITWIDTH       *(i)] ),      // input  wire [29 : 0] C
            .P  ( dsp_p  [HRLT_BITWIDTH       *(i+1)-1 : HRLT_BITWIDTH       *(i)] )       // output wire [29 : 0] P
        );

        if(i == 0) begin
            assign dsp_c[HRLT_BITWIDTH*(i+1  )-1 : HRLT_BITWIDTH*(i  )] = {HRLT_BITWIDTH{1'd0}};
        end
        else begin
            assign dsp_c[HRLT_BITWIDTH*(i+1  )-1 : HRLT_BITWIDTH*(i  )] =
                   dsp_p[HRLT_BITWIDTH*(i+1-1)-1 : HRLT_BITWIDTH*(i-1)];
        end
    end
endgenerate

always @ (posedge clk) begin
    dly <= {dly[0], dsp_en[KERNEL_MAX-1]};
end

assign dout_en   = dly[1];
assign dout_hrlt = dsp_p[HRLT_BITWIDTH*(KERNEL_MAX)-1 : HRLT_BITWIDTH*(KERNEL_MAX-1)];


genvar k;
generate
    `ifdef SIM
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef1_d1;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt1_d1;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef2_d1;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt2_d1;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef3_d1;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt3_d1;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef4_d1;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt4_d1;

        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef1_d2;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt1_d2;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef2_d2;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt2_d2;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef3_d2;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt3_d2;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef4_d2;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt4_d2;

        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef1_d3;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt1_d3;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef2_d3;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt2_d3;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef3_d3;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt3_d3;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef4_d3;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt4_d3;

        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef1_d4;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt1_d4;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef2_d4;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt2_d4;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef3_d4;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt3_d4;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef4_d4;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt4_d4;

        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef1_d5;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt1_d5;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef2_d5;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt2_d5;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef3_d5;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt3_d5;
        reg signed [KERNEL_COEF_BITWIDTH-1 : 0] coef4_d5;
        reg signed [VRLT_BITWIDTH-1 : 0]        vrlt4_d5;

        wire       [HRLT_BITWIDTH-1 : 0]        hrlt;
        always @ (posedge clk) begin
            {coef1_d5, coef1_d4, coef1_d3, coef1_d2, coef1_d1} <= {coef1_d4, coef1_d3, coef1_d2, coef1_d1, din_coef[KERNEL_COEF_BITWIDTH*(1)-1 : KERNEL_COEF_BITWIDTH*(0)]};
            {coef2_d5, coef2_d4, coef2_d3, coef2_d2, coef2_d1} <= {coef2_d4, coef2_d3, coef2_d2, coef2_d1, din_coef[KERNEL_COEF_BITWIDTH*(2)-1 : KERNEL_COEF_BITWIDTH*(1)]};
            {coef3_d5, coef3_d4, coef3_d3, coef3_d2, coef3_d1} <= {coef3_d4, coef3_d3, coef3_d2, coef3_d1, din_coef[KERNEL_COEF_BITWIDTH*(3)-1 : KERNEL_COEF_BITWIDTH*(2)]};
            {coef4_d5, coef4_d4, coef4_d3, coef4_d2, coef4_d1} <= {coef4_d4, coef4_d3, coef4_d2, coef4_d1, din_coef[KERNEL_COEF_BITWIDTH*(4)-1 : KERNEL_COEF_BITWIDTH*(3)]};

            {vrlt1_d5, vrlt1_d4, vrlt1_d3, vrlt1_d2, vrlt1_d1} <= {vrlt1_d4, vrlt1_d3, vrlt1_d2, vrlt1_d1, din_vrlt[VRLT_BITWIDTH*(1)-1 : VRLT_BITWIDTH*(0)]};
            {vrlt2_d5, vrlt2_d4, vrlt2_d3, vrlt2_d2, vrlt2_d1} <= {vrlt2_d4, vrlt2_d3, vrlt2_d2, vrlt2_d1, din_vrlt[VRLT_BITWIDTH*(2)-1 : VRLT_BITWIDTH*(1)]};
            {vrlt3_d5, vrlt3_d4, vrlt3_d3, vrlt3_d2, vrlt3_d1} <= {vrlt3_d4, vrlt3_d3, vrlt3_d2, vrlt3_d1, din_vrlt[VRLT_BITWIDTH*(3)-1 : VRLT_BITWIDTH*(2)]};
            {vrlt4_d5, vrlt4_d4, vrlt4_d3, vrlt4_d2, vrlt4_d1} <= {vrlt4_d4, vrlt4_d3, vrlt4_d2, vrlt4_d1, din_vrlt[VRLT_BITWIDTH*(4)-1 : VRLT_BITWIDTH*(3)]};
        end
        assign hrlt =   coef1_d5 * vrlt1_d5 +
                        coef2_d5 * vrlt2_d5 +
                        coef3_d5 * vrlt3_d5 +
                        coef4_d5 * vrlt4_d5 ;

    `endif
endgenerate









endmodule