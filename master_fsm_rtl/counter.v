module counter(
               input            clk,
               input            rst_n,
               input            rst_count_2,
               input            count_inc,
               output reg [3:0] count
);

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) count <= 0;
    else 
    begin
        if(rst_count_2) count <= 0;
        else if(count_inc)
        begin
            count <= count + 1'b1;
        end
    end
end
endmodule