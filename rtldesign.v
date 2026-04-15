// ============================================================
//  fifo_stream.v
//  Synchronous FIFO with AXI-S style valid/ready handshake.
//
//  DEPTH must be a power of 2 so that ADDR_WIDTH-bit pointers
//  wrap naturally without extra modulo logic.
//
//  out_data is COMBINATORIAL (show-ahead / fall-through).
//  This ensures out_valid and out_data are always aligned -
//  no 1-cycle gap when the FIFO fills from empty.
// ============================================================
module fifo_stream #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8,
    parameter ADDR_WIDTH = 3        // must equal log2(DEPTH)
)(
    input  wire                     clk,
    input  wire                     rst,

    // ── Upstream (producer) port ──────────────────────────
    input  wire [DATA_WIDTH-1:0]    in_data,
    input  wire                     in_valid,   // producer has data
    output wire                     in_ready,   // we can accept data

    // ── Downstream (consumer) port ────────────────────────
    output wire [DATA_WIDTH-1:0]    out_data,   // FIX: wire, not reg (see below)
    output wire                     out_valid,  // we have data to give
    input  wire                     out_ready   // consumer can accept
);

    // ── Internal memory ───────────────────────────────────
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ── Pointers and occupancy ────────────────────────────
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   count;     // one extra bit: holds 0 to DEPTH

    // ── Status flags ──────────────────────────────────────
    wire empty = (count == 0);
    wire full  = (count == DEPTH);

    // ── Handshake enables (named for readability) ─────────
    // FIX: use wr_en / rd_en instead of repeating the compound condition
    wire wr_en = in_valid  && in_ready;   // valid write this cycle
    wire rd_en = out_valid && out_ready;  // valid read  this cycle

    // ── Flow-control outputs ──────────────────────────────
    assign in_ready  = !full;     // accept input  when not full
    assign out_valid = !empty;    // present output when not empty

    // ─────────────────────────────────────────────────────
    //  WRITE PATH
    //  Latch incoming data into memory on every accepted write.
    // ─────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_ptr] <= in_data;
    end

    // Advance write pointer; wraps automatically at 2^ADDR_WIDTH
    always @(posedge clk) begin
        if (rst)        wr_ptr <= 0;
        else if (wr_en) wr_ptr <= wr_ptr + 1;
    end

    // ─────────────────────────────────────────────────────
    //  READ PATH
    //  FIX: out_data is combinatorial, NOT registered.
    //
    //  The previous registered version had a 1-cycle bug:
    //    - Cycle N  : write into empty FIFO → count becomes 1
    //                 out_valid goes HIGH (combinatorial from count)
    //    - Cycle N+1: out_data STILL holds old/reset value because
    //                 the "if (!empty)" always-block fires one edge late.
    //  => Receiver sees out_valid=1 with stale out_data. Data corruption.
    //
    //  Combinatorial read removes the latency entirely:
    //  out_data = mem[rd_ptr] is always the current head of the FIFO,
    //  so out_valid and out_data are always in sync.
    // ─────────────────────────────────────────────────────
    assign out_data = mem[rd_ptr];   // show-ahead / fall-through output

    // Advance read pointer on every accepted read
    always @(posedge clk) begin
        if (rst)        rd_ptr <= 0;
        else if (rd_en) rd_ptr <= rd_ptr + 1;
    end

    // ─────────────────────────────────────────────────────
    //  OCCUPANCY COUNTER
    //  2'b11 (simultaneous read + write) → count unchanged (correct)
    //  2'b00 (idle)                      → count unchanged (correct)
    // ─────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst)
            count <= 0;
        else
            case ({wr_en, rd_en})
                2'b10:   count <= count + 1;   // write only
                2'b01:   count <= count - 1;   // read  only
                default: count <= count;        // idle or simultaneous R+W
            endcase
    end

endmodule


