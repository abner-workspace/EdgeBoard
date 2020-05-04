`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Description :
*   @Create : 2020.04.20
*   @Modify :
******************************************************************************/
module dsp_mux
(
    input               clk,
    input               din_en,
    input      [7 : 0]  din_a,
    input      [7 : 0]  din_b,
    input      [7 : 0]  din_d,
    output reg          dout_en = 1'd0,
    output reg [15 : 0] dout_ab,
    output reg [15 : 0] dout_db
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
reg         [1 : 0]  dly     = 1'd0;
reg                  flag_1  = 1'd0;
reg                  flag_2  = 1'd0;
reg                  flag_bd = 1'd0;
wire        [32 : 0] p;
wire signed [15 : 0] p_ab;
wire signed [15 : 0] p_db;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
// DSP48 INT8 Mux: p = (a*2^17 + d) * b
// D_BITWIDTH = 25
// A_BITWIDTH = 25
// B_BITWIDTH = 8
// Tier_A4     = EN
// Tier_B4     = EN
// Tier_C6     = EN
// OUT_BITWIDTH = 33
// Delay      = 2
ip_scaler_dsp_v ip_scaler_dsp_v (
    .CLK( clk                     ),  // input wire CLK
    .CE ( din_en                  ),
    .A  ( {din_a, 17'd0}          ),  // input  wire [24 : 0] A
    .B  ( din_b                   ),  // input  wire [ 7 : 0] B
    .D  ( {{17{din_d[7]}}, din_d} ),  // input  wire [24 : 0] D
    .P  ( p                       )   // output wire [32 : 0] P
);

assign p_ab = p[32:17];
assign p_db = p[15: 0];

always @ (posedge clk) begin
    flag_1  <= (|din_d) & (|din_b);
    flag_2  <= din_d[7] ^ din_b[7];
    flag_bd <= flag_1 & flag_2;
end

always @ (posedge clk) begin
    {dout_en, dly} <= {dly, din_en};
    if(dly[1]) begin
        dout_ab <= (flag_bd) ? ($signed(p_ab) + $signed(16'd1)) : p_ab;
        dout_db <= p_db;
    end
end

/*
// sim
// * (a + d) * b
// * a+ d+ b+ : ab+0 db+0
// * a+ d- b- : ab+0 db+0
// * a- d+ b+ : ab+0 db+0
// * a- d- b- : ab+0 db+0
// * a+ d+ b- : ab+1 db+0 (& d!=0)
// * a+ d- b+ : ab+1 db+0 (& d!=0)
// * a- d+ b- : ab+1 db+0 (& d!=0)
// * a- d- b+ : ab+1 db+0 (& d!=0)
reg signed [7 : 0]  din_a_d1;
reg signed [7 : 0]  din_b_d1;
reg signed [7 : 0]  din_d_d1;
reg signed [7 : 0]  din_a_d2;
reg signed [7 : 0]  din_b_d2;
reg signed [7 : 0]  din_d_d2;
reg signed [15 : 0] rlt_ab;
reg signed [15 : 0] rlt_db;
reg                 err_ab;
reg                 err_db;
always @ (posedge clk) begin
    din_a_d1 <= din_a;
    din_b_d1 <= din_b;
    din_d_d1 <= din_d;
    din_a_d2 <= din_a_d1;
    din_b_d2 <= din_b_d1;
    din_d_d2 <= din_d_d1;
    rlt_ab   <= din_a_d2 * din_b_d2;
    rlt_db   <= din_d_d2 * din_b_d2;
    err_ab   <= (rlt_ab != dout_ab);
    err_db   <= (rlt_db != dout_db);
end

*/

endmodule