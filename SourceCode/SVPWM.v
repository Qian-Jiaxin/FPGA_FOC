module SVPWM(
    iClk,
    iRst_n,
    iModulate_en,
    iValpha,
    iVbeta,
    oPWM_u,
    oPWM_v,
    oPWM_w,
    oModulate_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iModulate_en;
    input wire [15:0] iValpha,iVbeta;
    output wire oPWM_u,oPWM_v,oPWM_w;
    output wire oModulate_done;

    wire [2:0] nsector;
    wire [15:0] nv1,nv2,nv3;
    wire nic_done,nas_done,ncw_done;
    wire [11:0] nccr_a,nccr_b,nccr_c;

    Inv_Clark inv_clark(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iIC_en(iModulate_en),
        .iValpha(iValpha),
        .iVbeta(iVbeta),
        .oV1(nv1),
        .oV2(nv2),
        .oV3(nv3),
        .oIC_done(nic_done)
    );

    SVPWM_Analyse_Sector svpwm_analyse_sector(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iAS_en(nic_done),
        .iA(!nv1[15]),
        .iB(!nv2[15]),
        .iC(!nv3[15]),
        .oSector(nsector),
        .oAS_done(nas_done)
    );

    SVPWM_Calculate_Workingtime svpwm_calculate_workingtime(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iCW_en(nas_done),
        .iSector(nsector),
        .iV1(nv1),
        .iV2(nv2),
        .iV3(nv3),
        .oCCR_a(nccr_a),
        .oCCR_b(nccr_b),
        .oCCR_c(nccr_c),
        .oCW_done(ncw_done)
    );

    SVPWM_Modulate_PWM svpwm_modulate_pwm(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iMP_en(ncw_done),
        .iCCR_a(nccr_a),
        .iCCR_b(nccr_b),
        .iCCR_c(nccr_c),
        .oPWM_u(oPWM_u),
        .oPWM_v(oPWM_v),
        .oPWM_w(oPWM_w),
        .oMP_done(oModulate_done)
    );

endmodule

module SVPWM_Analyse_Sector(
    iClk,
    iRst_n,
    iAS_en,
    iA,
    iB,
    iC,
    oSector,
    oAS_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iAS_en;
    input wire iA,iB,iC;
    output reg [2:0] oSector;
    output reg oAS_done;

    localparam Sector_1 = 3'd1;
    localparam Sector_2 = 3'd2;
    localparam Sector_3 = 3'd3;
    localparam Sector_4 = 3'd4;
    localparam Sector_5 = 3'd5;
    localparam Sector_6 = 3'd6;

    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b11;
    localparam S3 = 2'b10;

    reg [1:0] state;
    reg nas_en_pre_state;
    reg [2:0] ntemp_a,ntemp_b,ntemp_c,nN;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nas_en_pre_state <= 1'b0;
        end
        else begin
            nas_en_pre_state <= iAS_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            state <= S0;
            ntemp_a <= 3'd0;
            ntemp_b <= 3'd0;
            ntemp_c <= 3'd0;
            nN <= 3'd0;
            oAS_done <= 1'b0;
            oSector <= 3'd0;
        end
        else begin
            case (state)
                S0:  begin
                    if((!nas_en_pre_state) & iAS_en) begin
                        ntemp_a <= iA;
                        ntemp_b <= iB;
                        ntemp_c <= iC;
                        state <= S1;
                    end
                    else begin
                        ntemp_a <= 3'd0;
                        ntemp_b <= 3'd0;
                        ntemp_c <= 3'd0;
                        oAS_done <= 1'b0;
                        state <= state;
                    end
                end
                S1: begin
                    nN <= ntemp_a + (ntemp_b<<1) + (ntemp_c<<2);
                    state <= S2;
                end
                S2: begin
                    case (nN)
                        3'd1: oSector <= Sector_2;
                        3'd2: oSector <= Sector_6;
                        3'd3: oSector <= Sector_1;
                        3'd4: oSector <= Sector_4;
                        3'd5: oSector <= Sector_3;
                        3'd6: oSector <= Sector_5;
                        default: ;
                    endcase
                    oAS_done <= 1'b1;
                    state <= S0;
                end
                default: state <= S0;
            endcase
        end
    end

endmodule

module SVPWM_Calculate_Workingtime(
    iClk,
    iRst_n,
    iCW_en,
    iSector,
    iV1,
    iV2,
    iV3,
    oCCR_a,
    oCCR_b,
    oCCR_c,
    oCW_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iCW_en;
    input wire [2:0] iSector;
    input wire signed [15:0] iV1,iV2,iV3;
    output reg [11:0] oCCR_a,oCCR_b,oCCR_c;
    output reg oCW_done;

    localparam T = 13'd4999;

    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b11;
    localparam S3 = 2'b10;

    localparam Sector_1 = 3'd1;
    localparam Sector_2 = 3'd2;
    localparam Sector_3 = 3'd3;
    localparam Sector_4 = 3'd4;
    localparam Sector_5 = 3'd5;
    localparam Sector_6 = 3'd6;

    reg ncw_en_pre_state;
    reg [1:0] state;
    reg signed [15:0] nux,nuy;
    reg [28:0] ntx,nty;
    reg [13:0] nccr_a,nccr_b,nccr_c;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncw_en_pre_state <= 1'b0;
        end
        else begin
            ncw_en_pre_state <= iCW_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nux <= 16'd0;
            nuy <= 16'd0;
            ntx <= 29'd0;
            nty <= 29'd0;
            oCCR_a <= 12'd0;
            oCCR_b <= 12'd0;
            oCCR_c <= 12'd0;
            oCW_done <= 1'b0;
            state <= S0;
        end
        else begin
            case (state)
                S0: begin
                    if((!ncw_en_pre_state) & iCW_en) begin
                        case (iSector)
                            Sector_1: begin
                                nux <= iV2;
                                nuy <= iV1;
                            end
                            Sector_2: begin
                                nux <= -iV2;
                                nuy <= -iV3;
                            end
                            Sector_3: begin
                                nux <= iV1;
                                nuy <= iV3;
                            end
                            Sector_4: begin
                                nux <= -iV1;
                                nuy <= -iV2;
                            end
                            Sector_5: begin
                                nux <= iV3;
                                nuy <= iV2;
                            end
                            Sector_6: begin
                                nux <= -iV3;
                                nuy <= -iV1;
                            end
                            default: begin
                                nux <= nux;
                                nuy <= nuy; 
                            end
                        endcase
                        state <= S1;
                    end
                    else begin
                        oCW_done <= 1'b0;
                        state <= state;
                    end
                end
                S1: begin
                    ntx <= (nux * T)>>15;
                    nty <= (nuy * T)>>15;
                    state <= S2;
                end
                S2: begin
                    nccr_a <= (T - ntx[12:0] - nty[12:0])>>2;
                    nccr_b <= (T + ntx[12:0] - nty[12:0])>>2;
                    nccr_c <= (T + ntx[12:0] + nty[12:0])>>2;
                    state <= S3;
                end
                S3: begin
                    case (iSector)
                        Sector_1: begin
                            oCCR_a <= nccr_a[11:0];
                            oCCR_b <= nccr_b[11:0];
                            oCCR_c <= nccr_c[11:0];
                        end
                        Sector_2: begin
                            oCCR_a <= nccr_b[11:0];
                            oCCR_b <= nccr_a[11:0];
                            oCCR_c <= nccr_c[11:0];
                        end
                        Sector_3: begin
                            oCCR_a <= nccr_c[11:0];
                            oCCR_b <= nccr_a[11:0];
                            oCCR_c <= nccr_b[11:0];
                        end
                        Sector_4: begin
                            oCCR_a <= nccr_c[11:0];
                            oCCR_b <= nccr_b[11:0];
                            oCCR_c <= nccr_a[11:0];
                        end
                        Sector_5: begin
                            oCCR_a <= nccr_b[11:0];
                            oCCR_b <= nccr_c[11:0];
                            oCCR_c <= nccr_a[11:0];
                        end
                        Sector_6: begin
                            oCCR_a <= nccr_a[11:0];
                            oCCR_b <= nccr_c[11:0];
                            oCCR_c <= nccr_b[11:0];
                        end
                        default: begin
                            oCCR_a <= oCCR_a;
                            oCCR_b <= oCCR_b;
                            oCCR_c <= oCCR_c; 
                        end
                    endcase
                    oCW_done <= 1'b1;
                    state <= S0;
                end
                default: state <= S0;
            endcase
        end
    end

endmodule

module SVPWM_Modulate_PWM(
    iClk,
    iRst_n,
    iMP_en,
    iCCR_a,
    iCCR_b,
    iCCR_c,
    oPWM_u,
    oPWM_v,
    oPWM_w,
    oMP_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iMP_en;
    input wire [11:0] iCCR_a,iCCR_b,iCCR_c;
    output wire oPWM_u,oPWM_v,oPWM_w;
    output reg oMP_done;

    localparam Sector_1 = 3'd1;
    localparam Sector_2 = 3'd2;
    localparam Sector_3 = 3'd3;
    localparam Sector_4 = 3'd4;
    localparam Sector_5 = 3'd5;
    localparam Sector_6 = 3'd6;

    localparam T = 13'd4999;

    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b11;
    localparam S3 = 2'b10;

    reg nmp_en_pre_state;
    reg [11:0] ncount; 
    reg [1:0] state;
    reg [11:0] nccr_a_autoreload,nccr_b_autoreload,nccr_c_autoreload;
    reg nflag_autoreload;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nmp_en_pre_state <= 1'b0;
        end
        else begin
            nmp_en_pre_state <= iMP_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nccr_a_autoreload <= 12'd0; 
            nccr_b_autoreload <= 12'd0; 
            nccr_c_autoreload <= 12'd0; 
        end
        else begin
            if((!nmp_en_pre_state) & iMP_en) begin
                nccr_a_autoreload <= iCCR_a;
                nccr_b_autoreload <= iCCR_b;
                nccr_c_autoreload <= iCCR_c; 
            end
            else if(nflag_autoreload) begin
                nccr_a_autoreload <= iCCR_a;
                nccr_b_autoreload <= iCCR_b;
                nccr_c_autoreload <= iCCR_c; 
            end
            else begin
                nccr_a_autoreload <= nccr_a_autoreload;
                nccr_b_autoreload <= nccr_b_autoreload;
                nccr_c_autoreload <= nccr_c_autoreload; 
            end
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n)begin
            nflag_autoreload <= 1'b0;
            ncount <= 11'd0;
            state <= S0;
            oMP_done <= 1'b0;
        end
        else begin
            case (state)
                S0: begin
                    if((!nmp_en_pre_state) & iMP_en) begin
                        state <= S1;
                    end
                    else begin
                        nflag_autoreload <= 1'b0;
                        ncount <= 11'd0;
                        oMP_done <= 1'b0;
                        state <= S0;
                    end
                end
                S1: begin
                    if(ncount == (T>>1)) begin
                        nflag_autoreload <= 1'b1;
                        state <= S2;
                    end
                    else begin
                        nflag_autoreload <= 1'b0;
                        ncount <= ncount + 1'd1;
                        oMP_done <= 1'b0; 
                    end
                end
                S2: begin
                    if(ncount == 10'd0) begin
                        nflag_autoreload <= 1'b1;
                        oMP_done <= 1'b1;
                        state <= S1;
                    end
                    else begin
                        nflag_autoreload <= 1'b0;
                        ncount <= ncount - 1'd1;
                        oMP_done <= 1'b0; 
                    end
                end
                default: state <= S0;
            endcase 
        end
    end
    assign oPWM_u = (ncount >= nccr_a_autoreload) ? 1'b1:1'b0;
    assign oPWM_v = (ncount >= nccr_b_autoreload) ? 1'b1:1'b0;
    assign oPWM_w = (ncount >= nccr_c_autoreload) ? 1'b1:1'b0;

endmodule