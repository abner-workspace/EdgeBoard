`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create   : 2019-12-25 14:40:51
*             pad image h for N*line
******************************************************************************/
module scaler_pad
#(
    parameter PIXEL_BITWIDTH  = 8,
    parameter PIXEL_NUM       = 2,
    parameter IMG_H_MAX       = 3840,
    parameter IMG_H_BITWIDTH  = CLOG2(IMG_H_MAX)
)(
    input                                       s_clk,
    input                                       s_rst,
    input                                       start,
    input      [IMG_H_BITWIDTH-1 : 0]           len,
    output reg                                  done         = 1'd0,
    output reg                                  m_axis_valid = 1'd0,
    output     [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0] m_axis_pixel
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
reg [IMG_H_BITWIDTH-1 : 0] cnt = {IMG_H_BITWIDTH{1'd0}};
wire                       m_axis_last;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
always @ (posedge s_clk) begin
    if(start) begin
        m_axis_valid <= 1'd1;
    end
    else if(m_axis_last) begin
        m_axis_valid <= 1'd0;
    end
end

assign m_axis_pixel = {(PIXEL_BITWIDTH*PIXEL_NUM){1'd0}};
assign m_axis_last  = (cnt == (len - 1'd1)) ? 1'd1 : 1'd0;

always @ (posedge s_clk) begin
    if(start) begin
        cnt <= {IMG_H_BITWIDTH{1'd0}};
    end
    else if(m_axis_valid) begin
        cnt <= cnt + 1'd1;
    end
end

always @ (posedge s_clk) begin
    done <= m_axis_valid & m_axis_last;
end

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule