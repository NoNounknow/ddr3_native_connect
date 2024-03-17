module app_rd_addr_ctrl #(
    parameter   rd_base_addr    = 0 ,
    parameter   rd_burst_length = 64,
    parameter   IW = 1024,
    parameter   IH = 768 ,
    parameter   Pixel_wd = 2
)(
    input   wire            I_clk           ,//rd_fifo_rclk & rd_cmd_wclk
    input   wire            I_Rst_n         ,
    input   wire            rd_start_rl     ,

    output  wire            rd_cmd_wren     ,
    output  wire    [2:0]   rd_cmd_wrcmd    ,
    output  wire    [7:0]   rd_cmd_wrbl     ,
    output  wire    [27:0]  rd_cmd_wraddr   ,

    output  wire            rd_data_end     ,
    output  wire            rd_fifo_rden    ,
    input   wire    [15:0]  rd_rd_data_count // hdmi fifo
);

//-----------------------------------------------//
    localparam Total_Frame_Offset = (IW)*(IH)*(Pixel_wd)/4;
    localparam Brust_Offset       = 512;
    localparam Max_Frame0         = Total_Frame_Offset - Brust_Offset;

            reg             r_rd_cmd_wren   ;
            reg     [27:0]  r_rd_cmd_wraddr ;

            reg             rd_en_r         ;
            reg     [7:0]   rd_cnt          ;
            reg             r_rd_data_end   ;

//-----------------------------------------------//
    assign  rd_cmd_wren   =  r_rd_cmd_wren  ;
    assign  rd_cmd_wrcmd  =  3'b001;
    assign  rd_cmd_wrbl   =  rd_burst_length;  
    assign  rd_cmd_wraddr =  r_rd_cmd_wraddr;
    assign  rd_fifo_rden  =  rd_en_r        ;
    assign  rd_data_end   =  r_rd_data_end  ;

    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            r_rd_cmd_wren <= 1'b0;
        end else if(rd_start_rl == 1'b1 && r_rd_cmd_wren == 1'b0) begin
            r_rd_cmd_wren <= 1'b1;
        end else begin
            r_rd_cmd_wren <= 1'b0;
        end
    end

    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            r_rd_cmd_wraddr <= rd_base_addr;
        end else if(r_rd_cmd_wraddr == Max_Frame0 && r_rd_cmd_wren == 1'b1) begin
            r_rd_cmd_wraddr <= rd_base_addr;
        end else if(r_rd_cmd_wren == 1'b1) begin
            r_rd_cmd_wraddr <= r_rd_cmd_wraddr + Brust_Offset;
        end else begin
            r_rd_cmd_wraddr <= r_rd_cmd_wraddr;
        end
    end

    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            rd_en_r <= 1'b0;
        end else if(rd_en_r == 1'b1 && rd_cnt == rd_burst_length - 1'b1) begin
            rd_en_r <= 1'b0;
        end else if(rd_rd_data_count == rd_burst_length) begin
            rd_en_r <= 1'b1;
        end else begin
            rd_en_r <= rd_en_r;
        end
    end

    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            rd_cnt <= 'd0;
        end else if(rd_en_r == 1'b1 && rd_cnt == rd_burst_length - 1'b1) begin
            rd_cnt <= 'd0;
        end else if(rd_en_r == 1'b1) begin
            rd_cnt <= rd_cnt + 1'b1;
        end
    end

    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            r_rd_data_end <= 1'b0;
        end else if(rd_en_r == 1'b1 && rd_cnt == rd_burst_length - 1'b1) begin
            r_rd_data_end <= 1'b1;
        end else begin
            r_rd_data_end <= 1'b0;
        end
    end
endmodule