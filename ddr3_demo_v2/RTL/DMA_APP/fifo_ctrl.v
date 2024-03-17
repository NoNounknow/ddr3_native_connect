module fifo_ctrl #(
    parameter   wr_base_addr    = 0 ,
    parameter   rd_base_addr    = 0 ,
    parameter   wr_burst_length = 64,
    parameter   rd_burst_length = 64,
    parameter   IW = 1024,
    parameter   IH = 768 ,
    parameter   Pixel_wd = 2
)(
    input   wire            rst_n        ,
    output  wire            rd_start     ,
    //wdata
     //wr
    input   wire            wr_fifo_rst_n,
    input   wire            wr_fifo_wclk ,
    input   wire    [255:0] wr_fifo_wdata,
    input   wire            wr_fifo_wren ,
     //rd
    input   wire            wr_fifo_rclk ,
    input   wire            wr_fifo_rden ,
    output  wire    [255:0] wr_fifo_rdata,
    output  wire            wr_data_req  ,//wr req
    //wcmd
    //wcmd
     //rd
    input   wire            wr_cmd_rden  ,
    output  wire    [2:0]   wr_cmd_rdcmd ,
    output  wire    [7:0]   wr_cmd_rdbl  ,
    output  wire    [27:0]  wr_cmd_rdaddr,

    //rdata
     //wr
    input   wire            rd_fifo_rst_n,
    input   wire            rd_fifo_wclk ,
    input   wire    [255:0] rd_fifo_wdata,
    input   wire            rd_fifo_wren ,
     //rd
    input   wire            rd_fifo_rclk ,
    input   wire            rd_fifo_rden ,
    output  wire    [255:0] rd_fifo_rdata,
    output  wire            rd_data_req  ,//rd req
     //rd
    input   wire            rd_cmd_rden  ,
    output  wire    [2:0]   rd_cmd_rdcmd ,
    output  wire    [7:0]   rd_cmd_rdbl  ,
    output  wire    [27:0]  rd_cmd_rdaddr
);

//----------------------------------------------------------------------------------//

    localparam Total_Frame_Offset = (IW)*(IH)*(Pixel_wd)/4;
    localparam Brust_Offset       = 512;
    localparam Max_Frame0         = Total_Frame_Offset - Brust_Offset;

//----------------------------------------------------------------------------------//

            wire            wr_fifo_full    ;
            wire            wr_fifo_empty   ;
            wire    [08:0]  wr_rd_data_count;
            wire    [08:0]  wr_wr_data_count;

            wire            rd_fifo_full    ;
            wire            rd_fifo_empty   ;
            wire    [08:0]  rd_rd_data_count;
            wire    [08:0]  rd_wr_data_count;

    //wr cmd
            reg             r1_wr_cmd_rden  ;
            reg             r2_wr_cmd_rden  ;
            reg     [27:0]  r_wr_cmd_rdaddr ;
    //rd cmd
            reg             r1_rd_cmd_rden  ;
            reg             r2_rd_cmd_rden  ;
            reg     [27:0]  r_rd_cmd_rdaddr ;
    //start
            reg             r1_rd_start     ;
            reg             r2_rd_start     ;
            reg             r3_rd_start     ;
           wire             rd_access       ;
//----------------------------------------------------------------------------------//
    assign  rd_start = (r1_rd_start == 1'b1)&&(r2_rd_start == 1'b1)&&(r3_rd_start == 1'b1);
    assign  rd_access = (r1_rd_start == 1'b1)&&(r2_rd_start == 1'b1);
    //req
    assign  wr_data_req = (wr_rd_data_count >= wr_burst_length);
    assign  rd_data_req = (rd_access == 1'b1)?(rd_wr_data_count <= rd_burst_length*2):1'b0;

//----------------------------------------------------------------------------------//
    // wr cmd
    assign  wr_cmd_rdcmd  = 3'b000;
    assign  wr_cmd_rdbl   = wr_burst_length;
    assign  wr_cmd_rdaddr = r_wr_cmd_rdaddr;

    //wr_cmd_rden
    always @(posedge wr_fifo_rclk) begin
        r1_wr_cmd_rden <= wr_cmd_rden   ;
        r2_wr_cmd_rden <= r1_wr_cmd_rden;
    end

    always @(posedge wr_fifo_rclk) begin
        if(rst_n == 1'b0) begin
            r_wr_cmd_rdaddr <= wr_base_addr;
        end else if((r1_wr_cmd_rden == 1'b1 && r2_wr_cmd_rden == 1'b0) && (r_wr_cmd_rdaddr == Max_Frame0)) begin
            r_wr_cmd_rdaddr <= wr_base_addr;
        end else if((r1_wr_cmd_rden == 1'b1 && r2_wr_cmd_rden == 1'b0)) begin
            r_wr_cmd_rdaddr <= r_wr_cmd_rdaddr + Brust_Offset;
        end else begin
            r_wr_cmd_rdaddr <= r_wr_cmd_rdaddr;
        end
    end
//display start---------------------------------------------------------------//
    // r1_rd_start
    always @(posedge wr_fifo_rclk) begin
        if(rst_n == 1'b0) begin
            r1_rd_start <= 1'b0;
        end else if((r1_wr_cmd_rden == 1'b1 && r2_wr_cmd_rden == 1'b0) && (r_wr_cmd_rdaddr == Max_Frame0)) begin
            r1_rd_start <= 1'b1;
        end else begin
            r1_rd_start <= r1_rd_start;
        end
    end
    always @(posedge wr_fifo_rclk) begin
        if(rst_n == 1'b0) begin
            r2_rd_start <= 1'b0;
        end else if(r1_rd_start == 1'b1 && rd_fifo_full == 1'b0) begin
            r2_rd_start <= 1'b1;
        end else begin
            r2_rd_start <= r2_rd_start;
        end
    end
    always @(posedge wr_fifo_rclk) begin
        if(rst_n == 1'b0) begin
            r3_rd_start <= 1'b0;
        end else if(r1_rd_start == 1'b1 && r2_rd_start == 1'b1 && rd_wr_data_count >= rd_burst_length*2) begin
            r3_rd_start <= 1'b1;
        end else begin
            r3_rd_start <= r3_rd_start;
        end
    end
//display start---------------------------------------------------------------//
//----------------------------------------------------------------------------------//
    wr_data_w256x128_r256x128 wr_data_fifo (
    .rst      ((!rst_n)|(!wr_fifo_rst_n)), // input wire rst
    .wr_clk   ( wr_fifo_wclk            ), // input wire wr_clk
    .rd_clk   ( wr_fifo_rclk            ), // input wire rd_clk
    .din      ( wr_fifo_wdata           ), // input wire [255 : 0] din
    .wr_en    ( wr_fifo_wren            ), // input wire wr_en
    .rd_en    ( wr_fifo_rden            ), // input wire rd_en
    .dout     ( wr_fifo_rdata           ), // output wire [255 : 0] dout
    .full     ( wr_fifo_full            ), // output wire full
    .empty    ( wr_fifo_empty           ), // output wire empty
    .rd_data_count( wr_rd_data_count    ), // output wire [7 : 0] rd_data_count
    .wr_data_count( wr_wr_data_count    ), // output wire [7 : 0] wr_data_count
    .wr_rst_busy(),      // output wire wr_rst_busy
    .rd_rst_busy()       // output wire rd_rst_busy
    );
//----------------------------------------------------------------------------------//

    assign  rd_cmd_rdcmd  =  3'b001;
    assign  rd_cmd_rdbl   =  rd_burst_length; 
    assign  rd_cmd_rdaddr =  r_rd_cmd_rdaddr;

    always @(posedge rd_fifo_wclk) begin
        r1_rd_cmd_rden <= rd_cmd_rden;
        r2_rd_cmd_rden <= r1_rd_cmd_rden;
    end

    always @(posedge rd_fifo_wclk) begin
        if(rst_n == 1'b0) begin
            r_rd_cmd_rdaddr <= rd_base_addr;
        end else if((r1_rd_cmd_rden == 1'b1 && r2_rd_cmd_rden == 1'b0) && (r_rd_cmd_rdaddr == Max_Frame0)) begin
            r_rd_cmd_rdaddr <= rd_base_addr;
        end else if((r1_rd_cmd_rden == 1'b1 && r2_rd_cmd_rden == 1'b0)) begin
            r_rd_cmd_rdaddr <= r_rd_cmd_rdaddr + Brust_Offset;
        end else begin
            r_rd_cmd_rdaddr <= r_rd_cmd_rdaddr;
        end
    end
//----------------------------------------------------------------------------------//
    rd_data_w256x128_r256x128 rd_data_fifo (
    .rst      ((!rst_n)|(!rd_fifo_rst_n)|(!r1_rd_start)),// input wire rst
    .wr_clk   ( rd_fifo_wclk            ),// input wire wr_clk
    .rd_clk   ( rd_fifo_rclk            ),// input wire rd_clk
    .din      ( rd_fifo_wdata           ),// input wire [255 : 0] din
    .wr_en    ( rd_fifo_wren            ),// input wire wr_en
    .rd_en    ( rd_fifo_rden            ),// input wire rd_en
    .dout     ( rd_fifo_rdata           ),// output wire [255 : 0] dout
    .full     ( rd_fifo_full            ),// output wire full
    .empty    ( rd_fifo_empty           ),// output wire empty
    .rd_data_count( rd_rd_data_count    ),// output wire [7 : 0] rd_data_count
    .wr_data_count( rd_wr_data_count    ),// output wire [7 : 0] wr_data_count
    .wr_rst_busy(),      // output wire wr_rst_busy
    .rd_rst_busy()       // output wire rd_rst_busy
    );

endmodule