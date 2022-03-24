module ADC_DataTreat(
    iClk,
    iRst_n,
    iEn,
    iSin,
    iCos,
    iADC124_MISO,
    oADC124_CS_n,
    oADC124_SCLK,
    oADC124_MOSI,
    oId_current,
    oIq_current,
    oDone
);
    input wire iClk;
    input wire iRst_n;
    input wire iEn;
    input wire [15:0] iSin,iCos;
    input wire iADC124_MISO;
    output wire oADC124_CS_n;
    output wire oADC124_SCLK;
    output wire oADC124_MOSI;
    output wire [11:0] oId_current,oIq_current;
    output wire oDone;

    localparam ADC_CUR_OFFSET = 12'd2047;

    wire [11:0] niu,niv;
    wire signed [11:0] niu_sign,niv_sign;
    wire [11:0] nialpha,nibeta;
    wire nadc124_acquire_done,nc_done;

    ADC124S051 adc124s051_data(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iAcquireCurrent_en(iEn),
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

    assign niu_sign = $signed(niu) - $signed(ADC_CUR_OFFSET);
    assign niv_sign = $signed(niv) - $signed(ADC_CUR_OFFSET);
    Clark clark(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iC_en(nadc124_acquire_done),
        .iIu(niu_sign),
        .iIv(niv_sign),
        .oIalpha(nialpha),
        .oIbeta(nibeta),
        .oC_done(nc_done)
    );

    Park park(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iP_en(nc_done),
        .iSin(iSin),
        .iCos(iCos),
        .iIalpha(nialpha),
        .iIbeta(nibeta),
        .oId(oId_current),
        .oIq(oIq_current),
        .oP_done(oDone)
    );

endmodule