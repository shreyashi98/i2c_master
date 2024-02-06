module master_slave_tb;

parameter ADDR_LEN = 7;
parameter DATA_LEN = 8;
parameter SETUP_SDA_START=2;
parameter SETUP_SCL_START=4;
parameter SETUP_SDA_STOP = 2;
parameter T_LOW         = 6;
parameter T_HIGH        = 4;
parameter SETUP_SDA     = 3;

parameter ADDR_COUNTER_LEN =3;
parameter DATA_COUNTER_LEN = 3;

reg clk;
reg rst_n;
reg start;
reg [ADDR_LEN-1:0] add_reg;
reg R_W;
reg [DATA_LEN-1:0] data_1;
reg [DATA_LEN-1:0] data_2;
reg                ack_3p;
reg sda_reg;
wire scl;
tri1 sda; // pull-up resistor
wire[3:0] state_master;
wire free;

reg [DATA_LEN-1:0] data_received;
wire [DATA_LEN-1:0] data_sent;

fsm_master #(
    .T_LOW                  (T_LOW          ),
    .T_HIGH                 (T_HIGH         ),
    .ADDR_LEN               (ADDR_LEN       ),
    .SETUP_SCL_START        (SETUP_SCL_START),
    .SETUP_SDA_START        (SETUP_SDA_START),
    .SETUP_SDA              (SETUP_SDA      ),
    .SETUP_SDA_STOP         (SETUP_SDA_STOP ),
    .DATA_LEN               (DATA_LEN       )
) FSM_MASTER_DUT
(
    .clk                (clk        ),
    .rst_n              (rst_n      ),
    .start              (start      ),
    .add_reg            (add_reg    ),
    .R_W                (R_W        ),
    .data_1             (data_1     ),
    .data_2             (data_2     ),
    .ack_3p             (ack_3p     ),
    .scl                (scl        ),
    .sda                (sda        ),
    .state_master       (state_master),
    //.output_value_valid (output_value_valid),
    .free               (free       )
);

slave_sda_generate #(
    .ADDR_LEN           (ADDR_LEN          ),
    .DATA_LEN           (DATA_LEN          ),
    .ADDR_COUNTER_LEN   (ADDR_COUNTER_LEN  ),
    .DATA_COUNTER_LEN   (DATA_COUNTER_LEN   )

) SLAVE_DUT (
    .sda            (sda        ),
    .scl            (scl        ),
    .data_received  (data_received),
    .data_sent      (data_sent  )
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    clk = 0;
    #5000 $finish;
end

initial begin
    $dumpfile("tb_.vcd");
    $dumpvars(0, master_slave_tb);
end

initial begin
    #CLK_PERIOD rst_n=1'b0; start = 1'b0; add_reg = 7'b1011011; R_W = 0;ack_3p=1; data_1 = 8'b10101100; data_2 = 8'b01000010; sda_reg = 0; data_received = 8'b00011101;
    #CLK_PERIOD rst_n=1'b1;  start = 1'b1; R_W = 1'b0; ack_3p = 1'b1;
    #CLK_PERIOD start=1'b0;
end

endmodule