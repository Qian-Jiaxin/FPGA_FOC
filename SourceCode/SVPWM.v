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

    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b11;
    localparam S3 = 2'b10;

    reg [1:0] state;
    reg nas_en,ncw_en,nmp_en;
    reg nic_done_pre_state,nas_done_pre_state,ncw_done_pre_state;
    wire [2:0] nsector;
    wire [15:0] nv1,nv2,nv3;
    wire nic_done,nas_done,ncw_done;
    wire [11:0] nccr_a,nccr_b,nccr_c;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nic_done_pre_state <= 1'b0;
            nas_done_pre_state <= 1'b0;
            ncw_done_pre_state <= 1'b0;
        end
        else begin
            nic_done_pre_state <= nic_done;
            nas_done_pre_state <= nas_done;
            ncw_done_pre_state <= ncw_done;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nas_en <= 1'b0;
            ncw_en <= 1'b0;
            nmp_en <= 1'b0;
            state <= S0;
        end
        else begin
            case (state)
                S0: begin
                    if((!nic_done_pre_state) & nic_done) begin
                        nas_en <= 1'b1;
                        state <= S1;
                    end
                    else begin
                        nas_en <= 1'b0;
                        ncw_en <= 1'b0;
                        nmp_en <= 1'b0;
                    end
                end
                S1: begin
                    if((!nas_done_pre_state) & nas_done) begin
                        ncw_en <= 1'b1;
                        state <= S2;
                    end
                end
                S2: begin
                    if((!ncw_done_pre_state) & ncw_done) begin
                        nmp_en <= 1'b1;
                        state <= S0;
                    end
                end
                default: state <= S0;
            endcase
        end
    end

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
        .iAS_en(nas_en),
        .iA(!nv1[15]),
        .iB(!nv2[15]),
        .iC(!nv3[15]),
        .oSector(nsector),
        .oAS_done(nas_done)
    );

    SVPWM_Calculate_Workingtime svpwm_calculate_workingtime(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iCW_en(ncw_en),
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
        .iMP_en(nmp_en),
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
    localparam K = 13'd4329; //sqrt(3)*T/2

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
    reg [11:0] nta,ntb,nt0_7;
    reg [1:0] state;
    reg signed [15:0] ndata_a,ndata_b;
    wire signed [27:0] ntemp_a,ntemp_b;

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
            nta <= 12'd0;
            ntb <= 12'd0;
            nt0_7 <= 12'd0;
            ndata_a <= 16'd0;
            ndata_b <= 16'd0;
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
                                ndata_a <= iV2;
                                ndata_b <= iV1;
                            end
                            Sector_2: begin
                                ndata_a <= -iV2;
                                ndata_b <= -iV3;
                            end
                            Sector_3: begin
                                ndata_a <= iV1;
                                ndata_b <= iV3;
                            end
                            Sector_4: begin
                                ndata_a <= -iV1;
                                ndata_b <= -iV2;
                            end
                            Sector_5: begin
                                ndata_a <= iV3;
                                ndata_b <= iV2;
                            end
                            Sector_6: begin
                                ndata_a <= -iV3;
                                ndata_b <= -iV1;
                            end
                            default: ;
                        endcase
                        state <= S1;
                    end
                    else begin
                        oCW_done <= 1'b0;
                        state <= state;
                    end
                end
                S1: begin
                    nta <= ntemp_a[11:0];
                    ntb <= ntemp_b[11:0];
                    nt0_7 <= (T[12:1] - ntemp_a[11:0] - ntemp_b[11:0])>>1;
                    state <= S2;
                end
                S2: begin
                    case (iSector)
                        Sector_1: begin
                            oCCR_a <= nt0_7;
                            oCCR_b <= nt0_7 + nta;
                            oCCR_c <= nt0_7 + nta + ntb;
                        end
                        Sector_2: begin
                            oCCR_a <= nt0_7 + nta;
                            oCCR_b <= nt0_7;
                            oCCR_c <= nt0_7 + nta + ntb;
                        end
                        Sector_3: begin
                            oCCR_a <= nt0_7 + nta + ntb;
                            oCCR_b <= nt0_7;
                            oCCR_c <= nt0_7 + nta;
                        end
                        Sector_4: begin
                            oCCR_a <= nt0_7 + nta + ntb;
                            oCCR_b <= nt0_7 + nta;
                            oCCR_c <= nt0_7;
                        end
                        Sector_5: begin
                            oCCR_a <= nt0_7 + nta;
                            oCCR_b <= nt0_7 + nta + ntb;
                            oCCR_c <= nt0_7;
                        end
                        Sector_6: begin
                            oCCR_a <= nt0_7;
                            oCCR_b <= nt0_7 + nta + ntb;
                            oCCR_c <= nt0_7 + nta;
                        end
                        default: ;
                    endcase
                    oCW_done <= 1'b1;
                    state <= S0;
                end
                default: state <= S0;
            endcase
        end
    end
    assign ntemp_a = (ndata_a[14:0] * K)>>15;
    assign ntemp_b = (ndata_b[14:0] * K)>>15;

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

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nmp_en_pre_state <= 1'b0;
        end
        else begin
            nmp_en_pre_state <= iMP_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n)begin
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
                        ncount <= 11'd0;
                        oMP_done <= 1'b0;
                        state <= S0;
                    end
                end
                S1: begin
                    if(ncount == (T>>1)) begin
                        state <= S2;
                    end
                    else begin
                        ncount <= ncount + 1'd1;
                        oMP_done <= 1'b0; 
                    end
                end
                S2: begin
                    if(ncount == 10'd0) begin
                        oMP_done <= 1'b1;
                        state <= S1;
                    end
                    else begin
                        ncount <= ncount - 1'd1;
                        oMP_done <= 1'b0; 
                    end
                end
                default: state <= S0;
            endcase 
        end
    end
    assign oPWM_u = (ncount >= iCCR_a) ? 1'b1:1'b0;
    assign oPWM_v = (ncount >= iCCR_b) ? 1'b1:1'b0;
    assign oPWM_w = (ncount >= iCCR_c) ? 1'b1:1'b0;

endmodule