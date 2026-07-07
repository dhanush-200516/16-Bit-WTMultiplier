// =============================================================================
// Module      : cla_32bit
// Pipeline    : STAGE 5  (final addition)
// Description : A 32-bit Carry Lookahead Adder (CLA). Adds the two final
//               32-bit rows produced by the Wallace Tree (after all 6
//               reduction levels) to produce the final product P[31:0].
//
//               WHY CARRY LOOKAHEAD INSTEAD OF RIPPLE CARRY?
//               A plain ripple-carry adder must wait for the carry to
//               propagate one bit at a time, all the way from bit 0 to
//               bit 31 -- this is slow. A Carry Lookahead Adder instead
//               pre-computes "generate" (g = a&b, a carry is generated
//               here regardless of incoming carry) and "propagate"
//               (p = a^b, an incoming carry would pass through this bit)
//               signals for every bit, then combines them with lookahead
//               logic so that carries within a group of bits are all
//               available almost immediately, instead of rippling one
//               at a time.
//
//               STRUCTURE: 8 x 4-bit CLA blocks, chained together.
//               Each 4-bit block computes its own internal carries using
//               full lookahead logic, AND produces two block-level signals:
//                 Block Generate (BG) = would this block create a carry-out
//                                       even with no carry-in?
//                 Block Propagate (BP) = would this block pass a carry-in
//                                        straight through to its carry-out?
//               These BG/BP signals let the carry INTO each block be
//               computed directly, without waiting for the previous
//               block's internal bit-by-bit carry chain to finish --
//               this is the "lookahead" that gives the adder its speed.
// =============================================================================
module cla_32bit (
    input  wire [31:0] A_in,    // first operand  (Wallace Tree Row A)
    input  wire [31:0] B_in,    // second operand (Wallace Tree Row B)
    output wire [31:0] Sum,     // 32-bit sum output (this is the final product P)
    output wire        Cout     // final carry-out (unused for valid 16x16 multiply)                               
    // -------------------------------------------------------------------
);
    // Step 1: Generate (g) and Propagate (p) for every one of the 32 bits.
    //   g[i] = A_in[i] & B_in[i]   -> a carry is generated at bit i
    //   p[i] = A_in[i] ^ B_in[i]   -> a carry-in would propagate through bit i
    // -------------------------------------------------------------------
    wire [31:0] g, p;
    assign g = A_in & B_in;
    assign p = A_in ^ B_in;

    // -------------------------------------------------------------------
    // Step 2: Per-block (4-bit) lookahead carry logic.
    // We have 8 blocks: block 0 = bits [3:0], block 1 = bits [7:4], ... block 7 = bits [31:28]
    // block_cin[k]  = carry coming IN to block k
    // block_cout[k] = carry coming OUT of block k (= block_cin[k+1])
    // block_G[k], block_P[k] = block-level Generate / Propagate (used for inter-block lookahead)
    // -------------------------------------------------------------------
    wire [7:0] block_G, block_P;     // block-level generate/propagate
    wire [8:0] block_cin;            // block_cin[0] = overall Cin (=0 for this design),
                                      // block_cin[1..7] = carry into blocks 1-7,
                                      // block_cin[8]    = final carry-out of the whole adder
    assign block_cin[0] = 1'b0;

    // -------------------------------------------------------------------
    // Step 3: Inter-block carry lookahead.
    // -------------------------------------------------------------------
    assign block_cin[1] = block_G[0] | (block_P[0] & block_cin[0]);
    assign block_cin[2] = block_G[1] | (block_P[1] & block_cin[1]);
    assign block_cin[3] = block_G[2] | (block_P[2] & block_cin[2]);
    assign block_cin[4] = block_G[3] | (block_P[3] & block_cin[3]);
    assign block_cin[5] = block_G[4] | (block_P[4] & block_cin[4]);
    assign block_cin[6] = block_G[5] | (block_P[5] & block_cin[5]);
    assign block_cin[7] = block_G[6] | (block_P[6] & block_cin[6]);
    assign block_cin[8] = block_G[7] | (block_P[7] & block_cin[7]);  // final carry-out of the adder
    assign Cout = block_cin[8];

    // -------------------------------------------------------------------
    // Step 4: Instantiate the 8 individual 4-bit CLA blocks.
    // -------------------------------------------------------------------

    cla_block_4bit BLOCK0 (
        .g(g[3:0]), .p(p[3:0]), .cin(block_cin[0]),
        .sum(Sum[3:0]), .block_G(block_G[0]), .block_P(block_P[0])
    );

    cla_block_4bit BLOCK1 (
        .g(g[7:4]), .p(p[7:4]), .cin(block_cin[1]),
        .sum(Sum[7:4]), .block_G(block_G[1]), .block_P(block_P[1])
    );

    cla_block_4bit BLOCK2 (
        .g(g[11:8]), .p(p[11:8]), .cin(block_cin[2]),
        .sum(Sum[11:8]), .block_G(block_G[2]), .block_P(block_P[2])
    );

    cla_block_4bit BLOCK3 (
        .g(g[15:12]), .p(p[15:12]), .cin(block_cin[3]),
        .sum(Sum[15:12]), .block_G(block_G[3]), .block_P(block_P[3])
    );

    cla_block_4bit BLOCK4 (
        .g(g[19:16]), .p(p[19:16]), .cin(block_cin[4]),
        .sum(Sum[19:16]), .block_G(block_G[4]), .block_P(block_P[4])
    );

    cla_block_4bit BLOCK5 (
        .g(g[23:20]), .p(p[23:20]), .cin(block_cin[5]),
        .sum(Sum[23:20]), .block_G(block_G[5]), .block_P(block_P[5])
    );

    cla_block_4bit BLOCK6 (
        .g(g[27:24]), .p(p[27:24]), .cin(block_cin[6]),
        .sum(Sum[27:24]), .block_G(block_G[6]), .block_P(block_P[6])
    );

    cla_block_4bit BLOCK7 (
        .g(g[31:28]), .p(p[31:28]), .cin(block_cin[7]),
        .sum(Sum[31:28]), .block_G(block_G[7]), .block_P(block_P[7])
    );

