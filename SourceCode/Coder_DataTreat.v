module Corder_DataTreat(
    iClk,
    iRst_n,
    iEn_Rd,
    iRx,
    oDir,
    oTx,
    oSin,
    oCos,
    oSpeed,
    oWarning,
    oDone_Rd
);
    input wire iClk;
    input wire iRst_n;
    input wire iEn_Rd;
    input wire iRx;
    output wire oDir;
    output wire oTx;
    output wire signed [15:0] oSin,oCos;
    output reg signed [12:0] oSpeed;
    output wire oWarning;
    output wire oDone_Rd;

    /*********************传感器数据获取*********************/
    wire [19:0] nrd_data_st;
    // wire [15:0] nrd_data_mt;
    wire nnikon_rd_done;

    NIKON nikon_data(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iRd_en(iEn_Rd),
        .iRx(iRx),
        .oDir(oDir),
        .oTx(oTx),
        .oRd_data_st(nrd_data_st),
        // .oRd_data_mt(nrd_data_mt),
        .oRd_warning(oWarning),
        .oRd_done(nnikon_rd_done)
    );

    /******************************************************/

    /***********************触发处理***********************/
    reg nnikon_rd_done_pre_state;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nnikon_rd_done_pre_state <= 1'b0;
        end
        else begin
            nnikon_rd_done_pre_state <= nnikon_rd_done; 
        end
    end

    /******************************************************/

    /***********************角度处理***********************/
    localparam POLE_PAIRS = 3'd5;
    localparam SPECIAL_ANGLE = 20'd1048575;

    reg [19:0] ntheta_elec;
    reg ncordic_cal_en;
    wire [22:0] ntheta_elec_temp;

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
        .oCordic_done(oDone_Rd)
    );

    /******************************************************/

    /***********************速度处理***********************/
    localparam SPEED_MAX = 13'sd2621;

    reg [19:0] nrd_data_st_pre;
    reg [19:0] nspeed_temp;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nrd_data_st_pre <= 20'd0;
            nspeed_temp <= 20'd0;
            oSpeed <= 13'd0;
        end
        else begin
            if((!nnikon_rd_done_pre_state) & nnikon_rd_done) begin
                nrd_data_st_pre <= nrd_data_st;
                nspeed_temp <= nrd_data_st - nrd_data_st_pre;
            end
            else begin
                if($signed(nspeed_temp) > SPEED_MAX) begin
                    oSpeed <= SPEED_MAX; 
                end
                else if($signed(nspeed_temp) < -SPEED_MAX) begin
                    oSpeed <= -SPEED_MAX; 
                end
                else begin
                    oSpeed <= nspeed_temp[12:0];
                end
            end
        end
    end

    /******************************************************/

endmodule