module tb_;

parameter ADDR_LEN = 7;
parameter DATA_LEN = 8;
parameter FREQ_DIFF = 4;

reg clk;
reg rst_n;
reg start;
reg [ADDR_LEN-1:0] add_reg;
reg R_W;
reg [DATA_LEN-1:0] data_1;
reg [DATA_LEN-1:0] data_2;
wire scl;
wire sda;
wire free;


fsm_master #(
    .FREQ_DIFF(FREQ_DIFF),
    .ADDR_LEN(ADDR_LEN),
    .DATA_LEN(DATA_LEN)
) FSM_MASTER_DUT
(
    .clk                (clk        ),
    .rst_n              (rst_n      ),
    .start              (start      ),
    .add_reg            (add_reg    ),
    .R_W                (R_W        ),
    .data_1             (data_1     ),
    .data_2             (data_2     ),
    .scl                (scl        ),
    .sda                (sda        ),
    .free               (free       )
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    clk = 0;
    #5000 $finish;
end

initial begin
    $dumpfile("tb_.vcd");
    $dumpvars(0, tb_);
end

initial begin
    #CLK_PERIOD rst_n=1; start=0; add_reg={ADDR_LEN{1'b0}}; R_W=0; data_1={DATA_LEN{1'b0}}; data_2={DATA_LEN{1'b0}};
    #CLK_PERIOD rst_n=0;
    #CLK_PERIOD rst_n=1;
    #CLK_PERIOD start=1; add_reg=7'b1010110;
end

endmodule
`default_nettype wire