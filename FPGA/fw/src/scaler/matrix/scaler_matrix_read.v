`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create   : 2019-12-30 13:49:12
******************************************************************************/
module scaler_matrix_read
#(
    parameter KERNEL_MAX        = 4,
    parameter KERNEL_BITWIDTH   = CLOG2(KERNEL_MAX),
    /* MATRIX RAM PARAMETER */
    parameter RAM_DELAY         = 2,
    parameter RAM_NUM           = KERNEL_MAX+1,
    parameter RAM_NUM_BITWIDTH  = CLOG2(RAM_NUM),
    parameter RAM_DEEP          = 3840,
    parameter RAM_ADDR_BITWIDTH = CLOG2(RAM_DEEP),
    parameter RAM_DATA_BITWIDTH = 8
)(
    input                                                           core_clk,
    input                                                           core_rst,
    input                                                           core_start,
// matrix pixel output (Interface using ram type)
    input                                                           m_axis_connect_ready,
    output reg                                                      m_axis_connect_valid = 1'd0,
    input                                                           matrix_ram_read_stride,
    input                                                           matrix_ram_read_repeat,
    input                                                           matrix_ram_read_en,
    output                                                          matrix_ram_read_rsp_en,
    output     [RAM_DATA_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0]      matrix_ram_read_rsp_pixel,
    input                                                           matrix_ram_read_done,
// matrix ram
    output reg [RAM_NUM-1 : 0]                                      ram_enb,
    output reg [RAM_ADDR_BITWIDTH-1 : 0]                            ram_addrb,
    input      [RAM_DATA_BITWIDTH*RAM_NUM-1 : 0]                    ram_doutb,
    input                                                           ram_write_done,
    input      [RAM_NUM_BITWIDTH-1 : 0]                             ram_write_num,
    output                                                          ram_read_done,
    output     [RAM_NUM_BITWIDTH-1 : 0]                             ram_read_num
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam  ST_IDLE    = 0,
            ST_WAIT    = 1,
            ST_CONNECT = 2,
            ST_STRIDE  = 3,
            ST_STREAM  = 4,
            ST_REPEAT  = 5,
            ST_NEXT    = 6;

`define NON_EMPTY  (1'd0)
`define     EMPTY  (1'd1)
/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg  [3 : 0] state_curr = ST_IDLE;
reg  [3 : 0] state_next = ST_IDLE;

/* matrix read logic control */
wire                                        ram_state_empty;
reg  [RAM_NUM_BITWIDTH-1 : 0]               ram_space           = {RAM_NUM_BITWIDTH{1'd0}};
reg  [1 : 0]                                ram_write_done_dly  = 2'd0;
reg  [5 : 0]                                ram_read_done_dly   = 6'd0;
wire                                        connect_ok;
wire [RAM_NUM-1 : 0]                        ram_sel;
reg  [RAM_ADDR_BITWIDTH-1 : 0]              ram_cnt             = {RAM_ADDR_BITWIDTH{1'd0}};
reg  [RAM_DELAY-1 : 0]                      ram_read_en_dly     = {RAM_DELAY{1'd0}};
reg                                         ram_read_rsp_en     = 1'd0;

wire                                        manual_rst;
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
        ST_IDLE             : begin state_next = core_start                      ? ST_WAIT             : state_curr; end
        ST_WAIT             : begin state_next = (ram_state_empty == `NON_EMPTY) ? ST_CONNECT          : state_curr; end
        ST_CONNECT          : begin state_next = connect_ok                      ? ST_STRIDE           : state_curr; end
        ST_STRIDE           : begin state_next = matrix_ram_read_stride          ? ST_NEXT             : ST_STREAM;  end
        ST_STREAM           : begin state_next = matrix_ram_read_done            ? ST_REPEAT           : state_curr; end
        ST_REPEAT           : begin state_next = matrix_ram_read_repeat          ? ST_CONNECT          : ST_NEXT;    end
        ST_NEXT             : begin state_next = ram_read_done_dly[5]            ? ST_WAIT             : state_curr; end
        default:begin end
    endcase
