`timescale 1ns/1ps
/****************************************************************
* Auther : CYabner
* Mail   : hn.cy@foxmail.com
* Time   : 2019.02.14
* Design :
****************************************************************/

`include "filesystem_common.v"

module filesystem_operate
#(
    parameter  FILE_ID            = 0,
    parameter  AXI_ADDR_BITWIDTH  = 32,
    parameter  AXI_DATA_BITWIDTH  = 64,
    parameter  AXI_LEN_BITWIDTH   = 4,
    parameter  AXI_STRB_BITWIDTH  = 8
)(
    input       clk,
    input       rst,
    // Write Channel
    output reg                             s_axi_awready = 1'd0,
    input                                  s_axi_awvalid,
    input       [AXI_ADDR_BITWIDTH-1 : 0]  s_axi_awaddr,
    input       [AXI_LEN_BITWIDTH-1 : 0]   s_axi_awlen,
    output reg                             s_axi_wready = 1'd0,
    input                                  s_axi_wvalid,
    input       [AXI_DATA_BITWIDTH-1 : 0]  s_axi_wdata,
    input       [AXI_STRB_BITWIDTH-1 : 0]  s_axi_wstrb,
    input                                  s_axi_wlast,
    // Read Channel
    output reg                             s_axi_arready = 1'd0,
    input                                  s_axi_arvalid,
    input       [AXI_ADDR_BITWIDTH-1 : 0]  s_axi_araddr,
    input       [AXI_LEN_BITWIDTH-1 : 0]   s_axi_arlen,
    input                                  s_axi_rready,
    output reg                             s_axi_rvalid = 1'd0,
    output reg  [AXI_DATA_BITWIDTH-1 : 0]  s_axi_rdata,
    output                                 s_axi_rlast
);
/********************************************************************************
*
*   Define localparam
*
********************************************************************************/
localparam FILE_NAME     = (FILE_ID == 0) ? `FILE_0_FILE_NAME :
                           (FILE_ID == 1) ? `FILE_1_FILE_NAME :
                        //    (FILE_ID == 2) ? `FILE_2_FILE_NAME :
                        //    (FILE_ID == 3) ? `FILE_3_FILE_NAME :
                                            `FILE_0_FILE_NAME ;

localparam AXI_BASE_ADDR = (FILE_ID == 0) ? `FILE_0_AXI_BASE_ADDR :
                           (FILE_ID == 1) ? `FILE_1_AXI_BASE_ADDR :
                        //    (FILE_ID == 2) ? `FILE_2_AXI_BASE_ADDR :
                        //    (FILE_ID == 3) ? `FILE_3_AXI_BASE_ADDR :
                                            `FILE_0_AXI_BASE_ADDR ;
/********************************************************************************
*
*   Define reg / wire
*
********************************************************************************/

reg  [AXI_ADDR_BITWIDTH-1 : 0] write_addr = {AXI_ADDR_BITWIDTH{1'd0}};
reg  [AXI_LEN_BITWIDTH-1  : 0] write_len  = {AXI_LEN_BITWIDTH{1'd0}};
reg  [AXI_LEN_BITWIDTH-1  : 0] write_cnt  = {AXI_LEN_BITWIDTH{1'd0}};
wire                           write_last;
reg                            write_err = 1'd0;
reg  [AXI_ADDR_BITWIDTH-1 : 0] read_addr = {AXI_ADDR_BITWIDTH{1'd0}};
reg  [AXI_LEN_BITWIDTH-1  : 0] read_len  = {AXI_LEN_BITWIDTH{1'd0}};
reg  [AXI_LEN_BITWIDTH-1  : 0] read_cnt  = {AXI_LEN_BITWIDTH{1'd0}};

/********************************************************************************
*
*   file operator
*
********************************************************************************/
reg                           write_enable = 1'd0;
reg                           write_stop   = 1'd0;
reg                           read_enable  = 1'd0;
reg                           read_stop    = 1'd0;
reg                           write_fopen_flag = 1'd0;
reg                           write_fseek_flag = 1'd0;
reg                           write_hold = 1'd0;
reg                           write_fclose_flag = 1'd0;
reg                           read_fopen_flag = 1'd0;
reg                           read_fseek_flag = 1'd0;
reg                           read_fclose_flag = 1'd0;
integer                       write_fp;
integer                       write_fseek_status;
integer                       read_fp;
integer                       read_fseek_status;

/*---------------------------------------- ADDR Control and File Control-------------------------------------------------*/
always @ (posedge clk) begin
// Write Addr Channel
    if(rst | write_fclose_flag) begin
        s_axi_awready <= 1'd1;
   end
    else if(s_axi_awready & s_axi_awvalid) begin
        s_axi_awready <= 1'd0;
    end
end

always @ (posedge clk) begin
    if(s_axi_awready & s_axi_awvalid) begin
        write_addr <= s_axi_awaddr;
        write_len  <= s_axi_awlen;
    end
end

always @ (posedge clk) begin
    if(rst) begin
        write_hold <= 1'd0;
    end
    else if(write_fseek_flag) begin
        write_hold <= 1'd1;
    end
    else if(s_axi_wready & s_axi_wvalid & write_last) begin
        write_hold <= 1'd0;
    end
end

always @ (posedge clk) begin
    if(rst) begin
        s_axi_wready <= 1'd0;
    end
    else if(s_axi_wready & s_axi_wvalid & write_last) begin
        s_axi_wready <= 1'd0;
    end
    else if(write_fseek_flag | write_hold) begin
        s_axi_wready <= 1'd1;
    end
end

always @ (posedge clk) begin
    if(s_axi_awready & s_axi_awvalid) begin
        write_cnt <= {AXI_LEN_BITWIDTH{1'd0}};
    end
    else if(s_axi_wready & s_axi_wvalid) begin
        write_cnt <= write_cnt + 1'd1;
    end
end

assign write_last = (write_cnt == write_len) ? 1'd1 : 1'd0;

always @ (posedge clk) begin
    if(s_axi_wready & s_axi_wvalid & s_axi_wlast) begin
        if(write_last) begin
            write_err <= 1'd0;
        end
        else begin
            write_err <= 1'd1;
        end
    end
    else begin
        write_err <= 1'd0;
    end
    if(write_err) begin
        $display("ERR : File %s write len \n", FILE_NAME);
    end
end

/*---------------------------------------- Write Control ------------------------------------------------*/
always @ (posedge clk) begin
    {write_fseek_flag, write_fopen_flag} <= {write_fopen_flag, (s_axi_awready & s_axi_awvalid)};
end

always @ (posedge clk) begin
    write_fclose_flag <= s_axi_wready & s_axi_wvalid & s_axi_wlast;
end

always @ (posedge clk) begin
    if(rst) begin
        write_enable <= 1'd0;
    end
    else if(write_stop) begin
        write_enable <= 1'd0;
    end
    else if(write_fopen_flag) begin
        write_enable <= 1'd1;
    end
end

// step 1 :  open
always @ (posedge clk) begin
    if(write_fopen_flag & (~write_enable)) begin
        read_stop <= 1'd1;
        if(read_enable) begin
            $display("fclose: read File, %s could be opened.\n", FILE_NAME);
            $fclose(read_fp);
        end
        write_fp = $fopen(FILE_NAME, "wb");
        if (write_fp == 0) begin
            $display("Error: File, %s could not be opened.\n", FILE_NAME);
            $finish;
        end
        $display("fopen: write File, %s could be opened.\n", FILE_NAME);
    end
    else begin
        read_stop <= 1'd0;
    end
end

// step 2 :  seek
always @ (posedge clk) begin
    if(write_fseek_flag) begin
        write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR) , 0);
    end
end

// step3 :   write
always @ (posedge clk) begin
    if(s_axi_wready & s_axi_wvalid) begin
        if(AXI_DATA_BITWIDTH >= 32) begin
            if(s_axi_wstrb[0]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*1-1 : 8*0]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+1 , 0);
            end

            if(s_axi_wstrb[1]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*2-1 : 8*1]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+2 , 0);
            end

            if(s_axi_wstrb[2]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*3-1 : 8*2]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+3 , 0);
            end

            if(s_axi_wstrb[3]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*4-1 : 8*3]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+4 , 0);
            end
        end
// must DATA = 64bit
        if(AXI_DATA_BITWIDTH >= 64) begin
            if(s_axi_wstrb[4]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*5-1 : 8*4]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+5 , 0);
            end

            if(s_axi_wstrb[5]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*6-1 : 8*5]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+6 , 0);
            end

            if(s_axi_wstrb[6]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*7-1 : 8*6]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+7 , 0);
            end

            if(s_axi_wstrb[7]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*8-1 : 8*7]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+8 , 0);
            end
        end
// must DATA = 128bit
        if(AXI_DATA_BITWIDTH >= 128) begin
            if(s_axi_wstrb[8]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*9-1 : 8*8]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+9 , 0);
            end

            if(s_axi_wstrb[9]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*10-1 : 8*9]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+10 , 0);
            end

            if(s_axi_wstrb[10]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*11-1 : 8*10]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+11 , 0);
            end

            if(s_axi_wstrb[11]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*12-1 : 8*11]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+12 , 0);
            end

            if(s_axi_wstrb[12]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*13-1 : 8*12]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+13, 0);
            end

            if(s_axi_wstrb[13]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*14-1 : 8*13]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+14 , 0);
            end

            if(s_axi_wstrb[14]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*15-1 : 8*14]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+15 , 0);
            end

            if(s_axi_wstrb[15]) begin
                $fwrite(write_fp, "%c",s_axi_wdata[8*16-1 : 8*15]);
            end
            else begin
                write_fseek_status = $fseek(write_fp, (write_addr-AXI_BASE_ADDR)+16 , 0);
            end


        end

    end
end

always @ (posedge clk) begin
    if(write_fclose_flag) begin
        // $fclose(write_fp);
    end
end


/*---------------------------------------- Read Control ------------------------------------------------*/
always @ (posedge clk) begin
// Read Addr Channel
    if(rst | read_fclose_flag) begin
        s_axi_arready <= 1'd1;
    end
    else if(s_axi_arready & s_axi_arvalid) begin
        s_axi_arready <= 1'd0;
    end
end

always @ (posedge clk) begin
    if(s_axi_arready & s_axi_arvalid) begin
        read_addr = s_axi_araddr;
        read_len  = s_axi_arlen;
    end
end

always @ (posedge clk) begin
    if(rst) begin
        s_axi_rvalid <= 1'd0;
    end
    else if(read_fseek_flag) begin
        s_axi_rvalid <= 1'd1;
    end
    else if(s_axi_rready & s_axi_rvalid & s_axi_rlast) begin
        s_axi_rvalid <= 1'd0;
    end
end

assign s_axi_rlast = (read_cnt == read_len) ? 1'd1 : 1'd0;

/*----------------------------------------------- Read File -----------------------------------------------------*/
always @ (posedge clk) begin
    {read_fseek_flag, read_fopen_flag} <= {read_fopen_flag, s_axi_arready & s_axi_arvalid};
end

always @ (posedge clk) begin
    read_fclose_flag <= s_axi_rready & s_axi_rvalid & s_axi_rlast;
end

always @ (posedge clk) begin
    if(rst) begin
        read_enable <= 1'd0;
    end
    else if(read_stop) begin
        read_enable <= 1'd0;
    end
    else if(read_fopen_flag) begin
        read_enable <= 1'd1;
    end
end

// step 1 : open
always @ (posedge clk) begin
    if(read_fopen_flag & (~read_enable)) begin
        write_stop <= 1'd1;
        if(write_enable) begin
            $display("fclose: write File, %s could be opened.\n", FILE_NAME);
            $fclose(write_fp);
        end
        read_fp = $fopen(FILE_NAME, "rb");
        if (read_fp == 0) begin
            read_fp = $fopen(FILE_NAME, "wb");
            $fclose(read_fp);
            read_fp = $fopen(FILE_NAME, "rb");
            if(read_fp == 0) begin
                $display("Error: File, %s could not be opened.\n", FILE_NAME);
                $finish;
            end
        end
        $display("fopen: read File, %s could be opened.\n", FILE_NAME);
    end
    else begin
        write_stop <= 1'd0;
    end
end

// step 2 : seek
always @ (posedge clk) begin
    if(read_fseek_flag) begin
        read_fseek_status = $fseek(read_fp, (read_addr-AXI_BASE_ADDR) , 0);
    end
end

// step 3 : read
always @ (posedge clk) begin
    if(read_fseek_flag | (s_axi_rready & s_axi_rvalid)) begin
        s_axi_rdata[8*1-1 : 8*0] = $fgetc(read_fp);
        s_axi_rdata[8*2-1 : 8*1] = $fgetc(read_fp);
        s_axi_rdata[8*3-1 : 8*2] = $fgetc(read_fp);
        s_axi_rdata[8*4-1 : 8*3] = $fgetc(read_fp);
        s_axi_rdata[8*5-1 : 8*4] = $fgetc(read_fp);
        s_axi_rdata[8*6-1 : 8*5] = $fgetc(read_fp);
        s_axi_rdata[8*7-1 : 8*6] = $fgetc(read_fp);
        s_axi_rdata[8*8-1 : 8*7] = $fgetc(read_fp);

        s_axi_rdata[8*9-1 : 8*8] = $fgetc(read_fp);
        s_axi_rdata[8*10-1 : 8*9] = $fgetc(read_fp);
        s_axi_rdata[8*11-1 : 8*10] = $fgetc(read_fp);
        s_axi_rdata[8*12-1 : 8*11] = $fgetc(read_fp);
        s_axi_rdata[8*13-1 : 8*12] = $fgetc(read_fp);
        s_axi_rdata[8*14-1 : 8*13] = $fgetc(read_fp);
        s_axi_rdata[8*15-1 : 8*14] = $fgetc(read_fp);
        s_axi_rdata[8*16-1 : 8*15] = $fgetc(read_fp);

    end
end

always @ (posedge clk) begin
    if(s_axi_arready & s_axi_arvalid) begin
        read_cnt <= {AXI_LEN_BITWIDTH{1'd0}};
    end
    else if(s_axi_rready & s_axi_rvalid) begin
        read_cnt <= read_cnt + 1'd1;
    end
end

// step 4 : close
always @ (posedge clk) begin
    if(read_fclose_flag) begin
        // $fclose(read_fp);
    end
end

endmodule