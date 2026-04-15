`timescale 1ns/1ps

module tb_pipeline;

parameter DATA_WIDTH = 8;

reg clk;
reg rst;

reg [DATA_WIDTH-1:0] in_data;
reg start;

wire [DATA_WIDTH-1:0] out_data;
wire out_valid;
reg out_ready;

// Optional (since you exposed it)
wire fifo_in_ready;


// DUT
pipeline_top dut (
    .clk(clk),
    .rst(rst),
    .in_data(in_data),
    .start(start),
    .fifo_in_ready(fifo_in_ready),
    .out_data(out_data),
    .out_valid(out_valid),
    .out_ready(out_ready)
);


// Clock generation (100 MHz → 10ns period)
always #5 clk = ~clk;


// Stimulus
initial begin
    clk = 0;
    rst = 1;
    start = 0;
    in_data = 0;
    out_ready = 1;

    // Reset
    #20;
    rst = 0;

    // Send 10 values
    repeat (10) begin
        @(posedge clk);

        if (fifo_in_ready) begin
            in_data <= in_data + 1;
            start   <= 1;
        end else begin
            start   <= 0;
        end
    end

    // Stop input
    @(posedge clk);
    start <= 0;

    // Let pipeline drain
    #200;

    $finish;
end


// Monitor output
always @(posedge clk) begin
    if (out_valid && out_ready) begin
        $display("Time=%0t | Output=%0d", $time, out_data);
    end
end

endmodule
