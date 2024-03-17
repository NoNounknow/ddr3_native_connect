module dma_app_topv2 (
    input   wire    I_Rst_n,//SYS RST
    input   wire    I_Clk  ,//SYS CLK

    output wire   [13:0]	ddr3_addr           ,
    output wire   [2:0]	    ddr3_ba             ,
    output wire   		    ddr3_cas_n          ,
    output wire   [0:0]	    ddr3_ck_n           ,
    output wire   [0:0]	    ddr3_ck_p           ,
    output wire   [0:0]	    ddr3_cke            ,
    output wire 			ddr3_ras_n          ,
    output wire 			ddr3_reset_n        ,
    output wire 			ddr3_we_n           ,
    inout         [31:0]	ddr3_dq             ,
    inout         [3:0]		ddr3_dqs_n          ,
    inout         [3:0]		ddr3_dqs_p          ,
    output wire   [0:0]	    ddr3_cs_n           ,
    output wire   [3:0]	    ddr3_dm             ,
    output wire   [0:0]	    ddr3_odt            ,
    input  wire             uart_rx             ,
    //hdmi
    output  wire            HDMI_CLK_P          ,
    output  wire            HDMI_CLK_N          ,
    output  wire    [2:0]   HDMI_TX_P           ,
    output  wire    [2:0]   HDMI_TX_N           
);
//------------------------------------------------------------------------------//
    //PLL
    wire                    O_CLK_200MHZ        ;
    wire                    O_CLK_50MHZ         ;
    wire                    O_CLK_100MHZ        ;
    wire                    PLL0_LOCK           ;
    wire                    PLL1_LOCK           ;
    wire                    CLK_PIXEL_BASE      ;
    wire                    CLK_PIXEL_5X        ;
    //DDR3
    wire                    ui_clk              ;
    wire          [31:0]    app_wdf_mask        ;
    //app
    wire          [27:0]	app_addr            ;        
    wire          [2:0]		app_cmd             ;    
    wire         			app_en              ;                
    wire          [255:0]	app_wdf_data        ;                
    wire         			app_wdf_end         ;                
    wire         			app_wdf_wren        ;                
    wire          [255:0]	app_rd_data         ;        
    wire    			    app_rd_data_end     ;                
    wire    			    app_rd_data_valid   ;                
    wire    			    app_rdy             ;    
    wire    			    app_wdf_rdy         ;        
    wire    			    app_sr_req          ;        
    wire    			    app_ref_req         ;        
    wire    			    app_zq_req          ;        
    wire    			    app_sr_active       ;                
    wire    			    app_ref_ack         ;                
    wire    			    app_zq_ack          ; 
    //wr ctrl
    wire                    ex_wr_start         ;
    wire          [27:0]    ex_wr_addr          ;
    wire          [2:0]     ex_wr_cmd           ;
    wire          [7:0]     ex_wr_burst_len     ;
    wire          [255:0]   ex_wr_data          ;
    wire          [31:0]    ex_wr_wdf_mask      ;

    wire          [27:0]	wr_app_addr         ;        
    wire          [2:0]		wr_app_cmd          ;    
    wire         			wr_app_en           ;  
    //wr aribe
    wire                    ex_wr_burst_start   ;
    wire                    ex_wr_burst_end     ;
    //wr fifo
    wire                    ex_wr_rd_en         ;
    //rd ctrl
    wire                    ex_rd_start         ;
    wire          [27:0]    ex_rd_addr          ;
    wire          [2:0]     ex_rd_cmd           ;
    wire          [7:0]     ex_rd_burst_len     ;
    wire          [255:0]   ex_rd_data          ;
    //rd fifo
    wire                    ex_rd_wr_en         ;
    //rd aribe
    wire                    ex_rd_burst_start   ;
    wire                    ex_rd_burst_end     ;

    wire          [27:0]	rd_app_addr         ;        
    wire          [2:0]		rd_app_cmd          ;    
    wire         			rd_app_en           ; 

    //uart
    wire          [7:0]     uart_rx_data        ;
    wire                    uart_rx_vaild       ;
    //hdmi
    wire                    O_Pre_De            ;
    wire                    O_Pre_Vsync         ;
    wire                    O_Pre_Hsync         ;
    wire                    I_Post_De           ;
    wire                    I_Post_Vsync        ;
    wire                    I_Post_Hsync        ;
    wire          [15:0]    hdmi_rd_data        ;

//------------------------------------------------------------------------------//
//tmp
    // wr data fifo
    wire                    wr_fifo_wclk        ;
    wire          [255:0]   wr_fifo_wdata       ;
    wire                    wr_fifo_wren        ;
    // rd data fifo
    wire                    rd_fifo_rclk        ;
    wire                    rd_fifo_rden        ;
    wire          [255:0]   rd_fifo_rdata       ;
//pre
    wire                    Pre_wren            ;
    wire          [255:0]   Pre_wdata           ;
    wire                    rd_start_rl         ;

//------------------------------------------------------------------------------//
    wire                    rd_fifo_req         ;
    wire                    wr_fifo_req         ;
    wire                    display_start       ;

    assign  app_sr_req   = 1'b0;
    assign  app_ref_req  = 1'b0;
    assign  app_zq_req   = 1'b0;
    assign  ex_wr_wdf_mask = 32'b0;

    assign  app_addr = rd_app_addr|wr_app_addr;
    assign  app_en   = rd_app_en|wr_app_en;
    assign  app_cmd  = (wr_app_en)?(wr_app_cmd):(rd_app_cmd);

    assign  rd_fifo_rclk = CLK_PIXEL_BASE;
    assign  wr_fifo_wclk = O_CLK_50MHZ   ;

//------------------------------------------------------------------------------//

  PLL_0_APP PLL_0_APP
   (
    // Clock out ports
    .O_CLK_200MHZ( O_CLK_200MHZ ),     // output O_CLK_200MHZ
    .O_CLK_50MHZ ( O_CLK_50MHZ  ),     // output O_CLK_50MHZ 
    .O_CLK_100MHZ( O_CLK_100MHZ ),
    // Status and control signals
    .resetn     ( I_Rst_n       ),     // input resetn
    .locked     ( PLL0_LOCK     ),     // output locked
   // Clock in ports
    .I_CLK_50MHZ( I_Clk         )      // input I_CLK_50MHZ
);
  PLL_1 PLL_1
   (
    // Clock out ports
    .CLK_PIXEL_BASE ( CLK_PIXEL_BASE  ), // output CLK_PIXEL_BASE
    .CLK_PIXEL_5X   ( CLK_PIXEL_5X    ), // output CLK_PIXEL_5X
    // Status and control signals
    .resetn         ( PLL0_LOCK       ), // input resetn
    .locked         ( PLL1_LOCK       ), // output locked
   // Clock in ports
    .clk_in1        ( O_CLK_100MHZ    )  // input clk_in1
);

rx_teach Uart_Rx(
    .Sys_clk                 ( O_CLK_50MHZ         ),
    .Rst_n                   ( PLL0_LOCK           ),
    .data_in                 ( uart_rx             ),
    .data_receive            ( uart_rx_data        ),
    .rx_done                 ( uart_rx_vaild       )
);

uart_buff #(
    .IW ( 8    ),
    .OW ( 256  ))
 u_uart_buff (
    .sys_clk                 ( O_CLK_50MHZ       ),
    .rst_n                   ( PLL0_LOCK         ),
    .uart_rx_vaild           ( uart_rx_vaild     ),
    .uart_rx_data            ( uart_rx_data      ),

    .uart_8to256_data        ( wr_fifo_wdata     ),
    .uart_8to256_vaild       ( wr_fifo_wren      )
);

// hdmi_top
hdmi_top #(
    .H_ActiveSize ( 1024                   ),
    .H_SyncStart  ( 1024 + 24              ),
    .H_SyncEnd    ( 1024 + 24 + 136        ),
    .H_FrameSize  ( 1024 + 24 + 136 + 160  ),
    .V_ActiveSize ( 768                    ),
    .V_SyncStart  ( 768 + 3                ),
    .V_SyncEnd    ( 768 + 3 + 6            ),
    .V_FrameSize  ( 768 + 3 + 6 + 29       ))
 HDMI_TOP (
    .Pixl_CLK                ( CLK_PIXEL_BASE   ),
    .Pixl_5xCLK              ( CLK_PIXEL_5X     ),
    .Rst_n                   ( PLL1_LOCK && init_calib_complete && display_start),
    .I_Pixel_Data            ( hdmi_rd_data     ),
    .I_PLL_LOCK              ( PLL1_LOCK        ),

    .HDMI_CLK_P              ( HDMI_CLK_P       ),
    .HDMI_CLK_N              ( HDMI_CLK_N       ),
    .HDMI_TX_P               ( HDMI_TX_P        ),
    .HDMI_TX_N               ( HDMI_TX_N        ),
    .O_Pre_De                ( O_Pre_De         ),
    .O_Pre_Vsync             ( O_Pre_Vsync      ),
    .O_Pre_Hsync             ( O_Pre_Hsync      ),
    .I_Post_De               ( I_Post_De        ),
    .I_Post_Vsync            ( I_Post_Vsync     ),
    .I_Post_Hsync            ( I_Post_Hsync     )
);

hdmi_buff #(
    .Iw ( 256 ),
    .Ow ( 16  ))
 HDMI_Buff (
    .rst_n                   ( PLL1_LOCK && init_calib_complete && display_start),
    .hdmi_clk                ( CLK_PIXEL_BASE           ),
    .hdmi_Pre_de             ( O_Pre_De                 ),
    .hdmi_Pre_hsync          ( O_Pre_Hsync              ),
    .hdmi_Pre_vsync          ( O_Pre_Vsync              ),
    .fifo_rd_data            ( rd_fifo_rdata            ),// rd fifo rd data

    .hdmi_Post_en            ( I_Post_De                ),
    .hdmi_Post_hsync         ( I_Post_Hsync             ),
    .hdmi_Post_vsync         ( I_Post_Vsync             ),
    .hdmi_rd_data            ( hdmi_rd_data             ),
    .fifo_rd_en              ( rd_fifo_rden             )// rd fifo rd en
);

app_arbit  app_arbit_inst0 (
    .I_clk                   ( ui_clk              ),
    .I_Rst_n                 ( init_calib_complete ),
    //rd
    .I_ch0_req               ( rd_fifo_req         ),
    .I_ch0_start             ( ex_rd_burst_start   ),
    .I_ch0_end               ( ex_rd_burst_end     ),
    //wr
    .I_ch1_req               ( wr_fifo_req         ),
    .I_ch1_start             ( ex_wr_burst_start   ),
    .I_ch1_end               ( ex_wr_burst_end     ),
    //vaild
    .O_ch0_vaild             ( ex_rd_start         ),
    .O_ch1_vaild             ( ex_wr_start         )
);

 app_dma_wr  app_dma_wr_inst0 (
     .I_sys_clk               ( ui_clk              ),
     .I_Rst_n                 ( init_calib_complete ),
     .ex_wr_start             ( ex_wr_start         ),
     .ex_wr_addr              ( ex_wr_addr          ),
     .ex_wr_cmd               ( ex_wr_cmd           ),
     .ex_wr_burst_len         ( ex_wr_burst_len     ),
     .ex_wr_data              ( ex_wr_data          ),
     .ex_wr_wdf_mask          ( ex_wr_wdf_mask      ),
     .app_rdy                 ( app_rdy             ),
     .app_wdf_rdy             ( app_wdf_rdy         ),
  
     .ex_wr_burst_start       ( ex_wr_burst_start   ),
     .ex_wr_burst_end         ( ex_wr_burst_end     ),
     .ex_wr_rd_en             ( ex_wr_rd_en         ),
     .app_addr                ( wr_app_addr         ),
     .app_cmd                 ( wr_app_cmd          ),
     .app_en                  ( wr_app_en           ),
     .app_wdf_data            ( app_wdf_data        ),
     .app_wdf_end             ( app_wdf_end         ),
     .app_wdf_wren            ( app_wdf_wren        ),
     .app_wdf_mask            ( app_wdf_mask        )
 );

app_dma_rd  app_dma_rd_inst0 (
    .I_sys_clk               ( ui_clk              ),
    .I_Rst_n                 ( init_calib_complete ),
    .ex_rd_start             ( ex_rd_start         ),
    .ex_rd_addr              ( ex_rd_addr          ),
    .ex_rd_cmd               ( ex_rd_cmd           ),
    .ex_rd_burst_len         ( ex_rd_burst_len     ),
    .app_rd_data             ( app_rd_data         ),
    .app_rd_data_end         ( app_rd_data_end     ),
    .app_rd_data_valid       ( app_rd_data_valid   ),
    .app_rdy                 ( app_rdy             ),

    .ex_rd_data              ( ex_rd_data          ),
    .ex_rd_wr_en             ( ex_rd_wr_en         ),
    .ex_rd_burst_start       ( ex_rd_burst_start   ),
    .ex_rd_burst_end         ( ex_rd_burst_end     ),
    .app_addr                ( rd_app_addr         ),
    .app_cmd                 ( rd_app_cmd          ),
    .app_en                  ( rd_app_en           )
);


fifo_ctrl #(
    .wr_base_addr    ( 0               ),
    .rd_base_addr    ( 0               ),
    .wr_burst_length ( 'd64            ),
    .rd_burst_length ( 'd64            ),
    .IW              ( 'd1024          ),
    .IH              ( 'd768           ),
    .Pixel_wd        ( 'd2             ))
 u_fifo_ctrl (
    .rst_n                   ( init_calib_complete          ),
    .rd_start                ( display_start                ),
    //wr data wr
    .wr_fifo_rst_n           ( init_calib_complete          ),
    .wr_fifo_wclk            ( wr_fifo_wclk                 ),
    .wr_fifo_wdata           ( wr_fifo_wdata                ),
    .wr_fifo_wren            ( wr_fifo_wren                 ),
    //wr data rd                
    .wr_fifo_rclk            ( ui_clk                       ),
    .wr_fifo_rden            ( ex_wr_rd_en                  ),
    .wr_cmd_rden             ( ex_wr_burst_start            ),
    //rd data wr
    .rd_fifo_rst_n           ( init_calib_complete          ),
    .rd_fifo_wclk            ( ui_clk                       ),
    .rd_fifo_wdata           ( ex_rd_data                   ),
    .rd_fifo_wren            ( ex_rd_wr_en                  ),
    //rd data rd
    .rd_fifo_rclk            ( rd_fifo_rclk                 ),
    .rd_fifo_rden            ( rd_fifo_rden                 ),
    .rd_cmd_rden             ( ex_rd_burst_start            ),
    //output
    //wr data rd
    .wr_fifo_rdata           ( ex_wr_data                   ),
    .wr_data_req             ( wr_fifo_req                  ),//req 
    //wr cmd rd
    .wr_cmd_rdcmd            ( ex_wr_cmd                    ),
    .wr_cmd_rdbl             ( ex_wr_burst_len              ),
    .wr_cmd_rdaddr           ( ex_wr_addr                   ),
    //rd data rd
    .rd_fifo_rdata           ( rd_fifo_rdata                ),
    .rd_data_req             ( rd_fifo_req                  ),//req
    //rd cmd rd
    .rd_cmd_rdcmd            ( ex_rd_cmd                    ),
    .rd_cmd_rdbl             ( ex_rd_burst_len              ),
    .rd_cmd_rdaddr           ( ex_rd_addr                   )
);

  mig_7series_0 MIG_APP (
    // Memory interface ports
    .ddr3_addr                      ( ddr3_addr),            // output [13:0]	ddr3_addr
    .ddr3_ba                        ( ddr3_ba),              // output [2:0]	ddr3_ba
    .ddr3_cas_n                     ( ddr3_cas_n),           // output			ddr3_cas_n
    .ddr3_ck_n                      ( ddr3_ck_n),            // output [0:0]	ddr3_ck_n
    .ddr3_ck_p                      ( ddr3_ck_p),            // output [0:0]	ddr3_ck_p
    .ddr3_cke                       ( ddr3_cke),             // output [0:0]	ddr3_cke
    .ddr3_ras_n                     ( ddr3_ras_n),           // output			ddr3_ras_n
    .ddr3_reset_n                   ( ddr3_reset_n),         // output			ddr3_reset_n
    .ddr3_we_n                      ( ddr3_we_n),            // output			ddr3_we_n
    .ddr3_dq                        ( ddr3_dq),              // inout [31:0]	ddr3_dq
    .ddr3_dqs_n                     ( ddr3_dqs_n),           // inout [3:0]		ddr3_dqs_n
    .ddr3_dqs_p                     ( ddr3_dqs_p),           // inout [3:0]		ddr3_dqs_p
    .init_calib_complete            ( init_calib_complete),  // output			init_calib_complete
	.ddr3_cs_n                      ( ddr3_cs_n),            // output [0:0]	ddr3_cs_n
    .ddr3_dm                        ( ddr3_dm),              // output [3:0]	ddr3_dm
    .ddr3_odt                       ( ddr3_odt),             // output [0:0]	ddr3_odt
    // Application interface ports 
    .app_addr                       ( app_addr           ),  // input [27:0]	app_addr
    .app_cmd                        ( app_cmd            ),  // input [2:0]		app_cmd
    .app_en                         ( app_en             ),  // input			app_en            
    .app_wdf_data                   ( app_wdf_data       ),  // input [255:0]	app_wdf_data      
    .app_wdf_end                    ( app_wdf_end        ),  // input			app_wdf_end       
    .app_wdf_wren                   ( app_wdf_wren       ),  // input			app_wdf_wren      
    .app_rd_data                    ( app_rd_data        ),  // output [255:0]	app_rd_data
    .app_rd_data_end                ( app_rd_data_end    ),  // output			app_rd_data_end   
    .app_rd_data_valid              ( app_rd_data_valid  ),  // output			app_rd_data_valid
    .app_rdy                        ( app_rdy            ),  // output			app_rdy
    .app_wdf_rdy                    ( app_wdf_rdy        ),  // output			app_wdf_rdy
    
    .app_sr_req                     ( app_sr_req         ),  // input			app_sr_req
    .app_ref_req                    ( app_ref_req        ),  // input			app_ref_req
    .app_zq_req                     ( app_zq_req         ),  // input			app_zq_req
    .app_sr_active                  ( app_sr_active      ),  // output			app_sr_active     
    .app_ref_ack                    ( app_ref_ack        ),  // output			app_ref_ack       
    .app_zq_ack                     ( app_zq_ack         ),  // output			app_zq_ack        
    //Ui 
    .ui_clk                         ( ui_clk             ),  // output			ui_clk
    .ui_clk_sync_rst                (                    ),  // output			ui_clk_sync_rst
    .app_wdf_mask                   ( app_wdf_mask       ),  // input [31:0]	app_wdf_mask      
    // System Clock Ports
    .sys_clk_i                      ( O_CLK_200MHZ      ),
    .sys_rst                        ( PLL0_LOCK         ) // input sys_rst
    );
endmodule