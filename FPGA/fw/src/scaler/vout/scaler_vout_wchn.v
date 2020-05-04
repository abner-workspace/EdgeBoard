`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create   : 2020.04.22
*   @Modify   :
******************************************************************************/
module scaler_vout_wchn#(
    parameter BRAM_ADDR_BITWIDTH = 11,
    parameter BRAM_DATA_BITWIDTH = 8
)(
    input                                   core_clk,
    input                                   core_rst,
    input                                   core_start,
    output reg                              s_axis_connect_ready,
    input                                   s_axis_connect_valid,
    input                                   s_axis_core_valid,
    input      [BRAM_DATA_BITWIDTH-1 : 0]   s_axis_core_pixel,
    input                                   s_axis_core_done,
    output reg [1 : 0]                      ena = 2'd0,
    output reg [BRAM_ADDR_BITWIDTH-1 : 0]   addra,
    output reg [BRAM_DATA_BITWIDTH-1 : 0]   dina,
    output reg                              wdone,
    input                                   wfull
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam SW_PING = 0, SW_PONG   = 1;
localparam WFULL   = 0, WNONFULL  = 1;

localparam ST_IDLE    = 0,
           ST_WAIT    = 1,
           ST_CONNECT = 2,
           ST_STREAM  = 3,
           ST_DElAY   = 4;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg [3 : 0] state_curr = ST_IDLE;
reg [3 : 0] state_next = ST_IDLE;

wire                             connect_ok;
reg [5 : 0]                      delay      = 6'd0;
reg                              swa        = SW_PING;
reg [BRAM_ADDR_BITWIDTH-1 : 0]   cnta       = {BRAM_ADDR_BITWIDTH{1'd0}};
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
always @ (posedge core_clk) begin
    if(core_rst) begin
        state_curr <= ST_IDLE;
    end
    else begin
        state_curr <= state_next;
    end
end

always @ (*) begin
    case (state_curr)
        ST_IDLE    : begin state_next = core_start          ? ST_WAIT    : state_next; end
        ST_WAIT    : begin state_next = (wfull == WNONFULL) ? ST_CONNECT : state_next; end
        ST_CONNECT : begin state_next = connect_ok          ? ST_STREAM  : state_next; end
        ST_STREAM  : begin state_next = s_axis_core_done    ? ST_DElAY   : state_next; end
        ST_DElAY   : begin state_next = delay[5]            ? ST_WAIT    : state_next; end
        default    : begin state_next = ST_IDLE; end
    endcase
end

// connect
always @ (posedge core_clk) begin
    if(state_curr == ST_CONNECT) begin
        if(s_axis_connect_ready & s_axis_connect_valid) begin
            s_axis_connect_ready <= 1'd0;
        end
        else begin
            s_axis_connect_ready <= 1'd1;
        end
    end
    else begin
        s_axis_connect_ready <= 1'd0;
    end
end

assign connect_ok = s_axis_connect_ready & s_axis_connect_valid;

// stream
always @ (posedge core_clk) begin
    if(state_curr == ST_STREAM) begin
        if(s_axis_core_valid) begin
            ena   <= (swa == SW_PING) ? 2'b01 : 2'b10;
            addra <= cnta;
            dina  <= s_axis_core_pixel;
            cnta  <= cnta + 1'd1;
        end
        else begin
            ena   <= 2'b00;
        end
    end
    else begin
        ena   <= 2'b00;
        addra <= {BRAM_ADDR_BITWIDTH{1'd0}};
        cnta  <= {BRAM_ADDR_BITWIDTH{1'd0}};
    end
end

// Delay
always @ (posedge core_clk) begin
    delay <= {delay[4 : 0], (state_curr == ST_DElAY)};
    wdone <=  delay == 6'b000011;
end

always @ (posedge core_clk) begin
    if(core_rst) begin
        swa <= SW_PING;
    end
    else if(delay == 6'b000001) begin
        swa <= ~swa;
    end
end

endmodule