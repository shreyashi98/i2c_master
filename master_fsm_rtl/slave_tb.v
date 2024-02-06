module slave_tb;

    wire sda_pin;
    reg sda;
    reg sda_op;
    reg scl;
    //reg clk;
    reg [7:0] data_received;
    wire [7:0] data_sent;
    reg write_inout;

    //slave_sda_generate S1 (clk,scl,sda_pin,data_received,data_sent);
    slave_sda_generate S1 (scl,sda_pin,data_received,data_sent);

    assign sda_pin = write_inout ? sda : 1'bz;

    /*initial clk = 1'b0;
    always #2.5 clk <= ~clk;*/

    initial begin
        $dumpfile("slave.vcd"); 
        $dumpvars(0, slave_tb);
        $monitor($time," scl = %b sda = %b address_counter = %d",scl,sda, S1.address_counter);
        write_inout = 1; sda = 1; scl = 1;
        #5 sda = 1; scl = 1; 
        data_received = 8'hA8;
        #5 sda = 0;
        #5 scl = 0;
        #5 sda = 1;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 write_inout = 0; scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0; write_inout = 1; sda = 0;
        #5 scl = 1;

        #5 scl = 0;
        #5 scl = 1;
        #5 scl = 0;
        
        #5 scl = 1;
        #5 sda = 1;

        #500 $finish;
    end

endmodule