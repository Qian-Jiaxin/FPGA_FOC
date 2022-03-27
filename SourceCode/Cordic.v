module Cordic(
    iClk,
    iRst_n,
    iCordic_en,
    iTheta,
    oSin,
    oCos,
    oCordic_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iCordic_en;
    input wire [19:0] iTheta;
    output wire signed [15:0] oSin;
    output wire signed [15:0] oCos;
    output wire oCordic_done;

    //状态机
    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b11;
    localparam S3 = 2'b10;

    //上升沿处理寄存器
    reg ncordic_ac_done_pre_state;
    reg ncordic_sp_done_pre_state;
    reg ncordic_ep_done_pre_state;
    reg [2:0] state;

    //例化参数
    reg ncordic_sp_en;
    reg ncordic_ep_en;
    wire [17:0] ntheta_sp;
    wire signed [15:0] nsin_sp;
    wire signed [15:0] ncos_sp;
    wire [1:0] nphase;
    wire ncordic_sp_done;
    wire nconvert_done;
    wire nexplore_done;

    Cordic_Angle_Convert ncordic_angle_convert(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iConvert_en(iCordic_en),
        .iTheta(iTheta),
        .oPhase(nphase),
        .oTheta(ntheta_sp),
        .oConvert_done(nconvert_done)
    );

    Cordic_Single_Phase ncordic_single_phase(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iCordic_sp_en(ncordic_sp_en),
        .iTheta(ntheta_sp),
        .oSin(nsin_sp),
        .oCos(ncos_sp),
        .oCordic_sp_done(ncordic_sp_done)
    );

    Cordic_Explore ncordic_explore(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iExplore_en(ncordic_ep_en),
        .iSin_sp(nsin_sp),
        .iCos_sp(ncos_sp),
        .iPhase(nphase),
        .oSin(oSin),
        .oCos(oCos),
        .oExplore_done(nexplore_done)
    );

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncordic_ac_done_pre_state <= 1'b0;
            ncordic_sp_done_pre_state <= 1'b0;
            ncordic_ep_done_pre_state <= 1'b0;
        end
        else begin
            ncordic_ac_done_pre_state <= nconvert_done;
            ncordic_sp_done_pre_state <= ncordic_sp_done;
            ncordic_ep_done_pre_state <= nexplore_done;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            state <= S0;
            ncordic_sp_en <= 1'b0;
            ncordic_ep_en <= 1'b0;
        end
        else begin
            case (state)
                S0: begin 
                    ncordic_sp_en <= 1'b0;
                    ncordic_ep_en <= 1'b0;
                    state <= S1;
                end
                S1: begin
                    if((!ncordic_ac_done_pre_state) & nconvert_done) begin
                        ncordic_sp_en <= 1'b1;
                        state <= S2;
                    end
                    else begin
                        state <= state;
                    end
                end
                S2: begin
                    if((!ncordic_sp_done_pre_state) & ncordic_sp_done) begin
                        ncordic_ep_en <= 1'b1;
                        state <= S3;
                    end
                    else begin
                        state <= state;
                    end
                end
                S3: begin
                    if((!ncordic_ep_done_pre_state) & nexplore_done) begin
                        state <= S0;
                    end
                    else begin
                        state <= state;
                    end
                end
                default: state <= S0;
            endcase
        end
    end
    assign oCordic_done = nexplore_done;

endmodule

module Cordic_Angle_Convert(
    iClk,
    iRst_n,
    iConvert_en,
    iTheta,
    oTheta,
    oPhase,
    oConvert_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iConvert_en;
    input wire [19:0] iTheta;
    output reg [17:0] oTheta;
    output reg [1:0] oPhase;
    output reg oConvert_done;

    //象限
    // localparam phase_1 = 2'b00;
    // localparam phase_2 = 2'b01;
    // localparam phase_3 = 2'b10;
    // localparam phase_4 = 2'b11;

    reg nconvert_en_pre_state;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nconvert_en_pre_state <= 1'b0;
        end
        else begin
            nconvert_en_pre_state <= iConvert_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oPhase <= 2'b00;
            oTheta <= 18'd0;
            oConvert_done <= 1'b0;
        end
        else if((!nconvert_en_pre_state) & iConvert_en) begin
            oPhase <= iTheta[19:18];
            oTheta <= iTheta[17:0];
            oConvert_done <= 1'b1; 
        end
        else begin
            oConvert_done <= 1'b0;
        end
    end

endmodule

module Cordic_Single_Phase(
    iClk,
    iRst_n,
    iCordic_sp_en,
    iTheta,
    oSin,
    oCos,
    oCordic_sp_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iCordic_sp_en;
    input wire [17:0] iTheta;
    output reg [15:0] oSin;
    output reg [15:0] oCos;
    output reg oCordic_sp_done;

    //特殊角度处理
    localparam rot0 = $signed(18'd131071);
    localparam rot1 = $signed(18'd77376);
    localparam rot2 = $signed(18'd40883);
    localparam rot3 = $signed(18'd20753);
    localparam rot4 = $signed(18'd10416);
    localparam rot5 = $signed(18'd5213);
    localparam rot6 = $signed(18'd2607);
    localparam rot7 = $signed(18'd1303);
    localparam rot8 = $signed(18'd651);
    localparam rot9 = $signed(18'd325);
    localparam rot10 = $signed(18'd163);
    localparam rot11 = $signed(18'd81);
    localparam rot12 = $signed(18'd40);
    localparam rot13 = $signed(18'd20);
    localparam rot14 = $signed(18'd10);
    localparam rot15 = $signed(18'd4);

    //状态机
    localparam S0 = 4'b0000;
    localparam S1 = 4'b0001;
    localparam S2 = 4'b0011;
    localparam S3 = 4'b0010;
    localparam S4 = 4'b0110;
    localparam S5 = 4'b0111;
    localparam S6 = 4'b0101;
    localparam S7 = 4'b0100;
    localparam S8 = 4'b1100;
    localparam S9 = 4'b1101;
    localparam S10 = 4'b1111;
    localparam S11 = 4'b1110;
    localparam S12 = 4'b1010;
    localparam S13 = 4'b1011;
    localparam S14 = 4'b1001;
    localparam S15 = 4'b1000;

    reg ncordic_sp_en_pre_state;
    reg [3:0] state;
    reg signed [15:0] ntemp_cos,ntemp_sin;
    reg signed [22:0] nerror;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncordic_sp_en_pre_state <= 1'b0;
        end
        else begin
            ncordic_sp_en_pre_state <= iCordic_sp_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            state <= S0;
            ntemp_cos <= 16'd0;
            ntemp_sin <= 16'd0;
            nerror <= 23'd0;
            oCos <= 16'd0;
            oSin <= 16'd0;
            oCordic_sp_done <= 1'b0;
        end
        else begin
            case (state)
                S0: begin
                    if((!ncordic_sp_en_pre_state) & iCordic_sp_en) begin
                        nerror <= iTheta;
                        ntemp_cos <= 16'd19897;
                        ntemp_sin <= 16'd0;
                        state <= S1;
                    end
                    else begin
                        ntemp_cos <= 16'd0;
                        ntemp_sin <= 16'd0;
                        oCordic_sp_done <= 1'b0;
                        state <= state;
                    end
                end
                S1: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>0)) : (ntemp_cos - (ntemp_sin>>>0));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>0)) : (ntemp_sin + (ntemp_cos>>>0));
                    nerror <= nerror[22] ? (nerror + rot0) : (nerror - rot0);
                    state <= S2;
                end
                S2: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>1)) : (ntemp_cos - (ntemp_sin>>>1));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>1)) : (ntemp_sin + (ntemp_cos>>>1));
                    nerror <= nerror[22] ? (nerror + rot1) : (nerror - rot1);
                    state <= S3;
                end
                S3: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>2)) : (ntemp_cos - (ntemp_sin>>>2));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>2)) : (ntemp_sin + (ntemp_cos>>>2));
                    nerror <= nerror[22] ? (nerror + rot2) : (nerror - rot2);
                    state <= S4;
                end
                S4: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>3)) : (ntemp_cos - (ntemp_sin>>>3));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>3)) : (ntemp_sin + (ntemp_cos>>>3));
                    nerror <= nerror[22] ? (nerror + rot3) : (nerror - rot3);
                    state <= S5;
                end
                S5: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>4)) : (ntemp_cos - (ntemp_sin>>>4));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>4)) : (ntemp_sin + (ntemp_cos>>>4));
                    nerror <= nerror[22] ? (nerror + rot4) : (nerror - rot4);
                    state <= S6;
                end
                S6: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>5)) : (ntemp_cos - (ntemp_sin>>>5));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>5)) : (ntemp_sin + (ntemp_cos>>>5));
                    nerror <= nerror[22] ? (nerror + rot5) : (nerror - rot5);
                    state <= S7;
                end
                S7: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>6)) : (ntemp_cos - (ntemp_sin>>>6));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>6)) : (ntemp_sin + (ntemp_cos>>>6));
                    nerror <= nerror[22] ? (nerror + rot6) : (nerror - rot6);
                    state <= S8;
                end
                S8: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>7)) : (ntemp_cos - (ntemp_sin>>>7));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>7)) : (ntemp_sin + (ntemp_cos>>>7));
                    nerror <= nerror[22] ? (nerror + rot7) : (nerror - rot7);
                    state <= S9;
                end
                S9: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>8)) : (ntemp_cos - (ntemp_sin>>>8));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>8)) : (ntemp_sin + (ntemp_cos>>>8));
                    nerror <= nerror[22] ? (nerror + rot8) : (nerror - rot8);
                    state <= S10;
                end
                S10: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>9)) : (ntemp_cos - (ntemp_sin>>>9));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>9)) : (ntemp_sin + (ntemp_cos>>>9));
                    nerror <= nerror[22] ? (nerror + rot9) : (nerror - rot9);
                    state <= S11;
                end
                S11: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>10)) : (ntemp_cos - (ntemp_sin>>>10));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>10)) : (ntemp_sin + (ntemp_cos>>>10));
                    nerror <= nerror[22] ? (nerror + rot10) : (nerror - rot10);
                    state <= S12;
                end
                S12: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>11)) : (ntemp_cos - (ntemp_sin>>>11));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>11)) : (ntemp_sin + (ntemp_cos>>>11));
                    nerror <= nerror[22] ? (nerror + rot11) : (nerror - rot11);
                    state <= S13;
                end
                S13: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>12)) : (ntemp_cos - (ntemp_sin>>>12));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>12)) : (ntemp_sin + (ntemp_cos>>>12));
                    nerror <= nerror[22] ? (nerror + rot12) : (nerror - rot12);
                    state <= S14;
                end
                S14: begin
                    ntemp_cos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>13)) : (ntemp_cos - (ntemp_sin>>>13));
                    ntemp_sin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>13)) : (ntemp_sin + (ntemp_cos>>>13));
                    nerror <= nerror[22] ? (nerror + rot13) : (nerror - rot13);
                    state <= S15;
                end
                S15: begin
                    oCos <= nerror[22] ? (ntemp_cos + (ntemp_sin>>>14)) : (ntemp_cos - (ntemp_sin>>>14));
                    oSin <= nerror[22] ? (ntemp_sin - (ntemp_cos>>>14)) : (ntemp_sin + (ntemp_cos>>>14));
                    oCordic_sp_done <= 1'b1;
                    state <= S0;
                end
                default: state <= S0;
            endcase
        end
    end
