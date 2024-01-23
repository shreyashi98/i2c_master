// `include "scl_gen.v"
// `include "sda_gen.v"

module fsm_master #(
    parameter FREQ_DIFF = 4,
    parameter ADDR_LEN  = 7,
    parameter DATA_LEN  = 8
                            )
    (
        input                   clk,
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
    wire       rst_count;
    wire       wait_for_sync;
    wire       add_sent;
    wire       data_received;
    wire       data_sent;

    scl_generate #(
        .THRESHOLD          (FREQ_DIFF/2    ),
        .ADDR_LEN           (ADDR_LEN       ),
        .DATA_LEN           (DATA_LEN       )
        ) 
        SCL
        (
            .clk                (clk            ),
            .state_master       (state_master   ),
            .rst_count          (rst_count      ),
            .count_ctrl         (count_ctrl     ),
            .scl                (scl            ),
            .wait_for_sync      (wait_for_sync  ),
            .add_sent           (add_sent       ),
            .data_received      (data_received  ),
            .data_sent          (data_sent      )
        );
    
    sda_generate #(
        .THRESHOLD          (FREQ_DIFF/2    ),
        .ADDR_LEN           (ADDR_LEN       ),
        .DATA_LEN           (DATA_LEN       )
        ) SDA(
            .clk                (clk            ),
            .start              (start          ),
            .scl                (scl            ),
            .count_ctrl         (count_ctrl     ),
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
            .state_master       (state_master   ),
            .free               (free           )
        );

endmodule