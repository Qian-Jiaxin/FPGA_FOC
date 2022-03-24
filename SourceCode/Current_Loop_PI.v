module Current_Loop_PI(
    iClk,
    iRst_n,
    iTarget_d,   //速度环输入或者位置环输入id
    iCurrent_d,  //ADC采样得到
    iKp_d,
    iKi_d,
    iTarget_q,   //速度环输入或者位置环输入iq
    iCurrent_q,  //ADC采样得到
    iKp_q,
    iKi_q,
    iCal_en,
    oCal_d,      //输出ud
    oCal_q,      //输出uq
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

    localparam U_MAX = $signed(16'd32767);
    localparam I_MAX = $signed(12'd2047);

    localparam S0 = 3'd0;
    localparam S1 = 3'd1;
    localparam S2 = 3'd2;
    localparam S3 = 3'd3;
    localparam S4 = 3'd4;
    localparam S5 = 3'd5;

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
                    nstate <= S5; 
                end
                S5: begin
                    nstate <= S0;
                    oCal_done <= 1'b1; 
                end
                default: nstate <= S0;
            endcase 
        end
    end

    reg signed [12:0] nerror_d;
    reg signed [12:0] nerror_I_d;
    reg signed [17:0] ncal_d;
    reg [27:0] ntemp_P_d,ntemp_I_d;
    reg nflag_clamping_d;
    reg nflag_saturation_d;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nerror_d <= 13'd0;
            nerror_I_d <= 13'd0;
            ntemp_P_d <= 28'd0;
            ntemp_I_d <= 28'd0;
            ncal_d <= 18'd0;
            nflag_clamping_d <= 1'b0;
            nflag_saturation_d <= 1'b0;
            oCal_d <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_d <= iTarget_d - iCurrent_d;
                    end
                    else begin
                        nerror_d <= nerror_d; 
                    end
                end
                S1: begin
                    if(nerror_d > I_MAX) begin
                        nerror_d <= I_MAX;
                    end
                    else if(nerror_d < -I_MAX) begin
                        nerror_d <= -I_MAX;
                    end 
                    else begin
                        nerror_d <= nerror_d; 
                    end
                    nflag_clamping_d <= (nerror_d[12] == oCal_d[15]) & nflag_saturation_d;
                end
                S2: begin
                    if(!nflag_clamping_d) begin
                        nerror_I_d <= nerror_I_d + nerror_d;
                    end
                    else begin
                        nerror_I_d <= nerror_I_d;
                    end
                end
                S3: begin
                    ntemp_P_d <= (iKp_d * nerror_d)>>>12;
                    ntemp_I_d <= (iKi_d * nerror_I_d)>>>12;
                end
                S4: begin
                    ncal_d = $signed(ntemp_P_d[15:0]) + $signed(ntemp_I_d[15:0]);
                end
                S5: begin
                    if(ncal_d > U_MAX) begin
                        nflag_saturation_d <= 1'b1;
                        oCal_d <= U_MAX;
                    end 
                    else if(ncal_d < -U_MAX)begin
                        nflag_saturation_d <= 1'b1;
                        oCal_d <= -U_MAX;
                    end
                    else begin
                        nflag_saturation_d <= 1'b0;
                        oCal_d <= {ncal_d[17],ncal_d[14:0]};
                    end
                end
                default: ;
            endcase
        end
    end

    reg signed [12:0] nerror_q;
    reg signed [12:0] nerror_I_q;
    reg signed [17:0] ncal_q;
    reg [27:0] ntemp_P_q,ntemp_I_q;
    reg nflag_clamping_q;
    reg nflag_saturation_q;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nerror_q <= 13'd0;
            nerror_I_q <= 13'd0;
            ntemp_P_q <= 28'd0;
            ntemp_I_q <= 28'd0;
            ncal_q <= 18'd0;
            nflag_clamping_q <= 1'b0;
            nflag_saturation_q <= 1'b0;
            oCal_q <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_q <= iTarget_q - iCurrent_q;
                    end
                    else begin
                        nerror_q <= nerror_q; 
                    end
                end
                S1: begin
                    if(nerror_q > I_MAX) begin
                        nerror_q <= I_MAX;
                    end
                    else if(nerror_q < -I_MAX) begin
                        nerror_q <= -I_MAX;
                    end 
                    else begin
                        nerror_q <= nerror_q; 
                    end
                    nflag_clamping_q <= (nerror_q[12] == oCal_q[15]) & nflag_saturation_q;
                end
                S2: begin
                    if(!nflag_clamping_q) begin
                        nerror_I_q <= nerror_I_q + nerror_q;
                    end
                    else begin
                        nerror_I_q <= nerror_I_q;
                    end
                end
                S3: begin
                    ntemp_P_q <= (iKp_q * nerror_q)>>>12;
                    ntemp_I_q <= (iKi_q * nerror_I_q)>>>12;
                end
                S4: begin
                    ncal_q = $signed(ntemp_P_q[15:0]) + $signed(ntemp_I_q[15:0]);
                end
                S5: begin
                    if(ncal_q > U_MAX) begin
                        nflag_saturation_q <= 1'b1;
                        oCal_q <= U_MAX;
                    end 
                    else if(ncal_q < -U_MAX)begin
                        nflag_saturation_q <= 1'b1;
                        oCal_q <= -U_MAX;
                    end
                    else begin
                        nflag_saturation_q <= 1'b0;
                        oCal_q <= {ncal_q[17],ncal_q[14:0]};
                    end
                end
                default: ;
            endcase
        end
    end

endmodule