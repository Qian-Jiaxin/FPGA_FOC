module Clark(
    iClk,
    iRst_n,
    iC_en,
    iIu,
    iIv,
    oIalpha,
    oIbeta,
    oC_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iC_en;
    input wire signed [11:0] iIu,iIv;
    output reg signed [11:0] oIalpha,oIbeta;
    output reg oC_done;

    localparam num_1_sqrt3 = 10'd591;   //1/sqrt(3) * (2^10-1)

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;

    reg nc_en_pre_state;
    reg [1:0] nstate;
    reg signed [22:0] niu_temp,niv_temp;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nc_en_pre_state <= 1'b0;
        end
        else begin
            nc_en_pre_state <= iC_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            niu_temp <= 23'd0;
            niv_temp <= 23'd0;
            nstate <= S0;
            oIalpha <= 12'd0;
            oIbeta <= 12'd0;
            oC_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!nc_en_pre_state) & iC_en) begin
                        niu_temp <= iIu * $signed({1'b0,num_1_sqrt3});
                        niv_temp <= iIv * $signed({1'b0,num_1_sqrt3});
                        nstate <= S1;
                    end
                    else begin
                        nstate <= nstate;
                        oC_done <= 1'b0;
                    end
                end
                S1: begin
                    nstate <= S0;
                    oIalpha <= iIu;
                    oIbeta  <= $signed(niu_temp[21:10]) + $signed(niv_temp[20:9]);
                    oC_done <= 1'b1;
                end
                default: nstate <= S0;
            endcase
        end
    end

endmodule