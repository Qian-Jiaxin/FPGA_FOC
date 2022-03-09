module FOC(
    iClk,
    iRst_n,
    //编码器通讯信号
    iRx,
    oDir,
    oTx,
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
    //控制信号
    output wire oPWM_u,oPWM_v,oPWM_w;
    output wire oSD_u_n,oSD_v_n,oSD_w_n;

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;
    localparam S3 = 2'd3;

    reg [1:0] nstate;
    reg nac_en,ncl_en;
    reg [12:0] ncount;
    wire [19:0] ntheta_elec;
    wire [1:0] nac_warning;
    wire nrd_done,nmodulate_done;
    wire nclk_100m;
    wire npll_locked;

    assign oSD_u_n = 1'b1;
    assign oSD_v_n = 1'b1;
    assign oSD_w_n = 1'b1;

    always @(posedge nclk_100m or negedge iRst_n) begin
        if(!iRst_n) begin
            nac_en <= 1'b0;
            ncl_en <= 1'b0;
            ncount <= 13'd0;
            nstate <= S0;
        end
        else begin
            if(npll_locked) begin
                case (nstate)
                    S0: begin
                        if(ncount == 13'd4999) begin
                            nac_en <= 1'b1;
                            ncount <= 13'd0;
                            nstate <= S1;
                        end
                        else begin
                            ncount <= ncount + 1'd1;
                            nac_en <= 1'b0;
                            ncl_en <= 1'b0;
                        end
                    end
                    S1: begin
                       if(ncount == 13'd4999) begin
                            nac_en <= 1'b1;
                            ncl_en <= 1'b1;
                            ncount <= 13'd0;
                        end
                        else begin
                            ncount <= ncount + 1'd1;
                            nac_en <= 1'b0;
                            ncl_en <= 1'b0;
                        end 
                    end
                    default: nstate <= S0;
                endcase
                
            end
            else begin
                nac_en <= 1'b0;
                ncl_en <= 1'b0;
                nstate <= S0;
            end
        end
    end
    
    PLL_100M pll_100m(
        .inclk0(iClk),
        .c0(nclk_100m),
        .locked(npll_locked)
    );

    Acquire_Data acquire_data(
        .iClk(nclk_100m),
        .iRst_n(iRst_n),
        .iAC_en(nac_en),
        .iRx(iRx),
        .oDir(oDir),
        .oTx(oTx),
        .oTheta_elec(ntheta_elec),
        .oAC_warning(nac_warning)
    );

    Current_Loop current_loop(
        .iClk(nclk_100m),
        .iRst_n(iRst_n),
        .iTheta_elec(ntheta_elec),
        // .iId_set(),
        // .iIq_set(),
        .iCL_en(ncl_en),
        .oPWM_u(oPWM_u),
        .oPWM_v(oPWM_v),
        .oPWM_w(oPWM_w),
        .oModulate_done(nmodulate_done)
    );

endmodule