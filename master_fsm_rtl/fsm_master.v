// Master Controller
module fsm_master #(
    parameter FREQ_DIFF = 4,
    parameter T_LOW     = 6,
    parameter T_HIGH    = 4,
    parameter ADDR_LEN  = 7,
    parameter SETUP_SCL_START = 4,
    parameter DATA_LEN  = 8
                            )
    (
        input                   clk,
        input                   rst_n,
        input                   start,
        input [ADDR_LEN-1:0]    add_reg,
        input                   R_W,
        input [DATA_LEN-1:0]    data_1,
        input [DATA_LEN-1:0]    data_2,
        output                  scl,
        inout                   sda,
        output                  free
    );


    wire [3:0] state_master;
    wire [6:0] count_ctrl;
    wire [3:0] count;
    wire       count_inc;
    wire       rst_count_2;
    wire       rst_count;
    wire       wait_for_sync;
    wire       add_sent;
    wire       data_received;
    wire       data_sent;

    scl_generate #(
        .THRESHOLD          (FREQ_DIFF/2    ),
        .T_LOW              (T_LOW          ),
        .T_HIGH             (T_HIGH         ),
        .ADDR_LEN           (ADDR_LEN       ),
        .SETUP_SCL_START    (SETUP_SCL_START),
        .DATA_LEN           (DATA_LEN       )
        ) 
        SCL
        (
            .clk                (clk            ),
            .rst_n              (rst_n          ),
            .state_master       (state_master   ),
            .rst_count          (rst_count      ),
            .count              (count          ),
            .count_ctrl         (count_ctrl     ),
            .scl                (scl            ),
            .wait_for_sync      (wait_for_sync  ),
            .add_sent           (add_sent       ),
            .data_received      (data_received  ),
            .data_sent          (data_sent      ),
            .count_inc          (count_inc      )
        );
    
    sda_generate #(
        .THRESHOLD          (FREQ_DIFF/2    ),
        .ADDR_LEN           (ADDR_LEN       ),
        .DATA_LEN           (DATA_LEN       )
        ) SDA(
            .clk                (clk            ),
            .rst_n              (rst_n          ),
            .start              (start          ),
            .scl                (scl            ),
            .count_ctrl         (count_ctrl     ),
            .count              (count          ),
            .wait_for_sync      (wait_for_sync  ),
            .add_sent           (add_sent       ),
            .data_received      (data_received  ),
            .data_sent          (data_sent      ),
            .add_reg            (add_reg        ),
            .R_W                (R_W            ),
            .data_1             (data_1         ),
            .data_2             (data_2         ),
            .sda                (sda            ),
            .rst_count          (rst_count      ),
            .rst_count_2        (rst_count_2    ),
            .state_master       (state_master   ),
            .free               (free           )
        );

    counter COUNTER(
            .clk                (clk            ),
            .rst_n              (rst_n          ),
            .rst_count_2        (rst_count_2    ),
            .count_inc          (count_inc      ),
            .count              (count          )
    );

endmodule