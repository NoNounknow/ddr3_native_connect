module uart_buff #(
    parameter   IW = 8,
    parameter   OW = 256
)(
    input   wire            sys_clk             ,
    input   wire            rst_n               ,
    input   wire            uart_rx_vaild       ,
    input   wire    [7:0]   uart_rx_data        ,
    output  wire    [255:0] uart_8to256_data    ,
    output  wire            uart_8to256_vaild   
);
    localparam  DATA_MAX = 32;
            reg     [7:0]   data_cnt            ;
            reg     [255:0] shift_data          ;
            reg             r1_uart_8to256_vaild;

    assign  uart_8to256_vaild = r1_uart_8to256_vaild;
    assign  uart_8to256_data  = shift_data;

    always @(posedge sys_clk) begin
        if(rst_n == 1'b0) begin
            data_cnt <= 'd0;
        end else if(uart_rx_vaild == 1'b1 && data_cnt == DATA_MAX - 1'b1) begin
            data_cnt <= 'd0;
        end else if(uart_rx_vaild == 1'b1) begin
            data_cnt <= data_cnt + 1'b1;
        end else begin
            data_cnt <= data_cnt;
        end
    end
    
    // shift_data
    always @(posedge sys_clk) begin
        if(rst_n == 1'b0) begin
            shift_data <= 'd0;
        end else if(uart_rx_vaild == 1'b1) begin
            shift_data <= {shift_data[247:0],uart_rx_data};
        end else begin
            shift_data <= shift_data;
        end
    end    

    always @(posedge sys_clk) begin
        if(rst_n == 1'b0) begin
            r1_uart_8to256_vaild <= 1'b0;
        end else if(uart_rx_vaild == 1'b1 && data_cnt == DATA_MAX - 1'b1) begin
            r1_uart_8to256_vaild <= 1'b1;
        end else begin
            r1_uart_8to256_vaild <= 1'b0;
        end
    end

ila_0 ila_0 (
	.clk(sys_clk), // input wire clk
	.probe0({
        rst_n             ,
        uart_rx_vaild     ,
        uart_rx_data      ,
        uart_8to256_data  ,
        uart_8to256_vaild 
    }) // input wire [299:0] probe0
);
endmodule