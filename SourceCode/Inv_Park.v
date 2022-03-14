module Inv_Park(
    iClk,
    iRst_n,
    iIP_en,
    iSin,
    iCos,
    iVd,
    iVq,
    oIP_done,
    oValpha,
    oVbeta
);
    input wire iClk;
    input wire iRst_n;
    input wire iIP_en;
    input wire signed [15:0] iSin,iCos;
    input wire signed [15:0] iVd,iVq;
    output reg oIP_done;
    output reg [15:0] oValpha,oVbeta;//有符号类型

    reg nip_en_pre_state;
    wire signed [31:0] ntemp_dc,ntemp_qs,ntemp_ds,ntemp_qc;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nip_en_pre_state <= 1'b0;
        end
        else begin
            nip_en_pre_state <= iIP_en;
        end
    end

    assign ntemp_dc = (iVd * iCos)>>>15;
    assign ntemp_ds = (iVd * iSin)>>>15;
    assign ntemp_qc = (iVq * iCos)>>>15;
    assign ntemp_qs = (iVq * iSin)>>>15;
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oValpha <= 16'd0;
            oVbeta <= 16'd0;
            oIP_done <= 1'b0;
        end
        else begin
            if((!nip_en_pre_state) & iIP_en) begin
                oValpha <= $signed(ntemp_dc[15:0]) - $signed(ntemp_qs[15:0]);
                oVbeta <= $signed(ntemp_ds[15:0]) + $signed(ntemp_qc[15:0]);
                oIP_done <= 1'b1;
            end
            else begin
                oIP_done <= 1'b0;
            end
        end
    end

endmodule