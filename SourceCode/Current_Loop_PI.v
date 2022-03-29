module Current_Loop_PI(
    iClk,
    iRst_n,
    iTarget_d,
    iCurrent_d,
    iKp_d,
    iKi_d,
    iTarget_q,
    iCurrent_q,
    iKp_q,
    iKi_q,
    iCal_en,
    oCal_d,
    oCal_q,
    oCal_done  
);
    input wire iClk;
    input wire iRst_n;
    input wire signed [11:0] iTarget_d,iCurrent_d;
    input wire signed [11:0] iTarget_q,iCurrent_q;
    input wire signed [15:0] iKp_d,iKi_d;
    input wire signed [15:0] iKp_q,iKi_q;
    input wire iCal_en;
    output reg signed [15:0] oCal_d,oCal_q;
    output reg oCal_done;

    localparam U_MAX = 16'sd30000;
    localparam I_MAX = 12'sd2047;

    localparam S0 = 3'd0;
    localparam S1 = 3'd1;
    localparam S2 = 3'd2;
    localparam S3 = 3'd3;
    localparam S4 = 3'd4;

    reg ncal_en_pre_state;
    reg [2:0] nstate;
    
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncal_en_pre_state <= 1'b0;
        end 
        else begin
            ncal_en_pre_state <= iCal_en;
        end
    end
    
    /***********************状态机管理**********************/

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nstate <= S0;
            oCal_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nstate <= S1;
                    end
                    else begin
                        nstate <=nstate;
                        oCal_done <= 1'b0;
                    end
                end 
                S1: begin
                    nstate <= S2; 
                end
                S2: begin
                    nstate <= S3; 
                end
                S3:begin
                    nstate <= S4; 
                end
                S4: begin
                    nstate <= S0; 
                    oCal_done <= 1'b1; 
                end
                default: nstate <= S0;
            endcase 
        end
    end
    /******************************************************/

    /**********************Id->Ud处理**********************/

    reg signed [12:0] nerror_d_temp;
    reg signed [11:0] nerror_d;
    reg signed [27:0] ncal_d;
    reg signed [27:0] nlasttime_I_d;
    reg signed [27:0] ncal_P_d,ncal_I_d;
    reg nflag_clamping_d;
    reg nflag_saturation_d;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nerror_d_temp <= 13'd0;
            nerror_d <= 12'd0;
            ncal_P_d <= 28'd0;
            ncal_I_d <= 28'd0;
            nlasttime_I_d <= 28'd0;
            ncal_d <= 28'd0;
            nflag_clamping_d <= 1'b0;
            nflag_saturation_d <= 1'b0;
            oCal_d <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_d_temp <= iTarget_d - iCurrent_d;
                    end
                end
                S1: begin
                    if(nerror_d_temp[12:11] == 2'b01) begin
                        nerror_d <= I_MAX;
                    end
                    else if(nerror_d_temp[12:11] == 2'b10) begin
                        nerror_d <= -I_MAX;
                    end 
                    else begin
                        nerror_d <= nerror_d_temp[11:0]; 
                    end
                end
                S2: begin
                    ncal_P_d <= (iKp_d * nerror_d);
                    ncal_I_d <= (iKi_d * nerror_d);
                    nflag_clamping_d <= !((nerror_d[11] ^~ ncal_d[27]) && nflag_saturation_d);
                end
                S3: begin
                    nlasttime_I_d <= nlasttime_I_d + (ncal_I_d & {28{nflag_clamping_d}});
                    ncal_d <= ncal_P_d + nlasttime_I_d + (ncal_I_d & {28{nflag_clamping_d}});
                end
                S4: begin
                    if($signed(ncal_d[27:9]) >= U_MAX) begin
                        nflag_saturation_d <= 1'b1;
                        oCal_d <= U_MAX;
                    end
                    else if($signed(ncal_d[27:9]) <= -U_MAX)begin
                        nflag_saturation_d <= 1'b1;
                        oCal_d <= -U_MAX;
                    end
                    else begin
                        nflag_saturation_d <= 1'b0;
                        oCal_d <= ncal_d[24:9];
                    end
                end
                default: ;
            endcase
        end
    end

    /******************************************************/

    /**********************Iq->Ud处理**********************/

    reg signed [12:0] nerror_q_temp;
    reg signed [11:0] nerror_q;
    reg signed [27:0] ncal_q;
    reg signed [27:0] nlasttime_I_q;
    reg signed [27:0] ncal_P_q,ncal_I_q;
    reg nflag_clamping_q;
    reg nflag_saturation_q;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nerror_q_temp <= 13'd0;
            nerror_q <= 12'd0;
            ncal_P_q <= 28'd0;
            ncal_I_q <= 28'd0;
            nlasttime_I_q <= 28'd0;
            ncal_q <= 28'd0;
            nflag_clamping_q <= 1'b0;
            nflag_saturation_q <= 1'b0;
            oCal_q <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_q_temp <= iTarget_q - iCurrent_q;
                    end
                end
                S1: begin
                    if(nerror_q_temp[12:11] == 2'b01) begin
                        nerror_q <= I_MAX;
                    end
                    else if(nerror_q_temp[12:11] == 2'b10) begin
                        nerror_q <= -I_MAX;
                    end 
                    else begin
                        nerror_q <= nerror_q_temp[11:0]; 
                    end
                end
                S2: begin
                    ncal_P_q <= (iKp_q * nerror_q);
                    ncal_I_q <= (iKi_q * nerror_q);
                    nflag_clamping_q <= !((nerror_q[11] ^~ ncal_q[27]) && nflag_saturation_q);
                end
                S3: begin
                    nlasttime_I_q <= nlasttime_I_q + (ncal_I_q & {28{nflag_clamping_q}});
                    ncal_q <= ncal_P_q + nlasttime_I_q + (ncal_I_q & {28{nflag_clamping_q}});
                end
                S4: begin
                    if($signed(ncal_q[27:9]) >= U_MAX) begin
                        nflag_saturation_q <= 1'b1;
                        oCal_q <= U_MAX;
                    end
                    else if($signed(ncal_q[27:9]) <= -U_MAX)begin
                        nflag_saturation_q <= 1'b1;
                        oCal_q <= -U_MAX;
                    end
                    else begin
                        nflag_saturation_q <= 1'b0;
                        oCal_q <= ncal_q[24:9];
                    end
                end
                default: ;
            endcase
        end
    end

    /******************************************************/

endmodule