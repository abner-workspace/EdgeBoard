`timescale 1ns/1ps
/******************************************************************************
* Auther : abner
* Email  : hn.cy@foxmail.com
* Description :
*   @Create : 2020.04.20
*   @Modify : 2020.05.04
*       1.新增参数支持 DSPE1 和 DSPE2
******************************************************************************/
module dsp_mux
#(
    parameter DSP_DEVICE = "DSPE2" // "DSPE1" "DSPE2"
)(
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
wire        [32 : 0] p_dspe1;  //  DSPE1 使用
wire        [34 : 0] p_dspe2;  //  DSPE2 使用
wire signed [15 : 0] p_ab;
wire signed [15 : 0] p_db;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
generate
    if(DSP_DEVICE == "DSPE1") begin
        // DSP48 INT8 Mux: p = (a*2^17 + d) * b
        // Pipleline Options = Expert
        // Tier : A4 B4 C6
        // Control prots = CE_Global
        // Input Port Properties = D25 A25 B8
        // Output Port Properties = Full Precision(33)
        // Delay      = 2
        ip_scaler_dsp_v ip_scaler_dsp_v (
            .CLK( clk                     ),  // input wire CLK
            .CE ( din_en                  ),
            .A  ( {din_a, 17'd0}          ),  // input  wire [24 : 0] A
            .B  ( din_b                   ),  // input  wire [ 7 : 0] B
            .D  ( {{17{din_d[7]}}, din_d} ),  // input  wire [24 : 0] D
            .P  ( p_dspe1                 )   // output wire [32 : 0] P
        );

        assign p_ab = p_dspe1[32:17];
        assign p_db = p_dspe1[15: 0];

        always @ (posedge clk) begin
            {dout_en, dly} <= {dly, din_en};
            if(dly[1]) begin
                dout_ab <= p_ab + p_db[15];
                dout_db <= p_db;
            end
        end
    end
    else if(DSP_DEVICE == "DSPE2") begin
        // DSP48 INT8 Mux: p = (a*2^18 + d) * b
        // Pipleline Options = Expert
        // Tier : A4 B4 C6
        // Control prots = CE_Global
        // Input Port Properties = D27 A27 B8
        // Output Port Properties = Full Precision(35)
        // Delay      = 2
        ip_scaler_dsp_v ip_scaler_dsp_v (
            .CLK( clk                      ),  // input wire CLK
            .CE ( din_en                   ),
            .A  ( {din_a[7], din_a, 18'd0} ),  // input  wire [26 : 0] A
            .B  ( din_b                    ),  // input  wire [ 7 : 0] B
            .D  ( {{19{din_d[7]}}, din_d}  ),  // input  wire [26 : 0] D
            .P  ( p_dspe2                  )   // output wire [34 : 0] P
        );

        assign p_ab = p_dspe2[33:18];
        assign p_db = p_dspe2[15: 0];

        always @ (posedge clk) begin
            {dout_en, dly} <= {dly, din_en};
            if(dly[1]) begin
                dout_ab <= p_ab + p_db[15];
                dout_db <= p_db;
            end
        end
    end
endgenerate

generate
    `ifdef SIM
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
        reg  signed [7 : 0]  din_a_d1;
        reg  signed [7 : 0]  din_b_d1;
        reg  signed [7 : 0]  din_d_d1;
        reg  signed [7 : 0]  din_a_d2;
        reg  signed [7 : 0]  din_b_d2;
        reg  signed [7 : 0]  din_d_d2;
        reg  signed [7 : 0]  din_a_d3;
        reg  signed [7 : 0]  din_b_d3;
        reg  signed [7 : 0]  din_d_d3;
        wire signed [15 : 0] rlt_ab;
        wire signed [15 : 0] rlt_db;
        reg                  err_ab;
        reg                  err_db;
        always @ (posedge clk) begin
            din_a_d1 <= din_a;
            din_b_d1 <= din_b;
            din_d_d1 <= din_d;
            din_a_d2 <= din_a_d1;
            din_b_d2 <= din_b_d1;
            din_d_d2 <= din_d_d1;
            din_a_d3 <= din_a_d2;
            din_b_d3 <= din_b_d2;
            din_d_d3 <= din_d_d2;
            err_ab   <= (rlt_ab != dout_ab);
            err_db   <= (rlt_db != dout_db);
        end
        assign rlt_ab = din_a_d3 * din_b_d3;
        assign rlt_db = din_d_d3 * din_b_d3;
    `endif
endgenerate

endmodule