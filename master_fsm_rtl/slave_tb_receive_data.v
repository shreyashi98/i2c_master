module slave_tb6;

    tri1 sda_pin;
    reg sda;
    reg sda_op;
    reg scl;
    reg receive_data1_ack;
    reg receive_data2_ack;
    //reg clk;
    reg [7:0] data1_received;
    reg [7:0] data2_received;
    wire [7:0] data1_sent;
    wire [7:0] data2_sent;
    reg write_inout;

    //slave_sda_generate S1 (clk,scl,sda_pin,data_received,data_sent);
    slave_sda_generate S1 (scl,sda_pin,receive_data1_ack,receive_data2_ack,data1_received,data2_received,data1_sent,data2_sent);

    assign sda_pin = write_inout ? sda : 1'bz;

    initial begin
        $dumpfile("slave6.vcd"); 
        $dumpvars(0, slave_tb6);
        $monitor($time," scl = %b sda = %b address_counter = %d",scl,sda, S1.address_counter);
        write_inout = 1; sda = 1'bz; scl = 1; receive_data1_ack = 0; receive_data2_ack = 1;
        #5 sda = 1'bz; scl = 1;
        #5 sda = 0;
        #5 scl = 0;
        #5 sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 write_inout = 0; scl = 0;
        #5 scl = 1;
        #5 scl = 0; write_inout = 1; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 1'bz;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; write_inout = 0;
        #5 scl = 1;

        #5 scl = 0; write_inout = 1; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 0;
        #5 scl = 1;
        #5 scl = 0; sda = 1;
        #5 scl = 1;
        #5 scl = 0; write_inout = 0;
        #5 scl = 1;

        #5 scl = 0;write_inout = 1; sda = 0;
        #5 scl = 1;
        #5 scl = 0;
        
        #5 scl = 1;
        #5 sda = 1;

        #500 $finish;
    end

endmodule