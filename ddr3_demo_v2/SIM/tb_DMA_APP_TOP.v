`timescale  1ns / 1ps
`define Period 20
module tb_DMA_APP_TOP;

parameter CS_WIDTH  = 1;  // # of unique CS outputs to memory.
parameter DM_WIDTH  = 4;  // # of DM (data mask)
parameter DQ_WIDTH  = 32; // # of DQ (data)
parameter DQS_WIDTH = 4;  // # of DQ per DQS
parameter ODT_WIDTH = 1;  // # of ODT outputs to memory.
parameter ROW_WIDTH = 14; // # of memory Row Address bits.

localparam real TPROP_DQS = 0.00; // Delay for DQS signal during Write Operatio
localparam real TPROP_DQS_RD = 0.00;  // Delay for DQS signal during Read Operation
localparam real TPROP_PCB_CTRL = 0.00;  // Delay for Address and Ctrl signals
localparam real TPROP_PCB_DATA = 0.00;  // Delay for data signal during Write operation
localparam real TPROP_PCB_DATA_RD = 0.00; // Delay for data signal during Read operation
localparam MEMORY_WIDTH = 16;
localparam NUM_COMP     = DQ_WIDTH / MEMORY_WIDTH;

// DMA_APP_TOP Inputs
reg   I_Rst_n                              ;
reg   I_Clk                                ;

// DMA_APP_TOP Outputs
wire  [13:0]  ddr3_addr                    ;
wire  [2:0]   ddr3_ba                      ;
wire  ddr3_cas_n                           ;
wire  [0:0]  ddr3_ck_n                     ;
wire  [0:0]  ddr3_ck_p                     ;
wire  [0:0]  ddr3_cke                      ;
wire  ddr3_ras_n                           ;
wire  ddr3_reset_n                         ;
wire  ddr3_we_n                            ;
wire  [0:0]  ddr3_cs_n                     ;
wire  [3:0]  ddr3_dm                       ;
wire  [0:0]  ddr3_odt                      ;

// DMA_APP_TOP Bidirs
wire  [31:0]  ddr3_dq                      ;
wire  [3:0]  ddr3_dqs_n                    ;
wire  [3:0]  ddr3_dqs_p                    ;

reg  [(CS_WIDTH*1)-1:0]       ddr3_cs_n_sdram_tmp;
reg  [DM_WIDTH-1:0]           ddr3_dm_sdram_tmp;     
reg  [ODT_WIDTH-1:0]          ddr3_odt_sdram_tmp;

wire [DQ_WIDTH-1:0]           ddr3_dq_sdram;
reg  [ROW_WIDTH-1:0]          ddr3_addr_sdram [0:1];
reg  [3-1:0]                  ddr3_ba_sdram [0:1];
reg                           ddr3_ras_n_sdram;
reg                           ddr3_cas_n_sdram;
reg                           ddr3_we_n_sdram;
wire [(CS_WIDTH*1)-1:0]       ddr3_cs_n_sdram;
wire [ODT_WIDTH-1:0]          ddr3_odt_sdram;
reg  [1-1:0]                  ddr3_cke_sdram;
wire [DM_WIDTH-1:0]           ddr3_dm_sdram;
wire [DQS_WIDTH-1:0]          ddr3_dqs_p_sdram;
wire [DQS_WIDTH-1:0]          ddr3_dqs_n_sdram;
reg  [1-1:0]                  ddr3_ck_p_sdram;
reg  [1-1:0]                  ddr3_ck_n_sdram;


//sim Port--------------------------------------------------------------------//
  //clk
  reg                sim_ui_clk         ;
  //wr
  reg                sim_wr_start       ;
  reg    [27:0]      sim_wr_addr        ;
  reg    [2:0]       sim_wr_cmd         ;
  reg    [7:0]       sim_wr_burst_len   ;
  reg    [255:0]     sim_wr_data        ;
  reg    [31:0]      sim_wr_wdf_mask    ;
  reg                sim_wr_burst_start ;
  reg                sim_wr_burst_end   ;
  reg                sim_wr_rd_en       ;
  //rd
  reg                sim_rd_start        ;
  reg    [27:0]      sim_rd_addr         ;
  reg    [2:0]       sim_rd_cmd          ;
  reg    [7:0]       sim_rd_burst_len    ;
  reg    [255:0]     sim_rd_data         ;
  reg                sim_rd_vaild        ;
  reg    [7:0]       sim_error_cnt       ; 
//sim Port--------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------------------//
initial begin
    I_Clk = 0;
end
always #(`Period/2) I_Clk = ~ I_Clk;

initial begin
    I_Rst_n <= 1'b0;
    repeat(10) @(posedge I_Clk);
    I_Rst_n <= 1'b1;
end

