module Inv_Park(
    iClk,
    iRst_n,
    iIP_en,
    iVd,
    iVq,
    iTheta,
    oIP_done,
    oValpha,
    oVbeta
);
    input wire iClk;
    input wire iRst_n;
    input wire iIP_en;
    input wire signed [15:0] iVd,iVq;
    input wire [19:0] iTheta;
    output reg oIP_done;
    output reg [15:0] oValpha,oVbeta;//有符号类型

    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b11;
    localparam S3 = 2'b10;

    reg nip_en_pre_state;
    reg ncordic_cal_done_pre_state;
    reg [1:0] state;
    reg signed [31:0] ntemp_dc,ntemp_qs,ntemp_ds,ntemp_qc;
    wire ncordic_cal_en;
    wire ncordic_cal_done;
    wire signed [15:0] nsin;
    wire signed [15:0] ncos;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nip_en_pre_state <= 1'b0;
            ncordic_cal_done_pre_state <= 1'b0;
        end
        else begin
            nip_en_pre_state <= iIP_en;
            ncordic_cal_done_pre_state <= ncordic_cal_done;
        end
    end
    assign ncordic_cal_en = (!nip_en_pre_state) & iIP_en;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            state <= S0;
            ntemp_dc <= 32'd0;
            ntemp_ds <= 32'd0;
            ntemp_qc <= 32'd0;
            ntemp_qs <= 32'd0;
            oValpha <= 16'd0;
            oVbeta <= 16'd0;
            oIP_done <= 1'b0;
        end
        else begin
            case (state)
                S0: begin
                    if((!ncordic_cal_done_pre_state) & ncordic_cal_done) begin
                        ntemp_dc <= (iVd * ncos)>>>15;
                        ntemp_ds <= (iVd * nsin)>>>15;
                        ntemp_qc <= (iVq * ncos)>>>15;
                        ntemp_qs <= (iVq * nsin)>>>15;
                        state <= S1;
                    end
                    else begin
                        oIP_done <= 1'b0;
                        state <= state;
                    end
                end
                S1: begin
                    oValpha <= ntemp_dc[15:0] - ntemp_qs[15:0];
                    oVbeta <= ntemp_ds[15:0] + ntemp_qc[15:0];
                    oIP_done <= 1'b1;
                    state <= S0;
                end
                default: state <= S0;
            endcase
        end
    end

    Cordic cordic(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iCordic_en(ncordic_cal_en),
        .iTheta(iTheta),
        .oSin(nsin),
        .oCos(ncos),
        .oCordic_done(ncordic_cal_done)
    );

endmodule