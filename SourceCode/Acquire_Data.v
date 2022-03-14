module Acquire_Data(
    iClk,
    iRst_n,
    iAC_en,
    //编码器RS485通信
    iRx,
    oDir,
    oTx,
    //模数转换器SPI通信
    iADC124_MISO,
    oADC124_CS_n,
    oADC124_SCLK,
    oADC124_MOSI,
    //数据输出
    oSIN,
    oCOS,
    oIq_set,
    oId_set,
    oAC_warning
);

    input wire iClk;
    input wire iRst_n;
    input wire iAC_en;

    input wire iRx;
    output wire oDir;
    output wire oTx;

    input wire iADC124_MISO;
    output wire oADC124_CS_n;
    output wire oADC124_SCLK;
    output wire oADC124_MOSI;

    output wire [15:0] oSIN,oCOS;
    output wire [11:0] oIq_set,oId_set;
    output wire [1:0]oAC_warning;

    localparam POLE_PAIRS = 3'd5;
    localparam SPECIAL_ANGLE = 20'd1048575;

    localparam S0 = 1'd0;
    localparam S1 = 1'd1;

    ////////////////////////////编码器数据获取及处理////////////////////////////
    // reg nstate_cal_theta;
    wire [22:0] ntheta_elec_temp;
    reg [19:0] ntheta_elec;
    reg ncordic_cal_en;
    reg nnikon_rd_done_pre_state;
    wire [19:0] nrd_data_st;
    wire [15:0] nrd_data_mt;
    wire nnikon_warning;
    wire nnikon_rd_done;

    NIKON nikon_data(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iRd_en(iAC_en),
        .iRx(iRx),
        .oDir(oDir),
        .oTx(oTx),
        .oRd_data_st(nrd_data_st),
        .oRd_data_mt(nrd_data_mt),
        .oRd_warning(nnikon_warning),
        .oRd_done(nnikon_rd_done)
    );
    assign ntheta_elec_temp = nrd_data_st * POLE_PAIRS;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nnikon_rd_done_pre_state <= 1'b0;
        end
        else begin
            nnikon_rd_done_pre_state <= nnikon_rd_done; 
        end
    end

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
        .oSin(oSIN),
        .oCos(oCOS),
        .oCordic_done(ncordic_cal_done)
    );
    //////////////////////////////////////////////////////////////////////////


    ///////////////////////////模数转换数据采集及处理///////////////////////////
    reg [11:0] niu,niv;
    wire nadc124_acquire_done;

    ADC124S051 adc124s051_data(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iAcquireCurrent_en(iAC_en),
        // .iAcquireVoltage_en,
        .iMISO(iADC124_MISO),
        .oCS_n(oADC124_CS_n),
        .oSCLK(oADC124_SCLK),
        .oMOSI(oADC124_MOSI),
        .oIu(niu),
        .oIv(niv),
        // .oUu(oUu),
        // .oUv(oUv),
        .oAcquire_done(nadc124_acquire_done)
    );


    //////////////////////////////////////////////////////////////////////////

endmodule