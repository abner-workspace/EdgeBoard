`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/01/07 12:12:55
// Design Name:
// Module Name: tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module tb(

);
reg clk = 0;
reg rst = 1;
reg              din_en = 0;
reg     [7 : 0]  din_a = 8'd0;
reg     [7 : 0]  din_b = 8'd0;
reg     [7 : 0]  din_d = 8'd0;
wire             dout_en;
wire    [15 : 0] dout_p1;
wire    [15 : 0] dout_p2;

always #1 clk = ~clk;
initial begin
    rst = 1;
    din_en = 0;
    #100
    forever begin
        @ (posedge clk) begin
            din_en <= 1'd1;
            din_a  <= din_a + 1;

            if(din_a == 255) begin
                din_d <= din_d + 1;
            end

            if((din_a == 255) & (din_d == 255)) begin
                din_b  <= din_b + 1;
            end
        end
    end
end

// dsp_mux inst_dsp_mux(
//     .clk                ( clk ),
//     .din_en             ( din_en ),
//     .din_a              ( din_a  ),
//     .din_b              ( din_b  ),
//     .din_d              ( din_d  )
// );

// scaler_dsp_pu inst_scaler_dsp_pu(
//     .clk            ( clk                          ),
//     .din_en         ( din_en                       ),
//     .din_coef       ( {din_b, din_b, din_b, din_b} ),
//     .din_pixel_1    ( {din_a, din_a, din_a, din_a} ),
//     .din_pixel_2    ( {din_d, din_d, din_d, din_d} ),
//     .dout_en        ( dout_en ),
//     .dout_result_1  ( dout_p1 ),
//     .dout_result_2  ( dout_p2 )
// );



// scaler_dsp_v inst_scaler_dsp_v(
//     .clk            ( clk                          ),
//     .din_en         ( din_en                       ),
//     .din_coef       ( {din_b, din_b, din_b, din_b} ),
//     .din_pixel      ( {din_a, din_a, din_a, din_a,din_a, din_a, din_a, din_a,din_a, din_a, din_a, din_a,din_a, din_a, din_a, din_a})
// );


// scaler_dsp inst_scaler_dsp(
//     .core_clk              ( clk ),
//     .core_rst              ( rst ),
//     .s_axis_scaler_valid   ( din_en ),
//     .s_axis_scaler_pixel   ( {din_a, din_a, din_a, din_a,din_a, din_a, din_a, din_a,din_a, din_a, din_a, din_a,din_a, din_a, din_a, din_a}),
//     .s_axis_scaler_coef_h  ( {din_b, din_b, din_b, din_b}),
//     .s_axis_scaler_coef_v  ( {din_b, din_b, din_b, din_b}),
//     .s_axis_scaler_done    ( 0 ),
//     .m_axis_core_valid     ( ),
//     .m_axis_core_data      ( ),
//     .m_axis_core_done      ( )
// );

top inst_top();


endmodule