endmodule


// =============================================================================
// Module      : cla_block_4bit
// Description : A single 4-bit Carry Lookahead block. Takes pre-computed
//               generate (g) and propagate (p) signals for 4 bits, plus the
//               carry coming into this block, and produces:
//                 - the 4 sum bits for this block
//                 - block_G : would this block generate a carry on its own?
//                 - block_P : would this block propagate an incoming carry
//                             straight through to its carry-out?
//               This block does NOT use ripple carry internally -- every
//               internal carry (c1, c2, c3) is computed directly from the
//               g/p signals and cin using the standard lookahead equations,
//               so all 4 sum bits are available with the same short delay.
// =============================================================================
module cla_block_4bit (
    input  wire [3:0] g,         // generate signals for bits 0-3 of this block
    input  wire [3:0] p,         // propagate signals for bits 0-3 of this block
    input  wire       cin,       // carry coming into this block (bit 0's carry-in)
    output wire [3:0] sum,       // 4 sum bits for this block
    output wire       block_G,   // block-level generate (for the next block's lookahead)
    output wire       block_P    // block-level propagate (for the next block's lookahead)
);
    // Internal carries within the block, computed directly via lookahead
    // (NOT by rippling cin through g[0],g[1],g[2] one at a time).
    wire c1, c2, c3;
    // c1 = carry out of bit 0 = "bit 0 generates a carry" OR
    //      ("bit 0 would propagate an incoming carry" AND "there was an incoming carry")
    assign c1 = g[0] | (p[0] & cin);
    // c2 = carry out of bit 1: a carry can originate at bit 1 itself,
    //      or at bit 0 and propagate through bit 1,
    //      or come in from cin and propagate through both bit 0 and bit 1
    assign c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    // c3 = carry out of bit 2: same idea, one bit further
    assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    // Each sum bit = propagate signal XOR the carry coming into that bit
    // (sum_i = p_i XOR c_i, where c_0 = cin for bit 0)
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c1;
    assign sum[2] = p[2] ^ c2;
    assign sum[3] = p[3] ^ c3;

    // Block Generate: would this 4-bit block produce a carry-out even if
    // there was no carry-in? This is true if any of the bits in the block
    // generates a carry, OR if the first bit propagates and the second bit generates, OR if the first two bits propagate and the third generates, etc.
    assign block_G = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

    // Block Propagate: would this block pass an incoming carry straight
    // through to its carry-out? Only if EVERY bit in the block propagates.
    assign block_P = p[0] & p[1] & p[2] & p[3];

endmodule