// ============================================================
//  ram_stream.v
//  Functionally identical to fifo_stream but uses a separately
//  named memory so Vivado can infer it as a block RAM (BRAM)
//  rather than distributed LUT-RAM when DEPTH is large enough.
//
//  Same wr_en / rd_en refactor and combinatorial-read fix apply.
// ============================================================
module ram_stream #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8,
    parameter ADDR_WIDTH = 3
)(
    input  wire                     clk,
    input  wire                     rst,

    // ── Upstream port ─────────────────────────────────────
    input  wire [DATA_WIDTH-1:0]    in_data,
    input  wire                     in_valid,
    output wire                     in_ready,

    // ── Downstream port ───────────────────────────────────
    output wire [DATA_WIDTH-1:0]    out_data,   // FIX: wire (same bug as FIFO)
    output wire                     out_valid,
    input  wire                     out_ready
);

    reg [DATA_WIDTH-1:0] ram_mem [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   count;

    wire empty = (count == 0);
    wire full  = (count == DEPTH);

    // Named handshake enables
    wire wr_en = in_valid  && in_ready;
    wire rd_en = out_valid && out_ready;

    assign in_ready  = !full;
    assign out_valid = !empty;

    // ── Write path ────────────────────────────────────────
    always @(posedge clk) begin
        if (wr_en)
            ram_mem[wr_ptr] <= in_data;
    end

    always @(posedge clk) begin
        if (rst)        wr_ptr <= 0;
        else if (wr_en) wr_ptr <= wr_ptr + 1;
    end

    // ── Read path (combinatorial output - same fix as FIFO) ──
    assign out_data = ram_mem[rd_ptr];

    always @(posedge clk) begin
        if (rst)        rd_ptr <= 0;
        else if (rd_en) rd_ptr <= rd_ptr + 1;
    end

    // ── Occupancy counter ─────────────────────────────────
    always @(posedge clk) begin
        if (rst)
            count <= 0;
        else
            case ({wr_en, rd_en})
                2'b10:   count <= count + 1;
                2'b01:   count <= count - 1;
                default: count <= count;
            endcase
    end

endmodule


// ============================================================
//  rom_lut.v
//  Read-only lookup table. Single-entry output pipeline register
//  with correct AXI-S handshake.
//
//  in_ready uses the "elastic buffer" condition:
//    ready = downstream is ready  OR  output slot is empty
//  This allows accepting a new input whenever the output reg
//  is free, without waiting for the downstream to explicitly ACK.
//
//  No changes needed here - logic was already correct.
// ============================================================
module rom_lut #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8,
    parameter ADDR_WIDTH = 3
)(
    input  wire                     clk,
    input  wire                     rst,

    // ── Upstream port ─────────────────────────────────────
    input  wire [DATA_WIDTH-1:0]    in_data,    // lower bits used as ROM address
    input  wire                     in_valid,
    output wire                     in_ready,

    // ── Downstream port ───────────────────────────────────
    output reg  [DATA_WIDTH-1:0]    out_data,
    output reg                      out_valid,
    input  wire                     out_ready
);

    // ── ROM contents (synthesises to LUT-ROM or BRAM) ─────
    reg [DATA_WIDTH-1:0] rom_mem [0:DEPTH-1];

    initial begin
        rom_mem[0] = 8'd10;
        rom_mem[1] = 8'd20;
        rom_mem[2] = 8'd30;
        rom_mem[3] = 8'd40;
        rom_mem[4] = 8'd50;
        rom_mem[5] = 8'd60;
        rom_mem[6] = 8'd70;
        rom_mem[7] = 8'd80;
    end

    // Use only the address bits from in_data
    wire [ADDR_WIDTH-1:0] addr = in_data[ADDR_WIDTH-1:0];

    // ── Backpressure: accept new data when output slot is free ──
    // "Elastic buffer" condition:
    //   - If out_valid=0 the output register is empty → always ready
    //   - If out_valid=1 but out_ready=1 the slot drains this cycle → ready
    assign in_ready = out_ready || !out_valid;

    // ── Output pipeline register ──────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            out_data  <= 0;
            out_valid <= 0;
        end
        else begin
            if (in_valid && in_ready) begin
                // Accept new input: latch ROM lookup result
                out_data  <= rom_mem[addr];
                out_valid <= 1'b1;
            end
            else if (out_ready) begin
                // Downstream consumed the word; clear valid
                // (out_data value retained but irrelevant)
                out_valid <= 1'b0;
            end
            // else: out_valid=1, out_ready=0 → hold, no change
        end
    end

endmodule


// ============================================================
//  pipeline_top.v
//  Chains FIFO → RAM → ROM into a 3-stage streaming pipeline.
//
//  Data flow:
//    in_data → [FIFO buffer] → [RAM buffer] → [ROM LUT] → out_data
//
//  FIX: in_ready from the FIFO was left unconnected (.in_ready()).
//  Floating backpressure means data is silently dropped when the
//  FIFO is full. It is now wired to the fifo_in_ready output port
//  so the upstream controller can gate 'start' accordingly.
// ============================================================
module pipeline_top #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8,
    parameter ADDR_WIDTH = 3
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire [DATA_WIDTH-1:0]    in_data,
    input  wire                     start,       // acts as in_valid for FIFO

    // FIX: expose FIFO backpressure so upstream can stall 'start'
    output wire                     fifo_in_ready,

    output wire [DATA_WIDTH-1:0]    out_data,
    output wire                     out_valid,
    input  wire                     out_ready
);

    // ── Stage 1 → Stage 2 interface wires ─────────────────
    wire [DATA_WIDTH-1:0] fifo_out_data;
    wire                  fifo_out_valid;
    wire                  fifo_out_ready;   // driven by ram_stream.in_ready

    // ── Stage 2 → Stage 3 interface wires ─────────────────
    wire [DATA_WIDTH-1:0] ram_out_data;
    wire                  ram_out_valid;
    wire                  ram_out_ready;    // driven by rom_lut.in_ready

    // ── Stage 1: Input FIFO buffer ────────────────────────
    fifo_stream u_fifo (
        .clk      (clk),
        .rst      (rst),
        .in_data  (in_data),
        .in_valid (start),
        .in_ready (fifo_in_ready),      // FIX: was left unconnected
        .out_data (fifo_out_data),
        .out_valid(fifo_out_valid),
        .out_ready(fifo_out_ready)
    );

    // ── Stage 2: RAM buffer ───────────────────────────────
    ram_stream u_ram (
        .clk      (clk),
        .rst      (rst),
        .in_data  (fifo_out_data),
        .in_valid (fifo_out_valid),
        .in_ready (fifo_out_ready),     // backpressure back to FIFO
        .out_data (ram_out_data),
        .out_valid(ram_out_valid),
        .out_ready(ram_out_ready)
    );

    // ── Stage 3: ROM lookup table ─────────────────────────
    rom_lut u_rom (
        .clk      (clk),
        .rst      (rst),
        .in_data  (ram_out_data),
        .in_valid (ram_out_valid),
        .in_ready (ram_out_ready),      // backpressure back to RAM
        .out_data (out_data),
        .out_valid(out_valid),
        .out_ready(out_ready)
    );

endmodule
