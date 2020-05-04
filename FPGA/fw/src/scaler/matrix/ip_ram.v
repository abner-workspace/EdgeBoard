`timescale 1ns/1ps
/****************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Time   : 2019.02.14
* Design :
* Description :
****************************************************************/

module ip_ram
#(
    parameter RAM_DEEP            = 300,
    parameter RAM_ADDR_BITWIDTH   = CLOG2(RAM_DEEP),
    parameter RAM_DATA_BITWIDTH   = 8,
    parameter RAM_DELAY           = 2                         // 1 or 2
)
(
    input                               clka,
    input                               ena,
    input                               wea,
    input   [RAM_ADDR_BITWIDTH-1 : 0]   addra,
    input   [RAM_DATA_BITWIDTH-1 : 0]   dina,
    input                               clkb,
    input                               enb,
    input   [RAM_ADDR_BITWIDTH-1 : 0]   addrb,
    output  [RAM_DATA_BITWIDTH-1 : 0]   doutb
);

/********************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
(* ram_style="block" *)
reg  [RAM_DATA_BITWIDTH-1 : 0]     RAM_MEM [RAM_DEEP-1 : 0];
reg  [RAM_DATA_BITWIDTH-1 : 0]     delay_dout_d1 = {RAM_DATA_BITWIDTH{1'd0}};

/************************************************************************************************************************
*
*   RTL Verilog
*
************************************************************************************************************************/
integer var;
initial begin
    for (var = 0; var < RAM_DEEP; var = var + 1) begin
        RAM_MEM[var] = {RAM_DATA_BITWIDTH{1'd1}};
    end
end

// write bram
always @ (posedge clka) begin
    if(ena & wea) begin
        RAM_MEM[addra] <= dina;
    end
end

// read bram
always @ (posedge clkb) begin
    if(enb) begin
        delay_dout_d1 <= RAM_MEM[addrb];
    end
end

generate
    if(RAM_DELAY == 1) begin
        assign doutb = delay_dout_d1;
    end
    else if(RAM_DELAY == 2) begin
        reg [RAM_DATA_BITWIDTH-1 : 0]      delay_dout_d2;
        always @ (posedge clkb) begin
            delay_dout_d2 <= delay_dout_d1;
        end
        assign doutb = delay_dout_d2;
    end
endgenerate

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction


endmodule
