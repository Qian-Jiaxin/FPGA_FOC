module Current_Loop(
    iClk,
    iRst_n,
    iTheta_elec,
    // iId_set,
    // iIq_set,
    iCL_en,
    oPWM_u,
    oPWM_v,
    oPWM_w,
    oModulate_done
);
    input wire iClk;
    input wire iRst_n;
    input wire [19:0] iTheta_elec;
    // input wire [11:0] iId_set,iIq_set;
    input wire iCL_en;
    output wire oPWM_u,oPWM_v,oPWM_w;
    output wire oModulate_done;

    reg nmodulate_done_pre_en;
    wire signed [15:0] nvd,nvq;
    wire [15:0] nvalpha,nvbeta;
    wire nip_done;

    assign nvd = 16'd0;
    assign nvq = 16'd1000;

    Inv_Park inv_park(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iIP_en(iCL_en),
        .iVd(nvd),
        .iVq(nvq),
        .iTheta(iTheta_elec),
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

endmodule