initial begin
  //wr
  sim_wr_start     = 'd0;
  sim_wr_addr      = 'd0;
  sim_wr_cmd       = 'd0;
  sim_wr_burst_len = 'd0;
  sim_wr_data      = 'd0;
  sim_wr_wdf_mask  = 'd0;
  sim_ui_clk       = 'd0;
  sim_wr_rd_en     = 'd0;
  sim_wr_burst_start = 'd0;
  sim_wr_burst_end   = 'd0;
  //rd
  sim_rd_start      = 0;
  sim_rd_addr       = 0;
  sim_rd_cmd        = 0;
  sim_rd_burst_len  = 0;
  sim_rd_data       = 0;
  sim_rd_vaild      = 0;
  sim_error_cnt     = 0;

  force sim_ui_clk = u_DMA_APP_TOP.ui_clk;

  force u_DMA_APP_TOP.ex_wr_start      = sim_wr_start    ;
  force u_DMA_APP_TOP.ex_wr_addr       = sim_wr_addr     ;
  force u_DMA_APP_TOP.ex_wr_cmd        = sim_wr_cmd      ;
  force u_DMA_APP_TOP.ex_wr_burst_len  = sim_wr_burst_len;
  force u_DMA_APP_TOP.ex_wr_data       = sim_wr_data     ;
  force u_DMA_APP_TOP.ex_wr_wdf_mask   = sim_wr_wdf_mask ;

  force sim_wr_burst_start = u_DMA_APP_TOP.ex_wr_burst_start;
  force sim_wr_burst_end   = u_DMA_APP_TOP.ex_wr_burst_end  ;
  force sim_wr_rd_en       = u_DMA_APP_TOP.ex_wr_rd_en         ;

  force u_DMA_APP_TOP.ex_rd_start      = sim_rd_start    ;
  force u_DMA_APP_TOP.ex_rd_addr       = sim_rd_addr     ;
  force u_DMA_APP_TOP.ex_rd_cmd        = sim_rd_cmd      ;
  force u_DMA_APP_TOP.ex_rd_burst_len  = sim_rd_burst_len;

  force sim_rd_data  = u_DMA_APP_TOP.ex_rd_data;
  force sim_rd_vaild = u_DMA_APP_TOP.ex_rd_wr_en;
end

initial begin
  #(501);
  Gen_initial_wr_cmd();
end

initial begin
  #(501);
  Gen_wr_data();
end

initial begin
  #(501);
  Gen_initial_rd_cmd();
end

initial begin
  #(501);
  Check_rd_data();
end
//-----------------------------------------------------------------------------------------------------//


//Task-------------------------------------------------------------------------------------------------//

task Gen_initial_rd_cmd();
  begin
  repeat(1) @(posedge sim_wr_burst_end);
  repeat(1) @(posedge sim_ui_clk);
  sim_rd_start     <= 1'b1;
  sim_rd_burst_len <= 8'd64;
  sim_rd_cmd       <= 3'b1;
  repeat(1) @(posedge sim_ui_clk);
  sim_rd_start     <= 1'b0;
  sim_rd_burst_len <= 'd0;
  sim_rd_cmd       <= 'd1;
  end
endtask

task Gen_initial_wr_cmd();
  begin
  @(posedge u_DMA_APP_TOP.init_calib_complete);
  repeat(1) @(posedge sim_ui_clk);
  sim_wr_start <= 1'b1;
  sim_wr_burst_len <= 8'd64;
  sim_wr_wdf_mask  <= 32'b0;
  sim_wr_cmd       <= 3'b0;
  repeat(1) @(posedge sim_ui_clk);
  sim_wr_start     <= 1'b0;
  sim_wr_burst_len <= 'd0;
  sim_wr_wdf_mask  <= 'd0;
  sim_wr_cmd       <= 'd0;
  end
endtask


