`timescale 1ns/1ps
/******************************************************************************
* Auther : CY.abner
* Mail   : hn.cy@foxmail.com
* Gitee  : https://gitee.com/abnerwork/
* Description :
*   @Create : 2019-12-25 14:40:51
*           Data is input by row and output by column
*   @Modify : 2020-03-30 22:25:00
*
******************************************************************************/
module scaler_matrix
#(
    parameter PIXEL_BITWIDTH  = 8,
    parameter IMG_H_MAX       = 3840,
    parameter IMG_V_MAX       = 2160,
    parameter IMG_H_BITWIDTH  = CLOG2(IMG_H_MAX),
    parameter IMG_V_BITWIDTH  = CLOG2(IMG_V_MAX),
    parameter KERNEL_MAX      = 4,
    parameter KERNEL_BITWIDTH = CLOG2(KERNEL_MAX),
    parameter MATRIX_DELAY    = 4
)(
    input                                                   s_clk,
    input                                                   s_rst,
    input                                                   s_start,
    output                                                  s_axis_connect_ready,
    input                                                   s_axis_connect_valid,
    input                                                   s_axis_img_valid,
    input      [PIXEL_BITWIDTH-1 : 0]                       s_axis_img_pixel,
    input                                                   s_axis_img_done,
    input                                                   core_clk,
    input                                                   core_rst,
    input                                                   core_start,
    input                                                   m_axis_connect_ready,
    output                                                  m_axis_connect_valid,
    input                                                   matrix_ram_read_stride,
    input                                                   matrix_ram_read_repeat,
    input                                                   matrix_ram_read_en,
    output                                                  matrix_ram_read_rsp_en,
    output     [PIXEL_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] matrix_ram_read_rsp_pixel,
    input                                                   matrix_ram_read_done
);

/*******************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam RAM_DELAY         = 2;
localparam RAM_NUM           = KERNEL_MAX+1;  // +1 for pingpong memory
localparam RAM_NUM_BITWIDTH  = CLOG2(RAM_NUM);
localparam RAM_DEEP          = IMG_H_MAX;
localparam RAM_ADDR_BITWIDTH = IMG_H_BITWIDTH;
localparam RAM_DATA_BITWIDTH = PIXEL_BITWIDTH;
/*******************************************************************************
*
*   Define reg / wire
*
********************************************************************************/
wire [RAM_NUM-1 : 0]                   ram_ena;
wire [RAM_NUM-1 : 0]                   ram_wea;
wire [RAM_ADDR_BITWIDTH-1 : 0]         ram_addra;
wire [RAM_DATA_BITWIDTH-1 : 0]         ram_dina;
wire [RAM_NUM-1 : 0]                   ram_enb;
wire [RAM_ADDR_BITWIDTH-1 : 0]         ram_addrb;
wire [RAM_DATA_BITWIDTH*RAM_NUM-1 : 0] ram_doutb;
// matrix ram control signal
wire                                   ram_write_done;
wire [RAM_NUM_BITWIDTH-1 : 0]          ram_write_num;
wire                                   ram_read_done;
wire [RAM_NUM_BITWIDTH-1 : 0]          ram_read_num;

wire                                   ram_write_done_cdc;
wire [RAM_NUM_BITWIDTH-1 : 0]          ram_write_num_cdc;
wire                                   ram_read_done_cdc;
wire [RAM_NUM_BITWIDTH-1 : 0]          ram_read_num_cdc;
/*******************************************************************************
*
*   RTL verilog
*
*******************************************************************************/
scaler_matrix_ram #(
    .RAM_NUM                      ( RAM_NUM             ),
    .RAM_DEEP                     ( RAM_DEEP            ),
    .RAM_ADDR_BITWIDTH            ( RAM_ADDR_BITWIDTH   ),
    .RAM_DATA_BITWIDTH            ( RAM_DATA_BITWIDTH   ),
    .RAM_DELAY                    ( RAM_DELAY           )
) inst_scaler_matrix_ram(
    .ram_clka                     ( s_clk               ),
    .ram_ena                      ( ram_ena             ),
    .ram_wea                      ( ram_wea             ),
    .ram_addra                    ( ram_addra           ),
    .ram_dina                     ( ram_dina            ),
    .ram_clkb                     ( core_clk            ),
    .ram_enb                      ( ram_enb             ),
    .ram_addrb                    ( ram_addrb           ),
    .ram_doutb                    ( ram_doutb           )
);

/********************************** matrix_write *****************************/
scaler_matrix_write #(
    .KERNEL_MAX                  ( KERNEL_MAX           ),
    .KERNEL_BITWIDTH             ( KERNEL_BITWIDTH      ),
    .RAM_NUM                     ( RAM_NUM              ),
    .RAM_NUM_BITWIDTH            ( RAM_NUM_BITWIDTH     ),
    .RAM_DEEP                    ( RAM_DEEP             ),
    .RAM_ADDR_BITWIDTH           ( RAM_ADDR_BITWIDTH    ),
    .RAM_DATA_BITWIDTH           ( RAM_DATA_BITWIDTH    )
)inst_scaler_matrix_write(
    .s_clk                       ( s_clk                ),
    .s_rst                       ( s_rst                ),
    .s_start                     ( s_start              ),
    .s_axis_connect_ready        ( s_axis_connect_ready ),
    .s_axis_connect_valid        ( s_axis_connect_valid ),
    .s_axis_img_valid            ( s_axis_img_valid     ),
    .s_axis_img_pixel            ( s_axis_img_pixel     ),
    .s_axis_img_done             ( s_axis_img_done      ),
    .ram_ena                     ( ram_ena              ),
    .ram_wea                     ( ram_wea              ),
    .ram_addra                   ( ram_addra            ),
    .ram_dina                    ( ram_dina             ),
    .ram_write_done              ( ram_write_done       ),
    .ram_write_num               ( ram_write_num        ),
    .ram_read_done               ( ram_read_done_cdc    ),
    .ram_read_num                ( ram_read_num_cdc     )
);

/********************************** matrix_read *****************************/
scaler_matrix_read #(
    .KERNEL_MAX                  ( KERNEL_MAX           ),
    .KERNEL_BITWIDTH             ( KERNEL_BITWIDTH      ),
    .RAM_DELAY                   ( RAM_DELAY            ),
    .RAM_NUM                     ( RAM_NUM              ),
    .RAM_NUM_BITWIDTH            ( RAM_NUM_BITWIDTH     ),
    .RAM_DEEP                    ( RAM_DEEP             ),
    .RAM_ADDR_BITWIDTH           ( RAM_ADDR_BITWIDTH    ),
    .RAM_DATA_BITWIDTH           ( RAM_DATA_BITWIDTH    )
) inst_scaler_matrix_read(
    .core_clk                    ( core_clk                  ),
    .core_rst                    ( core_rst                  ),
    .core_start                  ( core_start                ),
    .m_axis_connect_ready        ( m_axis_connect_ready      ),
    .m_axis_connect_valid        ( m_axis_connect_valid      ),
    .matrix_ram_read_stride      ( matrix_ram_read_stride    ),
    .matrix_ram_read_repeat      ( matrix_ram_read_repeat    ),
    .matrix_ram_read_en          ( matrix_ram_read_en        ),
    .matrix_ram_read_rsp_en      ( matrix_ram_read_rsp_en    ),
    .matrix_ram_read_rsp_pixel   ( matrix_ram_read_rsp_pixel ),
    .matrix_ram_read_done        ( matrix_ram_read_done      ),
    .ram_enb                     ( ram_enb                   ),
    .ram_addrb                   ( ram_addrb                 ),
    .ram_doutb                   ( ram_doutb                 ),
    .ram_write_done              ( ram_write_done_cdc        ),
    .ram_write_num               ( ram_write_num_cdc         ),
    .ram_read_done               ( ram_read_done             ),
    .ram_read_num                ( ram_read_num              )
);

xpm_cdc_array_single #(
    .DEST_SYNC_FF   (4),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF   (0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK (0),   // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG  (1),   // DECIMAL; 0=do not register input, 1=register input
    .WIDTH          (1+RAM_NUM_BITWIDTH)    // DECIMAL; range: 1-1024
) xpm_cdc_core_to_s (
    .src_clk        ( core_clk                              ),
    .src_in         ( {ram_read_done,     ram_read_num}     ),
    .dest_clk       ( s_clk                                 ),
    .dest_out       ( {ram_read_done_cdc, ram_read_num_cdc} )
);

xpm_cdc_array_single #(
    .DEST_SYNC_FF   (4),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF   (0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK (0),   // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG  (1),   // DECIMAL; 0=do not register input, 1=register input
    .WIDTH          (1+RAM_NUM_BITWIDTH)    // DECIMAL; range: 1-1024
) xpm_cdc_s_to_core (
    .src_clk        ( s_clk                                   ),
    .src_in         ( {ram_write_done,     ram_write_num}     ),
    .dest_clk       ( core_clk                                ),
    .dest_out       ( {ram_write_done_cdc, ram_write_num_cdc} )
);


function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule