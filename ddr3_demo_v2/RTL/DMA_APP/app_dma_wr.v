module app_dma_wr (
    //Ui Port
    input   wire                I_sys_clk         ,
    input   wire                I_Rst_n           ,
    //ex control signs
    input   wire                ex_wr_start       , // start   
    input   wire    [27:0]      ex_wr_addr        , // addr     
    input   wire    [2:0]       ex_wr_cmd         , // cmd
    input   wire    [7:0]       ex_wr_burst_len   , // burst_len
    input   wire    [255:0]     ex_wr_data        , // data    
    input   wire    [31:0]      ex_wr_wdf_mask    ,
    output  wire                ex_wr_burst_start ,
    output  wire                ex_wr_burst_end   ,
    output  wire                ex_wr_rd_en       ,
    //DDR3 Port
    output  wire    [27:0]		app_addr          ,              
    output  wire    [2:0]		app_cmd           ,          
    output  wire			    app_en            ,                      
    output  wire    [255:0]	    app_wdf_data      ,                      
    output  wire			    app_wdf_end       ,                      
    output  wire			    app_wdf_wren      ,                                          
    input	wire		        app_rdy           ,          
    input	wire		        app_wdf_rdy       ,   
    output  wire    [31:0]      app_wdf_mask                       
);                   
//inter Port--------------------------------------------------------------------//
    //Office Port
            reg     [27:0]		itr_app_addr      ; 
            reg     [2:0]		itr_app_cmd       ; 
            reg 			    itr_app_en        ; 
            reg     [31:0]      itr_wdf_mask      ;
            reg     [7:0]       itr_burst_len     ;
        
            reg 			    itr_app_wdf_end   ; 
            reg 			    itr_app_wdf_wren  ; 

            reg                 wr_start_cycle    ;
            reg     [7:0]       wr_burst_cnt      ;
            reg     [7:0]       wr_cmd_cnt        ;
            reg                 itr_wr_burst_end  ;
    //reg ex signs
            
    //cmd
    assign  app_addr     = itr_app_addr     ;
    assign  app_cmd      = itr_app_cmd      ;
    assign  app_en       = itr_app_en       ;

    //wdf
    assign  app_wdf_end  = itr_app_wdf_end  ;
    assign  app_wdf_wren = itr_app_wdf_wren ;

    assign  app_wdf_mask = itr_wdf_mask   ;

    assign  ex_wr_burst_start = (ex_wr_start == 1'b1 && wr_start_cycle == 1'b0);
    assign  ex_wr_burst_end = itr_wr_burst_end;

    assign  app_wdf_data = ex_wr_data     ;
    assign  ex_wr_rd_en = ((app_wdf_wren == 1'b1) && (app_wdf_rdy == 1'b1));
//wr----------------------------------------------------------------------------//

    //wr_start_cycle
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            wr_start_cycle <= 1'b0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1 && wr_cmd_cnt == itr_burst_len - 1'b1) begin
            wr_start_cycle <= 1'b0;
        end else if(ex_wr_start == 1'b1 && wr_start_cycle == 1'b0) begin
            wr_start_cycle <= 1'b1;
        end
    end

    //wr_burst_end
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_wr_burst_end <= 1'b0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1 && wr_cmd_cnt == itr_burst_len - 1'b1) begin
            itr_wr_burst_end <= 1'b1;
        end else begin
            itr_wr_burst_end <= 1'b0;
        end
    end

    //wr_burst_cnt
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            wr_burst_cnt <= 'd0;
        end else if(app_wdf_wren == 1'b1 && app_wdf_rdy == 1'b1 && wr_burst_cnt == itr_burst_len - 1'b1) begin
            wr_burst_cnt <= 'd0;
        end else if(app_wdf_wren == 1'b1 && app_wdf_rdy == 1'b1) begin
            wr_burst_cnt <= wr_burst_cnt + 1'b1;
        end else begin
            wr_burst_cnt <= wr_burst_cnt;
        end
    end

    //wdf_wren
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_app_wdf_wren <= 1'b0;
        end else if((app_wdf_wren == 1'b1) && (app_wdf_rdy == 1'b1) && (wr_burst_cnt == itr_burst_len - 1'b1))begin
            itr_app_wdf_wren <= 1'b0;
        end else if(ex_wr_start == 1'b1 && wr_start_cycle == 1'b0) begin
            itr_app_wdf_wren <= 1'b1;
        end else begin
            itr_app_wdf_wren <= itr_app_wdf_wren;
        end
    end

    //app_wdf_end
    always @(*) begin
        if(app_wdf_wren == 1'b1 && app_wdf_rdy == 1'b1) begin
            itr_app_wdf_end <= 1'b1;
        end else begin
            itr_app_wdf_end <= 1'b0;
        end
    end 

    // wr_cmd_cnt
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            wr_cmd_cnt <= 'd0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1 && wr_cmd_cnt == itr_burst_len - 1'b1)begin
            wr_cmd_cnt <= 'd0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1) begin
            wr_cmd_cnt <= wr_cmd_cnt + 1'b1;
        end else begin
            wr_cmd_cnt <= wr_cmd_cnt;
        end
    end

    //app_en
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_app_en <= 1'b0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1 && wr_cmd_cnt == itr_burst_len - 1'b1) begin
            itr_app_en <= 1'b0; 
        end else if(app_wdf_wren == 1'b1 && app_wdf_rdy == 1'b1) begin
            itr_app_en <= 1'b1;
        end else begin
            itr_app_en <= itr_app_en;
        end
    end

    //app_addr
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_app_addr <= 'd0;
        end else if(ex_wr_burst_end == 1'b1) begin
            itr_app_addr <= 'd0;
        end else if(ex_wr_start == 1'b1 && wr_start_cycle == 1'b0) begin
            itr_app_addr <= ex_wr_addr;
        end else if(app_en == 1'b1 && app_rdy == 1'b1) begin
            itr_app_addr <= itr_app_addr + 'd8;
        end else begin
            itr_app_addr <= itr_app_addr;
        end
    end
    
    // cmd & burst length
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_app_cmd   <= 'd0;
            itr_burst_len <= 'd0;
            itr_wdf_mask  <= 'd0;
        end else if(ex_wr_start == 1'b1 && wr_start_cycle == 1'b0) begin
            itr_app_cmd   <= ex_wr_cmd ;
            itr_burst_len <= ex_wr_burst_len;
            itr_wdf_mask  <= ex_wr_wdf_mask;
        end else begin
            itr_app_cmd   <= itr_app_cmd;
            itr_burst_len <= itr_burst_len;
            itr_wdf_mask  <= itr_wdf_mask;
        end
    end

endmodule
