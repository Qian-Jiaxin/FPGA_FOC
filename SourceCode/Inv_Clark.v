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
    output reg [15:0] oV1,oV2,oV3;
    output reg oIC_done;

    localparam num_sqrt3_2 = 10'd886;   //sqrt(3)/2 * (2^10-1)

    reg nic_en_pre_state;
    wire signed [26:0] ncalout_1,ncalout_2;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nic_en_pre_state <= 1'b0;
        end
        else begin
            nic_en_pre_state <= iIC_en;
        end
    end

    assign ncalout_1 = (iValpha * $signed({{1'b0},num_sqrt3_2}))>>>10;
    assign ncalout_2 = iVbeta>>>1;
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oIC_done <= 1'b0;
            oV1 <= 16'd0;
            oV2 <= 16'd0;
            oV3 <= 16'd0;
        end
        else begin
            if((!nic_en_pre_state) & iIC_en) begin
                oV1 <= iVbeta;
                oV2 <= $signed(ncalout_1[15:0]) - $signed(ncalout_2[15:0]);
                oV3 <= -$signed(ncalout_1[15:0]) - $signed(ncalout_2[15:0]);
                oIC_done <= 1'b1;
            end
            else begin
                oIC_done <= 1'b0;
            end
        end
    end

endmodule