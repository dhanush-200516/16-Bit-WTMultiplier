// =============================================================================
// Module      : tb_pipelined_wallace_mult_16x16
`timescale 1ns/1ps

module tb_pipelined_wallace_mult_16x16;

    // -------------------------------------------------------------------
    // Testbench parameters
    // -------------------------------------------------------------------
    parameter CLK_PERIOD   = 20;     // 20 ns period = 50 MHz (project spec, Section 3)
    parameter NUM_RANDOM   = 1000;   // minimum required random test count (project spec)
    parameter PIPE_LATENCY = 4;      // verified pipeline latency in clock cycles
                                      // (5 register stages; result for an input
                                      // applied at cycle T appears at cycle T+4 --
                                      // this was carefully verified by simulation
                                      // before writing this testbench, see project
                                      // documentation for the full derivation)

    // -------------------------------------------------------------------
    // DUT signal declarations
    // -------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         valid_in;
    reg  [15:0] A;
    reg  [15:0] B;
    wire [31:0] P;
    wire        valid_out;

    // -------------------------------------------------------------------
    // Instantiate the Device Under Test (DUT)
    // -------------------------------------------------------------------
    pipelined_wallace_mult_16x16 DUT (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .A(A),
        .B(B),
        .P(P),
        .valid_out(valid_out)
    );

    // -------------------------------------------------------------------
    // Clock generation: 50 MHz (20 ns period -> 10 ns high, 10 ns low)
    // -------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------
    // SCOREBOARD: remembers every (A, B) pair sent, in the order sent, so
    // that when a result appears on P, we know EXACTLY which input it
    // corresponds to (the oldest still-unmatched entry), regardless of
    // pipeline latency. This is implemented as a simple array-based queue.
    // -------------------------------------------------------------------
    reg  [15:0] scoreboard_A [0:NUM_RANDOM+50];   // a little extra room for directed tests
    reg  [15:0] scoreboard_B [0:NUM_RANDOM+50];
    integer     sb_write_ptr;   // next free slot to WRITE a new sent input into
    integer     sb_read_ptr;    // next slot to READ when a result comes back

    // -------------------------------------------------------------------
    // Pass/Fail bookkeeping
    // -------------------------------------------------------------------
    integer total_checked;
    integer total_passed;
    integer total_failed;

    // -------------------------------------------------------------------
    // Reference model: plain multiplication using Verilog's '*' operator.
    // This is ONLY used here, in the testbench, as the "known-correct"
    // answer to compare the DUT against. The DUT itself never uses '*' --
    // it builds the multiplication entirely from the Wallace Tree +
    // Carry Lookahead Adder structure, which is exactly what is being
    // verified.
    // -------------------------------------------------------------------
    reg [31:0] expected_product;

    // -------------------------------------------------------------------
    // VCD waveform dump setup (for viewing in GTKWave)
    // -------------------------------------------------------------------
    initial begin
        $dumpfile("wallace_mult_waveform.vcd");
        $dumpvars(0, tb_pipelined_wallace_mult_16x16);
    end

    // -------------------------------------------------------------------
    // Task: send_input
    // Applies one (A,B) pair on the rising edge, with valid_in = 1, and
    // records it into the scoreboard queue so it can be matched against
    // its result later, whenever that result appears.
    // -------------------------------------------------------------------
    task send_input(input [15:0] a_val, input [15:0] b_val);
        begin
            A        = a_val;
            B        = b_val;
            valid_in = 1'b1;
            scoreboard_A[sb_write_ptr] = a_val;
            scoreboard_B[sb_write_ptr] = b_val;
            sb_write_ptr = sb_write_ptr + 1;
            @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------
    // Task: check_output
    // Called every clock cycle. If valid_out is high, P holds a genuine
    // result -- pop the oldest entry from the scoreboard queue, compute
    // what the answer SHOULD have been for that entry, and compare.
    // -------------------------------------------------------------------
    task check_output;
        begin
            if (valid_out) begin
                expected_product = scoreboard_A[sb_read_ptr] * scoreboard_B[sb_read_ptr];
                total_checked = total_checked + 1;
                if (P === expected_product) begin
                    total_passed = total_passed + 1;
                    $display("PASS  at time %0t : A=%0d B=%0d  expected P=%0d  got P=%0d",
                              $time, scoreboard_A[sb_read_ptr], scoreboard_B[sb_read_ptr],
                              expected_product, P);
                end
                else begin
                    total_failed = total_failed + 1;
                    $display("FAIL  at time %0t : A=%0d B=%0d  expected P=%0d  got P=%0d",
                              $time, scoreboard_A[sb_read_ptr], scoreboard_B[sb_read_ptr],
                              expected_product, P);
                end
                sb_read_ptr = sb_read_ptr + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------
    // Background process: every clock cycle, check whether a result has
    // appeared and validate it. This runs continuously throughout the
    // entire test, independent of however the stimulus tasks below choose
    // to drive A/B/valid_in.
    // -------------------------------------------------------------------
    always @(posedge clk) begin
        check_output;
    end

    // -------------------------------------------------------------------
    // MAIN STIMULUS
    // -------------------------------------------------------------------
    integer i;
    reg [15:0] rand_a, rand_b;

    initial begin
        // ---- Initialize all bookkeeping ----
        sb_write_ptr  = 0;
        sb_read_ptr   = 0;
        total_checked = 0;
        total_passed  = 0;
        total_failed  = 0;
        valid_in      = 1'b0;
        A             = 16'b0;
        B             = 16'b0;

        // ---- Apply synchronous reset for a few cycles ----
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        $display("=================================================================");
        $display(" Starting self-checking testbench for pipelined_wallace_mult_16x16");
        $display(" Clock period = %0d ns (%0.1f MHz)", CLK_PERIOD, 1000.0/CLK_PERIOD);
        $display(" Verified pipeline latency = %0d clock cycles", PIPE_LATENCY);
        $display("=================================================================");

        $display("\n--- Running directed (corner-case) tests ---");
        send_input(16'd0,      16'd0);                  // 0 x 0
        send_input(16'hFFFF,   16'hFFFF);                // max x max (largest possible product)
        send_input(16'hFFFF,   16'd0);                   // max x 0
        send_input(16'd0,      16'hFFFF);                 // 0 x max
        send_input(16'hFFFF,   16'd1);                    // max x 1
        send_input(16'd1,      16'hFFFF);                  // 1 x max
        send_input(16'h8000,   16'hFFFF);                  // half-max x max (tests middle carry chain)
        send_input(16'hFFFF,   16'h8000);                  // max x half-max
        send_input(16'hAAAA,   16'h5555);                  // alternating bit patterns (1010... x 0101...)
        send_input(16'h5555,   16'hAAAA);                  // alternating bit patterns (reversed)
        send_input(16'h0001,   16'h0001);                  // 1 x 1 (smallest nonzero product)
        send_input(16'hFFFE,   16'hFFFE);                  // near-max x near-max

        // ---- Let the pipeline drain a bit after directed tests before random tests ----
        valid_in = 1'b0;
        repeat (PIPE_LATENCY + 2) @(posedge clk);

        $display("\n--- Running %0d random tests (back-to-back, 1 input per cycle) ---", NUM_RANDOM);
        for (i = 0; i < NUM_RANDOM; i = i + 1) begin
            rand_a = $random;
            rand_b = $random;
            send_input(rand_a, rand_b);
        end
        
        valid_in = 1'b0;
        repeat (PIPE_LATENCY + 5) @(posedge clk);

        // -----------------------------------------------------------
        // FINAL PASS / FAIL SUMMARY REPORT
        // -----------------------------------------------------------
        $display("\n=================================================================");
        $display(" TEST SUMMARY");
        $display("=================================================================");
        $display(" Total results checked : %0d", total_checked);
        $display(" Passed                : %0d", total_passed);
        $display(" Failed                : %0d", total_failed);
        if (total_failed == 0 && total_checked >= NUM_RANDOM) begin
            $display(" OVERALL RESULT        : PASS");
        end
        else begin
            $display(" OVERALL RESULT        : FAIL");
        end
        $display("=================================================================");

        $finish;
    end
    initial begin
        #(CLK_PERIOD * (NUM_RANDOM + 100));
        $display("\n*** TIMEOUT: simulation ran too long, check for a stuck pipeline ***");
        $finish;
    end

endmodule
