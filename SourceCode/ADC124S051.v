module ADC124S051(
    iClk,//100M
    iRst_n,
    iAcquire_en,
    iMISO,
    oCS_n,
    oSCLK,
    oMOSI,
    oIu,
    oIv,
    oUu,
    oUv,
    oAcquire_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iAcquire_en;
    input wire iMISO;
    output wire oCS_n;
    output wire oSCLK;
    output wire oMOSI;
    output reg [11:0] oIu,oIv,oUu,oUv;
    output reg oAcquire_done;

    localparam ADDR0 = 2'b00;
    localparam ADDR1 = 2'b01;
    localparam ADDR2 = 2'b10;
    localparam ADDR3 = 2'b11;

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b011;
    localparam S3 = 3'b010;
    localparam S4 = 3'b110;
    localparam S5 = 3'b100;
    localparam S6 = 3'b101;
    localparam S7 = 3'b111;

    reg nacquire_en_pre_state,nrd_done_pre_state;
    reg nrd_en;
    reg [1:0] naddr;
    wire [11:0] ndata;
    reg [2:0] nstate;
    wire nrd_done;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nacquire_en_pre_state <= 1'b0;
            nrd_done_pre_state <= 1'b0;
        end
        else begin
            nacquire_en_pre_state <= iAcquire_en; 
            nrd_done_pre_state <= nrd_done;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin 
            nrd_en <= 1'b0;
            nstate <= S0;
            oIu <= 12'd0;
            oIv <= 12'd0;
            oUu <= 12'd0;
            oUv <= 12'd0;
            oAcquire_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    nstate <= S1;
                    oAcquire_done <= 1'b0;
                end
                S1: begin
                    if((!nacquire_en_pre_state) & iAcquire_en) begin
                        naddr <= ADDR0;
                        nrd_en <= 1'b1;
                        nstate <= S2;
                    end 
                    else begin
                        nrd_en <= 1'b0;
                        nstate <= nstate;
                    end
                end
                S2: begin
                    if(nrd_done_pre_state & (!nrd_done)) begin
                        oUv <= ndata;
                        naddr <= ADDR1;
                        nrd_en <= 1'b1;
                        nstate <= S3;
                    end
                    else begin
                        nrd_en <= 1'b0;
                        nstate <= nstate;
                    end
                end
                S3: begin
                    if(nrd_done_pre_state & (!nrd_done)) begin
                        oUu <= ndata;
                        naddr <= ADDR2;
                        nrd_en <= 1'b1;
                        nstate <= S4;
                    end
                    else begin
                        nrd_en <= 1'b0;
                        nstate <= nstate;
                    end
                end
                S4: begin
                    if(nrd_done_pre_state & (!nrd_done)) begin
                        oIv <= ndata;
                        naddr <= ADDR3;
                        nrd_en <= 1'b1;
                        nstate <= S5;
                    end
                    else begin
                        nrd_en <= 1'b0;
                        nstate <= nstate;
                    end
                end
                S5: begin
                    if(nrd_done_pre_state & (!nrd_done)) begin
                        oIu <= ndata;
                        nrd_en <= 1'b0;
                        nstate <= S0;
                        oAcquire_done <= 1'b1;
                    end
                    else begin
                        nrd_en <= 1'b0;
                        nstate <= nstate;
                    end
                end
                default: nstate <= S0;
            endcase
        end
    end

    ADC124S051_SPI_READ_ONEPORT adc124s051_spi_read_oneport(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .iRd_en(nrd_en),
        .iADDR(naddr),
        .iMISO(iMISO),
        .oCS_n(oCS_n),
        .oSCLK(oSCLK),
        .oMOSI(oMOSI),
        .oData(ndata),
        .oRd_done(nrd_done)
    );

endmodule

module ADC124S051_SPI_READ_ONEPORT(
    iClk,
    iRst_n,
    iRd_en,
    iADDR,
    iMISO,
    oCS_n,
    oSCLK,
    oMOSI,
    oData,
    oRd_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iRd_en;
    input wire [1:0] iADDR;
    input wire iMISO;
    output wire oCS_n;
    output reg oSCLK;   //5M
    output reg oMOSI;
    output reg  [11:0] oData;
    output reg oRd_done;

    localparam DONTCARE_BIT = 1'b0;

    reg nrd_en_pre_state;
    reg nworking;
    reg [4:0] nsclk_gen_count;
    reg [4:0] nsclk_count;
    reg [2:0] ntemp_0,ntemp_1,ntemp_2,ntemp_3,ntemp_4,ntemp_5,ntemp_6,ntemp_7,ntemp_8,ntemp_9,ntemp_10,ntemp_11;

    assign oCS_n = !nworking;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nrd_en_pre_state <= 1'b0;
        end
        else begin
            nrd_en_pre_state <= iRd_en; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nworking <= 1'b0;
        end
        else begin
           if((!nrd_en_pre_state) & iRd_en) begin
                nworking <= 1'b1;
           end
           else if(oRd_done) begin
            nworking <= 1'b0; 
           end
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nsclk_gen_count <= 5'd0;
        end
        else if(nworking) begin
            if(nsclk_gen_count == 5'd19) begin
                nsclk_gen_count <= 5'd0; 
            end
            else begin
                nsclk_gen_count <= nsclk_gen_count + 1'd1; 
            end
        end
        else begin
            nsclk_gen_count <= 5'd0;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nsclk_count <= 5'd0;
        end
        else if(nworking) begin
            if(nsclk_gen_count == 5'd19) begin
                nsclk_count <= nsclk_count + 1'd1;
            end
        end
        else begin
            nsclk_count <= 5'd0; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oRd_done <= 1'b0;
        end
        else if(nsclk_count == 5'd16) begin
            oRd_done <= 1'b1; 
        end
        else begin
            oRd_done <= 1'b0; 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oSCLK <= 1'b1; 
        end
        else if(nworking) begin
            if(nsclk_gen_count == 5'd9) begin
                oSCLK <= 1'b0; 
            end 
            else if(nsclk_gen_count == 5'd19) begin
                oSCLK <= 1'b1; 
            end
            else begin
                oSCLK <= oSCLK; 
            end
        end
        else begin
            oSCLK <= 1'b1; 
        end
    end

    //trans
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            oMOSI <= DONTCARE_BIT;
        end
        else if(nworking) begin
            if(nsclk_gen_count == 5'd9) begin
                case (nsclk_count)
                    4'd0: oMOSI <= DONTCARE_BIT; 
                    4'd1: oMOSI <= DONTCARE_BIT; 
                    4'd2: oMOSI <= DONTCARE_BIT; 
                    4'd3: oMOSI <= iADDR[1]; 
                    4'd4: oMOSI <= iADDR[0]; 
                    4'd5: oMOSI <= DONTCARE_BIT; 
                    4'd6: oMOSI <= DONTCARE_BIT; 
                    4'd7: oMOSI <= DONTCARE_BIT; 
                    default: ;
                endcase
            end
            else begin
                oMOSI <= oMOSI; 
            end
        end
        else begin
            oMOSI <= DONTCARE_BIT;
        end
    end

    //rece
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin 
            ntemp_0 <= 3'd0;
            ntemp_1 <= 3'd0;
            ntemp_2 <= 3'd0;
            ntemp_3 <= 3'd0;
            ntemp_4 <= 3'd0;
            ntemp_5 <= 3'd0;
            ntemp_6 <= 3'd0;
            ntemp_7 <= 3'd0;
            ntemp_8 <= 3'd0;
            ntemp_9 <= 3'd0;
            ntemp_10 <= 3'd0;
            ntemp_11 <= 3'd0;
            oData <= 12'd0;
        end
        else if(nworking) begin
            if((nsclk_gen_count > 5'd10) & (nsclk_gen_count < 5'd18)) begin
                case (nsclk_count)
                    4'd4: ntemp_11 <= ntemp_11 + iMISO;
                    4'd5: ntemp_10 <= ntemp_10 + iMISO;
                    4'd6: ntemp_9 <= ntemp_9 + iMISO;
                    4'd7: ntemp_8 <= ntemp_8 + iMISO;
                    4'd8: ntemp_7 <= ntemp_7 + iMISO;
                    4'd9: ntemp_6 <= ntemp_6 + iMISO;
                    4'd10: ntemp_5 <= ntemp_5 + iMISO;
                    4'd11: ntemp_4 <= ntemp_4 + iMISO;
                    4'd12: ntemp_3 <= ntemp_3 + iMISO;
                    4'd13: ntemp_2 <= ntemp_2 + iMISO;
                    4'd14: ntemp_1 <= ntemp_1 + iMISO;
                    4'd15: ntemp_0 <= ntemp_0 + iMISO;
                    default: ;
                endcase
            end
            else if(nsclk_gen_count == 5'd19) begin
                oData[11] <= (ntemp_11 >= 3'd4) ? 1'b1:1'b0;
                oData[10] <= (ntemp_10 >= 3'd4) ? 1'b1:1'b0;
                oData[9] <= (ntemp_9 >= 3'd4) ? 1'b1:1'b0;
                oData[8] <= (ntemp_8 >= 3'd4) ? 1'b1:1'b0;
                oData[7] <= (ntemp_7 >= 3'd4) ? 1'b1:1'b0;
                oData[6] <= (ntemp_6 >= 3'd4) ? 1'b1:1'b0;
                oData[5] <= (ntemp_5 >= 3'd4) ? 1'b1:1'b0;
                oData[4] <= (ntemp_4 >= 3'd4) ? 1'b1:1'b0;
                oData[3] <= (ntemp_3 >= 3'd4) ? 1'b1:1'b0;
                oData[2] <= (ntemp_2 >= 3'd4) ? 1'b1:1'b0;
                oData[1] <= (ntemp_1 >= 3'd4) ? 1'b1:1'b0;
                oData[0] <= (ntemp_0 >= 3'd4) ? 1'b1:1'b0;
            end
        end
        else begin
            ntemp_0 <= 3'd0;
            ntemp_1 <= 3'd0;
            ntemp_2 <= 3'd0;
            ntemp_3 <= 3'd0;
            ntemp_4 <= 3'd0;
            ntemp_5 <= 3'd0;
            ntemp_6 <= 3'd0;
            ntemp_7 <= 3'd0;
            ntemp_8 <= 3'd0;
            ntemp_9 <= 3'd0;
            ntemp_10 <= 3'd0;
            ntemp_11 <= 3'd0;
        end
    end

endmodule
