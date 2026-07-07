// =============================================================================
// Module      : partial_product_gen
// Pipeline    : STAGE 1
// Description : Generates all 256 partial product bits for a 16-bit x 16-bit
//               unsigned multiplication.
//
//               For each pair of bits A[j] and B[i], the partial product bit
//               is simply their AND: pp[i][j] = A[j] & B[i].
//
//               Row i of partial products (formed using B[i]) is logically
//               shifted left by i bit positions before being added to the
//               other rows -- this is exactly how long multiplication works
//               on paper: each row of the multiplicand is shifted according
//               to which digit of the multiplier produced it.
//
//               These 16 rows, each up to 16 bits wide but shifted into a
//               31-bit-wide column space (columns 0 to 30), are exactly the
//               raw inputs that Stage 2 (Wallace reduction) will compress.
//
//               Output organization:
//               Instead of packing all 256 bits into one flat bus (which
//               would be very hard to read/trace), each of the 16 rows is
//               given its own named 16-bit output bus: pp_row0 .. pp_row15.
//               Stage 2 will pick off individual bits from these buses
//               according to which column they land in.
// =============================================================================

module partial_product_gen (
    input  wire [15:0] A,        // multiplicand, A[15:0]
    input  wire [15:0] B,        // multiplier,   B[15:0]

    // Each row below holds 16 partial-product bits: row i = (A & {16{B[i]}})
    // i.e. if B[i] = 1, the row equals A; if B[i] = 0, the row is all zero.
    // NOTE: these rows are NOT yet shifted -- the shifting (i.e. which
    // *column* each row's bits land in) is handled implicitly by Stage 2,
    // which reads pp_row_i[j] as contributing to column (i + j).
    output wire [15:0] pp_row0,
    output wire [15:0] pp_row1,
    output wire [15:0] pp_row2,
    output wire [15:0] pp_row3,
    output wire [15:0] pp_row4,
    output wire [15:0] pp_row5,
    output wire [15:0] pp_row6,
    output wire [15:0] pp_row7,
    output wire [15:0] pp_row8,
    output wire [15:0] pp_row9,
    output wire [15:0] pp_row10,
    output wire [15:0] pp_row11,
    output wire [15:0] pp_row12,
    output wire [15:0] pp_row13,
    output wire [15:0] pp_row14,
    output wire [15:0] pp_row15
);

    // ---------------------------------------------------------------------
    // Row i is formed by AND-ing every bit of A with the single bit B[i].
    // {16{B[i]}} replicates bit B[i] sixteen times to form a 16-bit mask,
    // e.g. if B[i] = 1, {16{B[i]}} = 16'b1111111111111111 (all ones),
    //      if B[i] = 0, {16{B[i]}} = 16'b0000000000000000 (all zeros).
    // ANDing this mask with A gives: A if B[i]=1, or all-zero if B[i]=0.
    // This is exactly pp[i][j] = A[j] & B[i] for all j, computed in one
    // bitwise operation per row instead of 16 separate single-bit ANDs.
    // ---------------------------------------------------------------------

    assign pp_row0  = A & {16{B[0]}};   // row 0:  bits land in columns  0..15
    assign pp_row1  = A & {16{B[1]}};   // row 1:  bits land in columns  1..16
    assign pp_row2  = A & {16{B[2]}};   // row 2:  bits land in columns  2..17
    assign pp_row3  = A & {16{B[3]}};   // row 3:  bits land in columns  3..18
    assign pp_row4  = A & {16{B[4]}};   // row 4:  bits land in columns  4..19
    assign pp_row5  = A & {16{B[5]}};   // row 5:  bits land in columns  5..20
    assign pp_row6  = A & {16{B[6]}};   // row 6:  bits land in columns  6..21
    assign pp_row7  = A & {16{B[7]}};   // row 7:  bits land in columns  7..22
    assign pp_row8  = A & {16{B[8]}};   // row 8:  bits land in columns  8..23
    assign pp_row9  = A & {16{B[9]}};   // row 9:  bits land in columns  9..24
    assign pp_row10 = A & {16{B[10]}};  // row 10: bits land in columns 10..25
    assign pp_row11 = A & {16{B[11]}};  // row 11: bits land in columns 11..26
    assign pp_row12 = A & {16{B[12]}};  // row 12: bits land in columns 12..27
    assign pp_row13 = A & {16{B[13]}};  // row 13: bits land in columns 13..28
    assign pp_row14 = A & {16{B[14]}};  // row 14: bits land in columns 14..29
    assign pp_row15 = A & {16{B[15]}};  // row 15: bits land in columns 15..30

endmodule
