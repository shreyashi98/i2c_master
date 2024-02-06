module slave_sda_generate #(
    parameter ADDR_LEN = 7,
    parameter ADDR_COUNTER_LEN = 3,
    parameter DATA_LEN = 8,
    parameter DATA_COUNTER_LEN = 3
)(
    //input clk;
    input scl,
    inout sda,
    input[DATA_LEN-1:0] data_received,
    output[DATA_LEN-1:0] data_sent

);

  reg [3:0] current_state = Idle;
  reg [3:0] next_state = Idle;
  reg R_W;
  reg sda_reg = 1'b1;
  reg start_signal = 1'b0;
  reg stop_signal = 1'b0;
  reg sda_write = 1'b0;
  reg reset_address_counter;
  reg [ADDR_COUNTER_LEN:0] address_counter;
  wire comp_bit;
  reg reset_rdata_counter;
  reg [DATA_COUNTER_LEN-1:0] rdata_counter;
  reg reset_wdata_counter;
  reg [DATA_COUNTER_LEN-1:0] wdata_counter;
  reg [DATA_LEN-1:0] received_data = 8'b00000000;
  reg [ADDR_LEN-1:0] slave_address = 7'b1011011;
  reg [ADDR_LEN-1:0] received_address = 7'b0000000;

  parameter Idle = 4'b0000;
  parameter Receive_address = 4'b0001;
  parameter delay_post_ack0 = 4'b0010;
  parameter delay_post_ack1 = 4'b0011;
  parameter Send_data = 4'b0100;
  parameter Check_ACK_NACK = 4'b0101;
  parameter Receive_data = 4'b0110;
  parameter GiveACK = 4'b0111;
  parameter Stop = 4'b1000;
  //parameter GiveACK = ;

  assign comp_bit = (received_address == slave_address);
  assign data_sent = received_data;
  assign sda = sda_write ? sda_reg : 1'bz;

  always @(current_state,sda,sda_reg,scl) begin
    case (current_state)
      Receive_address:
      begin
        if(scl) begin
          //address_counter = address_counter - 1;
          sda_reg = sda;
          if(address_counter == 1) R_W = sda_reg;
          else received_address = (received_address << 1) + sda_reg;
        end
        else if(~scl && address_counter == 0) begin
          if (comp_bit) begin
            sda_write = 1'b1;
            sda_reg = 1'b0;
            next_state = delay_post_ack0;
          end
          else begin
            sda_write = 1'b1;
            sda_reg = 1'b1;
            next_state = delay_post_ack1;
          end
        end

        else next_state = Receive_address;
      end
      delay_post_ack0:
      begin
        if (R_W == 1'b1) begin
          sda_write = 1'b1;
          next_state = Send_data;
          if (~scl) begin
          sda_reg = data_received[DATA_LEN-1];
          end
        end
        else begin
          if (~scl) sda_write = 1'b0;
          next_state = Receive_data;
        end
        //break;
      end
      delay_post_ack1:
      begin
        if (~scl) sda_write = 1'b0;
        next_state = Stop;
        //break;
      end
      Send_data:
      begin
        //rdata_counter -= 1;
        if (~scl) begin
          sda_write = 1'b1;
          if (rdata_counter == 0) begin
            sda_write = 1'b0;
            next_state = Check_ACK_NACK;
          end
          else begin
            sda_reg = data_received[rdata_counter];
            next_state = Send_data;
          end
        end
        
        //break;
      end
      Check_ACK_NACK:
      begin
        sda_write = 1'b0;
        next_state = Stop;
        //break;
      end
      Receive_data:
      begin
        
        if (wdata_counter == 0) begin
          next_state = GiveACK;
          if (~scl) begin 
            sda_write = 1'b1;
            sda_reg = 1'b0;
          end
        end
        else begin
          if (scl) begin
            sda_reg = sda;
            received_data = (received_data << 1) + sda_reg;
          end
          next_state = Receive_data;
        end
        
        //break;
      end
      GiveACK:
      begin
        if (~scl) sda_write = 1'b0;
        next_state = Stop;
      end
      Stop: 
      begin
        sda_write = 1'b0;
        //break;
      end
    endcase
  end

  always @(posedge scl) begin
    case (current_state)
      Idle:
      begin
        stop_signal <= 1'b0;
      end
      Receive_address:
      begin
        start_signal <= 1'b0;
        address_counter <= address_counter - 1;

      end
      delay_post_ack0:
      begin
        if (R_W == 1'b1) begin
          reset_rdata_counter <= 1'b1;
        end
        else begin
          reset_wdata_counter <= 1'b1;
        end
        //break;
      end
      /*delay_post_ack1:
      begin
        //sda <= sda_reg;
        sda_reg = 1'b1;
        reset_address_counter = 1'b1;
        next_state = Receive_address;
        //break;
      end*/
      Send_data:
      begin
        rdata_counter <= rdata_counter - 1;
        //sda_reg <= data_received[rdata_counter-1];
      end
      Check_ACK_NACK:
      begin
        //
      end
      Receive_data:
      begin
        wdata_counter <= wdata_counter - 1;
        
        //break;
      end
      GiveACK:
      begin
        next_state = Stop;
      end
    endcase
  end

always @(start_signal) begin
  if(start_signal) begin
    next_state = Receive_address;
  end
end

always @(posedge scl) begin
  current_state <= next_state;
end

always @(negedge sda) begin
  if (scl) begin
    reset_address_counter <= 1'b1;
    start_signal <= 1'b1;
  end
  
end

always @(posedge sda) begin
  if (scl) stop_signal <= 1'b1;
end

always @(stop_signal) begin
  if (stop_signal) begin
    current_state <= Idle;
  end
end

always @(address_counter, reset_address_counter) begin
  if (reset_address_counter || address_counter < 0 || address_counter > ADDR_LEN) begin
    address_counter = ADDR_LEN;
    reset_address_counter = 0;
  end
end
always @(rdata_counter, reset_rdata_counter) begin
  if (reset_rdata_counter || rdata_counter < 0 || rdata_counter > DATA_LEN-1) begin
    rdata_counter = DATA_LEN-1;
    reset_rdata_counter = 0;
  end
end

always @(wdata_counter, reset_wdata_counter) begin
  if (reset_wdata_counter || wdata_counter < 0 || wdata_counter > DATA_LEN-1) begin
    wdata_counter = DATA_LEN-1;
    reset_wdata_counter = 0;
  end
end

endmodule