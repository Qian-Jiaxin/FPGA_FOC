module NIKON(
    iClk,	//100M
    iRst_n,
    iRd_en,
    iRx,
    oDir,
    oTx,
    oRd_data_st,
    oRd_data_mt,
    oRd_warning,
    oRd_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iRd_en;
    input wire iRx;
    output reg oDir;
    output wire oTx;
    output reg [19:0] oRd_data_st;
    output reg [15:0] oRd_data_mt;
    output reg oRd_warning;
    output reg oRd_done;

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;
    localparam S3 = 2'd3;

    reg ntrans_en;
    reg nrd_en_pre_state;
    reg ntrans_done_pre_state,nrece_done_pre_state,ncheck_done_pre_state;
    reg [1:0] nstate;
    wire npll_locked;
    wire ntrans_done,nrece_done,ncheck_done;
    wire [63:0] nrece_data;
    wire [7:0] ncrc;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nrd_en_pre_state <= 1'b0;
            ntrans_done_pre_state <= 1'b0;
            nrece_done_pre_state <= 1'b0;
            ncheck_done_pre_state <= 1'b0;
        end
        else begin
            nrd_en_pre_state <= iRd_en;
            ntrans_done_pre_state <= ntrans_done; 
            nrece_done_pre_state <= nrece_done;
            ncheck_done_pre_state <= ncheck_done;
        end
    end
    
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ntrans_en <= 1'b0;
            nstate <= S0;
            oDir <= 1'b1;
            oRd_data_st <= 20'd0;
            oRd_data_mt <= 16'd0;
            oRd_warning <= 1'b0;
            oRd_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!nrd_en_pre_state) & iRd_en) begin
                        ntrans_en <=1'b1; 
                        nstate <= S1;
                        oDir <= 1'b1;
                    end
                    else begin
                        nstate <= nstate;
                        oRd_done <= 1'b0; 
                    end
                end
                S1: begin
                    if((!ntrans_done_pre_state) & ntrans_done) begin
                        nstate <= S2;
                        oDir <= 1'b0;
                    end
                    else begin
                        nstate <= nstate;
                        ntrans_en <=1'b0;
                    end
                end
                S2: begin
                    if((!nrece_done_pre_state) & nrece_done) begin
                        nstate <= S3;
                    end
                    else begin
                        nstate <= nstate;
                    end
                end
                S3: begin
                    if((!ncheck_done_pre_state) & ncheck_done) begin
                        if(ncrc == nrece_data[7:0]) begin
                            {oRd_data_st[0],oRd_data_st[1],oRd_data_st[2],oRd_data_st[3],oRd_data_st[4],oRd_data_st[5],oRd_data_st[6],oRd_data_st[7],oRd_data_st[8],oRd_data_st[9],oRd_data_st[10],oRd_data_st[11],oRd_data_st[12],oRd_data_st[13],oRd_data_st[14],oRd_data_st[15],oRd_data_st[16],oRd_data_st[17],oRd_data_st[18],oRd_data_st[19]} <= nrece_data[47:28];
                            {oRd_data_mt[0],oRd_data_mt[1],oRd_data_mt[2],oRd_data_mt[3],oRd_data_mt[4],oRd_data_mt[5],oRd_data_mt[6],oRd_data_mt[7],oRd_data_mt[8],oRd_data_mt[9],oRd_data_mt[10],oRd_data_mt[11],oRd_data_mt[12],oRd_data_mt[13],oRd_data_mt[14],oRd_data_mt[15]} <= nrece_data[27:12];
                            oRd_warning <= 1'b0;
                        end
                        else begin
                            oRd_data_st <= 20'd0;
                            oRd_data_mt <= 16'd0;
                            oRd_warning <= 1'b1;
                        end
                        nstate <= S0;
                        oRd_done <= 1'b1;
                    end
                    else begin
                        nstate <= nstate;
                    end
                end
                default: nstate <= S0;
            endcase
        end
    end
    
    NIKON_DATA_TRANS nikon_data_trans(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iTrans_en(ntrans_en),
        .oTx(oTx),
        .oTrans_done(ntrans_done)
    );

    NIKON_DATA_RECE nikon_data_rece(
        .iClk(iClk),
        .iRst_n(iRst_n),
        // .iRece_en(),
        .iRx(iRx),
        .oRece_data(nrece_data),
        .oRece_done(nrece_done)
    );

    NIKON_DATA_CHECK nikon_data_check(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iCheck_en(nrece_done),
        .iCheck_data(nrece_data[63:8]),
        .oCRC(ncrc),
        .oCheck_done(ncheck_done)
    );
    
