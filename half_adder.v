// =============================================================================
// Module      : half_adder
// Description : A Half Adder (HA) is the most basic building block of the
//               Wallace Tree compressor logic. It takes TWO single-bit inputs
//               and produces a SUM bit and a CARRY bit.
//
//               Truth table:
//                 a | b | sum | cout
//                 0 | 0 |  0  |  0
//                 0 | 1 |  1  |  0
//                 1 | 0 |  1  |  0
//                 1 | 1 |  0  |  1
//
//               In the Wallace Tree, a Half Adder is used whenever exactly
//               2 partial-product bits remain in a column after grouping
//               bits into sets of 3 for Full Adders. It "compresses" those
//               2 bits down to 1 sum bit (same column) + 1 carry bit
//               (passed to the next higher column).
// =============================================================================

module half_adder (
    input  wire a,      // first input bit
    input  wire b,      // second input bit
    output wire sum,    // sum output bit   = a XOR b
    output wire cout    // carry output bit = a AND b
);
    assign sum = a ^ b;
    assign cout = a & b;

endmodule
