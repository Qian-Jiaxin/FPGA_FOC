module Speed_Loop_PI(
    iClk,
    iRst_n,
    iTarget_spd,
    iCurrent_spd,
    iKp_spd,
    iKi_spd,
    iCal_en,
    oCal_Iq,
    oCal_done
);
    input wire iClk;
    input wire iRst_n;
    input wire signed [12:0] iTarget_spd,iCurrent_spd;
    input wire signed [15:0] iKp_spd,iKi_spd;
    input wire iCal_en;
    output reg signed [11:0] oCal_Iq;
    output reg oCal_done;

    localparam SPEED_MAX = 13'sd2621;
    localparam IQ_MAX = 12'sd2000;

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

    reg signed [13:0] nerror_spd_temp;
    reg signed [12:0] nerror_spd;
    reg signed [28:0] ncal_spd;
    reg signed [28:0] nlasttime_I_spd;
    reg signed [28:0] ncal_P_spd,ncal_I_spd;
    reg nflag_clamping_spd;
    reg nflag_saturation_spd;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nerror_spd_temp <= 14'd0;
            nerror_spd <= 13'd0;
            ncal_P_spd <= 29'd0;
            ncal_I_spd <= 29'd0;
            nlasttime_I_spd <= 29'd0;
            ncal_spd <= 29'd0;
            nflag_clamping_spd <= 1'b0;
            nflag_saturation_spd <= 1'b0;
            oCal_Iq <= 12'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_spd_temp <= iTarget_spd - iCurrent_spd;
                    end
                end
                S1: begin
                    if(nerror_spd_temp[13:12] == 2'b01) begin
                        nerror_spd <= SPEED_MAX;
                    end
                    else if(nerror_spd_temp[13:12] == 2'b10) begin
                        nerror_spd <= -SPEED_MAX;
                    end 
                    else begin
                        nerror_spd <= nerror_spd_temp[12:0]; 
                    end
                end
                S2: begin
                    ncal_P_spd <= (iKp_spd * nerror_spd);
                    ncal_I_spd <= (iKi_spd * nerror_spd);
                    nflag_clamping_spd <= !((nerror_spd[12] ^~ ncal_spd[28]) && nflag_saturation_spd);
                end
                S3: begin
                    nlasttime_I_spd <= nlasttime_I_spd + (ncal_I_spd & {29{nflag_clamping_spd}});
                    ncal_spd <= ncal_P_spd + nlasttime_I_spd + (ncal_I_spd & {29{nflag_clamping_spd}});
                end
                S4: begin
                    if($signed(ncal_spd[28:12]) >= IQ_MAX) begin
                        nflag_saturation_spd <= 1'b1;
                        oCal_Iq <= IQ_MAX;
                    end
                    else if($signed(ncal_spd[28:12]) <= -IQ_MAX)begin
                        nflag_saturation_spd <= 1'b1;
                        oCal_Iq <= -IQ_MAX;
                    end
                    else begin
                        nflag_saturation_spd <= 1'b0;
                        oCal_Iq <= ncal_spd[23:12];
                    end
                end
                default: ;
            endcase
        end
    end

endmodule