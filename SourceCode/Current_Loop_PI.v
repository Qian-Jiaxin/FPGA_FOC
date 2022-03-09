module Current_Loop_PI #(
    parameter Kp = 10'd1023,
    parameter KI = 10'd1023
)
(
    iClk,
    iRst_n,
    iTarget_data,   //速度环输入或者位置环输入iq
    iCurrent_data,  //ADC采样得到
    iCal_en,
    oCal_data,      //输出uq
    oCal_done  
);
    input wire iClk;
    input wire iRst_n;
    input wire signed [11:0] iTarget_data,iCurrent_data;
    input wire iCal_en;
    output reg signed [15:0] oCal_data;
    output reg oCal_done;

    localparam S0 = 1'd0;
    localparam S1 = 1'd1;

    reg ncal_en_pre_state;
    reg nstate;
    reg signed [11:0] nerror_sum;
    wire signed [11:0] nerror;
    wire signed [22:0] ncal_p,ncal_i;

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
            nerror_sum <= 12'd0;
            nstate <= S0;
            oCal_data <= 16'd0;
            oCal_done <= 1'b0; 
        end
        else begin
            case (nstate)
                S0: begin
                    if((!ncal_en_pre_state) & iCal_en) begin
                        nerror_sum <= nerror_sum + nerror;
                        nstate <= S1; 
                    end
                    else begin
                        oCal_done <= 1'b0;
                        nstate <= nstate;
                    end
                end
                S1: begin
                    nstate <= S0;
                    oCal_data <= ncal_p[15:0] + ncal_i[15:0];
                    oCal_done <= 1'b1;
                end
                default: nstate <= S0;
            endcase
        end
    end
    assign nerror = iTarget_data - iCurrent_data;
    assign ncal_p = ($signed({{1'b0},Kp}) * nerror)>>6;
    assign ncal_i = ($signed({{1'b0},KI}) * nerror_sum)>>6;

endmodule