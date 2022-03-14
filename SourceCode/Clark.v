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

    reg nc_en_pre_state;
    wire signed [22:0] niu_temp,niv_temp;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nc_en_pre_state <= 1'b0;
        end
        else begin
            nc_en_pre_state <= iC_en;
        end
    end

    assign niu_temp = iIu * $signed({1'b0,num_1_sqrt3})>>>10;
    assign niv_temp = iIv * $signed({1'b0,num_1_sqrt3})>>>9;
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oIalpha <= 12'd0;
            oIbeta <= 12'd0;
            oC_done <= 1'b0;
        end
        else begin
            if((!nc_en_pre_state) & iC_en) begin
                oIalpha <= iIu;
                oIbeta  <= $signed(niu_temp[11:0]) + $signed(niv_temp[11:0]);
                oC_done <= 1'b1;
            end
            else begin
                oC_done <= 1'b0; 
            end
        end
    end

endmodule