endmodule

module NIKON_DATA_TRANS(
    iClk,
    iRst_n,
    iTrans_en,
    oTx,
    oTrans_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iTrans_en;
    output reg oTx;
    output reg oTrans_done;

    localparam STARTBIT = 1'b0;
    localparam SINKCODE = 3'b010;
    localparam FRAMECODE = 2'b00;
    localparam ENCODERADDRESS = 3'b000; //default EAX
    localparam COMMANDCODE = 5'b00000;
    localparam CRC = 3'b000;
    localparam STOPBIT_IDLE = 1'b1;

    localparam S0 = 5'd0;
    localparam S1 = 5'd1;
    localparam S2 = 5'd2;
    localparam S3 = 5'd3;
    localparam S4 = 5'd4;
    localparam S5 = 5'd5;
    localparam S6 = 5'd6;
    localparam S7 = 5'd7;
    localparam S8 = 5'd8;
    localparam S9 = 5'd9;
    localparam S10 = 5'd10;
    localparam S11 = 5'd11;
    localparam S12 = 5'd12;
    localparam S13 = 5'd13;
    localparam S14 = 5'd14;
    localparam S15 = 5'd15;
    localparam S16 = 5'd16;
    localparam S17 = 5'd17;
    localparam S18 = 5'd18;
    localparam S19 = 5'd19;

    reg ntrans_en_pre_state;
    reg ntrans_working;
    reg [4:0] nstate;
    reg [5:0] ncount;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ntrans_en_pre_state <= 1'b0; 
        end
        else begin
            ntrans_en_pre_state <= iTrans_en; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncount <= 6'd0; 
        end
        else if(ntrans_working) begin
            if(ncount == 6'd39) begin
                ncount <= 6'd0; 
            end
            else begin
                ncount <= ncount + 1'd1; 
            end
        end
        else begin
            ncount <= 6'd0; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ntrans_working <= 1'b0;
            nstate <= S0;
            oTx <= STOPBIT_IDLE;
            oTrans_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ntrans_en_pre_state) & iTrans_en) begin
                        ntrans_working <= 1'b1;
                        nstate <= S1;
                        oTx <= STARTBIT;
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= STOPBIT_IDLE;
                        oTrans_done <= 1'b0;
                    end
                end
                S1: begin
                    if(ncount == 6'd39) begin
                        nstate <= S2;
                        oTx <= SINKCODE[0];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S2: begin
                    if(ncount == 6'd39) begin
                        nstate <= S3;
                        oTx <= SINKCODE[1];
                    end
                    else begin
                        nstate <= nstate; 
                        oTx <= oTx;
                    end
                end
                S3: begin
                    if(ncount == 6'd39) begin
                        nstate <= S4;
                        oTx <= SINKCODE[2];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S4: begin
                    if(ncount == 6'd39) begin
                        nstate <= S5;
                        oTx <= FRAMECODE[0];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S5: begin
                    if(ncount == 6'd39) begin
                        nstate <= S6;
                        oTx <= FRAMECODE[1];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S6: begin
                    if(ncount == 6'd39) begin
                        nstate <= S7;
                        oTx <= ENCODERADDRESS[0];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S7: begin
                    if(ncount == 6'd39) begin
                        nstate <= S8;
                        oTx <= ENCODERADDRESS[1];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S8: begin
                    if(ncount == 6'd39) begin
                        nstate <= S9;
                        oTx <= ENCODERADDRESS[2];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S9: begin
                    if(ncount == 6'd39) begin
                        nstate <= S10;
                        oTx <= COMMANDCODE[0];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S10: begin
                    if(ncount == 6'd39) begin
                        nstate <= S11;
                        oTx <= COMMANDCODE[1];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S11: begin
                    if(ncount == 6'd39) begin
                        nstate <= S12;
                        oTx <= COMMANDCODE[2];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S12: begin
                    if(ncount == 6'd39) begin
                        nstate <= S13;
                        oTx <= COMMANDCODE[3];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S13: begin
                    if(ncount == 6'd39) begin
                        nstate <= S14;
                        oTx <= COMMANDCODE[4];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S14: begin
                    if(ncount == 6'd39) begin
                        nstate <= S15;
                        oTx <= CRC[0];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S15: begin
                    if(ncount == 6'd39) begin
                        nstate <= S16;
                        oTx <= CRC[1];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S16: begin
                    if(ncount == 6'd39) begin
                        nstate <= S17;
                        oTx <= CRC[2];
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx;
                    end
                end
                S17: begin
                    if(ncount == 6'd39) begin
                        nstate <= S18;
                        oTx <= STOPBIT_IDLE; 
                    end
                    else begin
                        nstate <= nstate;
                        oTx <= oTx; 
                    end
                end
                S18: begin
                    if(ncount == 6'd39) begin
                        nstate <= S0;
                        ntrans_working <= 1'b0;
                        oTrans_done <= 1'b1;
                    end
                    else begin
                        nstate <= nstate;
                    end
                end
                default: nstate <= S0;
            endcase 
        end
    end

endmodule

module NIKON_DATA_RECE(
    iClk,
    iRst_n,
    // iRece_en,
    iRx,
    oRece_data,
    oRece_done
);
    input wire iClk;
    input wire iRst_n;
    // input wire iRece_en;
    input wire iRx;
    output reg [63:0] oRece_data;
    output reg oRece_done;

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;
    localparam S3 = 2'd3;

    reg nrx_sync_0,nrx_sync_1;
    reg nrece_cell_done_pre_state;
    reg [1:0] nstate;
    reg [63:0] nrece_temp_data;
    wire [15:0] nrece_cell_data;
    wire nrece_cell_done;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nrx_sync_0 <= 1'b0;
            nrx_sync_1 <= 1'b0;
        end
        else begin
            nrx_sync_0 <= iRx;
            nrx_sync_1 <= nrx_sync_0; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nrece_cell_done_pre_state <= 1'b0; 
        end
        else begin
            nrece_cell_done_pre_state <= nrece_cell_done;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nstate <= S0;
            nrece_temp_data <= 64'd0;
            oRece_data <= 64'd0;
            oRece_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!nrece_cell_done_pre_state) & nrece_cell_done) begin
                        nstate <= S1;
                        nrece_temp_data <= nrece_cell_data;
                    end
                    else begin
                        nstate <= nstate;
                        nrece_temp_data <= 64'd0;
                        oRece_done <= 1'b0;
                    end
                end 
                S1: begin
                    if((!nrece_cell_done_pre_state) & nrece_cell_done) begin
                        nstate <= S2;
                        nrece_temp_data <= (nrece_temp_data<<16) | nrece_cell_data;
                    end
                    else begin
                        nstate <= nstate;
                        nrece_temp_data <= nrece_temp_data;
                    end
                end
                S2: begin
                    if((!nrece_cell_done_pre_state) & nrece_cell_done) begin
                        nstate <= S3;
                        nrece_temp_data <= (nrece_temp_data<<16) | nrece_cell_data;
                    end
                    else begin
                        nstate <= nstate;
                        nrece_temp_data <= nrece_temp_data;
                    end
                end
                S3: begin
                    if((!nrece_cell_done_pre_state) & nrece_cell_done) begin
                        nstate <= S0;
                        oRece_data <= (nrece_temp_data<<16) | nrece_cell_data;
                        oRece_done <= 1'b1;
                    end
                    else begin
                        nstate <= nstate;
                        nrece_temp_data <= nrece_temp_data;
                    end
                end
                default: nstate <= S0;
            endcase 
        end
    end

    NIKON_DATA_RECE_CELL nikon_data_rece_cell(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iRx(nrx_sync_1),
        .oRece_cell_data(nrece_cell_data),
        .oRece_cell_done(nrece_cell_done)
    );
endmodule

module NIKON_DATA_RECE_CELL(
    iClk,
    iRst_n,
    iRx,
    oRece_cell_data,
    oRece_cell_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iRx;
    output reg [15:0] oRece_cell_data;
    output reg oRece_cell_done;

    localparam S0 = 5'd0;
    localparam S1 = 5'd1;
    localparam S2 = 5'd2;
    localparam S3 = 5'd3;
    localparam S4 = 5'd4;
    localparam S5 = 5'd5;
    localparam S6 = 5'd6;
    localparam S7 = 5'd7;
    localparam S8 = 5'd8;
    localparam S9 = 5'd9;
    localparam S10 = 5'd10;
    localparam S11 = 5'd11;
    localparam S12 = 5'd12;
    localparam S13 = 5'd13;
    localparam S14 = 5'd14;
    localparam S15 = 5'd15;
    localparam S16 = 5'd16;
    localparam S17 = 5'd17;
    localparam S18 = 5'd18;
    localparam S19 = 5'd19;

    reg nrx_pre_state;
    reg ncountworking;
    reg [2:0] noversampling[18:0];
    reg [4:0] nstate;
    reg [5:0] ncount;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nrx_pre_state <= 1'b0;
        end
        else begin
            nrx_pre_state <= iRx;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncount <= 6'd0; 
        end
        else if(ncountworking) begin
            if(ncount == 6'd39) begin
                ncount <= 6'd0;
            end
            else begin
                ncount <= ncount + 1'd1; 
            end
        end
        else begin
            ncount <= 6'd0; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncountworking <= 1'b0;
            nstate <= S0;
            noversampling[0] <= 3'd0;
            noversampling[1] <= 3'd0;
            noversampling[2] <= 3'd0;
            noversampling[3] <= 3'd0;
            noversampling[4] <= 3'd0;
            noversampling[5] <= 3'd0;
            noversampling[6] <= 3'd0;
            noversampling[7] <= 3'd0;
            noversampling[8] <= 3'd0;
            noversampling[9] <= 3'd0;
            noversampling[10] <= 3'd0;
            noversampling[11] <= 3'd0;
            noversampling[12] <= 3'd0;
            noversampling[13] <= 3'd0;
            noversampling[14] <= 3'd0;
            oRece_cell_data <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if(nrx_pre_state & (!iRx)) begin
                        ncountworking <= 1'b1;
                        nstate <= S1;
                    end
                    else begin
                        ncountworking <= 1'b0;
                        nstate <= nstate;
                        noversampling[0] <= 3'd0;
                        noversampling[1] <= 3'd0;
                        noversampling[2] <= 3'd0;
                        noversampling[3] <= 3'd0;
                        noversampling[4] <= 3'd0;
                        noversampling[5] <= 3'd0;
                        noversampling[6] <= 3'd0;
                        noversampling[7] <= 3'd0;
                        noversampling[8] <= 3'd0;
                        noversampling[9] <= 3'd0;
                        noversampling[10] <= 3'd0;
                        noversampling[11] <= 3'd0;
                        noversampling[12] <= 3'd0;
                        noversampling[13] <= 3'd0;
                        noversampling[14] <= 3'd0;
                        noversampling[15] <= 3'd0;
                        noversampling[16] <= 3'd0;
                        oRece_cell_done <= 1'b0;
                    end
                end 
                S1: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[0] <= noversampling[0] + nrx_pre_state;
                        end
                        6'd24: begin
                            nstate <= (noversampling[0] <= 3'd3) ? nstate:S0;
                        end
                        6'd38: begin
                            nstate <= S2;
                        end
                        default: ;
                    endcase 
                end
                S2: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[1] <= noversampling[1] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S3;
                            oRece_cell_data[15] <= (noversampling[1] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S3: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[2] <= noversampling[2] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S4;
                            oRece_cell_data[14] <= (noversampling[2] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S4: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[3] <= noversampling[3] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S5;
                            oRece_cell_data[13] <= (noversampling[3] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S5: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[4] <= noversampling[4] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S6;
                            oRece_cell_data[12] <= (noversampling[4] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S6: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[5] <= noversampling[5] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S7;
                            oRece_cell_data[11] <= (noversampling[5] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S7: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[6] <= noversampling[6] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S8;
                            oRece_cell_data[10] <= (noversampling[6] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S8: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[7] <= noversampling[7] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S9;
                            oRece_cell_data[9] <= (noversampling[7] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S9: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[8] <= noversampling[8] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S10;
                            oRece_cell_data[8] <= (noversampling[8] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S10: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[9] <= noversampling[9] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S11;
                            oRece_cell_data[7] <= (noversampling[9] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S11: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[10] <= noversampling[10] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S12;
                            oRece_cell_data[6] <= (noversampling[10] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S12: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[11] <= noversampling[11] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S13;
                            oRece_cell_data[5] <= (noversampling[11] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S13: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[12] <= noversampling[12] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S14;
                            oRece_cell_data[4] <= (noversampling[12] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S14: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[13] <= noversampling[13] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S15;
                            oRece_cell_data[3] <= (noversampling[13] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S15: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[14] <= noversampling[14] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S16;
                            oRece_cell_data[2] <= (noversampling[14] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S16: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[15] <= noversampling[15] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S17;
                            oRece_cell_data[1] <= (noversampling[15] <= 3'd3) ? 1'b0:1'b1;
                        end
                        default: ;
                    endcase 
                end
                S17: begin
                    case (ncount)
                        6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23: begin
                            noversampling[16] <= noversampling[16] + nrx_pre_state;
                        end
                        6'd38: begin
                            nstate <= S0;
                            oRece_cell_data[0] <= (noversampling[16] <= 3'd3) ? 1'b0:1'b1;
                            oRece_cell_done <= 1'b1;
                        end
                        default: ;
                    endcase 
                end
                default: nstate <= S0;
            endcase 
        end
    end

endmodule

module NIKON_DATA_CHECK(
    iClk,
    iRst_n,
    iCheck_en,
    iCheck_data,
    oCRC,
    oCheck_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iCheck_en;
    input wire [55:0] iCheck_data;
    output reg [7:0] oCRC;
    output reg oCheck_done;

    localparam S0 = 1'd0;
    localparam S1 = 1'd1;

    reg nstate;
    reg ncheck_en_pre_state;
    reg [5:0] ncount;
    reg [55:0] ncheck_data;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncheck_en_pre_state <= 1'b0;
        end 
        else begin
            ncheck_en_pre_state <= iCheck_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncount <= 6'd0;
            nstate <= S0;
            oCheck_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncheck_en_pre_state) & iCheck_en) begin
                        nstate <= S1;
                    end
                    else begin
                        ncount <= 6'd0;
                        nstate <= nstate;
                        oCheck_done <= 1'b0;
                    end
                end
                S1: begin
                    if(ncount == 6'd57) begin
                        nstate <= S0;
                        oCheck_done <= 1'b1;
                    end
                    else begin
                        ncount <= ncount + 1'b1; 
                    end
                end
                default: nstate <= S0;
            endcase
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncheck_data <= 56'd0;
            oCRC <= 8'd0;
        end
        else begin
           case (ncount)
               6'd0: begin
                    ncheck_data <= iCheck_data;
               end
               6'd57: begin
                    oCRC <= ncheck_data[55:48];
               end
               default: begin
                    if(ncheck_data[55] == 1'b0)
                        ncheck_data <= ncheck_data << 1;
                    else
                        ncheck_data <= ({ncheck_data[55:47] ^ 9'h11D, ncheck_data[46:0]}) << 1;
               end
           endcase 
        end 
    end

endmodule