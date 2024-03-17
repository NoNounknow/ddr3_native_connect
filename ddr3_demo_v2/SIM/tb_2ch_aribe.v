`timescale  1ns / 1ps
module tb_Aribe_LoopPrior_State_v1;

// Aribe_LoopPrior_State_v1 Parameters
parameter PERIOD  = 10;


// Aribe_LoopPrior_State_v1 Inputs
reg   I_clk                                = 0 ;
reg   I_Rst_n                              = 0 ;
reg   I_ch0_req                            = 0 ;
reg   I_ch0_start                          = 0 ;
reg   I_ch0_end                            = 0 ;
reg   I_ch1_req                            = 0 ;
reg   I_ch1_start                          = 0 ;
reg   I_ch1_end                            = 0 ;

// Aribe_LoopPrior_State_v1 Outputs
wire  O_ch0_vaild                          ;
wire  O_ch1_vaild                          ;


initial begin
    I_clk = 0;
end
always #(PERIOD/2) I_clk = ~ I_clk;

initial begin
    I_Rst_n <= 1'b0;
    repeat (100) @(posedge I_clk);
    I_Rst_n <= 1'b1;
end

initial begin  
    repeat (10) @(posedge I_clk);
    I_ch0_start <= 1'b0;
    I_ch0_end   <= 1'b0;
    I_ch1_start <= 1'b0;
    I_ch1_end   <= 1'b0;

    {I_ch1_req, I_ch0_req} <= 2'b00;
    @(posedge I_Rst_n);
    {I_ch1_req, I_ch0_req} <= 2'b11;
    repeat (1) @(posedge I_clk);
    {I_ch1_req, I_ch0_req} <= 2'b00;
    @(posedge O_ch0_vaild);
    repeat (2) @(posedge I_clk);
    I_ch0_start <= 1'b1;
    repeat (1) @(posedge I_clk);
    I_ch0_start <= 1'b0;
    repeat (64) @(posedge I_clk);
    I_ch0_end <= 1'b1;
    repeat (1) @(posedge I_clk);
    I_ch0_end <= 1'b0;
    repeat (64) @(posedge I_clk); 

    {I_ch1_req, I_ch0_req} <= 2'b10;
    repeat (1) @(posedge I_clk);
    {I_ch1_req, I_ch0_req} <= 2'b00;
    @(posedge O_ch1_vaild);
    repeat (2) @(posedge I_clk);
    I_ch1_start <= 1'b1;
    repeat (1) @(posedge I_clk);
    I_ch1_start <= 1'b0;
    repeat (64) @(posedge I_clk);
    I_ch1_end <= 1'b1;
    repeat (1) @(posedge I_clk);
    I_ch1_end <= 1'b0;
    repeat (64) @(posedge I_clk); 

    {I_ch1_req, I_ch0_req} <= 2'b10;
    repeat (1) @(posedge I_clk);
    {I_ch1_req, I_ch0_req} <= 2'b00;
    @(posedge O_ch1_vaild);
    repeat (2) @(posedge I_clk);
    I_ch1_start <= 1'b1;
    repeat (1) @(posedge I_clk);
    I_ch1_start <= 1'b0;
    repeat (64) @(posedge I_clk);
    I_ch1_end <= 1'b1;
    repeat (1) @(posedge I_clk);
    I_ch1_end <= 1'b0;
    repeat (64) @(posedge I_clk); 
end

app_arbit  app_arbit (
    .I_clk                   ( I_clk         ),
    .I_Rst_n                 ( I_Rst_n       ),
    .I_ch0_req               ( I_ch0_req     ),
    .I_ch0_start             ( I_ch0_start   ),
    .I_ch0_end               ( I_ch0_end     ),
    .I_ch1_req               ( I_ch1_req     ),
    .I_ch1_start             ( I_ch1_start   ),
    .I_ch1_end               ( I_ch1_end     ),

    .O_ch0_vaild             ( O_ch0_vaild   ),
    .O_ch1_vaild             ( O_ch1_vaild   )
);
endmodule