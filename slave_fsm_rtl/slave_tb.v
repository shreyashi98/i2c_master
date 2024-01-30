module slave_tb;

    wire sda_pin;
    reg sda;
    reg sda_op;
    reg scl;
    reg [7:0] data_received;
    wire [7:0] data_sent;
    reg write_inout;

    assign sda_pin = write_inout ? sda : 1'bz;

    slave_sda_generate S1 (scl,sda_pin,data_received,data_sent);

    initial begin
        $dumpfile("slave.vcd"); 
        $dumpvars(0, slave_tb);
        $monitor($time," scl = %b sda = %b",scl,sda);
        write_inout = 1; 
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
        #5 scl = 0;
        #5 scl = 1;
        #10 write_inout = 1; scl = 1; sda = 1;

        #500 $finish;
    end

endmodule