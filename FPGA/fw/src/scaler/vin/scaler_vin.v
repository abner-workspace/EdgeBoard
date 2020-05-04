`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Gitee  : https://gitee.com/abnerwork/
* Description :
*   @Create : 2019-12-24 13:42:31
*           1.Make sure the input video is a complete frame
*           2.Video input, starting with sof signal
*           3.When the input video is incomplete, fill it up with the image
*           of the next frame to ensure that the lower module will not make
*           mistakes.
*   @Modify : 2020-02-12 16:31:00
*           1.Add padding
******************************************************************************/
module scaler_vin
#(
    parameter PIXEL_BITWIDTH  = 8,
    parameter PIXEL_NUM       = 2,
    parameter IMG_H_MAX       = 3840,
    parameter IMG_V_MAX       = 2160,
    parameter IMG_H_BITWIDTH  = CLOG2(IMG_H_MAX),
    parameter IMG_V_BITWIDTH  = CLOG2(IMG_V_MAX),
    parameter PAD_MAX         = 2,
    parameter PAD_BITWIDTH    = CLOG2(PAD_MAX)
)(
    input                                                           s_clk,
    input                                                           s_rst,
    input                                                           s_start,
    input       [IMG_H_BITWIDTH-1 : 0]                              s_arg_img_src_h,
    input       [IMG_V_BITWIDTH-1 : 0]                              s_arg_img_src_v,
    output reg                                                      s_axis_ready         = 1'd0,
    input                                                           s_axis_valid,
    input       [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0]                    s_axis_pixel,
    input                                                           s_axis_sof,
    input                                                           s_axis_eol,
    input                                                           m_axis_connect_ready,
    output reg                                                      m_axis_connect_valid = 1'd0,
    output reg                                                      m_axis_img_valid     = 1'd0,
    output reg  [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0]                    m_axis_img_pixel     = {(PIXEL_BITWIDTH*PIXEL_NUM){1'd0}},
    output reg                                                      m_axis_img_done      = 1'd0
);

/*******************************************************************************
*
*   Define localparam
*
*******************************************************************************/
localparam FULL_BITWIDTH = IMG_V_BITWIDTH+2*PAD_BITWIDTH;
/*******************************************************************************
*
*   Define reg / wire
*
*******************************************************************************/
localparam  ST_IDLE       = 0,
            ST_CONNECT    = 1,
            ST_PAD_H_HEAD = 2,
            ST_PAD_V      = 3,
            ST_IMG_V      = 4,
            ST_PAD_H_TAIL = 5,
            ST_DONE       = 6;

reg [3 : 0] state_curr = ST_IDLE;
reg [3 : 0] state_next = ST_IDLE;

// arg
reg  [IMG_H_BITWIDTH-1 : 0]                arg_img_src_h = {IMG_H_BITWIDTH{1'd0}};
reg  [IMG_V_BITWIDTH-1 : 0]                arg_img_src_v = {IMG_V_BITWIDTH{1'd0}};
reg  [FULL_BITWIDTH-1 : 0]                 arg_img_v     = {FULL_BITWIDTH{1'd0}};
reg  [FULL_BITWIDTH-1 : 0]                 arg_full_v    = {FULL_BITWIDTH{1'd0}};
// fsm
wire                                       connect_ok;                                   // tell next module
wire                                       pad_h_en;                                     // padding operate en
wire                                       pad_v_en;                                     // padding operate en
reg  [PAD_BITWIDTH-1 : 0]                  pad_v_cnt       = {PAD_BITWIDTH{1'd0}};       // padding operate cnt
// pad stream
reg                                        pad_hold        = 1'd1;
reg                                        pad_start       = 1'd0;
reg  [IMG_H_BITWIDTH-1 : 0]                pad_len         = {IMG_H_BITWIDTH{1'd0}};
wire                                       pad_done;
wire                                       pad_axis_valid;
wire [PIXEL_BITWIDTH*PIXEL_NUM-1 : 0]      pad_axis_pixel;
// line stream
reg                                        eol_hold       = 1'd1;
wire                                       eol;
// full image+pad
reg  [FULL_BITWIDTH-1 : 0]                 full_cnt        = {FULL_BITWIDTH{1'd0}};
wire                                       full_ok;                                    // output image(pad+line in) done
wire                                       img_ok;                                     // img input done
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
always @ (posedge s_clk) begin
    if(s_rst) begin
        state_curr <= ST_IDLE;
    end
    else begin
        state_curr <= state_next;
    end
end

always @ (*) begin
    case (state_curr)
        ST_IDLE       : begin state_next = s_start      ?             ST_CONNECT    : state_curr;               end
        ST_CONNECT    : begin state_next = connect_ok   ?             ST_PAD_H_HEAD : state_curr;               end
        ST_PAD_H_HEAD : begin state_next = pad_h_en     ? (pad_done ? ST_PAD_V      : state_curr) : ST_PAD_V;   end
        ST_PAD_V      : begin state_next = pad_v_en     ? (pad_done ? ST_PAD_H_TAIL : state_curr) : ST_IMG_V;   end
        ST_IMG_V      : begin state_next = eol          ?             ST_PAD_H_TAIL : state_curr;               end
        ST_PAD_H_TAIL : begin state_next = pad_h_en     ? (pad_done ? ST_DONE       : state_curr) : ST_DONE;    end
        ST_DONE       : begin state_next = full_ok      ?             ST_IDLE                     : ST_CONNECT; end
    endcase
end

/*----------------------------------------------------------------------------*/
// save arg
always @ (posedge s_clk) begin
    if(state_curr == ST_IDLE) begin
        arg_img_src_h <= s_arg_img_src_h;
        arg_img_src_v <= s_arg_img_src_v;
    end
end

always @ (posedge s_clk) begin
    arg_img_v  <= arg_img_src_v + PAD_MAX;
    arg_full_v <= arg_img_src_v + PAD_MAX*2;
end

/*----------------------------------------------------------------------------*/
/* ST_CONNECT */
always @ (posedge s_clk) begin
    if(state_curr == ST_CONNECT) begin
        if(m_axis_connect_ready & m_axis_connect_valid) begin
            m_axis_connect_valid <= 1'd0;
        end
        else begin
            m_axis_connect_valid <= 1'd1;
        end
    end
    else begin
        m_axis_connect_valid <= 1'd0;
    end
end

assign connect_ok = m_axis_connect_ready & m_axis_connect_valid;

/*----------------------------------------------------------------------------*/
/* ST_PAD_H_HEAD ST_PAD_H_TAIL ST_PAD_V*/
always @ (posedge s_clk) begin
    if(pad_done) begin
        pad_hold <= 1'd1;
    end
    else if((((state_curr == ST_PAD_H_HEAD) | (state_curr == ST_PAD_H_TAIL)) & pad_h_en) |
             ((state_curr == ST_PAD_V) & pad_v_en)) begin
        pad_hold <= 1'd0;
    end
    else begin
        pad_hold <= 1'd1;
    end
end

always @ (posedge s_clk) begin
    if((state_curr == ST_PAD_H_HEAD) | (state_curr == ST_PAD_H_TAIL)) begin
        if(pad_h_en) begin
            if(pad_hold) begin
                pad_start <= 1'd1;
                pad_len   <= PAD_MAX;
            end
            else begin
                pad_start <= 1'd0;
            end
        end
    end
    else if(state_curr == ST_PAD_V) begin
        if(pad_v_en) begin
            if(pad_hold) begin
                pad_start <= 1'd1;
                pad_len   <= arg_img_src_h;
            end
            else begin
                pad_start <= 1'd0;
            end
        end
    end
    else begin
        pad_start <= 1'd0;
    end
end

// pad cnt
assign pad_h_en = (PAD_MAX   == {PAD_BITWIDTH{1'd0}}) ? 1'd0 : 1'd1;
assign pad_v_en = (pad_v_cnt == {PAD_BITWIDTH{1'd0}}) ? 1'd0 : 1'd1;

always @ (posedge s_clk) begin
    if((state_curr == ST_IDLE) | img_ok) begin
        pad_v_cnt <= PAD_MAX;
    end
    else if((state_curr == ST_PAD_V) & pad_done) begin
        pad_v_cnt <= pad_v_cnt - 1'd1;
    end
end

/*----------------------------------------------------------------------------*/
/* ST_IMG_V */
always @ (posedge s_clk) begin
    if(state_curr == ST_IMG_V) begin
        eol_hold <= 1'd0;
    end
    else begin
        eol_hold <= 1'd1;
    end
end

always @ (posedge s_clk) begin
    if(state_curr == ST_IMG_V) begin
        if(s_axis_ready & s_axis_valid & s_axis_eol) begin
            s_axis_ready <= 1'd0;
        end
        else if(eol_hold) begin
            s_axis_ready <= 1'd1;
        end
    end
    else begin
        s_axis_ready <= 1'd0;
    end
end

assign eol = s_axis_ready & s_axis_valid & s_axis_eol;

/*----------------------------------------------------------------------------*/
// full image + pad
always @ (posedge s_clk) begin
    if(state_curr == ST_IDLE) begin
        full_cnt <= {FULL_BITWIDTH{1'd0}};
    end
    else if(connect_ok) begin
        full_cnt <= full_cnt + 1'd1;
    end
end

assign img_ok  = (full_cnt == arg_img_v ) & eol;
assign full_ok = (full_cnt == arg_full_v);
/*----------------------------------------------------------------------------*/
/* OUTPUT */
always @ (posedge s_clk) begin
    if(pad_axis_valid) begin
        m_axis_img_valid <= 1'd1;
        m_axis_img_pixel <= pad_axis_pixel;
    end
    else if(s_axis_ready & s_axis_valid) begin
        m_axis_img_valid <= 1'd1;
        m_axis_img_pixel <= s_axis_pixel;
    end
    else begin
        m_axis_img_valid <= 1'd0;
        m_axis_img_pixel <= {(PIXEL_BITWIDTH*PIXEL_NUM){1'd0}};
    end
end

always @ (posedge s_clk) begin
    m_axis_img_done <= (state_curr == ST_DONE);
end

/*******************************************************************************
*
*   Call Module
*
*******************************************************************************/
scaler_pad #(
    .PIXEL_BITWIDTH   ( PIXEL_BITWIDTH ),
    .PIXEL_NUM        ( PIXEL_NUM      ),
    .IMG_H_MAX        ( IMG_H_MAX      ),
    .IMG_H_BITWIDTH   ( IMG_H_BITWIDTH )
) inst_scaler_pad (
    .s_clk            ( s_clk          ),
    .s_rst            ( s_rst          ),
    .start            ( pad_start      ),
    .len              ( pad_len        ),
    .done             ( pad_done       ),
    .m_axis_valid     ( pad_axis_valid ),
    .m_axis_pixel     ( pad_axis_pixel )
);

function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule