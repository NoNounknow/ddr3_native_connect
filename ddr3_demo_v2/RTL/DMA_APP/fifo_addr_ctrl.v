module fifo_addr_ctrl #(
    parameter   wr_base_addr    = 0     ,
    parameter   rd_base_addr    = 0     ,
    parameter   dw              = 256-1 ,// data width
    parameter   bl              = 64    ,// burst length
    parameter   Iw              = 1024  ,// image width
    parameter   Ih              = 768   ,// image highth
    parameter   Pixel_num       = 2   
)(
    input   wire            rst_n        ,
    //wdata
     //wr
    input   wire            wr_fifo_rst_n,
    input   wire            wr_fifo_wclk ,
    input   wire    [dw:0]  wr_fifo_wdata,
    input   wire            wr_fifo_wren ,
     //rd
    input   wire            wr_fifo_rclk ,
    input   wire            wr_fifo_rden ,
    output  wire    [dw:0]  wr_fifo_rdata,
    output  wire            wr_data_req  ,//wr req
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
    input   wire    [dw:0]  rd_fifo_wdata,
    input   wire            rd_fifo_wren ,
     //rd
    input   wire            rd_fifo_rclk ,
    input   wire            rd_fifo_rden ,
    output  wire    [dw:0]  rd_fifo_rdata,
    output  wire            rd_data_req  ,//rd req
    //rcmd
     //rd
    input   wire            rd_cmd_rden  ,
    output  wire    [2:0]   rd_cmd_rdcmd ,
    output  wire    [7:0]   rd_cmd_rdbl  ,
    output  wire    [27:0]  rd_cmd_rdaddr
);
//----------------------------------------------------------------------------------//

    localparam  addr_offset = ((dw+1)*(bl))/32;
    localparam  Total_Frame_Offset  = ((Iw * Ih * Pixel_num)/4) - addr_offset;


//----------------------------------------------------------------------------------//
            wire            wr_fifo_full    ;
            wire            wr_fifo_empty   ;
            wire    [15:0]  wr_rd_data_count;
            wire    [15:0]  wr_wr_data_count;

            //wr addr
            reg     [27:0]  wr_cmd_rdaddr_r ;
            reg             wr_cmd_rden_r1  ;
            reg             wr_cmd_rden_r2  ;

            wire            rd_fifo_full    ;
            wire            rd_fifo_empty   ;
            wire    [15:0]  rd_rd_data_count;
            wire    [15:0]  rd_wr_data_count;

            //rd addr
            reg     [27:0]  rd_cmd_rdaddr_r ;
            reg             rd_cmd_rden_r1  ;
            reg             rd_cmd_rden_r2  ;
//----------------------------------------------------------------------------------//

    assign  wr_data_req = (wr_rd_data_count >= bl);

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

    // wr cmd rd------------------------------------------------------------------------//
    always @(posedge wr_fifo_rclk) begin
        if((rst_n)&&(wr_fifo_rst_n)) begin
            wr_cmd_rdaddr_r <= 'd0;
        end else if(wr_cmd_rden_r1 == 1'b1 && wr_cmd_rden_r2 == 1'b0 && wr_cmd_rdaddr_r == Total_Frame_Offset) begin
            wr_cmd_rdaddr_r <= 'd0; 
        end else if(wr_cmd_rden_r1 == 1'b1 && wr_cmd_rden_r2 == 1'b0) begin
            wr_cmd_rdaddr_r <= wr_cmd_rdaddr_r + addr_offset;
        end
    end

    always @(posedge wr_fifo_rclk) begin
        {wr_cmd_rden_r2, wr_cmd_rden_r1} <= {wr_cmd_rden_r1, wr_cmd_rden};
    end
    
    assign  wr_cmd_rdaddr = wr_cmd_rdaddr_r;
    assign  wr_cmd_rdcmd  = 3'b000;
    assign  wr_cmd_rdbl   = bl;

    // wr cmd rd------------------------------------------------------------------------//

    assign  rd_data_req = (rd_rd_data_count)<=(bl * 2);

    rd_data_w256x128_r256x128 rd_data_fifo (
    .rst      ((!rst_n)|(!rd_fifo_rst_n)),// input wire rst
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

    // rd cmd rd------------------------------------------------------------------------//
    always @(posedge rd_fifo_wclk) begin
        if((rst_n)&&(rd_fifo_rst_n)) begin
            rd_cmd_rdaddr_r <= 'd0;
        end else if(rd_cmd_rden_r1 == 1'b1 && rd_cmd_rden_r2 == 1'b0 && rd_cmd_rdaddr_r == Total_Frame_Offset) begin
            rd_cmd_rdaddr_r <= 'd0; 
        end else if(rd_cmd_rden_r1 == 1'b1 && rd_cmd_rden_r2 == 1'b0) begin
            rd_cmd_rdaddr_r <= rd_cmd_rdaddr_r + addr_offset;
        end
    end

    always @(posedge rd_fifo_wclk) begin
        {rd_cmd_rden_r2, rd_cmd_rden_r1} <= {rd_cmd_rden_r1, rd_cmd_rden};
    end
    
    assign  rd_cmd_rdaddr = rd_cmd_rdaddr_r;
    assign  rd_cmd_rdcmd  = 3'b001;
    assign  rd_cmd_rdbl   = bl;

    // rd cmd rd------------------------------------------------------------------------//

endmodule