end

assign manual_rst = (state_curr == ST_IDLE);

/*----------------------------------------------------------------------------*/
/* ST_WAIT */
/* ram wr and rd control*/
always @ (posedge core_clk) begin
    ram_write_done_dly <= {ram_write_done_dly[0],  ram_write_done};
    ram_read_done_dly  <= {ram_read_done_dly[4:0], (state_curr == ST_NEXT)};
end

assign ram_read_done = | ram_read_done_dly;
assign ram_read_num  = {RAM_NUM_BITWIDTH{1'd0}} + 1'd1;

/* Judge full status according to wr_h_num and rd_h_num */
/* Similar to the FIFO */
always @ (posedge core_clk) begin
    if(state_curr == ST_IDLE) begin
        ram_space <= {RAM_NUM_BITWIDTH{1'd0}};
    end
    else if((ram_write_done_dly == 2'd1) & (ram_read_done_dly == 6'd1)) begin
        ram_space <= ram_space + ram_write_num - ram_read_num;
    end
    else if((ram_write_done_dly == 2'd1) & (ram_read_done_dly != 6'd1)) begin
        ram_space <= ram_space + ram_write_num;
    end
    else if((ram_write_done_dly != 2'd1) & (ram_read_done_dly == 6'd1)) begin
        ram_space <= ram_space - ram_read_num;
    end
end

assign ram_state_empty = (ram_space < KERNEL_MAX) ? `EMPTY : `NON_EMPTY;

/*----------------------------------------------------------------------------*/
/* ST_CONNECT */
/* matrix in control and read matrix */
always @ (posedge core_clk) begin
    if(state_curr == ST_IDLE) begin
        m_axis_connect_valid <= 1'd0;
    end
    else if(m_axis_connect_ready & m_axis_connect_valid) begin
        m_axis_connect_valid <= 1'd0;
    end
    else if(state_curr == ST_CONNECT) begin
        m_axis_connect_valid <= 1'd1;
    end
end

assign connect_ok = m_axis_connect_ready & m_axis_connect_valid;

/*----------------------------------------------------------------------------*/
/* ST_STREAM */
always @ (posedge core_clk) begin
    if(matrix_ram_read_done) begin
        ram_enb   <= {RAM_NUM{1'd0}};
        ram_cnt   <= {RAM_ADDR_BITWIDTH{1'd0}};
    end
    else if(matrix_ram_read_en) begin
        ram_enb   <= ram_sel;
        ram_addrb <= ram_cnt;
        ram_cnt   <= ram_cnt + 1'd1;
    end
    else begin
        ram_enb <= {RAM_NUM{1'd0}};
    end
end

always @ (posedge core_clk) begin
    {ram_read_rsp_en, ram_read_en_dly} <= {ram_read_en_dly, matrix_ram_read_en};
end

/*******************************************************************************
*
*   Call Module
*
*******************************************************************************/

scaler_matrix_combine #(
    .KERNEL_MAX                 ( KERNEL_MAX        ),
    .KERNEL_BITWIDTH            ( KERNEL_BITWIDTH   ),
    .RAM_NUM                    ( RAM_NUM           ),
    .RAM_NUM_BITWIDTH           ( RAM_NUM_BITWIDTH  ),
    .RAM_DATA_BITWIDTH          ( RAM_DATA_BITWIDTH )
) inst_scaler_matrix_combine(
    .core_clk                   ( core_clk                  ),
    .core_rst                   ( core_rst | manual_rst     ),
    .ram_sel                    ( ram_sel                   ),
    .ram_read_rsp_en            ( ram_read_rsp_en           ),
    .ram_read_rsp_data          ( ram_doutb                 ),
    .matrix_ram_read_repeat     ( matrix_ram_read_repeat    ),
    .matrix_ram_read_done       ( matrix_ram_read_done      ),
    .matrix_ram_read_rsp_en     ( matrix_ram_read_rsp_en    ),
    .matrix_ram_read_rsp_pixel  ( matrix_ram_read_rsp_pixel )
);

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule