module Inv_Clark(
    iClk,
    iRst_n,
    iIC_en,
    iValpha,
    iVbeta,
    oV1,
    oV2,
    oV3,
    oIC_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iIC_en;
    input wire signed [15:0] iValpha,iVbeta;
    output reg signed [15:0] oV1,oV2,oV3;
    output reg oIC_done;

    localparam num_sqrt3_2 = 10'd886;   //sqrt(3)/2 * (2^10-1)

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;

    reg nic_en_pre_state;
    reg [1:0] nstate;
    reg signed [26:0] ncalout_1,ncalout_2;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nic_en_pre_state <= 1'b0;
        end
        else begin
            nic_en_pre_state <= iIC_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncalout_1 <= 27'd0;
            ncalout_2 <= 27'd0;
            nstate <= S0;
            oIC_done <= 1'b0;
            oV1 <= 16'd0;
            oV2 <= 16'd0;
            oV3 <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!nic_en_pre_state) & iIC_en) begin
                        ncalout_1 <= iValpha * $signed({{1'b0},num_sqrt3_2});
                        ncalout_2 <= iVbeta>>>1;
                        nstate <= S1;
                    end
                    else begin
                        nstate <=nstate;
                        oIC_done <= 1'b0;
                    end
                end
                S1: begin
                    nstate <= S0;
                    oV1 <= iVbeta;
                    oV2 <= $signed(ncalout_1[25:10]) - $signed(ncalout_2[15:0]);
                    oV3 <= -$signed(ncalout_1[25:10]) - $signed(ncalout_2[15:0]);
                    oIC_done <= 1'b1;
                end 
                default: nstate <=S0;
            endcase 
        end
    end

endmodule