`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create   : 2020.04.22
*   @Modify   :
******************************************************************************/
module scaler_vout_mem
#(
    parameter BRAM_DEEP           = 1920,
    parameter BRAM_ADDR_BITWIDTH  = 11,
    parameter BRAM_DATA_BITWIDTH  = 8,
    parameter BRAM_DELAY          = 2
)(
    input                                   core_clk,
    input                                   core_rst,
    input      [1 : 0]                      ena,
    input      [BRAM_ADDR_BITWIDTH-1 : 0]   addra,
    input      [BRAM_DATA_BITWIDTH-1 : 0]   dina,
    input                                   wdone,
    output reg                              wfull,
    input     [1 : 0]                       enb,
    input     [BRAM_ADDR_BITWIDTH-1 : 0]    addrb,
    output    [BRAM_DATA_BITWIDTH*2-1 : 0]  doutb,
    input                                   rdone,
    output reg                              rempty
);


/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam WFULL   = 0, WNONFULL  = 1;
localparam REMPTY  = 0, RNONEMPTY = 1;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg  [1 : 0] space        = 2'd0;

/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
// Delay = 2
genvar i;
generate
    for (i = 0; i < 2; i=i+1) begin
        ip_ram #(
            .RAM_DEEP          ( BRAM_DEEP          ),
            .RAM_ADDR_BITWIDTH ( BRAM_ADDR_BITWIDTH ),
            .RAM_DATA_BITWIDTH ( BRAM_DATA_BITWIDTH ),
            .RAM_DELAY         ( BRAM_DELAY         )
        ) ip_scaler_vout (
            .clka              ( core_clk                                                    ),    // input wire clka
            .ena               ( ena   [i]                                                   ),    // input wire ena
            .wea               ( ena   [i]                                                   ),    // input wire [0 : 0] wea
            .addra             ( addra                                                       ),    // input wire [10 : 0] addra
            .dina              ( dina                                                        ),    // input wire [7 : 0] dina
            .clkb              ( core_clk                                                    ),    // input wire clkb
            .enb               ( enb   [i]                                                   ),    // input wire enb
            .addrb             ( addrb                                                       ),    // input wire [10 : 0] addrb
            .doutb             ( doutb [BRAM_DATA_BITWIDTH*(i+1)-1 : BRAM_DATA_BITWIDTH*(i)] )     // output wire [7 : 0] doutb
        );

    end
endgenerate

always @ (posedge core_clk) begin
    if(core_rst) begin
        space <= 2'd0;
    end
    else if(wdone & (~rdone)) begin
        space <= space  + 1'd1;
    end
    else if((~wdone) & rdone) begin
        space <= space - 1'd1;
    end
end

always @ (posedge core_clk) begin
    wfull  <= (space == 2'd2) ? WFULL  : WNONFULL;
    rempty <= (space == 2'd0) ? REMPTY : RNONEMPTY;
end


endmodule