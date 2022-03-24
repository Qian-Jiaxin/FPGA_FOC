module Current_Loop_PI(
    iClk,
    iRst_n,
    iTarget_d,   //速度环输入或者位置环输入id
    iCurrent_d,  //ADC采样得到
    iKp_d,
    iKi_d,
    iTarget_q,   //速度环输入或者位置环输入iq
    iCurrent_q,  //ADC采样得到
    iKp_q,
    iKi_q,
    iCal_en,
    oCal_d,      //输出ud
    oCal_q,      //输出uq
    oCal_done  
);
    input wire iClk;
    input wire iRst_n;
    input wire signed [11:0] iTarget_d,iCurrent_d;
    input wire signed [11:0] iTarget_q,iCurrent_q;
    input wire [9:0] iKp_d,iKi_d;
    input wire [9:0] iKp_q,iKi_q;
    input wire iCal_en;
    output reg [15:0] oCal_d,oCal_q;
    output reg oCal_done;

    localparam MAX = 16'd32767;

    localparam S0 = 3'd0;
    localparam S1 = 3'd1;
    localparam S2 = 3'd2;
    localparam S3 = 3'd3;
    localparam S4 = 3'd4;
    localparam S5 = 3'd5;

    reg ncal_en_pre_state;
    reg [2:0] nstate;
    reg signed [21:0] np_temp_d,ni_temp_d; 
    reg signed [21:0] np_temp_q,ni_temp_q; 
    reg signed [11:0] nerror_d;
    reg signed [11:0] nerror_q;
    reg signed [11:0] nerror_mult_p_d;
    reg signed [11:0] nerror_mult_p_q;
    reg signed [17:0] ncal_d_temp;
    reg signed [17:0] ncal_q_temp;
    
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            ncal_en_pre_state <= 1'b0;
        end 
        else begin
            ncal_en_pre_state <= iCal_en;
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nstate <= S0;
            oCal_done <= 1'b0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nstate <= S1;
                    end
                    else begin
                        nstate <=nstate;
                        oCal_done <= 1'b0;
                    end
                end 
                S1: begin
                    nstate <= S2; 
                end
                S2: begin
                    nstate <= S3; 
                end
                S3: begin
                    nstate <= S0;
                    oCal_done <= 1'b1; 
                end
                default: nstate <= S0;
            endcase 
        end
    end
    
    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nerror_d <= 12'd0;
            np_temp_d <=22'd0;
            ni_temp_d <=22'd0;
            oCal_d <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_d <= iTarget_d - iCurrent_d;
                        nerror_mult_p_d <= iTarget_d - iCurrent_d - nerror_d;
                    end
                    else begin
                        nerror_d <= nerror_d;
                    end
                end
                S1: begin
                    np_temp_d <= (nerror_mult_p_d * iKp_d)>>>6;
                    ni_temp_d <= (nerror_d * iKi_d)>>>6;
                end
                S2: begin
                    ncal_d_temp <= oCal_d + $signed(np_temp_d[15:0]) + $signed(ni_temp_d[15:0]);
                end
                S3: begin
                    if(ncal_d_temp >= $signed(MAX)) begin
                        oCal_d <= $signed(MAX);
                    end 
                    else if(ncal_d_temp <= -$signed(MAX)) begin
                        oCal_d <= -$signed(MAX); 
                    end
                    else begin
                        oCal_d <= oCal_d + $signed(np_temp_d[15:0]) + $signed(ni_temp_d[15:0]);
                    end
                end
                default: ;
            endcase 
        end
    end

    always @(posedge iClk or negedge iRst_n) begin
        if(!iRst_n) begin
            nerror_q <= 12'd0;
            np_temp_q <=22'd0;
            ni_temp_q <=22'd0;
            oCal_q <= 16'd0;
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_q <= iTarget_q - iCurrent_q;
                        nerror_mult_p_q <= iTarget_q - iCurrent_q - nerror_q;
                    end
                    else begin
                        nerror_q <= nerror_q;
                    end
                end
                S1: begin
                    np_temp_q <= (nerror_mult_p_q * iKp_q)>>>6;
                    ni_temp_q <= (nerror_q * iKi_q)>>>6;
                end
                S2: begin
                    ncal_q_temp <= oCal_q + $signed(np_temp_q[15:0]) + $signed(ni_temp_q[15:0]);
                end
                S3: begin
                    if(ncal_q_temp >= $signed(MAX)) begin
                        oCal_q <= $signed(MAX);
                    end 
                    else if(ncal_q_temp <= -$signed(MAX)) begin
                        oCal_q <= -$signed(MAX); 
                    end
                    else begin
                        oCal_q <= oCal_q + $signed(np_temp_q[15:0]) + $signed(ni_temp_q[15:0]);
                    end
                end
                default: ;
            endcase 
        end
    end

endmodule