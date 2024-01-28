module sda_generate #(
    parameter THRESHOLD         = 2,
    parameter ADDR_LEN          = 7,
    parameter DATA_LEN          = 8,
    parameter SETUP_SDA_START   = 2,
    parameter SETUP_SDA         = 3,
    parameter T_HIGH            = 4,
    parameter T_LOW             = 6
    )(
    input                       clk,
    input                       rst_n,
    input                       start,
    input                       scl,
    input [6:0]                 count_ctrl,
    input [3:0]                 count,
    input                       wait_for_sync,
    input                       add_sent,
    input                       data_received,
    input                       data_sent,
    input [ADDR_LEN-1:0]        add_reg,
    input                       R_W,
    input [DATA_LEN-1:0]        data_1,
    input [DATA_LEN-1:0]        data_2,
    inout                       sda,
    output                      rst_count,
    output                      rst_count_2,
    output [3:0]                state_master,
    output                      free
                                           );


    reg [3:0]           current_state;
    reg [3:0]           next_state;
    reg                 sda_reg;
    reg [1:0]           no_of_data_rec;
    reg [1:0]           no_of_data_sent; //See if one can be used
    reg [DATA_LEN-1:0]  data_mem [1:0];
    reg                 ack_reg;

    parameter Idle            = 4'b0000;
    parameter Ready           = 4'b0001;
    parameter Send_Address    = 4'b0010;
    parameter Write_Data      = 4'b0011;
    parameter Output_Data     = 4'b0100;
    parameter Check_ACK_data  = 4'b0101;
    parameter Read_Data       = 4'b0110;
    parameter Store_Data      = 4'b0111;
    parameter Check_for_Valid = 4'b1000;
    parameter Send_ACK        = 4'b1001;
    parameter Send_NACK       = 4'b1010;
    parameter Stop            = 4'b1011;
    parameter Check_ACK_addr  = 4'b1100;

//always block for data_mem
// always @(posedge clk or negedge ~rst_n) begin
//     if(~rst_n) begin
//         data_mem[0] <= data_1;
//         data_mem[1] <= data_2;
//     end
// end

//always block for curr_state
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n) begin
                current_state <= Idle;
            end else begin
                current_state <= next_state;
            end

        end
    //always block for sda_reg
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            sda_reg <= 1'b1;
        end
     else begin
        case (current_state) 
        Ready : begin
            if(count_ctrl == (SETUP_SDA_START -1)) begin
                sda_reg <= 1'b0;
            end
        end
        
        Send_Address : begin
            if(count <= ADDR_LEN -1) begin
                if(count_ctrl == T_LOW - SETUP_SDA - 1) sda_reg <= add_reg[(ADDR_LEN - 1) - count];
            end else begin
                if(count_ctrl == T_LOW - SETUP_SDA - 1) sda_reg <= R_W;
            end
        end

        Check_ACK_addr: begin
            if(count_ctrl == T_LOW -SETUP_SDA - 1) begin
                sda_reg <= 1'bz;
            end
        end

        Write_Data: begin
            if(count_ctrl == T_LOW -SETUP_SDA -1 && no_of_data_sent == 0) sda_reg <= data_1[DATA_LEN-1-count];
            else if(count_ctrl == T_LOW -SETUP_SDA -1 && no_of_data_sent == 1) sda_reg <= data_2[DATA_LEN-1-count];
        end

     endcase 

     end

        begin
            // if(current_state == Ready)
            // begin
            //     if(count_ctrl == 2*THRESHOLD ) sda_reg = 0;
            // end

            // if(current_state == Send_Address)
            // begin
            //     if(~scl && ~add_sent && count_ctrl/(2*THRESHOLD) <= 6) sda_reg = add_reg[6 - count_ctrl/(2*THRESHOLD)];
            //     else if(~scl && add_sent && R_W)
            //     begin
            //         sda_reg    <= R_W;
            //     end
            //     else if(~scl && add_sent && ~R_W)
            //     begin
            //         sda_reg    <= R_W;
            //     end
            // end

            // if(current_state == Read_Data)
            // begin
            //     sda_reg <= 1'bz;
            // end

            // else if(current_state == Store_Data)
            // begin
            //     sda_reg <= 1'bz;
            //     if(~scl && ~data_received && count_ctrl/(2*THRESHOLD) <= 7) data_mem[no_of_data_rec][7 - count_ctrl/(2*THRESHOLD)] = sda;
            // end

            //else if(current_state == Check_for_Valid)
            //begin
            //    if(data_mem[no_of_data_rec] != 8'hFF) next_state <= Send_ACK;
            //    else next_state <= Send_NACK;
            //end

            // else if(current_state == Send_ACK)
            // begin
            //     if(~scl) 
            //     begin
            //         sda_reg <= 1'b0;
            //     end
            // end

            //else if(current_state == Send_NACK)
            //begin
            //    next_state <= Stop;
            //end

            // else if(current_state == Write_Data)
            // begin
            //     sda_reg <= 1'bz;
            // end

            // else if(current_state == Output_Data)
            // begin
            //     if(~scl && ~data_sent && count_ctrl/(2*THRESHOLD) <= 7) sda_reg <= data_mem[no_of_data_sent][7 - count_ctrl/(2*THRESHOLD)];
            // end

        //     else if(current_state == Check_ACK)
        //     begin
        //         sda_reg <= 1'bz;
        //     end

        //     else if(current_state == Stop)
        //     begin
        //         if(count_ctrl == 4*THRESHOLD) 
        //         begin
        //             sda_reg    <= 1'b1;
        //         end
        //     end
         end
    end

