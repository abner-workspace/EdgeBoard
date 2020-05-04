module scaler_ctrl
#(
    parameter IMG_H_MAX             = 3840,
    parameter IMG_V_MAX             = 2160,
    parameter IMG_H_BITWIDTH        = CLOG2(IMG_H_MAX),
    parameter IMG_V_BITWIDTH        = CLOG2(IMG_V_MAX),
    parameter PAD_MAX               = 2,
    parameter PAD_BITWIDTH          = CLOG2(PAD_MAX),
    parameter KERNEL_MAX            = 4,
    parameter KERNEL_BITWIDTH       = CLOG2(KERNEL_MAX),
    parameter KERNEL_COEF_BITWIDTH  = 8,  // 8Q6
    parameter SF_BITWIDTH           = 24, // 24Q20
    parameter SF_INT_BITWIDTH       = 20,
    parameter SF_FRAC_BITWIDTH      = 4
)(
    input                                       s_clk,
    input                                       s_rst,
    output reg                                  s_rst_all          = 1,
    output reg [IMG_H_BITWIDTH-1 : 0]           s_arg_img_src_h    = 300,
    output reg [IMG_V_BITWIDTH-1 : 0]           s_arg_img_src_v    = 300,
    output reg                                  s_start            = 0,

    input                                       m_clk,
    input                                       m_rst,
    output reg                                  m_rst_all          = 0,
    output reg [IMG_H_BITWIDTH-1 : 0]           m_arg_img_des_h    = 100,
    output reg [IMG_V_BITWIDTH-1 : 0]           m_arg_img_des_v    = 100,
    output reg                                  m_start            = 0,

    input                                       core_clk,
    input                                       core_rst,
    output reg                                  core_rst_all       = 0,
    output reg [IMG_H_BITWIDTH-1 : 0]           core_arg_img_src_h = 300,
    output reg [IMG_V_BITWIDTH-1 : 0]           core_arg_img_src_v = 300,
    output reg [IMG_H_BITWIDTH-1 : 0]           core_arg_img_des_h = 100,
    output reg [IMG_V_BITWIDTH-1 : 0]           core_arg_img_des_v = 100,
    output reg                                  core_arg_mode      = 0, // 0 = scaler down 1 = scaler up
    output reg [SF_BITWIDTH-1 : 0]              core_arg_hsf       = 24'h30_0000,  //18_0000 = 300/200*(2**20) = // Isize / Osize
    output reg [SF_BITWIDTH-1 : 0]              core_arg_vsf       = 24'h30_0000,  //18_0000 = 300/200*(2**20) = // Isize / Osize
    output reg                                  core_start         = 0,
    output reg [KERNEL_COEF_BITWIDTH*KERNEL_MAX*KERNEL_MAX-1 : 0] scaler_coef,
    input                                       start
);

always @ (posedge core_clk) begin
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*0+0+1)-1 : KERNEL_COEF_BITWIDTH*(4*0+0+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*0+1+1)-1 : KERNEL_COEF_BITWIDTH*(4*0+1+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*0+2+1)-1 : KERNEL_COEF_BITWIDTH*(4*0+2+0)] = 2**6;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*0+3+1)-1 : KERNEL_COEF_BITWIDTH*(4*0+3+0)] = 0;

    scaler_coef[KERNEL_COEF_BITWIDTH*(4*1+0+1)-1 : KERNEL_COEF_BITWIDTH*(4*1+0+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*1+1+1)-1 : KERNEL_COEF_BITWIDTH*(4*1+1+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*1+2+1)-1 : KERNEL_COEF_BITWIDTH*(4*1+2+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*1+3+1)-1 : KERNEL_COEF_BITWIDTH*(4*1+3+0)] = 2**6;

    scaler_coef[KERNEL_COEF_BITWIDTH*(4*2+0+1)-1 : KERNEL_COEF_BITWIDTH*(4*2+0+0)] = 2**6;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*2+1+1)-1 : KERNEL_COEF_BITWIDTH*(4*2+1+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*2+2+1)-1 : KERNEL_COEF_BITWIDTH*(4*2+2+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*2+3+1)-1 : KERNEL_COEF_BITWIDTH*(4*2+3+0)] = 0;

    scaler_coef[KERNEL_COEF_BITWIDTH*(4*3+0+1)-1 : KERNEL_COEF_BITWIDTH*(4*3+0+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*3+1+1)-1 : KERNEL_COEF_BITWIDTH*(4*3+1+0)] = 2**6;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*3+2+1)-1 : KERNEL_COEF_BITWIDTH*(4*3+2+0)] = 0;
    scaler_coef[KERNEL_COEF_BITWIDTH*(4*3+3+1)-1 : KERNEL_COEF_BITWIDTH*(4*3+3+0)] = 0;

end

always @ (posedge core_clk) begin
    s_rst_all  <= core_rst;
    m_rst_all  <= core_rst;
    core_rst_all <= core_rst;
    s_start    <= start;
    m_start    <= start;
    core_start <= start;
end


function integer CLOG2 (input integer depth);
    begin
        for(CLOG2 = 0; depth > 0; CLOG2 = CLOG2 + 1) begin
            depth = depth >> 1;
        end
    end
endfunction

endmodule