task Gen_wr_data();
  integer i;
  begin
    repeat(1) @(posedge sim_wr_rd_en);
    for (i = 0; i < 64 ; i = i + 1) begin
        sim_wr_data = {224'b0, i[31:0]};
      @(posedge sim_ui_clk);
      if(sim_wr_rd_en == 1'b0) begin
        i = i - 1;
      end
    end
    sim_wr_data <= 'd0;
    @(posedge sim_ui_clk);
  end
endtask

task Check_rd_data();
  integer i;
  begin
    @(posedge sim_rd_vaild)
    for (i = 0; i < 64 ; i = i + 1) begin
      #1;
      if(sim_rd_vaild == 1'b1 && (i != sim_rd_data[31:0])) begin
        sim_error_cnt = sim_error_cnt + 1'b1;
      end
      @(posedge sim_ui_clk);
      if(sim_rd_vaild == 1'b0) begin
        i = i - 1;
      end
    end
      @(posedge sim_ui_clk);
      if(sim_error_cnt != 0) begin
        $display("sim_error_cnt is  %d", sim_error_cnt);
      end else begin
        $display("check successfully");
      end
  end
endtask

//-----------------------------------------------------------------------------------------------------//



//-----------------------------------------------------------------------------------------------------//
always @( * ) begin
  ddr3_ck_p_sdram     <=  ddr3_ck_p;
  ddr3_ck_n_sdram     <=  ddr3_ck_n;
  ddr3_addr_sdram[0]  <=  ddr3_addr;
  ddr3_addr_sdram[1]  <=  ddr3_addr;
  ddr3_ba_sdram[0]    <=  ddr3_ba;
  ddr3_ba_sdram[1]    <=  ddr3_ba;
  ddr3_ras_n_sdram    <=  ddr3_ras_n;
  ddr3_cas_n_sdram    <=  ddr3_cas_n;
  ddr3_we_n_sdram     <=  ddr3_we_n;
  ddr3_cke_sdram      <=  ddr3_cke;
end

always @( * )
  ddr3_cs_n_sdram_tmp <=  ddr3_cs_n;

assign ddr3_cs_n_sdram =  ddr3_cs_n_sdram_tmp;

always @( * )
  ddr3_dm_sdram_tmp <=  ddr3_dm;//DM signal generation

assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;     

always @( * )
  ddr3_odt_sdram_tmp <=   ddr3_odt;

assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;

DMA_APP_TOP  u_DMA_APP_TOP (
    .I_Rst_n                 ( I_Rst_n      ),
    .I_Clk                   ( I_Clk        ),

    .ddr3_addr               ( ddr3_addr    ),
    .ddr3_ba                 ( ddr3_ba      ),
    .ddr3_cas_n              ( ddr3_cas_n   ),
    .ddr3_ck_n               ( ddr3_ck_n    ),
    .ddr3_ck_p               ( ddr3_ck_p    ),
    .ddr3_cke                ( ddr3_cke     ),
    .ddr3_ras_n              ( ddr3_ras_n   ),
    .ddr3_reset_n            ( ddr3_reset_n ),
    .ddr3_we_n               ( ddr3_we_n    ),
    .ddr3_cs_n               ( ddr3_cs_n    ),
    .ddr3_dm                 ( ddr3_dm      ),
    .ddr3_odt                ( ddr3_odt     ),

    .ddr3_dq                 ( ddr3_dq      ),
    .ddr3_dqs_n              ( ddr3_dqs_n   ),
    .ddr3_dqs_p              ( ddr3_dqs_p   )
);

// Controlling the bi-directional BUS
genvar dqwd;
generate
  for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
    WireDelay #
    (
      .Delay_g     (TPROP_PCB_DATA),
      .Delay_rd    (TPROP_PCB_DATA_RD),
      .ERR_INSERT ("OFF")
    )
    u_delay_dq
    (
      .A                 (ddr3_dq[dqwd]),
      .B                 (ddr3_dq_sdram[dqwd]),
      .reset            (I_Rst_n),
      .phy_init_done (u_DMA_APP_TOP.init_calib_complete)
    );
  end

  WireDelay #
  (
    .Delay_g     (TPROP_PCB_DATA),
    .Delay_rd    (TPROP_PCB_DATA_RD),
    .ERR_INSERT ("OFF")
  )
  u_delay_dq_0
  (
    .A                 (ddr3_dq[0]),
    .B                 (ddr3_dq_sdram[0]),
    .reset            (I_Rst_n),
    .phy_init_done (u_DMA_APP_TOP.init_calib_complete)
  );
endgenerate

genvar dqswd;
generate
  for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
    WireDelay #
    (
      .Delay_g     (TPROP_DQS),
      .Delay_rd    (TPROP_DQS_RD),
      .ERR_INSERT ("OFF")
    )
    u_delay_dqs_p
    (
      .A                 (ddr3_dqs_p[dqswd]),
      .B                 (ddr3_dqs_p_sdram[dqswd]),
      .reset            (I_Rst_n),
      .phy_init_done (u_DMA_APP_TOP.init_calib_complete)
    );

    WireDelay #
    (
      .Delay_g     (TPROP_DQS),
      .Delay_rd    (TPROP_DQS_RD),
      .ERR_INSERT ("OFF")
    )
    u_delay_dqs_n
    (
      .A                 (ddr3_dqs_n[dqswd]),
      .B                 (ddr3_dqs_n_sdram[dqswd]),
      .reset            (I_Rst_n),
      .phy_init_done (u_DMA_APP_TOP.init_calib_complete)
    );
  end
endgenerate

//**************************************************************************//
// Memory Models instantiations
//**************************************************************************//

genvar r,i;
generate
  for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
      for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
        ddr3_model u_comp_ddr3
        (
          .rst_n    (ddr3_reset_n),
          .ck       (ddr3_ck_p_sdram),
          .ck_n     (ddr3_ck_n_sdram),
          .cke      (ddr3_cke_sdram[r]),
          .cs_n     (ddr3_cs_n_sdram[r]),
          .ras_n    (ddr3_ras_n_sdram),
          .cas_n    (ddr3_cas_n_sdram),
          .we_n     (ddr3_we_n_sdram),
          .dm_tdqs  (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
          .ba       (ddr3_ba_sdram[r]),
          .addr     (ddr3_addr_sdram[r]),
          .dq       (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
          .dqs      (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
          .dqs_n    (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
          .tdqs_n   (),
          .odt      (ddr3_odt_sdram[r])
        );
      end
    end
endgenerate

//-----------------------------------------------------------------------------------------------------//
endmodule