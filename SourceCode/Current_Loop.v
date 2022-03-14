module Current_Loop(
    iClk,
    iRst_n,
    iCL_en,
    iSin,
    iCos,
    // iId_set,
    // iIq_set,
    iADC124_MISO,
    oADC124_CS_n,
    oADC124_SCLK,
    oADC124_MOSI,
    oPWM_u,
    oPWM_v,
    oPWM_w,
    oModulate_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iCL_en;
    input wire [15:0] iSin,iCos;
    // input wire [11:0] iId_set,iIq_set;
    input wire iADC124_MISO;
    output wire oADC124_CS_n;
    output wire oADC124_SCLK;
    output wire oADC124_MOSI;
    output wire oPWM_u,oPWM_v,oPWM_w;
    output wire oModulate_done;

    wire [15:0] nvd,nvq;
    wire [15:0] nvalpha,nvbeta;
    wire [11:0] nid_current,niq_current;
    wire nip_done,nadc_treat_done,npical_done;

    assign nvd = 16'd0;
    assign nvq = -16'd1000;

    Inv_Park inv_park(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iIP_en(iCL_en),
        .iSin(iSin),
        .iCos(iCos),
        .iVd(nvd),
        .iVq(nvq),
        .oIP_done(nip_done),
        .oValpha(nvalpha),
        .oVbeta(nvbeta)
    );

    SVPWM svpwm(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iModulate_en(nip_done),
        .iValpha(nvalpha),
        .iVbeta(nvbeta),
        .oPWM_u(oPWM_u),
        .oPWM_v(oPWM_v),
        .oPWM_w(oPWM_w),
        .oModulate_done(oModulate_done)
    );

    ADC_DataTreat adc_treat(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iEn(oModulate_done),
        .iSin(iSin),
        .iCos(iCos),
        .iADC124_MISO(iADC124_MISO),
        .oADC124_CS_n(oADC124_CS_n),
        .oADC124_SCLK(oADC124_SCLK),
        .oADC124_MOSI(oADC124_MOSI),
        .oId_current(nid_current),
        .oIq_current(niq_current),
        .oDone(nadc_treat_done)
    );

    // Current_Loop_PI #(
    //     parameter Kp = 10'd1023,
    //     parameter KI = 10'd1023
    // )
    // id_pi (
    //     .iClk(iClk),
    //     .iRst_n(iRst_n),
    //     .iTarget_data(iId_set),
    //     .iCurrent_data(nid_current),  
    //     .iCal_en(nadc_treat_done),
    //     .oCal_data(nvd),
    //     .oCal_done(npical_done)
    // );

    // Current_Loop_PI #(
    //     parameter Kp = 10'd1023,
    //     parameter KI = 10'd1023
    // )
    // iq_pi (
    //     .iClk(iClk),
    //     .iRst_n(iRst_n),
    //     .iTarget_data(iIq_set),
    //     .iCurrent_data(nid_current),  
    //     .iCal_en(nadc_treat_done),
    //     .oCal_data(nvq),
    //     .oCal_done(npical_done)
    // );

endmodule