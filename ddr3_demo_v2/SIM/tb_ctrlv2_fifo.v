`timescale  1ns / 1ps
`define Period 20
module tb_ctrlv2_fifo;

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
  reg                sim_wr_wclk        ;
  reg     [255:0]    sim_wr_wdata       ;
  reg                sim_wr_wen         ;

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
  sim_ui_clk = 0;
  sim_wr_wclk = 0;
  sim_wr_wen = 0;
  sim_wr_wdata = 0;

  force sim_ui_clk  = dma_app_topv2.ui_clk     ;
  force sim_wr_wclk = dma_app_topv2.O_CLK_50MHZ;
  force dma_app_topv2.wr_fifo_wren      = sim_wr_wen   ;
  force dma_app_topv2.wr_fifo_wdata     = sim_wr_wdata;

end

initial begin
  @(posedge dma_app_topv2.init_calib_complete);
  repeat(100) @(posedge sim_ui_clk);
  #(1);
  Gen_wr_data();
  @(posedge sim_ui_clk);
  Gen_wr_data();
end
//-----------------------------------------------------------------------------------------------------//


//Task-------------------------------------------------------------------------------------------------//
task Gen_wr_data();
  integer i;
  begin
    for (i = 0; i < 64 ; i = i + 1) begin
      sim_wr_wen = 1'b1;
      sim_wr_wdata = i[31:0];
      @(posedge sim_wr_wclk);
    end 
    sim_wr_wen = 0;
    sim_wr_wdata = 0;
    @(posedge sim_wr_wclk);
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

dma_app_topv2  dma_app_topv2 (
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
    .ddr3_dqs_p              ( ddr3_dqs_p   ),
    .HDMI_CLK_P              (              ),
    .HDMI_CLK_N              (              ),
    .HDMI_TX_P               (              ),
    .HDMI_TX_N               (              )
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
      .phy_init_done (dma_app_topv2.init_calib_complete)
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
    .phy_init_done (dma_app_topv2.init_calib_complete)
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
      .phy_init_done (dma_app_topv2.init_calib_complete)
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
      .phy_init_done (dma_app_topv2.init_calib_complete)
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