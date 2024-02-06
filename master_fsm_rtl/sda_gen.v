module sda_generate #(
    //parameter THRESHOLD         = 2,
    parameter ADDR_LEN          = 7,
    parameter DATA_LEN          = 8,
    parameter SETUP_SDA_START   = 2,
    parameter SETUP_SDA_STOP    = 2,
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
    input                       ack_3p,
    inout                       sda,
    output                      rst_count,
    output                      rst_count_2,
    output [3:0]                state_master,
    output [DATA_LEN-1:0]       dout_1,
    output [DATA_LEN-1:0]       dout_2,
    //output                      output_value_valid,
    output                      free
                                           );


    reg [3:0]           current_state;
    reg [3:0]           next_state;
    reg                 sda_reg;
    reg [1:0]           no_of_data_rec;
    reg [1:0]           no_of_data_sent; //See if one can be used
    reg [DATA_LEN-1:0]  data_mem [1:0];
    reg                 ack_reg;
    wire                output_value_valid;

    parameter Idle            = 4'b0000;
    parameter Ready           = 4'b0001;
    parameter Send_Address    = 4'b0010;
    parameter Check_ACK_addr  = 4'b0011;
    parameter Write_Data      = 4'b0100;
    parameter Check_ACK_data  = 4'b0101;
    parameter Read_Data       = 4'b0110;
    parameter Send_ACK        = 4'b0111;
    parameter Stop            = 4'b1000;


    assign sda = output_value_valid ? sda_reg : 1'bz;
    assign dout_1 = data_mem[0];
    assign dout_2 =data_mem[1];


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

        Idle: begin
            sda_reg <= 1'b1;
        end

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

        Check_ACK_data: begin
            if(count_ctrl == T_LOW -SETUP_SDA - 1) begin
                sda_reg <= 1'bz;
            end
        end

        Read_Data: begin
            if(count_ctrl == T_LOW -SETUP_SDA -1) begin
                data_mem[no_of_data_sent][DATA_LEN-1-count] <= sda;
                sda_reg <= 1'bz;
            end
        end

        Send_ACK: begin
            if(count_ctrl == T_LOW -SETUP_SDA - 1) sda_reg <= ~ack_3p;
        end

        Stop: begin
            if (count_ctrl == T_HIGH+T_LOW -1 ) begin
                sda_reg <= 1'bz;
            end else if(count_ctrl >= T_LOW + SETUP_SDA_STOP -1) begin
                sda_reg <= 1; 
            end else begin
                sda_reg <= 0;
            end
        end
    
        
     endcase 

     end
    end

//always block for ack_reg
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        ack_reg <= 0;
    end else begin
        if(add_sent || data_sent) begin
            ack_reg <= 0;
        end else if((state_master == Check_ACK_addr || state_master == Check_ACK_data) && scl && sda) begin
            ack_reg <= 1;
        end
    end 
end

//always block for no_of_data_sent
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        no_of_data_sent <= 0;
    end else begin
        if(data_sent || data_received) no_of_data_sent <= no_of_data_sent + 1'b1;
        if(current_state == Idle) begin
            no_of_data_sent <= 0;
        end
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
            else if(ack_reg && (count_ctrl==T_LOW+T_HIGH-1)) begin
                next_state = Stop;
            end
        end

        Write_Data : begin
            if(data_sent) next_state = Check_ACK_data;
        end

        Check_ACK_data: begin
            if(no_of_data_sent == 1 && ~ack_reg && (count_ctrl==T_LOW+T_HIGH-1)) next_state = Write_Data;
            else if(no_of_data_sent == 1 && ack_reg && (count_ctrl==T_LOW+T_HIGH-1)) next_state = Stop;
            else if (no_of_data_sent == 2 && (count_ctrl == T_LOW + T_HIGH - 1)) next_state = Stop;
        end

        Read_Data: begin
            if(data_received) next_state = Send_ACK;
        end

        Send_ACK: begin
            if(no_of_data_sent < 2 && ack_3p && (count_ctrl==T_LOW+T_HIGH-1)) next_state = Read_Data;
            else if(no_of_data_sent < 2 && ~ack_3p && (count_ctrl==T_LOW+T_HIGH-1)) next_state = Stop;
            else if(no_of_data_sent == 2 && (count_ctrl==T_LOW+T_HIGH-1)) next_state = Stop;
        end

        Stop: begin
            if((count_ctrl==T_LOW+T_HIGH-1)) next_state = Idle;
        end
       
    endcase

end

    
    assign state_master = current_state;
    assign free = (current_state == Idle);
    assign rst_count = (current_state == Idle) || wait_for_sync || free || add_sent || data_sent || data_received ;
    assign rst_count_2 = wait_for_sync || add_sent || data_sent || data_received;
    assign output_value_valid = !((current_state == Read_Data )||(current_state == Idle) || ((current_state == Check_ACK_data || current_state == Check_ACK_addr) && count_ctrl >= (T_LOW - SETUP_SDA-1)));
    //assign sda = sda_reg;

endmodule