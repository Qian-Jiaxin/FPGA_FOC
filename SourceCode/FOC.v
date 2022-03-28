module FOC(
    iClk,
    iRst_n,
    //编码器通讯信号
    iRx,
    oDir,
    oTx,
    //ADC121通讯信号(母线)

    //ADC124通讯信号(电流/电压)
    iADC124_MISO,
    oADC124_CS_n,
    oADC124_SCLK,
    oADC124_MOSI,
    //控制信号
    oPWM_u,
    oPWM_v,
    oPWM_w,
    oSD_u_n,
    oSD_v_n,
    oSD_w_n
);
    input wire iClk;
    input wire iRst_n;
    //编码器通讯信号
    input wire iRx;
    output wire oDir;
    output wire oTx;
    //ADC121通讯信号(母线)

    //ADC124通讯信号(电流/电压)
    input wire iADC124_MISO;
    output wire oADC124_CS_n;
    output wire oADC124_SCLK;
    output wire oADC124_MOSI;
    //控制信号
    output wire oPWM_u,oPWM_v,oPWM_w;
    output wire oSD_u_n,oSD_v_n,oSD_w_n;

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;
    localparam S3 = 2'd3;

    reg [1:0] nstate;
    reg ncdt_en,ncl_en;
    wire ncdt_done,nmodulate_done;
    wire [15:0] nsin,ncos;
    wire ncdt_warning;
    wire nclk_100m;
    wire npll_locked;

    assign oSD_u_n = 1'b1;
    assign oSD_v_n = 1'b1;
    assign oSD_w_n = 1'b1;

    always @(posedge nclk_100m or negedge iRst_n) begin
        if(!iRst_n) begin
            ncdt_en <= 1'b0;
            ncl_en <= 1'b0;
            nstate <= S0;
        end
        else begin
            case (nstate)
                S0: begin
                    ncdt_en <= 1'b0;
                    ncl_en <= 1'b0;
                    nstate <= S1;
                end
                S1: begin
                    if(npll_locked) begin
                        ncdt_en <= 1'b1;
                        ncl_en <= 1'b0;
                        nstate <= S2;
                    end
                    else begin
                        ncdt_en <= ncdt_en;
                        ncl_en <= ncl_en;
                        nstate <= nstate;
                    end
                end
                S2: begin
                    if(ncdt_done) begin
                        ncdt_en <= 1'b0;
                        ncl_en <= 1'b1;
                        nstate <= S3;
                    end
                    else
                    begin
                        ncdt_en <= 1'b0;
                        ncl_en <= 1'b0;
                        nstate <= nstate; 
                    end
                end
                S3: begin
                    if(nmodulate_done) begin
                        ncdt_en <= 1'b1;
                        // ncl_en <= 1'b1;
                    end 
                    else begin
                        ncdt_en <= 1'b0;
                        ncl_en <= 1'b0;
                    end
                end
                default: nstate <= S0;
            endcase 
        end
    end
    
    PLL_100M pll_100m(
        .inclk0(iClk),
        .c0(nclk_100m),
        .locked(npll_locked)
    );

    Corder_DataTreat coder_datatreat(
        .iClk(nclk_100m),
        .iRst_n(iRst_n),
        .iEn(ncdt_en),
        .iRx(iRx),
        .oDir(oDir),
        .oTx(oTx),
        .oSin(nsin),
        .oCos(ncos),
        // .oWarning(ncdt_warning),
        .oDone(ncdt_done)
    );

    Current_Loop current_loop(
        .iClk(nclk_100m),
        .iRst_n(iRst_n),
        .iCL_en(ncl_en),
        .iSin(nsin),
        .iCos(ncos),
        .iId_set(12'd300),
        .iIq_set(12'd0),
        .iKp_d(16'd17653),
        .iKi_d(16'd697),
        .iKp_q(16'd17653),
        .iKi_q(16'd697),
        .iADC124_MISO(iADC124_MISO),
        .oADC124_CS_n(oADC124_CS_n),
        .oADC124_SCLK(oADC124_SCLK),
        .oADC124_MOSI(oADC124_MOSI),
        .oPWM_u(oPWM_u),
        .oPWM_v(oPWM_v),
        .oPWM_w(oPWM_w),
        .oModulate_done(nmodulate_done)
    );

endmodule