//always block for ack_reg
always @(posedge clk or negedge rst_n) begin
    if(rst_n) begin
        ack_reg <= 0;
    end else begin
        if(add_sent) begin
            ack_reg <= 0;
        end else if(scl && sda) begin
            ack_reg <= 1;
        end
    end 
end

//always block for no_of_data_sent
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        no_of_data_sent <= 0;
    end else begin
        if(data_sent) no_of_data_sent <= no_of_data_sent + 1;
    end
end

//Combo Logic for next_state
always @(*) begin
    next_state = current_state;

    case(current_state)
        Idle : begin
            if(start) begin
                next_state = Ready;
            end
        end

        Ready: begin
           if(wait_for_sync) begin
                next_state = Send_Address;
           end
        end

        Send_Address: begin
            if(add_sent) next_state = Check_ACK_addr;
        end

        Check_ACK_addr: begin
            if(~ack_reg && (count_ctrl==T_LOW+T_HIGH-1)) begin
                if(R_W) begin
                    next_state = Read_Data;
                end else begin
                    next_state = Write_Data;
                end
            end
        end

        Write_Data : begin
            if(data_sent) next_state = Check_ACK_data;
        end
       
    endcase

end


// always @(*) 
// begin
//     next_state = current_state;
    
//         if(current_state == Idle)
//         begin
//             if(start)
//             begin
//                 next_state = Ready;
//             end
//         end

//         else if(current_state == Ready)
//         begin
//             if(count_ctrl == 2*THRESHOLD) sda_reg = 0;
//             else if(wait_for_sync)
//             begin
//                 next_state  = Send_Address;
//             end
//             else next_state = Ready;
//         end

//         else if(current_state == Send_Address)
//         begin
//             if(~scl && add_sent && R_W)
//             begin
//                 next_state = Read_Data;
//             end
//             else if(~scl && add_sent && ~R_W)
//             begin
//                 next_state = Write_Data;
//             end
//         end

//         else if(current_state == Read_Data)
//         begin
//             if(~scl)
//             begin
//                 if(sda) next_state = Store_Data;
//                 else    next_state = Stop;
//             end
//         end

//         else if(current_state == Store_Data)
//         begin
//             if(data_received)
//             begin
//                 next_state = Check_for_Valid;
//             end
//         end

//         else if(current_state == Check_for_Valid)
//         begin
//             if(data_mem[no_of_data_rec] != 8'hFF) next_state = Send_ACK;
//             else next_state = Send_NACK;
//         end

//         else if(current_state == Send_ACK)
//         begin
//             if(~scl) 
//             begin
//                 no_of_data_rec   <= no_of_data_rec + 1'b1;
//             end
//             if(no_of_data_rec < 2) next_state = Store_Data;
//             else next_state <= Stop;
//         end

//         else if(current_state == Send_NACK)
//         begin
//             next_state = Stop;
//         end

//         else if(current_state == Write_Data)
//         begin
//             if(sda) next_state = Output_Data;
//             else next_state    = Write_Data;
//         end

//         else if(current_state == Output_Data)
//         begin
//             if(data_sent)
//             begin
//                 next_state = Check_ACK;
//             end
//         end

//         else if(current_state == Check_ACK)
//         begin
//             if(~scl)
//             begin
//                 no_of_data_sent <= no_of_data_sent + 1'b1;
//                 if(sda && no_of_data_sent < 2) next_state <= Output_Data;
//                 else if(~sda) next_state = Stop;
//             end
//         end

//         else if(current_state == Stop)
//         begin
//             if(count_ctrl == 4*THRESHOLD) 
//             begin
//                 next_state = Idle;
//             end
//         end
// end
    
    assign state_master = current_state;
    assign free = (current_state == Idle);
    assign rst_count = (current_state == Idle) || wait_for_sync || free || add_sent || data_sent || 
                        data_received ;
    assign rst_count_2 = wait_for_sync || add_sent || data_sent;
    assign sda = sda_reg;

endmodule