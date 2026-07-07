// =============================================================================
// Module      : full_adder
// Description : A Full Adder (FA) is the second core building block of the
//               Wallace Tree compressor logic. It takes THREE single-bit
//               inputs and produces a SUM bit and a CARRY bit. This is what
//               lets a Wallace Tree be much faster than a simple ripple
//               adder chain: one FA can absorb 3 bits in a single step.
//
//               Truth table:
//                 a | b | cin | sum | cout
//                 0 | 0 |  0  |  0  |  0
//                 0 | 0 |  1  |  1  |  0
//                 0 | 1 |  0  |  1  |  0
//                 0 | 1 |  1  |  0  |  1
//                 1 | 0 |  0  |  1  |  0
//                 1 | 0 |  1  |  0  |  1
//                 1 | 1 |  0  |  0  |  1
//                 1 | 1 |  1  |  1  |  1
//
//               In the Wallace Tree, a Full Adder is used whenever 3 (or a
//               multiple of 3) partial-product bits are present in a single
//               column. It "compresses" those 3 bits down to 1 sum bit
//               (stays in the same column) + 1 carry bit (passed up to the
//               next higher column). This 3-bits-to-2-bits reduction is
//               often called a "3:2 compressor".
// =============================================================================

module full_adder (
    input  wire a,      // first input bit
    input  wire b,      // second input bit
    input  wire cin,     // third input bit (historically called "carry-in")
    output wire sum,    // sum output bit
    output wire cout    // carry output bit, goes to the next higher column
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule
