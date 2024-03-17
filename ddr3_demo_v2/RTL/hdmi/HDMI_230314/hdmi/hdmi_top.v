module hdmi_top #(
    parameter  H_ActiveSize = 1280,          
    parameter  H_SyncStart  = 1280+48,       
    parameter  H_SyncEnd    = 1280+48+112,    
    parameter  H_FrameSize  = 1280+48+112+248,    
    parameter  V_ActiveSize = 1024,          
    parameter  V_SyncStart  = 1024+1,        
    parameter  V_SyncEnd    = 1024+1+3,      
    parameter  V_FrameSize  = 1024+1+3+38    
)( 
    input   wire    Pixl_CLK                    ,
    input   wire    Pixl_5xCLK                  ,
    input   wire    Rst_n                       ,
    //RD_hdmi_data
    input   wire    [15:0]  I_Pixel_Data        ,
    input   wire            I_PLL_LOCK          ,
    //Tmds
    output  wire            HDMI_CLK_P          ,
    output  wire            HDMI_CLK_N          ,
    output  wire    [2:0]   HDMI_TX_P           ,
    output  wire    [2:0]   HDMI_TX_N           ,
    //Pre
    output  wire            O_Pre_De            ,
    output  wire            O_Pre_Vsync         ,
    output  wire            O_Pre_Hsync         ,
    //Post
    input   wire            I_Post_De           ,
    input   wire            I_Post_Vsync        ,
    input   wire            I_Post_Hsync         
);
    //VGA Ports
            wire            Pre_H_Sync          ;
            wire            Pre_V_Sync          ;
    //HDMI Encode   
            wire    [9:0]   Encode_Red_10Bit    ;
            wire    [9:0]   Encode_Green_10Bit  ;
            wire    [9:0]   Encode_Blue_10Bit   ;
            wire    [9:0]   Encode_CLK_10Bit    ;
        //serializer Done   
            wire            Pre_Red             ;
            wire            Pre_Green           ;
            wire            Pre_Blue            ;
            wire            Pre_Clk             ;
        //Rst   
            wire            Rst_Posedge         ;
            wire            Rst_Negedge         ;
            wire            Pre_VGA_De          ;
        //bayer2rgb
            //0
            wire            P_0_V_Sync          ;
            wire            P_0_H_Sync          ;
            wire            P_0_VGA_De          ;
            wire    [7:0]   P_0_R               ;
            wire    [7:0]   P_0_G               ;
            wire    [7:0]   P_0_B               ;
            //1
            wire            P_1_V_Sync          ;
            wire            P_1_H_Sync          ;
            wire            P_1_VGA_De          ;
            wire    [7:0]   P_1_R               ;
            wire    [7:0]   P_1_G               ;
            wire    [7:0]   P_1_B               ;

    
    assign  Encode_CLK_10Bit = 10'b11111_00000  ;
    assign  Rst_Negedge      = (!Rst_Posedge)   ;

    // Pre
    assign  O_Pre_Vsync      = Pre_V_Sync       ;
    assign  O_Pre_Hsync      = Pre_H_Sync       ;
    assign  O_Pre_De         = Pre_VGA_De       ;


asyn_rst_syn reset_syn(
    .reset_n    ( Rst_n  && I_PLL_LOCK  ),
    .clk        ( Pixl_CLK              ),
    .syn_reset  ( Rst_Posedge           )
    );

