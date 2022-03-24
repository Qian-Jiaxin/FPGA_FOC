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
    input wire signed [11:0] iIalpha,iIbeta;
    output reg signed [11:0] oId,oIq;
    output reg oP_done;

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;

    reg np_en_pre_state;
    reg [1:0] nstate;
    reg signed [27:0] ntemp_ac,ntemp_as,ntemp_bc,ntemp_bs;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            np_en_pre_state <= 1'b0;
        end
        else begin
            np_en_pre_state <= iP_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ntemp_ac <= 28'd0;
            ntemp_as <= 28'd0;
            ntemp_bc <= 28'd0;
            ntemp_bs <= 28'd0;
            nstate <= S0;
            oId <= 12'd0;
            oIq <= 12'd0;
            oP_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!np_en_pre_state) & iP_en) begin
                        ntemp_ac <= (iIalpha * iCos)>>>15;
                        ntemp_bc <= (iIbeta * iCos)>>>15;
                        ntemp_as <= (iIalpha * iSin)>>>15;
                        ntemp_bs <= (iIbeta * iSin)>>>15;
                        nstate <= S1;
                    end
                    else begin
                        nstate <= nstate;
                        oP_done <= 1'b0;
                    end
                end
                S1: begin
                    nstate <= S0;
                    oId <= $signed(ntemp_ac[11:0]) + $signed(ntemp_bs[11:0]);
                    oIq <= $signed(ntemp_bc[11:0]) - $signed(ntemp_as[11:0]);
                    oP_done <= 1'b1;
                end
                default: nstate <= S0;
            endcase
        end
    end

endmodule