module tb_;

parameter ADDR_LEN = 7;
parameter DATA_LEN = 8;
parameter FREQ_DIFF = 4;
parameter SETUP_SDA_START=2;
parameter SETUP_SCL_START=4;

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
    .FREQ_DIFF              (FREQ_DIFF),
    .ADDR_LEN               (ADDR_LEN),
    .SETUP_SCL_START        (SETUP_SCL_START),
    .SETUP_SDA_START        (SETUP_SDA_START),
    .DATA_LEN               (DATA_LEN)
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
    #CLK_PERIOD RST_TEST;
    #CLK_PERIOD START_TEST(7'b1010110, 0);
    
end

task START_TEST(input[ADDR_LEN-1:0] addr, input r_w);
    begin
        wait(free);
        rst_n=1; start=1; data_1 =8'hab; data_2 = 8'hab; R_W=r_w;add_reg=addr; 
        #CLK_PERIOD; 
        if(free) begin
            $display("ERROR: free HIGH after start..");
            $finish;
        end
        else begin
            $display("Operation Started successfully..");
        end
        START_TEST_checker;
        SEND_ADDR_checker(addr);
    end
endtask

task START_TEST_checker;
    begin
        wait(~free);
        if(~sda || ~scl) begin
            $display("ERROR: START_TEST failed");
            $finish;
        end
        #SETUP_SDA_START
        if(sda || ~scl) begin
            $display("ERROR: START_TEST failed");
            $finish;
        end
        #(SETUP_SCL_START-SETUP_SDA_START)
        if(sda || scl) begin
            $display("ERROR: START_TEST failed");
            $finish;
        end
        $display("START condition verified..");
    end
endtask

task SEND_ADDR_checker(input[ADDR_LEN-1:0] addr);
    reg count;
    begin
        count = 0;
        wait(~scl);
        repeat(ADDR_LEN) begin
            wait(scl);
            if(sda != addr[ADDR_LEN-count -1]) begin
                $display("ERROR: Incorrect ADDR sent!");
                $finish;
            end
            count = count+1;
            wait(~scl);
        end
        $display("ADDR transmitted successfully..");
    end
endtask



task RST_TEST;
    begin
        @(posedge clk)
        rst_n = 1'b0; start=0; add_reg={ADDR_LEN{1'b0}}; R_W=0; data_1={DATA_LEN{1'b0}}; data_2={DATA_LEN{1'b0}};
        wait(CLK_PERIOD);
        if(~free || ~sda || ~scl) begin
            $display("RST_TEST FAILED");
            $finish;
        end else begin
            $display("RST_TEST passed.");
        end
    end

endtask

endmodule
// `default_nettype wire