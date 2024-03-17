module  app_arbit (
    input   wire            I_clk                       ,
    input   wire            I_Rst_n                     ,
    //Port
    //ch0
    input   wire            I_ch0_req                   ,
    input   wire            I_ch0_start                 ,
    input   wire            I_ch0_end                   ,
    output  wire            O_ch0_vaild                 ,
    //ch1
    input   wire            I_ch1_req                   ,
    input   wire            I_ch1_start                 ,
    input   wire            I_ch1_end                   ,
    output  wire            O_ch1_vaild                 
);

    //-----------------------------------------------------------------//
        localparam  state_idle  = 6'b0000_01;
        localparam  state_aribe = 6'b0000_10;

        localparam  state_ch0_0 = 6'b0001_00;
        localparam  state_ch0_1 = 6'b0010_00;

        localparam  state_ch1_0 = 6'b0100_00;
        localparam  state_ch1_1 = 6'b1000_00;

    //-----------------------------------------------------------------//
        //req
            //step.0
            wire    [1:0]   i_req_Concat                ;
            reg     [3:0]   double_req_Concat            ;
            //step.1
            reg     [3:0]   S1_req_Concat               ;
            //step.2
            reg     [3:0]   S2_req_Concat               ;
            //step.3
            wire    [1:0]   S3_req_Concat               ;
        //aribe
            wire            aribe_start                 ;
            wire            aribe_step                  ;
            reg             aribe_cycle                 ;
            reg     [1:0]   aribe_value                 ;
        //step
            reg     [3:0]   step                        ;
        //state
            reg     [5:0]   state                       ;
            wire            aribe_ch0_end               ;
            wire            aribe_ch1_end               ;
        //req vaild
            reg             reg_ch0_vaild               ;
            reg             reg_ch1_vaild               ;
        //start
            reg             r1_ch0_start                ;
            reg             r2_ch0_start                ;

            reg             r1_ch1_start                ;
            reg             r2_ch1_start                ;
    //-----------------------------------------------------------------//

    assign  i_req_Concat = {I_ch1_req, I_ch0_req};
    assign  aribe_start  = |i_req_Concat;
    assign  aribe_step   = (aribe_start == 1'b1 && aribe_cycle == 1'b0);

    assign  aribe_ch0_end = (I_ch0_end == 1'b1)&&(state == state_ch0_1);
    assign  aribe_ch1_end = (I_ch1_end == 1'b1)&&(state == state_ch1_1);

    assign O_ch0_vaild  = reg_ch0_vaild;
    assign O_ch1_vaild  = reg_ch1_vaild;

    always @(posedge I_clk) begin
        step[3:0] <= {step[2:0],aribe_step};
    end

    // Pose
    always @(posedge I_clk) begin
        {r2_ch0_start,r1_ch0_start} <= {r1_ch0_start,I_ch0_start};
        {r2_ch1_start,r1_ch1_start} <= {r1_ch1_start,I_ch1_start};
    end

    // aribe_cycle
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            aribe_cycle <= 1'b0;
        end else if(aribe_ch0_end|aribe_ch1_end) begin
            aribe_cycle <= 1'b0;
        end else if(aribe_start == 1'b1 && aribe_cycle == 1'b0 && state == state_idle) begin
            aribe_cycle <= 1'b1;
        end else begin
            aribe_cycle <= aribe_cycle;
        end
    end

    // step.0:reg
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            double_req_Concat <= 'd0; 
        end else if(aribe_start == 1'b1 && aribe_cycle == 1'b0) begin
            double_req_Concat <= {2{i_req_Concat}};
        end else begin
            double_req_Concat <= double_req_Concat;
        end
    end

    // step.1
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            S1_req_Concat <= 'd0;
        end else if(step[0] == 1'b1 && step[1] == 1'b0) begin
            S1_req_Concat <= ~(double_req_Concat - {2'b0,aribe_value});
        end else begin
            S1_req_Concat <= S1_req_Concat;
        end
    end

    // step.2  
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            S2_req_Concat <= 'd0;
        end else if(step[1] == 1'b1 && step[2] == 1'b0) begin
            S2_req_Concat <= (S1_req_Concat)&(double_req_Concat);
        end else begin
            S2_req_Concat <= S2_req_Concat;
        end
    end


    assign S3_req_Concat = ((S2_req_Concat[1:0])|(S2_req_Concat[3:2]));

    // aribe_value
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            aribe_value <= {1'b0,1'b1};
        end else if(aribe_value[1] == 1'b1 && step[0] == 1'b1 && step[1] == 1'b0) begin
            aribe_value <= {1'b0,1'b1};
        end else if(step[0] == 1'b1 && step[1] == 1'b0) begin
            aribe_value <= aribe_value << 1;
        end else begin
            aribe_value <= aribe_value;
        end
    end

    //req
    //ch0
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            reg_ch0_vaild <= 1'b0;
        end else if(state == state_ch0_0 && (r1_ch0_start == 1'b1 && r2_ch0_start == 1'b0)) begin
            reg_ch0_vaild <= 1'b0;
        end else if(state == state_ch0_0 && reg_ch0_vaild == 1'b0) begin
            reg_ch0_vaild <= 1'b1;
        end
    end
    //ch1
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            reg_ch1_vaild <= 1'b0;
        end else if(state == state_ch1_0 && (r1_ch1_start == 1'b1 && r2_ch1_start == 1'b0)) begin
            reg_ch1_vaild <= 1'b0;
        end else if(state == state_ch1_0 && reg_ch1_vaild == 1'b0) begin
            reg_ch1_vaild <= 1'b1;
        end
    end

    //state
    always @(posedge I_clk) begin
        if(I_Rst_n == 1'b0) begin
            state <= state_idle;
        end else begin
            case (state)
                state_idle: begin
                    if(aribe_start == 1'b1 && aribe_cycle == 1'b0) begin
                        state <= state_aribe;
                    end else begin
                        state <= state_idle;
                    end
                end
                state_aribe:begin
                    if(step[2] == 1'b1 && step[3] == 1'b0) begin
                        case (S3_req_Concat)
                            2'b01:begin
                                state <= state_ch0_0;
                            end 
                            2'b10:begin
                                state <= state_ch1_0;
                            end 
                            default: state <= state_aribe;
                        endcase
                    end else begin
                        state <= state_aribe;
                    end
                end
                // state.step.0
                state_ch0_0:begin
                    if((r1_ch0_start == 1'b1 && r2_ch0_start == 1'b0)) begin
                        state <= state_ch0_1;
                    end else begin
                        state <= state_ch0_0;
                    end
                end
                state_ch1_0:begin
                    if((r1_ch1_start == 1'b1 && r2_ch1_start == 1'b0)) begin
                        state <= state_ch1_1;
                    end else begin
                        state <= state_ch1_0;
                    end
                end

                // state.step.1
                state_ch0_1:begin
                    if(I_ch0_end == 1'b1) begin
                        state <= state_idle;
                    end else begin
                        state <= state_ch0_1;
                    end
                end
                state_ch1_1:begin
                    if(I_ch1_end == 1'b1) begin
                        state <= state_idle;
                    end else begin
                        state <= state_ch1_1;
                    end
                end
                default: begin
                    state <= state_idle;
                end
            endcase
        end
    end  
endmodule