endmodule

module Cordic_Explore(
    iClk,
    iRst_n,
    iExplore_en,
    iSin_sp,
    iCos_sp,
    iPhase,
    oSin,
    oCos,
    oExplore_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iExplore_en;
    input wire signed [15:0] iSin_sp;
    input wire signed [15:0] iCos_sp;
    input wire [1:0] iPhase;
    output reg signed [15:0] oSin;
    output reg signed [15:0] oCos;
    output reg oExplore_done;

    //象限
    localparam phase_1 = 2'b00;
    localparam phase_2 = 2'b01;
    localparam phase_3 = 2'b10;
    localparam phase_4 = 2'b11;

    reg nexplore_en_pre_state;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nexplore_en_pre_state <= 1'b0;
        end
        else begin
            nexplore_en_pre_state <= iExplore_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oSin <= 16'd0;
            oCos <= 16'd0;
            oExplore_done <= 1'b0;
        end
        else if((!nexplore_en_pre_state) & iExplore_en) begin
            case (iPhase)
                phase_1: begin
                    oSin <= iSin_sp;
                    oCos <= iCos_sp;
                end
                phase_2: begin
                    oSin <= iCos_sp;
                    oCos <= 16'd0 - iSin_sp;
                end
                phase_3: begin
                    oSin <= 16'd0 - iSin_sp;
                    oCos <= 16'd0 - iCos_sp;
                end
                phase_4: begin
                    oSin <= 16'd0 - iCos_sp;
                    oCos <= iSin_sp;
                end
                default: ;
            endcase
            oExplore_done <= 1'b1;
        end
        else begin
            oExplore_done <= 1'b0;
        end
    end
endmodule
