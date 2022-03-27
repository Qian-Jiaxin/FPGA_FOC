module Corder_DataTreat(
    iClk,
    iRst_n,
    iEn,
    iRx,
    oDir,
    oTx,
    oSin,
    oCos,
    oWarning,
    oDone
);
    input wire iClk;
    input wire iRst_n;
    input wire iEn;
    input wire iRx;
    output wire oDir;
    output wire oTx;
    output wire [15:0] oSin,oCos;
    output wire oWarning;
    output wire oDone;

    localparam POLE_PAIRS = 3'd5;
    localparam SPECIAL_ANGLE = 20'd1048575;

    reg [19:0] ntheta_elec;
    reg ncordic_cal_en;
    reg nnikon_rd_done_pre_state;
    wire [19:0] nrd_data_st;
    wire [15:0] nrd_data_mt;
    wire nnikon_rd_done;
    wire [22:0] ntheta_elec_temp;

    NIKON nikon_data(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iRd_en(iEn),
        .iRx(iRx),
        .oDir(oDir),
        .oTx(oTx),
        .oRd_data_st(nrd_data_st),
        .oRd_data_mt(nrd_data_mt),
        .oRd_warning(oWarning),
        .oRd_done(nnikon_rd_done)
    );

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nnikon_rd_done_pre_state <= 1'b0;
        end
        else begin
            nnikon_rd_done_pre_state <= nnikon_rd_done; 
        end
    end

    assign ntheta_elec_temp = nrd_data_st * POLE_PAIRS;
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ntheta_elec <= 20'd0;
            ncordic_cal_en <= 1'b0;
        end
        else begin
            if((!nnikon_rd_done_pre_state) & nnikon_rd_done) begin
                ntheta_elec <= SPECIAL_ANGLE - ntheta_elec_temp[19:0];
                ncordic_cal_en <= 1'b1;
            end
            else begin
                ncordic_cal_en <= 1'b0;
            end
        end
    end

    Cordic cordic(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iCordic_en(ncordic_cal_en),
        .iTheta(ntheta_elec),
        .oSin(oSin),
        .oCos(oCos),
        .oCordic_done(oDone)
    );

endmodule