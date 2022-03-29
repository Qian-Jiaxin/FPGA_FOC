module Speed_Loop(
    iClk,
    iRst_n,
    iSL_en,
    iSpd_set,
    iSpd_coder,
    iKp,
    iKi,
    oIq,
    oSL_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iSL_en;
    input wire signed [12:0] iSpd_coder;
    input wire signed [12:0] iSpd_set;
    input wire signed [15:0] iKp,iKi;
    output wire signed [11:0] oIq;
    output wire oSL_done;

    reg nsl_en_pre_state;
    reg [4:0] ncount;
    reg ncal_en;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nsl_en_pre_state <= 1'b0; 
        end 
        else begin
            nsl_en_pre_state <= iSL_en; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncount <= 5'd0;
        end 
        else begin
            if((!nsl_en_pre_state) & iSL_en) begin
                if(ncount == 5'd9) begin
                    ncount <= 5'd0; 
                end
                else begin
                    ncount <= ncount + 1'd1; 
                end
            end 
            else begin
                ncount <= ncount; 
            end
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncal_en <= 1'b0;
        end 
        else begin
            if(ncount == 5'd9) begin
                ncal_en <= 1'b1; 
            end
            else begin
                ncal_en <= 1'b0; 
            end
        end
    end

    Speed_Loop_PI pi(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iTarget_spd(iSpd_set),
        .iCurrent_spd(iSpd_coder),
        .iKp_spd(iKp),
        .iKi_spd(iKi),
        .iCal_en(ncal_en),
        .oCal_Iq(oIq),
        .oCal_done(oSL_done)
    );

endmodule