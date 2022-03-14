module Park(
    iClk,
    iRst_n,
    iP_en,
    iSin,
    iCos,
    iIalpha,
    iIbeta,
    oId,
    oIq,
    oP_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iP_en;
    input wire signed [15:0] iSin,iCos;
    input wire signed [11:0] iIalpha;
    input wire signed [11:0] iIbeta;
    output reg signed [11:0] oId;
    output reg signed [11:0] oIq;
    output reg oP_done;

    reg np_en_pre_state;
    wire signed [27:0] ntemp_ac,ntemp_as,ntemp_bc,ntemp_bs;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            np_en_pre_state <= 1'b0;
        end
        else begin
            np_en_pre_state <= iP_en;
        end
    end

    assign ntemp_ac = (iIalpha * iCos)>>>15;
    assign ntemp_bc = (iIbeta * iCos)>>>15;
    assign ntemp_as = (iIalpha * iSin)>>>15;
    assign ntemp_bs = (iIbeta * iSin)>>>15;
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oId <= 12'd0;
            oIq <= 12'd0;
            oP_done <= 1'b0;
        end
        else begin
           if((!np_en_pre_state) & iP_en) begin
                oId <= $signed(ntemp_ac[11:0]) + $signed(ntemp_bs[11:0]);
                oIq <= $signed(ntemp_bc[11:0]) - $signed(ntemp_as[11:0]);
                oP_done <= 1'b1;
           end
           else begin
                oP_done <=1'b0;
           end
        end
    end

endmodule