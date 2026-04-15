module fpga_top (
    input  wire        CLK100MHZ,
    input  wire [1:0]  btn,     // btn[0]=start, btn[1]=reset
    input  wire [3:0]  sw,
    output reg  [7:0]  LED
);

wire start_pulse;
wire rst;


// ================= BUTTON CONDITIONERS =================

// BTN0 → START (pulse)
btn_conditioner u_btn_start (
    .clk(CLK100MHZ),
    .rst(1'b0),
    .btn_raw(btn[0]),
    .btn_level(),
    .btn_pressed(start_pulse)
);

// BTN1 → RESET (level)
btn_conditioner u_btn_rst (
    .clk(CLK100MHZ),
    .rst(1'b0),
    .btn_raw(btn[1]),
    .btn_level(rst),
    .btn_pressed()
);


// ================= INPUT DATA =================
wire [7:0] in_data;
assign in_data = {4'b0000, sw};


// ================= PIPELINE =================
wire [7:0] out_data;
wire out_valid;

pipeline_top uut (
    .clk(CLK100MHZ),
    .rst(rst),

    .in_data(in_data),
    .start(start_pulse),

    .out_data(out_data),
    .out_valid(out_valid),
    .out_ready(1'b1)
);


// ================= OUTPUT =================
always @(posedge CLK100MHZ) begin
    if (rst)
        LED <= 8'b0;
    else if (out_valid)
        LED <= out_data;
end

endmodule



// =====================================================
// =============== BUTTON CONDITIONER ===================
// =====================================================

module btn_conditioner #(
    parameter COUNT_MAX = 2_000_000   // ~20ms @100MHz
)(
    input  wire clk,
    input  wire rst,
    input  wire btn_raw,

    output wire btn_level,
    output wire btn_pressed
);

    // -------- Synchronizer --------
    (* ASYNC_REG = "TRUE" *) reg ff1, ff2;
    always @(posedge clk) begin
        ff1 <= btn_raw;
        ff2 <= ff1;
    end
    wire btn_sync = ff2;


    // -------- Debounce --------
    reg [20:0] count;
    reg stable;

    always @(posedge clk) begin
        if (rst) begin
            count  <= 0;
            stable <= 0;
        end
        else begin
            if (btn_sync != stable) begin
                if (count < COUNT_MAX)
                    count <= count + 1;
                else begin
                    stable <= btn_sync;
                    count  <= 0;
                end
            end else begin
                count <= 0;
            end
        end
    end

    assign btn_level = stable;


    // -------- Edge Detect --------
    reg stable_d;

    always @(posedge clk) begin
        if (rst)
            stable_d <= 0;
        else
            stable_d <= stable;
    end

    assign btn_pressed = stable & ~stable_d;

endmodule
