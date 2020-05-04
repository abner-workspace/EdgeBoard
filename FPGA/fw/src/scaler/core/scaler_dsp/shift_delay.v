`timescale 1ns/1ps
/****************************************************************
* Auther : CYabner
* Mail   : hn.cy@foxmail.com
* Time   : 2019.02.14
* Design :
* Description :
****************************************************************/

module shift_delay
#(
    parameter integer DELAY    = 1,
    parameter integer BITWIDTH = 8
)(
    input                    clk,
    input   [BITWIDTH-1 : 0] i,
    input   [BITWIDTH-1 : 0] o
);

generate
    if(DELAY == 0) begin
        assign o = i;
    end
    else if(DELAY == 1) begin
        reg [BITWIDTH-1 : 0] d = {BITWIDTH{1'd0}};
        always @ (posedge clk) begin
            d <= i;
        end
        assign o = d;
    end
    else begin
        reg [BITWIDTH*DELAY-1 : 0] d = {(BITWIDTH*DELAY){1'd0}};
        always @ (posedge clk) begin
            d <= {d[BITWIDTH*(DELAY-1)-1 : 0],i};
        end
        assign o = d[BITWIDTH*DELAY-1 : BITWIDTH*(DELAY-1)];
    end
endgenerate

endmodule