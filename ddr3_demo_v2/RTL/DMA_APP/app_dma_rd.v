module app_dma_rd (
    //Ui Port
    input   wire                I_sys_clk         ,
    input   wire                I_Rst_n           ,
    //ex control signs
    input   wire                ex_rd_start       , // start   
    input   wire    [27:0]      ex_rd_addr        , // addr     
    input   wire    [2:0]       ex_rd_cmd         , // cmd
    input   wire    [7:0]       ex_rd_burst_len   , // burst_len
    output  wire    [255:0]     ex_rd_data        , // data    
    output  wire                ex_rd_wr_en       , // fifo wr en(rd_data_vaild)

    output  wire                ex_rd_burst_start ,
    output  wire                ex_rd_burst_end   ,
    //DDR3 Port
    output  wire    [27:0]		app_addr          ,              
    output  wire    [2:0]		app_cmd           ,          
    output  wire			    app_en            ,                      
    input   wire   [255:0]	    app_rd_data       ,  
    input   wire   			    app_rd_data_end   ,          
    input   wire   			    app_rd_data_valid ,          
    input	wire		        app_rdy                                    
);  

//inter Port--------------------------------------------------------------------//
    //Office Port
            reg     [27:0]		itr_app_addr      ; 
            reg     [2:0]		itr_app_cmd       ; 
            reg 			    itr_app_en        ; 
            reg     [7:0]       itr_burst_len     ;

            reg     [7:0]       rd_burst_cnt      ;
            reg     [7:0]       rd_cmd_cnt        ;
            reg                 rd_start_cycle    ;
            reg                 itr_rd_burst_end  ;

    //cmd
    assign  app_addr     = itr_app_addr     ;
    assign  app_cmd      = itr_app_cmd      ;
    assign  app_en       = itr_app_en       ;

    assign  ex_rd_burst_start = (ex_rd_start == 1'b1 && rd_start_cycle == 1'b0) ;
    assign  ex_rd_burst_end   = itr_rd_burst_end;

    assign  ex_rd_data   = app_rd_data      ;
    assign  ex_rd_wr_en  = (app_rd_data_valid == 1'b1 && app_rd_data_end == 1'b1);
//rd----------------------------------------------------------------------------//

    //rd_start_cycle
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            rd_start_cycle <= 1'b0;
        end else if(app_rd_data_valid == 1'b1 && app_rd_data_end == 1'b1 && rd_burst_cnt == itr_burst_len - 1'b1) begin
            rd_start_cycle <= 1'b0;
        end else if(ex_rd_start == 1'b1 && rd_start_cycle == 1'b0) begin
            rd_start_cycle <= 1'b1;
        end
    end

    //rd_burst_end
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_rd_burst_end <= 1'b0;
        end else if(app_rd_data_valid == 1'b1 && app_rd_data_end == 1'b1 && rd_burst_cnt == itr_burst_len - 1'b1) begin
            itr_rd_burst_end <= 1'b1;
        end else begin
            itr_rd_burst_end <= 1'b0;
        end
    end

    //rd_burst_cnt
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            rd_burst_cnt <= 'd0;
        end else if(app_rd_data_valid == 1'b1 && app_rd_data_end == 1'b1 && rd_burst_cnt == itr_burst_len - 1'b1) begin
            rd_burst_cnt <= 'd0;
        end else if(app_rd_data_valid == 1'b1 && app_rd_data_end == 1'b1) begin
            rd_burst_cnt <= rd_burst_cnt + 1'b1;
        end else begin
            rd_burst_cnt <= rd_burst_cnt;
        end
    end

    //app_en
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_app_en <= 1'b0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1 && rd_cmd_cnt == itr_burst_len - 1'b1) begin
            itr_app_en <= 1'b0; 
        end else if(ex_rd_start == 1'b1 && rd_start_cycle == 1'b0) begin
            itr_app_en <= 1'b1;
        end else begin
            itr_app_en <= itr_app_en;
        end
    end

    // rd_cmd_cnt
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            rd_cmd_cnt <= 'd0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1 && rd_cmd_cnt == itr_burst_len - 1'b1)begin
            rd_cmd_cnt <= 'd0;
        end else if(app_en == 1'b1 && app_rdy == 1'b1) begin
            rd_cmd_cnt <= rd_cmd_cnt + 1'b1;
        end else begin
            rd_cmd_cnt <= rd_cmd_cnt;
        end
    end

    //app_addr
    always @(posedge I_sys_clk) begin
        if(I_Rst_n == 1'b0) begin
            itr_app_addr <= 'd0;
        end else if(ex_rd_burst_end == 1'b1) begin
            itr_app_addr <= 'd0;
        end else if(ex_rd_start == 1'b1 && rd_start_cycle == 1'b0) begin
            itr_app_addr <= ex_rd_addr;
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
        end else if(ex_rd_start == 1'b1 && rd_start_cycle == 1'b0) begin
            itr_app_cmd   <= ex_rd_cmd ;
            itr_burst_len <= ex_rd_burst_len;
        end else begin
            itr_app_cmd   <= itr_app_cmd;
            itr_burst_len <= itr_burst_len;
        end
    end

endmodule