module app_wr_addr_ctrl #(
    parameter   wr_base_addr    = 0 ,
    parameter   wr_burst_length = 64,
    parameter   IW = 1024,
    parameter   IH = 768 ,
    parameter   Pixel_wd = 2
)(
    input   wire            I_clk        ,//wr_fifo_rclk & wr_cmd_wclk
    input   wire            I_Rst_n      ,
    input   wire            Pre_wren     ,
    input   wire    [255:0] Pre_wdata    ,
    //data
    output  wire    [255:0] wr_fifo_wdata,
    output  wire            wr_fifo_wren ,
    //cmd
    output  wire            wr_cmd_wren  ,
    output  wire    [2:0]   wr_cmd_wrcmd ,
    output  wire    [7:0]   wr_cmd_wrbl  ,
    output  wire    [27:0]  wr_cmd_wraddr
);

//-----------------------------------------------//
    localparam Total_Frame_Offset = (IW)*(IH)*(Pixel_wd)/4;
    localparam Brust_Offset       = 512;
    localparam Max_Frame0         = Total_Frame_Offset - Brust_Offset;
            reg     [255:0] r_Pre_wdata     ;
            reg             wren_r1         ;
            reg             wren_r2         ;
            reg     [7:0]   wr_cnt          ;

            reg             r_wr_cmd_wren   ;
            reg     [27:0]  r_wr_cmd_wraddr ;


//-----------------------------------------------//

    assign  wr_fifo_wren  = wren_r1     ;
    assign  wr_fifo_wdata = r_Pre_wdata ;

    assign  wr_cmd_wren   = r_wr_cmd_wren;
    assign  wr_cmd_wrcmd  = 3'b000;
    assign  wr_cmd_wrbl   = wr_burst_length;
    assign  wr_cmd_wraddr = r_wr_cmd_wraddr;

    always @(posedge I_clk) begin
        {wren_r2,wren_r1} <= {wren_r1, Pre_wren};
        r_Pre_wdata       <= Pre_wdata          ;
    end

    // wr_cnt
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            wr_cnt <= 'd0;
        end else if(wren_r2 == 1'b1 && wr_cnt == wr_burst_length - 1'b1) begin
            wr_cnt <= 'd0; 
        end else if(wren_r2 == 1'b1) begin
            wr_cnt <= wr_cnt + 1'b1;
        end else begin
            wr_cnt <= wr_cnt;
        end
    end

    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            r_wr_cmd_wren <= 1'b0;
        end else if(wren_r2 == 1'b1 && wr_cnt == wr_burst_length - 1'b1) begin
            r_wr_cmd_wren <= 1'b1;
        end else begin
            r_wr_cmd_wren <= 1'b0;
        end
    end

    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            r_wr_cmd_wraddr <= wr_base_addr;
        end else if(r_wr_cmd_wren == 1'b1 && r_wr_cmd_wraddr == Max_Frame0) begin
            r_wr_cmd_wraddr <= wr_base_addr;
        end else if(r_wr_cmd_wren == 1'b1) begin
            r_wr_cmd_wraddr <= r_wr_cmd_wraddr + Brust_Offset;
        end else begin
            r_wr_cmd_wraddr <= r_wr_cmd_wraddr;
        end
    end

endmodule