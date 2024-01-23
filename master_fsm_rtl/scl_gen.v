module scl_generate #(
    parameter THRESHOLD     = 2,
    parameter ADDR_LEN      = 7,
    parameter DATA_LEN      = 8
)(
    input              clk,
    input [3:0]        state_master,
    input              rst_count,
    output reg [6:0]   count_ctrl,
    output reg         scl,
    output             wait_for_sync,
    output             add_sent,
    output             data_received,
    output             data_sent
);

    

    parameter Idle            = 4'b0000;
    parameter Ready           = 4'b0001;
    parameter Send_Address    = 4'b0010;
    parameter Write_Data      = 4'b0011;
    parameter Output_Data     = 4'b0100;
    parameter Check_ACK       = 4'b0101;
    parameter Read_Data       = 4'b0110;
    parameter Store_Data      = 4'b0111;
    parameter Check_for_Valid = 4'b1000;
    parameter Send_ACK        = 4'b1001;
    parameter Send_NACK       = 4'b1010;
    parameter Stop            = 4'b1011;

    
    always @(posedge clk)
    begin
        if(rst_count) count_ctrl = 0;
        else
        begin
            count_ctrl = count_ctrl + 1'b1;

            if(state_master == Ready)
            begin
                if(count_ctrl == 4*THRESHOLD) 
                begin
                    scl   = 1'b0;
                    count_ctrl = 0;
                end
                else 
                begin
                    scl   = 1'b1;
                end
            end
            else if(state_master != Ready && state_master != Stop)
            begin
                if(count_ctrl == THRESHOLD)
                begin
                    scl   = ~scl;
                    count_ctrl = 0;
                end
            end
            else if(state_master == Stop)
            begin
                if(count_ctrl == 2*THRESHOLD)
                begin
                    scl = 1'b1;
                end
            end
        end
    end 

    assign wait_for_sync = (count_ctrl == 4*THRESHOLD) && (state_master == Ready);
    assign add_sent      = (count_ctrl == 2*ADDR_LEN*THRESHOLD) && (state_master == Send_Address);
    assign data_received = (count_ctrl == 2*DATA_LEN*THRESHOLD) && (state_master == Store_Data);
    assign data_sent     = (count_ctrl == 2*DATA_LEN*THRESHOLD) && (state_master == Output_Data);

endmodule