module hdmi_buff #(
    parameter   Iw = 256,
    parameter   Ow = 16
)(
    input   wire            rst_n           ,

    input   wire            hdmi_clk        ,  
    input   wire            hdmi_Pre_de     ,
    input   wire            hdmi_Pre_hsync  ,
    input   wire            hdmi_Pre_vsync  ,


    output  wire            hdmi_Post_en    ,
    output  wire            hdmi_Post_hsync ,
    output  wire            hdmi_Post_vsync ,
    output  wire  [15:0]    hdmi_rd_data    ,
    //fifo
    output  wire            fifo_rd_en      ,
    input   wire  [255:0]   fifo_rd_data    

);
    localparam  Div_Num = (Iw/Ow);
            reg   [7:0]     byte_cnt        ;
            reg             r_fifo_rd_en    ;
            reg   [255:0]   shift_rd_data   ;
        //hdmi
            reg             r1_hdmi_Pre_de      ;
            reg             r1_hdmi_Pre_hsync   ;
            reg             r1_hdmi_Pre_vsync   ;


    assign  hdmi_Post_en    = r1_hdmi_Pre_de        ;
    assign  hdmi_Post_hsync = r1_hdmi_Pre_hsync     ;
    assign  hdmi_Post_vsync = r1_hdmi_Pre_vsync     ;

    assign  hdmi_rd_data = (hdmi_Post_en == 1'b1)?(shift_rd_data[255:240]):('d0);

    // fifo_rd_en
    assign  fifo_rd_en   = r_fifo_rd_en;

    always @(posedge hdmi_clk) begin
        r1_hdmi_Pre_de    <= hdmi_Pre_de    ;
        r1_hdmi_Pre_hsync <= hdmi_Pre_hsync ;
        r1_hdmi_Pre_vsync <= hdmi_Pre_vsync ;
    end

    //byte_cnt
    always @(posedge hdmi_clk) begin
        if(rst_n == 1'b0) begin
            byte_cnt <= 'd0;
        end else if(hdmi_Pre_de == 1'b1 && byte_cnt == Div_Num - 1'b1) begin
            byte_cnt <= 'd0;
        end else if(hdmi_Pre_de == 1'b1) begin
            byte_cnt <= byte_cnt + 1'b1;
        end else begin
            byte_cnt <= byte_cnt;
        end
    end

    always @(*) begin
        if(hdmi_Pre_de == 1'b1 && byte_cnt == 'd0) begin
            r_fifo_rd_en <= 1'b1;
        end else begin
            r_fifo_rd_en <= 1'b0;
        end
    end

    always @(posedge hdmi_clk) begin
        if(rst_n == 1'b0) begin
            shift_rd_data <= 'd0;
        end else if(hdmi_Pre_de == 1'b1 && byte_cnt == 'd0) begin
            shift_rd_data <= fifo_rd_data;
        end else if(hdmi_Post_en == 1'b1) begin
            shift_rd_data <= {shift_rd_data[239:0],16'b0};
        end else begin
            shift_rd_data <= shift_rd_data;
        end
    end
    
endmodule