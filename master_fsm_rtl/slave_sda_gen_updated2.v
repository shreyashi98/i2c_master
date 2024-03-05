module slave_sda_generate #(
    parameter ADDR_LEN = 7,
    parameter ADDR_COUNTER_LEN = 3,
    parameter DATA_LEN = 8,
    parameter DATA_COUNTER_LEN = 3
)(
    //input clk;
    input scl,
    inout sda,
    input receive_data1_ack,
    input receive_data2_ack,
    input[DATA_LEN-1:0] data1_received,
    input[DATA_LEN-1:0] data2_received,
    output[DATA_LEN-1:0] data1_sent,
    output[DATA_LEN-1:0] data2_sent

);

  reg [3:0] current_state = IDLE;
  reg [3:0] next_state = IDLE;
  reg R_W;
  reg sda_reg;
  reg start_signal = 1'b0;
  //reg stop_signal = 1'b0;
  reg sda_write = 1'b0;
  reg reset_address_counter;
  reg receive_data_reg = 1'b0;
  reg ack_reg;
  reg [ADDR_COUNTER_LEN:0] address_counter;
  reg reset_rdata_counter;
  reg [DATA_COUNTER_LEN-1:0] rdata_counter;
  reg reset_wdata_counter;
  reg [DATA_COUNTER_LEN-1:0] wdata_counter;
  reg [DATA_LEN-1:0] received_data1 = 8'b00000000;
  reg [DATA_LEN-1:0] received_data2 = 8'b00000000;
  reg [ADDR_LEN-1:0] slave_address = 7'b1011011;
  reg [ADDR_LEN-1:0] received_address = 7'b0000000;

  wire comp_bit;

  parameter IDLE = 4'b0000;
  parameter RECEIVE_ADDRESS = 4'b0001;
  parameter DELAY_POST_ACK0 = 4'b0010;
  parameter DELAY_POST_ACK1 = 4'b0011;
  parameter SEND_DATA1 = 4'b0100;
  parameter CHECK_DATA1_ACK = 4'b0101;
  parameter SEND_DATA2 = 4'b0110;
  parameter CHECK_DATA2_ACK = 4'b0111;
  parameter RECEIVE_DATA1 = 4'b1000;
  parameter RECEIVE_DATA1_ACK = 4'b1001;
  parameter RECEIVE_DATA2 = 4'b1010;
  parameter RECEIVE_DATA2_ACK = 4'b1011;
  parameter STOP = 4'b1100;

  assign comp_bit = (received_address == slave_address);
  assign data1_sent = received_data1;
  assign data2_sent = received_data2;
  assign sda = sda_write ? sda_reg : 1'bz;

  always @(*) begin
    if(start_signal) begin
      next_state = RECEIVE_ADDRESS;
    end
    case (current_state)
      RECEIVE_ADDRESS:
      begin
        if(scl) begin
          sda_reg = sda;
          if(address_counter == 1) R_W = sda_reg;
        end
        else if(~scl && address_counter == 0) begin
          if (comp_bit) begin
            sda_write = 1'b1;
            sda_reg = 1'b0;
            next_state = DELAY_POST_ACK0;
          end
          else begin
            sda_write = 1'b1;
            sda_reg = 1'bz;
            next_state = DELAY_POST_ACK1;
          end
        end

        else next_state = RECEIVE_ADDRESS;
      end
      DELAY_POST_ACK0:
      begin
        if (R_W == 1'b1) begin
          next_state = SEND_DATA1;
          if (~scl) begin
            sda_write = 1'b1;
            sda_reg = data1_received[DATA_LEN-1] ? 1'bz : 1'b0;
          end
        end
        else begin
          if (~scl) sda_write = 1'b0;
          next_state = RECEIVE_DATA1;
        end
      end
      DELAY_POST_ACK1:
      begin
        if (~scl) sda_write = 1'b0;
        next_state = STOP;
      end
      SEND_DATA1:
      begin
        if (~scl) begin
          if (rdata_counter == 0) begin
            sda_write = 1'b0;
            next_state = CHECK_DATA1_ACK;
          end
          else begin
            sda_write = 1'b1;
            sda_reg = data1_received[rdata_counter-1] ? 1'bz : 1'b0;
            next_state = SEND_DATA1;
          end
        end
      end

      CHECK_DATA1_ACK:
      begin
        if (scl) begin
          sda_reg = sda;
          ack_reg = sda_reg;
        end
        else begin
          if (ack_reg) begin
            next_state = STOP;
            sda_write = 1'b0;
          end
          else begin
            next_state = SEND_DATA2;
            sda_write = 1'b1;
            sda_reg = data2_received[DATA_LEN-1] ? 1'bz : 1'b0;
          end
        end
      end

      SEND_DATA2:
      begin
        if (~scl) begin
          if (rdata_counter == 0) begin
            sda_write = 1'b0;
            next_state = CHECK_DATA2_ACK;
          end
          else begin
            sda_write = 1'b1;
            sda_reg = data2_received[rdata_counter-1] ? 1'bz : 1'b0;
            next_state = SEND_DATA2;
          end
        end
      end

      CHECK_DATA2_ACK:
      begin
        next_state = STOP;
      end

      RECEIVE_DATA1:
      begin
        if (wdata_counter == 0) begin
          next_state = RECEIVE_DATA1_ACK;
          if (~scl) begin 
            sda_write = 1'b1;
            sda_reg = receive_data1_ack ? 1'bz : 1'b0;
          end
        end
        else begin
          if (scl) begin
            sda_reg = sda;
            receive_data_reg = sda_reg;
          end
          next_state = RECEIVE_DATA1;
        end
      end

      RECEIVE_DATA1_ACK:
      begin
        if (~scl) sda_write = 1'b0;
        next_state = receive_data1_ack ? STOP : RECEIVE_DATA2;
      end

      RECEIVE_DATA2:
      begin
        if (wdata_counter == 0) begin
          next_state = RECEIVE_DATA2_ACK;
          if (~scl) begin 
            sda_write = 1'b1;
            sda_reg = receive_data2_ack ? 1'bz : 1'b0;
          end
        end
        else begin
          if (scl) begin
            sda_reg = sda;
            receive_data_reg = sda_reg;
          end
          next_state = RECEIVE_DATA2;
        end
      end
      RECEIVE_DATA2_ACK:
      begin
        if (~scl) sda_write = 1'b0;
        next_state = STOP;
      end
      STOP: 
      begin
        sda_write = 1'b0;
      end
    endcase

    if (reset_address_counter || address_counter < 0 || address_counter > ADDR_LEN) begin
      address_counter = ADDR_LEN;
      reset_address_counter = 0;
    end

    if (reset_rdata_counter || rdata_counter < 0 || rdata_counter > DATA_LEN-1) begin
      rdata_counter = DATA_LEN-1;
      reset_rdata_counter = 0;
    end

    if (reset_wdata_counter || wdata_counter < 0 || wdata_counter > DATA_LEN-1) begin
      wdata_counter = DATA_LEN-1;
      reset_wdata_counter = 0;
    end
  end

  always @(posedge scl) begin
    case (current_state)
      IDLE:
      begin
        //stop_signal <= 1'b0;
      end

      RECEIVE_ADDRESS:
      begin
        start_signal <= 1'b0;
        address_counter <= address_counter - 1;
      end

      DELAY_POST_ACK0:
      begin
        if (R_W == 1'b1) begin
          reset_rdata_counter <= 1'b1;
        end
        else begin
          reset_wdata_counter <= 1'b1;
        end
      end

      SEND_DATA1:
      begin
        rdata_counter <= rdata_counter - 1;
      end

      CHECK_DATA1_ACK:
      begin
        reset_rdata_counter <= 1'b1;
      end

      SEND_DATA2:
      begin
        rdata_counter <= rdata_counter - 1;
      end

      RECEIVE_DATA1:
      begin
        wdata_counter <= wdata_counter - 1;
      end

      RECEIVE_DATA1_ACK:
      begin
        reset_wdata_counter <= 1'b1;
      end

      RECEIVE_DATA2:
      begin
        wdata_counter <= wdata_counter - 1;
      end
    endcase
  end

  always @(negedge scl) begin
    case (current_state)
      RECEIVE_ADDRESS:
      begin
        if (address_counter != 0) received_address <= (received_address << 1) + sda_reg;
      end

      RECEIVE_DATA1:
      begin
        received_data1 <= (received_data1 << 1) + receive_data_reg;
      end
      
      RECEIVE_DATA2:
      begin
        received_data2 <= (received_data2 << 1) + receive_data_reg;
      end
    endcase
  end

  /*always @(start_signal) begin
    if(start_signal) begin
      next_state = RECEIVE_ADDRESS;
    end
  end*/

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
    if (scl) begin
        current_state <= IDLE;
        //stop_signal <= 1'b1;
    end
  end

  /*always @(stop_signal) begin
    if (stop_signal) begin
      current_state <= IDLE;
    end
  end*/

  /*always @(address_counter, reset_address_counter) begin
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
  end*/

endmodule