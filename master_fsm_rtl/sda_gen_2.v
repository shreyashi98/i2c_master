module sda_generate #(parameter THRESHOLD = 2)(clk, start, scl, count_ctrl, wait_for_sync, add_sent, data_received, data_sent, add_reg, 
                                           R_W, data_1, data_2, sda, rst_count, state_master, free);
    input            clk;            //
    input            start;          //
    input            scl;
    input            wait_for_sync;
    input            add_sent;
    input            data_received;
    input            data_sent;
    input [6:0]      add_reg;        //
    input            R_W;            //
    input [7:0]      data_1;         //
    input [7:0]      data_2;         //
    input [6:0]      count_ctrl;
    inout            sda;
    output           rst_count;
    output [4:0]     state_master;
    output           free;

    reg [4:0] current_state = Idle;
    reg [4:0] next_state;
    reg       sda_reg;
    reg [2:0] no_of_data_rec  = 0;
    reg [2:0] no_of_data_sent = 0;
    reg [7:0] data_mem [1:0];

    parameter Idle            = 5'b00000;
    parameter Ready           = 5'b00001;
    parameter Send_Address    = 5'b00010;
    parameter Write_Data      = 5'b00011;
    parameter Output_Data     = 5'b00100;
    parameter Check_ACK       = 5'b00101;
    parameter Read_Data       = 5'b00110;
    parameter Store_Data      = 5'b00111;
    parameter Check_for_Valid = 5'b01000;
    parameter Send_ACK        = 5'b01001;
    parameter Send_NACK       = 5'b01010;
    parameter Stop            = 5'b01011;

    always @(posedge clk)
    begin
        //if(current_state == Idle)
        //begin
         //   if(start)
         //   begin
          //      next_state <= Ready;
           // end
        //end

        if(current_state == Ready)
        begin
            if(count_ctrl == 2*THRESHOLD) sda_reg = 0;
        end

        else if(current_state == Send_Address)
        begin
            if(~scl && ~add_sent && count_ctrl/(2*THRESHOLD) <= 6) sda_reg = add_reg[6 - count_ctrl/(2*THRESHOLD)];
            else if(~scl && add_sent && R_W)
            begin
                sda_reg    <= R_W;
            end
            else if(~scl && add_sent && ~R_W)
            begin
                sda_reg    <= R_W;
            end
        end

        else if(current_state == Read_Data)
        begin
            sda_reg <= 1'bz;
        end

        else if(current_state == Store_Data)
        begin
            sda_reg <= 1'bz;
            if(~scl && ~data_received && count_ctrl/(2*THRESHOLD) <= 7) data_mem[no_of_data_rec][7 - count_ctrl/(2*THRESHOLD)] = sda;
        end

        //else if(current_state == Check_for_Valid)
        //begin
        //    if(data_mem[no_of_data_rec] != 8'hFF) next_state <= Send_ACK;
        //    else next_state <= Send_NACK;
        //end

        else if(current_state == Send_ACK)
        begin
            if(~scl) 
            begin
                sda_reg <= 1'b0;
            end
        end

        //else if(current_state == Send_NACK)
        //begin
        //    next_state <= Stop;
        //end

        else if(current_state == Write_Data)
        begin
            sda_reg <= 1'bz;
        end

        else if(current_state == Output_Data)
        begin
            if(~scl && ~data_sent && count_ctrl/(2*THRESHOLD) <= 7) sda_reg <= data_mem[no_of_data_sent][7 - count_ctrl/(2*THRESHOLD)];
        end

        else if(current_state == Check_ACK)
        begin
            sda_reg <= 1'bz;
        end

        else if(current_state == Stop)
        begin
            if(count_ctrl == 4*THRESHOLD) 
            begin
                sda_reg    <= 1'b1;
            end
        end

        current_state <= next_state;
    end

     always @(*)
    begin
        if(current_state == Idle)
        begin
            if(start)
            begin
                next_state <= Ready;
            end
        end

        else if(current_state == Ready)
        begin
            if(count_ctrl == 2*THRESHOLD) sda_reg = 0;
            else if(wait_for_sync)
            begin
                next_state  <= Send_Address;
            end
            else next_state <= Ready;
        end

        else if(current_state == Send_Address)
        begin
            if(~scl && add_sent && R_W)
            begin
                next_state <= Read_Data;
            end
            else if(~scl && add_sent && ~R_W)
            begin
                next_state = Write_Data;
            end
        end

        else if(current_state == Read_Data)
        begin
            if(~scl)
            begin
                if(sda) next_state <= Store_Data;
                else    next_state <= Stop;
            end
        end

        else if(current_state == Store_Data)
        begin
            if(data_received)
            begin
                next_state <= Check_for_Valid;
            end
        end

        else if(current_state == Check_for_Valid)
        begin
            if(data_mem[no_of_data_rec] != 8'hFF) next_state <= Send_ACK;
            else next_state <= Send_NACK;
        end

        else if(current_state == Send_ACK)
        begin
            if(~scl) 
            begin
                no_of_data_rec   <= no_of_data_rec + 1'b1;
            end
            if(no_of_data_rec < 2) next_state <= Store_Data;
            else next_state <= Stop;
        end

        else if(current_state == Send_NACK)
        begin
            next_state <= Stop;
        end

        else if(current_state == Write_Data)
        begin
            if(sda) next_state <= Output_Data;
            else next_state    <= Write_Data;
        end

        else if(current_state == Output_Data)
        begin
            if(data_sent)
            begin
                next_state <= Check_ACK;
            end
        end

        else if(current_state == Check_ACK)
        begin
            if(~scl)
            begin
                no_of_data_sent <= no_of_data_sent + 1'b1;
                if(sda && no_of_data_sent < 2) next_state <= Output_Data;
                else if(~sda) next_state <= Stop;
            end
        end

        else if(current_state == Stop)
        begin
            if(count_ctrl == 4*THRESHOLD) 
            begin
                next_state <= Idle;
            end
        end
    end
    
    assign state_master = current_state;
    assign free = (current_state == Idle);
    assign rst_count = (current_state == Idle) || wait_for_sync || free || add_sent || (current_state == Read_Data) || 
                       (current_state == Write_Data) || data_received || (current_state == Check_for_Valid) ||
                       (current_state == Send_ACK) || (current_state == Check_ACK);
    assign sda = sda_reg;

endmodule