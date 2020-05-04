`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Description :
*   @Create   : 2020.04.22
*   @Modify   :
******************************************************************************/
module scaler_vout_rall#(
    parameter PIXEL_NUM          = 1,
    parameter IMG_H_MAX          = 1920,
    parameter IMG_V_MAX          = 1080,
    parameter IMG_H_BITWIDTH     = CLOG2(IMG_H_MAX),
    parameter IMG_V_BITWIDTH     = CLOG2(IMG_V_MAX),
    parameter BRAM_ADDR_BITWIDTH = 11,
    parameter BRAM_DATA_BITWIDTH = 8
)(
    input                                             core_clk,
    input                                             core_rst,
    input                                             core_start,
    input      [IMG_H_BITWIDTH-1 : 0]                 core_arg_img_des_h,
    input      [IMG_V_BITWIDTH-1 : 0]                 core_arg_img_des_v,
    output reg [2*PIXEL_NUM-1 : 0]                    enb   = {(2*PIXEL_NUM){1'd0}},
    output reg [BRAM_ADDR_BITWIDTH-1 : 0]             addrb,
    input      [2*BRAM_DATA_BITWIDTH*PIXEL_NUM-1 : 0] doutb,
    output reg                                        rdone = 1'd0,
    input      [PIXEL_NUM-1 : 0]                      rempty,
    input                                             m_clk,
    input                                             m_rst,
    input                                             m_axis_ready,
    output                                            m_axis_valid,
    output     [BRAM_DATA_BITWIDTH*PIXEL_NUM-1 : 0]   m_axis_pixel,
    output                                            m_axis_sof,
    output                                            m_axis_eol,
    output reg                                        m_scaler_done = 1'd0
);


/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam SW_PING = 0, SW_PONG   = 1;
localparam REMPTY  = 0, RNONEMPTY = 1;

localparam ST_IDLE    = 0,
           ST_WAIT    = 1,
           ST_STREAM  = 2,
           ST_DONE    = 3;

/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
reg  [3 : 0] state_curr = ST_IDLE;
reg  [3 : 0] state_next = ST_IDLE;

reg                                       swb          = SW_PING;                    // for Read
reg                                       en_pre       = 1'd0;                       // for Read
reg  [BRAM_ADDR_BITWIDTH-1 : 0]           cntb         = {BRAM_ADDR_BITWIDTH{1'd0}}; // for Read
reg  [BRAM_ADDR_BITWIDTH-1 : 0]           cntb_pre     = {BRAM_ADDR_BITWIDTH{1'd0}}; // for Read
reg                                       stop         = 1'd0;                       // for Read
reg  [1 : 0]                              rsp_enb      = 2'd0;                       // for Read Rsp
reg  [1 : 0]                              rsp_lastb    = 2'd0;                       // for Read Rsp
reg                                       sof          = 1'd0;                       // start of frame
reg                                       eof          = 1'd0;                       // end of frame
reg                                       eol          = 1'd0;
reg  [IMG_V_BITWIDTH-1 : 0]               v_cnt        = {IMG_V_BITWIDTH{1'd0}};
wire                                      s_axis_valid;
wire [BRAM_DATA_BITWIDTH*PIXEL_NUM-1 : 0] s_axis_data;
wire                                      s_axis_sof;
wire                                      s_axis_eol;
wire                                      axis_prog_full;

// m clk cdc
reg                                       eol_hold     = 1'd0;
wire                                      eof_hold;
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
        ST_IDLE    : begin state_next = core_start            ? ST_WAIT    : state_next; end
        ST_WAIT    : begin state_next = (rempty == RNONEMPTY) ? ST_STREAM  : state_next; end
        ST_STREAM  : begin state_next = eol                   ? ST_DONE    : state_next; end
        ST_DONE    : begin state_next = eof                   ? ST_IDLE    : ST_WAIT;    end
        default    : begin state_next = ST_IDLE;                                         end
    endcase
end

// Stream
always @ (posedge core_clk) begin
    if(state_curr == ST_STREAM) begin
        if(~axis_prog_full) begin
            en_pre   <= 1'd1;
            cntb     <= cntb_pre;
            cntb_pre <= cntb_pre + 1'd1;
            if(cntb_pre == core_arg_img_des_h) begin
                stop <= 1'd1;
            end
        end
    end
    else begin
        cntb     <= {BRAM_ADDR_BITWIDTH{1'd0}};
        cntb_pre <= {BRAM_ADDR_BITWIDTH{1'd0}};
        stop     <= 1'd0;
    end
end

genvar i;
generate
    for (i = 0; i < PIXEL_NUM; i=i+1) begin
        always @ (posedge core_clk) begin
            if(state_curr == ST_STREAM) begin
                if(en_pre & (~stop)) begin
                    enb[2*(i+1)-1 : 2*(i)] <= (swb == SW_PING) ? 2'b01 : 2'b10;
                end
                else begin
                    enb[2*(i+1)-1 : 2*(i)] <= 2'd0;
                end
            end
            else begin
                enb[2*(i+1)-1 : 2*(i)] <= 2'd0;
            end
        end
    end
endgenerate

always @ (posedge core_clk) begin
    if(state_curr == ST_STREAM) begin
        if(en_pre & (~stop)) begin
            addrb <= cntb;
        end
    end
    else begin
        addrb <= {BRAM_ADDR_BITWIDTH{1'd0}};
    end
end

// rsp
always @ (posedge core_clk) begin
    rsp_enb   <= {rsp_enb[0],   |enb};
    rsp_lastb <= {rsp_lastb[0], stop};
end

// fifo
assign s_axis_valid = rsp_enb  [1];
assign s_axis_sof   = sof;
assign s_axis_eol   = rsp_lastb[1];

genvar j;
generate
    for (j = 0; j < PIXEL_NUM; j=j+1) begin
        assign s_axis_data[BRAM_DATA_BITWIDTH*(j+1)-1 : BRAM_DATA_BITWIDTH*(j)] = (swb == SW_PING) ? doutb[BRAM_DATA_BITWIDTH*(2*j+1)-1 : BRAM_DATA_BITWIDTH*(2*j+0)] :
                                                                                                     doutb[BRAM_DATA_BITWIDTH*(2*j+2)-1 : BRAM_DATA_BITWIDTH*(2*j+1)] ;
    end
endgenerate

// control

always @ (posedge core_clk) begin
    rdone <= rsp_enb[0] & rsp_lastb[0];
    eol   <= rdone;

    if(state_curr == ST_IDLE) begin
        sof <= 1'd1;
    end
    else if(s_axis_valid) begin
        sof <= 1'd0;
    end

    if(state_curr == ST_IDLE) begin
        swb <= SW_PING;
    end
    else if(rdone) begin
        swb <= ~swb;
    end
end

always @ (posedge core_clk) begin
    if(state_curr == ST_IDLE) begin
        v_cnt <= {IMG_V_BITWIDTH{1'd0}};
    end
    else if(rdone) begin
        v_cnt <= v_cnt + 1'd1;
    end
end

always @ (posedge core_clk) begin
    eof <= (v_cnt == core_arg_img_des_v);
end

ip_vout_fifo ip_vout_fifo (
    .s_aclk         ( core_clk                  ), // input wire s_aclk
    .s_aresetn      ( ~core_rst                 ), // input wire s_aresetn
    .s_axis_tready  (                           ), // output wire s_axis_tready
    .s_axis_tvalid  ( s_axis_valid              ), // input wire s_axis_tvalid
    .s_axis_tdata   ( s_axis_data               ), // input wire [15 : 0] s_axis_tdata
    .s_axis_tuser   ( {s_axis_sof, s_axis_eol}  ), // input wire [1 : 0] s_axis_tuser

    .m_aclk         ( m_clk                     ), // input wire s_aclk
    .m_axis_tready  ( m_axis_ready              ), // input wire m_axis_tready
    .m_axis_tvalid  ( m_axis_valid              ), // output wire m_axis_tvalid
    .m_axis_tdata   ( m_axis_pixel              ), // output wire [15 : 0] m_axis_tdata
    .m_axis_tuser   ( {m_axis_sof, m_axis_eol}  ), // output wire [1 : 0] m_axis_tuser
    .axis_prog_full ( axis_prog_full            )  // output wire axis_prog_full
);

always @ (posedge m_clk) begin
    if(m_axis_ready & m_axis_valid) begin
        eol_hold <= m_axis_eol;
    end
    m_scaler_done <= eof_hold & eol_hold;
end

xpm_cdc_array_single #(
    .DEST_SYNC_FF   (4),    // DECIMAL; range: 2-10
    .INIT_SYNC_FF   (0),    // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK (0),    // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG  (1),    // DECIMAL; 0=do not register input, 1=register input
    .WIDTH          (1)     // DECIMAL; range: 1-1024
)
xpm_cdc_core_to_m (
    .src_clk    ( core_clk  ),
    .src_in     ( eof       ),
    .dest_clk   ( m_clk     ),
    .dest_out   ( eof_hold  )
);

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction



endmodule