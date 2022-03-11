module ADC121S051(
    iClk,//100M
    iRst_n,
    iAcquire_en,
    iMISO,
    oCS_n,
    oSCLK,
    oUbus,
    oAcquire_done
);
    input wire iClk;
    input wire iRst_n;
    input wire iAcquire_en;
    input wire iMISO;
    output wire oCS_n;
    output reg oSCLK;
    output reg [11:0] oUbus;
    output reg oAcquire_done;

    reg nacquire_en_pre_state,nacquire_done_pre_state;
    reg nworking;
    reg [4:0] nsclk_gen_count;
    reg [4:0] nsclk_count;
    reg [2:0] ntemp_0,ntemp_1,ntemp_2,ntemp_3,ntemp_4,ntemp_5,ntemp_6,ntemp_7,ntemp_8,ntemp_9,ntemp_10,ntemp_11;

    assign oCS_n = !nworking;

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nacquire_en_pre_state <= 1'b0;
            nacquire_done_pre_state <= 1'b0;
        end 
        else begin
            nacquire_en_pre_state <= iAcquire_en; 
            nacquire_done_pre_state <= oAcquire_done;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nworking <= 1'b0;
        end
        else begin
            if((!nacquire_en_pre_state) & iAcquire_en) begin
                nworking <= 1'b1;
            end
            else if((!nacquire_done_pre_state) & oAcquire_done) begin
                nworking <= 1'b0;
            end
            else begin
                nworking <= nworking; 
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
            oAcquire_done <= 1'b0;
        end
        else if(nsclk_count == 5'd15) begin
            oAcquire_done <= 1'b1; 
        end
        else begin
            oAcquire_done <= 1'b0; 
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
            oUbus <= 12'd0;
        end
        else if(nworking) begin
            if((nsclk_gen_count > 5'd10) & (nsclk_gen_count < 5'd18)) begin
                case (nsclk_count)
                    4'd3:   ntemp_11 <= ntemp_11 + iMISO;
                    4'd4:   ntemp_10 <= ntemp_10 + iMISO;
                    4'd5:   ntemp_9 <= ntemp_9 + iMISO;
                    4'd6:   ntemp_8 <= ntemp_8 + iMISO;
                    4'd7:   ntemp_7 <= ntemp_7 + iMISO;
                    4'd8:   ntemp_6 <= ntemp_6 + iMISO;
                    4'd9:   ntemp_5 <= ntemp_5 + iMISO;
                    4'd10:  ntemp_4 <= ntemp_4 + iMISO;
                    4'd11:  ntemp_3 <= ntemp_3 + iMISO;
                    4'd12:  ntemp_2 <= ntemp_2 + iMISO;
                    4'd13:  ntemp_1 <= ntemp_1 + iMISO;
                    4'd14:  ntemp_0 <= ntemp_0 + iMISO;
                    default: ;
                endcase
            end
            // else if(nsclk_gen_count == 5'd19) begin
            // else if((nsclk_count == 5'd14) & (nsclk_gen_count == 5'd19)) begin
            else if(nsclk_count == 5'd15) begin
                oUbus[11] <= (ntemp_11 >= 3'd4) ? 1'b1:1'b0;
                oUbus[10] <= (ntemp_10 >= 3'd4) ? 1'b1:1'b0;
                oUbus[9] <= (ntemp_9 >= 3'd4) ? 1'b1:1'b0;
                oUbus[8] <= (ntemp_8 >= 3'd4) ? 1'b1:1'b0;
                oUbus[7] <= (ntemp_7 >= 3'd4) ? 1'b1:1'b0;
                oUbus[6] <= (ntemp_6 >= 3'd4) ? 1'b1:1'b0;
                oUbus[5] <= (ntemp_5 >= 3'd4) ? 1'b1:1'b0;
                oUbus[4] <= (ntemp_4 >= 3'd4) ? 1'b1:1'b0;
                oUbus[3] <= (ntemp_3 >= 3'd4) ? 1'b1:1'b0;
                oUbus[2] <= (ntemp_2 >= 3'd4) ? 1'b1:1'b0;
                oUbus[1] <= (ntemp_1 >= 3'd4) ? 1'b1:1'b0;
                oUbus[0] <= (ntemp_0 >= 3'd4) ? 1'b1:1'b0;
            end
            else begin
                ntemp_11 <= ntemp_11;
                ntemp_10 <= ntemp_10;
                ntemp_9 <= ntemp_9;
                ntemp_8 <= ntemp_8;
                ntemp_7 <= ntemp_7;
                ntemp_6 <= ntemp_6;
                ntemp_5 <= ntemp_5;
                ntemp_4 <= ntemp_4;
                ntemp_3 <= ntemp_3;
                ntemp_2 <= ntemp_2;
                ntemp_1 <= ntemp_1;
                ntemp_0 <= ntemp_0; 
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