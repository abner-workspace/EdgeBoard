`timescale 1ns/1ps
/******************************************************************************
* Auther : Abner
* Mail   : hn.cy@foxmail.com
* Gitee  : https://gitee.com/abnerwork/
* Description :
*   @Create : 2020-03-31 22:25:00
*           Data is input by row and output by column
*   @Modify : 2020-03-31 22:25:00
*
******************************************************************************/
module scaler_matrix_ram
#(
    parameter RAM_NUM             = 8,
    parameter RAM_DEEP            = 300,
    parameter RAM_ADDR_BITWIDTH   = CLOG2(RAM_DEEP),
    parameter RAM_DATA_BITWIDTH   = 8,
    parameter RAM_DELAY           = 2
)(
    input                                        ram_clka,
    input      [RAM_NUM-1 : 0]                   ram_ena,
    input      [RAM_NUM-1 : 0]                   ram_wea,
    input      [RAM_ADDR_BITWIDTH-1 : 0]         ram_addra,
    input      [RAM_DATA_BITWIDTH-1 : 0]         ram_dina,
    input                                        ram_clkb,
    input      [RAM_NUM-1 : 0]                   ram_enb,
    input      [RAM_ADDR_BITWIDTH-1 : 0]         ram_addrb,
    output     [RAM_DATA_BITWIDTH*RAM_NUM-1 : 0] ram_doutb
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

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
genvar i;
generate
    for (i = 0; i < RAM_NUM; i = i + 1) begin : matrix_ram
        ip_ram #(
            .RAM_DEEP            ( RAM_DEEP          ),
            .RAM_ADDR_BITWIDTH   ( RAM_ADDR_BITWIDTH ),
            .RAM_DATA_BITWIDTH   ( RAM_DATA_BITWIDTH ),
            .RAM_DELAY           ( RAM_DELAY         )
        ) ip_ram (
            .clka                ( ram_clka                                                   ),
            .ena                 ( ram_ena[i]                                                 ),
            .wea                 ( ram_wea[i]                                                 ),
            .addra               ( ram_addra                                                  ),
            .dina                ( ram_dina                                                   ),
            .clkb                ( ram_clkb                                                   ),
            .enb                 ( ram_enb[i]                                                 ),
            .addrb               ( ram_addrb                                                  ),
            .doutb               ( ram_doutb[RAM_DATA_BITWIDTH*(i+1)-1 : RAM_DATA_BITWIDTH*i] )
        );
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