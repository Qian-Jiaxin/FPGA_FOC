`timescale 1ns/1ps
`define Clk_Period 20

module FOC_TB();

    reg iClk;
    reg iRst_n;
    wire oPWM_u,oPWM_v,oPWM_w;

    initial iClk = 1'b1;
    always #(`Clk_Period/2) iClk = ~iClk;

    initial begin
        iRst_n = 1'b0;
        #(`Clk_Period) iRst_n = 1'b1;
    end

    FOC foc(
        .iClk(iClk),
        .iRst_n(iRst_n),
        .oPWM_u(oPWM_u),
        .oPWM_v(oPWM_v),
        .oPWM_w(oPWM_w)
    );

endmodule