VTC_TIMEING #(
    .H_ActiveSize       ( H_ActiveSize  ), //H_data
    .H_SyncStart        ( H_SyncStart   ), //H_data + H_Frontporch
    .H_SyncEnd          ( H_SyncEnd     ), //H_data + H_Frontporch + H_Sync
    .H_FrameSize        ( H_FrameSize   ), //H_data + H_Frontporch + H_Sync + H_backporch

    .V_ActiveSize       ( V_ActiveSize  ),  //V_data
    .V_SyncStart        ( V_SyncStart   ),  //V_data + V_Frontporch
    .V_SyncEnd          ( V_SyncEnd     ),  //V_data + V_Frontporch + V_Sync
    .V_FrameSize        ( V_FrameSize   )   //V_data + V_Frontporch + V_Sync + V_backporch    
    )
    VTC_TIMEING
    (
    .I_vtc_clk          ( Pixl_CLK      ),
    .I_vtc_rstn         ( Rst_Negedge   ),
    .O_vtc_vs           ( Pre_V_Sync    ),
    .O_vtc_hs           ( Pre_H_Sync    ),
    .O_vtc_de_valid     ( Pre_VGA_De    )
    );

    // uitpg Gen_Test_IMG	
    // (
    // .tpg_clk_i ( Pixl_CLK       ),   
    // .tpg_rstn_i( Rst_Negedge    ),   
    // .tpg_vs_i  ( Pre_V_Sync     ),   
    // .tpg_hs_i  ( Pre_H_Sync     ),   
    // .tpg_de_i  ( Pre_VGA_De     ),   

    // .tpg_vs_o  ( P_0_V_Sync     ),   
    // .tpg_hs_o  ( P_0_H_Sync     ),   
    // .tpg_de_o  ( P_0_VGA_De     ),   
    // .tpg_data_o({P_0_R,P_0_G,P_0_B}) 
    // );
    
    // Post
    assign P_0_R = {I_Pixel_Data[15:11],3'b0};
    assign P_0_G = {I_Pixel_Data[10: 5],2'b0};
    assign P_0_B = {I_Pixel_Data[ 4: 0],3'b0};
    assign P_0_V_Sync = I_Post_Vsync  ;
    assign P_0_H_Sync = I_Post_Hsync  ;
    assign P_0_VGA_De = I_Post_De     ;

//----------------------------------Gamma_06_Period----------------------------------------//
    Gamma_06_Period  Red_Gamma_06 (
    .Pre_Data                ( P_0_R       ),
    .Pre_clk                 ( Pixl_CLK    ),
    .Pre_Rst_n               ( Rst_Negedge ),

    .Pre_DE                  ( P_0_VGA_De   ),
    .Pre_Vsync               ( P_0_V_Sync   ),
    .Pre_Hsync               ( P_0_H_Sync   ),

    .Post_DE                 ( P_1_VGA_De  ),
    .Post_Vsync              ( P_1_V_Sync  ),
    .Post_Hsync              ( P_1_H_Sync  ),
    .Post_Data               ( P_1_R       )
);

    Gamma_06_Period  Gre_Gamma_06 (
    .Pre_Data                ( P_0_G       ),
    .Pre_clk                 ( Pixl_CLK    ),
    .Pre_Rst_n               ( Rst_Negedge ),

    .Pre_DE                  ( P_0_VGA_De  ),
    .Pre_Vsync               ( P_0_V_Sync  ),
    .Pre_Hsync               ( P_0_H_Sync  ),

    .Post_DE                 (             ),
    .Post_Vsync              (             ),
    .Post_Hsync              (             ),
    .Post_Data               ( P_1_G       )
);

    Gamma_06_Period  Blu_Gamma_06 (
    .Pre_Data                ( P_0_B       ),
    .Pre_clk                 ( Pixl_CLK    ),
    .Pre_Rst_n               ( Rst_Negedge ),

    .Pre_DE                  ( P_0_VGA_De   ),
    .Pre_Vsync               ( P_0_V_Sync   ),
    .Pre_Hsync               ( P_0_H_Sync   ),

    .Post_DE                 (             ),
    .Post_Vsync              (             ),
    .Post_Hsync              (             ),
    .Post_Data               ( P_1_B       )
);

//----------------------------------Gamma_06_Period----------------------------------------//
//Encode VGA_Pixl_2_Tmds
encode Inst0_Blue_EnCode (
	.clkin		( Pixl_CLK          ),
	.rstin		( Rst_Posedge       ),
	.din		( P_1_B             ),
	.c0			( P_1_V_Sync        ),
	.c1			( P_1_H_Sync        ),
	.de			( P_1_VGA_De        ),
	.dout		( Encode_Blue_10Bit )) ;
encode Inst0_Green_EnCode (
	.clkin		( Pixl_CLK          ),
	.rstin		( Rst_Posedge       ),
	.din	    ( P_1_G             ),
	.c0		    ( 1'b0              ),
	.c1		    ( 1'b0              ),
	.de			( P_1_VGA_De        ),
	.dout	    ( Encode_Green_10Bit)) ;
	
encode Inst0_Red_EnCode (
	.clkin		( Pixl_CLK          ),
	.rstin		( Rst_Posedge       ),
	.din		( P_1_R             ),
	.c0			( 1'b0              ),
	.c1			( 1'b0              ),
	.de			( P_1_VGA_De        ),
	.dout		( Encode_Red_10Bit  )) ;
//serializer == SelectIO 5:1
serializer_10_to_1 serializer_Blue(
    .reset              ( Rst_Posedge             ), 
    .paralell_clk       ( Pixl_CLK                ), 
    .serial_clk_5x      ( Pixl_5xCLK              ), 
    .paralell_data      ( Encode_Blue_10Bit       ), 

    .serial_data_out    ( Pre_Blue                )  
    );    
    
serializer_10_to_1 serializer_Green(
    .reset              ( Rst_Posedge             ), 
    .paralell_clk       ( Pixl_CLK                ), 
    .serial_clk_5x      ( Pixl_5xCLK              ), 
    .paralell_data      ( Encode_Green_10Bit      ),

    .serial_data_out    ( Pre_Green               )
    );
    
serializer_10_to_1 serializer_Red(
    .reset              ( Rst_Posedge             ), 
    .paralell_clk       ( Pixl_CLK                ), 
    .serial_clk_5x      ( Pixl_5xCLK              ), 
    .paralell_data      ( Encode_Red_10Bit        ),

    .serial_data_out    ( Pre_Red                 )
    );
//CLK
serializer_10_to_1 serializer_Clk(
    .reset              ( Rst_Posedge             ), 
    .paralell_clk       ( Pixl_CLK                ), 
    .serial_clk_5x      ( Pixl_5xCLK              ), 
    .paralell_data      ( Encode_CLK_10Bit        ),

    .serial_data_out    ( Pre_Clk                 )
    );
//OBUFDS
OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    
) TMDS0 (
    .I                  ( Pre_Blue       ),
    .O                  ( HDMI_TX_P[0] ),
    .OB                 ( HDMI_TX_N[0] ) 
);

OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    
) TMDS1 (
    .I                  ( Pre_Green    ),
    .O                  ( HDMI_TX_P[1]),
    .OB                 ( HDMI_TX_N[1] ) 
);

OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    
) TMDS2 (
    .I                  ( Pre_Red        ), 
    .O                  ( HDMI_TX_P[2] ), 
    .OB                 ( HDMI_TX_N[2] )  
);

OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    
) TMDS3 (
    .I                  ( Pre_Clk    ), 
    .O                  ( HDMI_CLK_P ),
    .OB                 ( HDMI_CLK_N ) 
);
endmodule