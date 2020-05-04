`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create : 2020-1-6 17:50:29
*           image pattern generator
******************************************************************************/

module image_pattern
#(
    parameter       PIXEL_BITWIDTH                                  = 8,
    parameter       PIXEL_NUM                                       = 1
)(
    input                                                           clk,
    input                                                           rst,
    input                                                           m_axis_ready,
    output reg                                                      m_axis_valid,
    output reg  [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0]                    m_axis_data,
    output reg                                                      m_axis_sof,
    output reg                                                      m_axis_eof,
    output reg                                                      m_axis_eol
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
`define IMAGE_W     300
`define IMAGE_H     300
/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg [12 : 0] w_timer = 13'd0;
reg [12 : 0] h_timer = 13'd0;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
always @ (posedge clk) begin
    if(rst) begin
        w_timer <= 13'd0;
    end
    else if(m_axis_ready) begin
        if(w_timer == (`IMAGE_W + 200)) begin
            w_timer <= 13'd0;
        end
        else begin
            w_timer <= w_timer + 1'd1;
        end
    end
end

always @ (posedge clk) begin
    if(rst) begin
        h_timer <= 13'd0;
    end
    else if(m_axis_ready) begin
        if(w_timer == (`IMAGE_W + 200)) begin
            if(h_timer == (`IMAGE_H + 100)) begin
                h_timer <= 13'd0;
            end
            else begin
                h_timer <= h_timer + 1'd1;
            end
        end
    end
end

always @ (posedge clk) begin
    m_axis_valid <= (100 <= w_timer) & (w_timer < (`IMAGE_W+100)) & (50 <= h_timer) & (h_timer < (`IMAGE_H+50));
    m_axis_data  <= {(PIXEL_BITWIDTH*PIXEL_NUM){1'd0}} + 8'hAA;
    m_axis_sof   <= (100 == w_timer) & (50 == h_timer);
    m_axis_eof   <= (100 == w_timer) & ((50+`IMAGE_H-1) == h_timer);
    m_axis_eol   <= (w_timer == (`IMAGE_W+100-1)) & (50 <= h_timer) & (h_timer < (`IMAGE_H+50));
end

endmodule