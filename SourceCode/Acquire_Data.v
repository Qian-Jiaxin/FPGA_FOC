module Acquire_Data(
    iClk,
    iRst_n,
    iAC_en,
    //编码器RS485通信
    iRx,
    oDir,
    oTx,
    //模数转换器SPI通信

    //数据输出
    oTheta_elec,
    oAC_warning
);

    input wire iClk;
    input wire iRst_n;
    input wire iAC_en;
    input wire iRx;
    output wire oDir;
    output wire oTx;
    output reg [19:0] oTheta_elec;
    output wire [1:0]oAC_warning;

    localparam POLE_PAIRS = 3'd5;
    localparam SPECIAL_ANGLE = 20'd1048575;

    localparam S0 = 1'd0;
    localparam S1 = 1'd1;

    reg nstate_cal_theta;
    reg [22:0] ntheta_elec_temp;
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
            nstate_cal_theta <= S0;
            ntheta_elec_temp <= 23'd0;
            oTheta_elec <= 20'd0;
        end
        else begin
            case (nstate_cal_theta)
                S0: begin
                    if((!nnikon_rd_done_pre_state) & nnikon_rd_done) begin
                        ntheta_elec_temp <= nrd_data_st * POLE_PAIRS;
                        nstate_cal_theta <= S1;
                    end
                    else begin
                        nstate_cal_theta <= nstate_cal_theta; 
                    end
                end
                S1: begin
                    oTheta_elec <= SPECIAL_ANGLE - ntheta_elec_temp[19:0];
                    nstate_cal_theta <= S0; 
                end
                default: nstate_cal_theta <= S0;
            endcase 
        end
    end


endmodule