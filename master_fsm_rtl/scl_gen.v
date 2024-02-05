module scl_generate #(
    //parameter THRESHOLD     = 2,
    parameter T_LOW         = 6,
    parameter T_HIGH        = 4,  //SCL is LOW for T_LOW*CLK_PERIOD and HIGH for T_HIGH*CLK_PERIOD
    parameter ADDR_LEN      = 7,
    parameter SETUP_SCL_START = 4,
    parameter DATA_LEN      = 8
)(
    input              clk,
    input              rst_n,
    input [3:0]        state_master,
    input              rst_count,
    input [3:0]        count,
    output reg [6:0]   count_ctrl,
    output reg         scl,
    output             wait_for_sync,
    output             add_sent,
    output             data_received,
    output             data_sent,
    output             count_inc
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

//always block for count_ctrl
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        count_ctrl <= 0;
    end else begin
        if (rst_count) begin
            count_ctrl <= 0;
        end else begin
            if (state_master == Ready) begin
                if(count_ctrl == (SETUP_SCL_START-1)) begin
                    count_ctrl <= 0;
                end else begin
                    count_ctrl <= count_ctrl + 1;
                end
            end else if(state_master != Ready && state_master != Stop && state_master!=Idle) begin
                if (count_ctrl == (T_LOW+T_HIGH-1)) begin
                    count_ctrl <= 0;
                end else begin
                    count_ctrl <= count_ctrl + 1; 
                end
            end else begin //what happens to cnt cntrl in other states?
                count_ctrl <= count_ctrl + 1;
            end
        end
    end
end

//always block for scl
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        scl <= 1; //check
    end else begin
        if (state_master == Ready) begin
            if (count_ctrl == SETUP_SCL_START-1) begin
                scl <= 1'b0;
            end
        end else if(state_master != Ready && state_master != Idle && state_master != Stop) begin
            if(count_ctrl < T_LOW -1 || count_ctrl == (T_HIGH + T_LOW -1) ) begin
                scl <= 1'b0;
            end else begin
                scl <= 1'b1;
            end
        end
        else if(state_master == Idle) begin
            scl <= 1'b1;
        end
        else if(state_master == Stop) begin
            if(count_ctrl < T_LOW -1) begin
                scl <= 1'b0;
            end else if (count_ctrl == T_HIGH+T_LOW -1 ) begin
                scl <= 1'bz;
            end
            else  begin
                scl <= 1'b1;
            end
        end
    end
end

    assign wait_for_sync = (count_ctrl == (SETUP_SCL_START-1)) && (state_master == Ready);
    assign add_sent      = (count      == ADDR_LEN) && (count_ctrl == T_HIGH + T_LOW -1 ) && (state_master == Send_Address);
    assign data_received = (count      == DATA_LEN-1) && (count_ctrl == T_HIGH + T_LOW - 1) && (state_master == Read_Data);
    assign data_sent     = (count      == DATA_LEN-1) && (count_ctrl == T_HIGH + T_LOW - 1) && (state_master == Write_Data);
    assign count_inc     = (count_ctrl == T_HIGH + T_LOW - 1) && (state_master == Send_Address || state_master == Write_Data|| state_master == Read_Data);

endmodule