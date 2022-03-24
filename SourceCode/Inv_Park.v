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

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;

    reg nip_en_pre_state;
    reg [1:0] nstate;
    reg signed [31:0] ntemp_dc,ntemp_qs,ntemp_ds,ntemp_qc;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nip_en_pre_state <= 1'b0;
        end
        else begin
            nip_en_pre_state <= iIP_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ntemp_dc <= 32'd0;
            ntemp_ds <= 32'd0;
            ntemp_qc <= 32'd0;
            ntemp_qs <= 32'd0;
            nstate <=S0;
            oValpha <= 16'd0;
            oVbeta <= 16'd0;
            oIP_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!nip_en_pre_state) & iIP_en) begin
                        ntemp_dc <= (iVd * iCos)>>>15;
                        ntemp_ds <= (iVd * iSin)>>>15;
                        ntemp_qc <= (iVq * iCos)>>>15;
                        ntemp_qs <= (iVq * iSin)>>>15;
                        nstate <= S1;
                    end
                    else begin
                        oIP_done <= 1'b0;
                        nstate <= nstate; 
                    end
                end
                S1: begin
                    nstate <= S0;
                    oValpha <= $signed(ntemp_dc[15:0]) - $signed(ntemp_qs[15:0]);
                    oVbeta <= $signed(ntemp_ds[15:0]) + $signed(ntemp_qc[15:0]);
                    oIP_done <= 1'b1;
                end
                default: nstate <= S0;
            endcase
        end
    end

endmodule