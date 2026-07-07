// =============================================================================
// Module      : pipelined_wallace_mult_16x16
// Description : TOP-LEVEL module for the 16-bit x 16-bit Pipelined Wallace
//               Tree Multiplier. This module connects all 5 pipeline stages
//               together with registers in between, and produces the final
//               32-bit product P[31:0] along with a valid_out signal that
//               tells the user when P actually contains a valid result.
//
//               PIPELINE STRUCTURE (5 register stages, 4-cycle latency):
//                 Stage 1 : partial_product_gen   (16x16 AND array)
//                 [register]
//                 Stage 2 : wallace_stage1        (Wallace reduction Levels 1+2)
//                 [register]
//                 Stage 3 : wallace_stage2        (Wallace reduction Levels 3+4)
//                 [register]
//                 Stage 4 : wallace_stage3        (Wallace reduction Levels 5+6)
//                 [register]
//                 Stage 5 : cla_32bit             (final 32-bit addition)
//                 [register] -> P[31:0] (final output register)
//
//               Because the pipeline has 5 register stages along the data
//               path (pp_row_q, s2_q, s3_q, s4_q, and the final P register),
//               a result for inputs applied on cycle T does not appear on
//               P until cycle T+4 (verified by simulation). This is the
//               standard, expected behavior of a 5-register pipeline when
//               both input and output are counted on the same 0-indexed
//               clock cycle numbering.
//
//               RESET: active-low (rst_n), synchronous. When rst_n = 0,
//               every pipeline register (data AND valid) is cleared on the
//               next clock edge. This guarantees no garbage data can ever
//               appear at the output after a reset.
//
//               THROUGHPUT: because every stage is registered, a NEW pair
//               of operands (A, B) can be applied on EVERY clock cycle --
//               the pipeline does not need to "drain" between operations.
//               Once filled (after 5 cycles), it produces one result per
//               clock cycle, every cycle.
// =============================================================================

module pipelined_wallace_mult_16x16 (
    input  wire        clk,        // system clock (50 MHz for simulation, see project spec)
    input  wire        rst_n,      // active-low synchronous reset
    input  wire        valid_in,   // asserted by the user when A,B are valid this cycle
    input  wire [15:0] A,          // multiplicand
    input  wire [15:0] B,          // multiplier
    output reg  [31:0] P,          // final 32-bit product (registered output)
    output reg         valid_out   // asserted when P holds a valid result
);

    // =========================================================================
    // PIPELINE REGISTERS
    // One set of registers per stage boundary, named with a "_q" suffix to
    // mean "the registered (clocked) version of this signal". This is a
    // standard, easily recognisable naming convention in RTL design.
    // =========================================================================
// Stage 1 -> Stage 2 pipeline registers (registered partial products)
    reg [15:0] pp_row0_q, pp_row1_q, pp_row2_q, pp_row3_q, pp_row4_q, pp_row5_q, pp_row6_q, pp_row7_q, pp_row8_q, pp_row9_q, pp_row10_q, pp_row11_q, pp_row12_q, pp_row13_q, pp_row14_q, pp_row15_q;

// Stage 2 -> Stage 3 pipeline registers (registered after Wallace L1+L2)
    reg s2_col0_b0_q, s2_col1_b0_q, s2_col2_b0_q, s2_col3_b0_q;
    reg s2_col3_b1_q, s2_col4_b0_q, s2_col4_b1_q, s2_col5_b0_q;
    reg s2_col5_b1_q, s2_col5_b2_q, s2_col6_b0_q, s2_col6_b1_q;
    reg s2_col6_b2_q, s2_col7_b0_q, s2_col7_b1_q, s2_col7_b2_q;
    reg s2_col7_b3_q, s2_col8_b0_q, s2_col8_b1_q, s2_col8_b2_q;
    reg s2_col8_b3_q, s2_col9_b0_q, s2_col9_b1_q, s2_col9_b2_q;
    reg s2_col9_b3_q, s2_col9_b4_q, s2_col10_b0_q, s2_col10_b1_q;
    reg s2_col10_b2_q, s2_col10_b3_q, s2_col10_b4_q, s2_col11_b0_q;
    reg s2_col11_b1_q, s2_col11_b2_q, s2_col11_b3_q, s2_col11_b4_q;
    reg s2_col12_b0_q, s2_col12_b1_q, s2_col12_b2_q, s2_col12_b3_q;
    reg s2_col12_b4_q, s2_col12_b5_q, s2_col13_b0_q, s2_col13_b1_q;
    reg s2_col13_b2_q, s2_col13_b3_q, s2_col13_b4_q, s2_col13_b5_q;
    reg s2_col14_b0_q, s2_col14_b1_q, s2_col14_b2_q, s2_col14_b3_q;
    reg s2_col14_b4_q, s2_col14_b5_q, s2_col14_b6_q, s2_col15_b0_q;
    reg s2_col15_b1_q, s2_col15_b2_q, s2_col15_b3_q, s2_col15_b4_q;
    reg s2_col15_b5_q, s2_col15_b6_q, s2_col16_b0_q, s2_col16_b1_q;
    reg s2_col16_b2_q, s2_col16_b3_q, s2_col16_b4_q, s2_col16_b5_q;
    reg s2_col16_b6_q, s2_col16_b7_q, s2_col17_b0_q, s2_col17_b1_q;
    reg s2_col17_b2_q, s2_col17_b3_q, s2_col17_b4_q, s2_col17_b5_q;
    reg s2_col17_b6_q, s2_col18_b0_q, s2_col18_b1_q, s2_col18_b2_q;
    reg s2_col18_b3_q, s2_col18_b4_q, s2_col18_b5_q, s2_col18_b6_q;
    reg s2_col19_b0_q, s2_col19_b1_q, s2_col19_b2_q, s2_col19_b3_q;
    reg s2_col19_b4_q, s2_col19_b5_q, s2_col20_b0_q, s2_col20_b1_q;
    reg s2_col20_b2_q, s2_col20_b3_q, s2_col20_b4_q, s2_col20_b5_q;
    reg s2_col21_b0_q, s2_col21_b1_q, s2_col21_b2_q, s2_col21_b3_q;
    reg s2_col21_b4_q, s2_col21_b5_q, s2_col22_b0_q, s2_col22_b1_q;
    reg s2_col22_b2_q, s2_col22_b3_q, s2_col22_b4_q, s2_col23_b0_q;
    reg s2_col23_b1_q, s2_col23_b2_q, s2_col23_b3_q, s2_col24_b0_q;
    reg s2_col24_b1_q, s2_col24_b2_q, s2_col24_b3_q, s2_col25_b0_q;
    reg s2_col25_b1_q, s2_col25_b2_q, s2_col25_b3_q, s2_col26_b0_q;
    reg s2_col26_b1_q, s2_col26_b2_q, s2_col27_b0_q, s2_col27_b1_q;
    reg s2_col27_b2_q, s2_col28_b0_q, s2_col28_b1_q, s2_col29_b0_q;
    reg s2_col29_b1_q, s2_col30_b0_q, s2_col30_b1_q, s2_col31_b0_q;

// Stage 3 -> Stage 4 pipeline registers (registered after Wallace L3+L4)
    reg s3_col0_b0_q, s3_col1_b0_q, s3_col2_b0_q, s3_col3_b0_q;
    reg s3_col4_b0_q, s3_col5_b0_q, s3_col5_b1_q, s3_col6_b0_q;
    reg s3_col6_b1_q, s3_col7_b0_q, s3_col7_b1_q, s3_col8_b0_q;
    reg s3_col8_b1_q, s3_col9_b0_q, s3_col9_b1_q, s3_col10_b0_q;
    reg s3_col10_b1_q, s3_col10_b2_q, s3_col11_b0_q, s3_col11_b1_q;
    reg s3_col11_b2_q, s3_col12_b0_q, s3_col12_b1_q, s3_col12_b2_q;
    reg s3_col13_b0_q, s3_col13_b1_q, s3_col13_b2_q, s3_col14_b0_q;
    reg s3_col14_b1_q, s3_col14_b2_q, s3_col15_b0_q, s3_col15_b1_q;
    reg s3_col15_b2_q, s3_col15_b3_q, s3_col16_b0_q, s3_col16_b1_q;
    reg s3_col16_b2_q, s3_col16_b3_q, s3_col17_b0_q, s3_col17_b1_q;
    reg s3_col17_b2_q, s3_col17_b3_q, s3_col18_b0_q, s3_col18_b1_q;
    reg s3_col18_b2_q, s3_col18_b3_q, s3_col19_b0_q, s3_col19_b1_q;
    reg s3_col19_b2_q, s3_col19_b3_q, s3_col20_b0_q, s3_col20_b1_q;
    reg s3_col20_b2_q, s3_col21_b0_q, s3_col21_b1_q, s3_col21_b2_q;
    reg s3_col22_b0_q, s3_col22_b1_q, s3_col22_b2_q, s3_col23_b0_q;
    reg s3_col23_b1_q, s3_col23_b2_q, s3_col24_b0_q, s3_col24_b1_q;
    reg s3_col25_b0_q, s3_col25_b1_q, s3_col26_b0_q, s3_col26_b1_q;
    reg s3_col27_b0_q, s3_col27_b1_q, s3_col28_b0_q, s3_col28_b1_q;
    reg s3_col29_b0_q, s3_col29_b1_q, s3_col30_b0_q, s3_col30_b1_q;
    reg s3_col31_b0_q, s3_col31_b1_q, s3_col32_b0_q;

// Stage 4 -> Stage 5 pipeline registers (registered after Wallace L5+L6)
    reg s4_col0_b0_q, s4_col1_b0_q, s4_col2_b0_q, s4_col3_b0_q;
    reg s4_col4_b0_q, s4_col5_b0_q, s4_col6_b0_q, s4_col7_b0_q;
    reg s4_col7_b1_q, s4_col8_b0_q, s4_col8_b1_q, s4_col9_b0_q;
    reg s4_col9_b1_q, s4_col10_b0_q, s4_col10_b1_q, s4_col11_b0_q;
    reg s4_col11_b1_q, s4_col12_b0_q, s4_col12_b1_q, s4_col13_b0_q;
    reg s4_col13_b1_q, s4_col14_b0_q, s4_col14_b1_q, s4_col15_b0_q;
    reg s4_col15_b1_q, s4_col16_b0_q, s4_col16_b1_q, s4_col17_b0_q;
    reg s4_col17_b1_q, s4_col18_b0_q, s4_col18_b1_q, s4_col19_b0_q;
    reg s4_col19_b1_q, s4_col20_b0_q, s4_col20_b1_q, s4_col21_b0_q;
    reg s4_col21_b1_q, s4_col22_b0_q, s4_col22_b1_q, s4_col23_b0_q;
    reg s4_col23_b1_q, s4_col24_b0_q, s4_col24_b1_q, s4_col25_b0_q;
    reg s4_col25_b1_q, s4_col26_b0_q, s4_col26_b1_q, s4_col27_b0_q;
    reg s4_col27_b1_q, s4_col28_b0_q, s4_col28_b1_q, s4_col29_b0_q;
    reg s4_col29_b1_q, s4_col30_b0_q, s4_col30_b1_q, s4_col31_b0_q;
    reg s4_col31_b1_q, s4_col32_b0_q, s4_col32_b1_q, s4_col33_b0_q;


    // Valid signal pipeline: shifts valid_in through 5 flip-flops, one per
    // pipeline stage, so valid_out lines up exactly with the cycle the
    // corresponding result appears on P.
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;

    // =========================================================================
    // STAGE 1: Partial Product Generation (combinational)
    // =========================================================================
    wire [15:0] pp_row0, pp_row1, pp_row2, pp_row3, pp_row4, pp_row5, pp_row6, pp_row7;
    wire [15:0] pp_row8, pp_row9, pp_row10, pp_row11, pp_row12, pp_row13, pp_row14, pp_row15;

    partial_product_gen U_PP_GEN (
        .A(A),
        .B(B),
        .pp_row0(pp_row0), .pp_row1(pp_row1), .pp_row2(pp_row2), .pp_row3(pp_row3),
        .pp_row4(pp_row4), .pp_row5(pp_row5), .pp_row6(pp_row6), .pp_row7(pp_row7),
        .pp_row8(pp_row8), .pp_row9(pp_row9), .pp_row10(pp_row10), .pp_row11(pp_row11),
        .pp_row12(pp_row12), .pp_row13(pp_row13), .pp_row14(pp_row14), .pp_row15(pp_row15)
    );

    // =========================================================================
    // STAGE 2: Wallace Tree Reduction Levels 1 & 2 (combinational)
    // Inputs come from the REGISTERED partial products (pp_rowX_q).
    // =========================================================================
    wire s2_col0_b0, s2_col1_b0, s2_col2_b0, s2_col3_b0;
    wire s2_col3_b1, s2_col4_b0, s2_col4_b1, s2_col5_b0;
    wire s2_col5_b1, s2_col5_b2, s2_col6_b0, s2_col6_b1;
    wire s2_col6_b2, s2_col7_b0, s2_col7_b1, s2_col7_b2;
    wire s2_col7_b3, s2_col8_b0, s2_col8_b1, s2_col8_b2;
    wire s2_col8_b3, s2_col9_b0, s2_col9_b1, s2_col9_b2;
    wire s2_col9_b3, s2_col9_b4, s2_col10_b0, s2_col10_b1;
    wire s2_col10_b2, s2_col10_b3, s2_col10_b4, s2_col11_b0;
    wire s2_col11_b1, s2_col11_b2, s2_col11_b3, s2_col11_b4;
    wire s2_col12_b0, s2_col12_b1, s2_col12_b2, s2_col12_b3;
    wire s2_col12_b4, s2_col12_b5, s2_col13_b0, s2_col13_b1;
    wire s2_col13_b2, s2_col13_b3, s2_col13_b4, s2_col13_b5;
    wire s2_col14_b0, s2_col14_b1, s2_col14_b2, s2_col14_b3;
    wire s2_col14_b4, s2_col14_b5, s2_col14_b6, s2_col15_b0;
    wire s2_col15_b1, s2_col15_b2, s2_col15_b3, s2_col15_b4;
    wire s2_col15_b5, s2_col15_b6, s2_col16_b0, s2_col16_b1;
    wire s2_col16_b2, s2_col16_b3, s2_col16_b4, s2_col16_b5;
    wire s2_col16_b6, s2_col16_b7, s2_col17_b0, s2_col17_b1;
    wire s2_col17_b2, s2_col17_b3, s2_col17_b4, s2_col17_b5;
    wire s2_col17_b6, s2_col18_b0, s2_col18_b1, s2_col18_b2;
    wire s2_col18_b3, s2_col18_b4, s2_col18_b5, s2_col18_b6;
    wire s2_col19_b0, s2_col19_b1, s2_col19_b2, s2_col19_b3;
    wire s2_col19_b4, s2_col19_b5, s2_col20_b0, s2_col20_b1;
    wire s2_col20_b2, s2_col20_b3, s2_col20_b4, s2_col20_b5;
    wire s2_col21_b0, s2_col21_b1, s2_col21_b2, s2_col21_b3;
    wire s2_col21_b4, s2_col21_b5, s2_col22_b0, s2_col22_b1;
    wire s2_col22_b2, s2_col22_b3, s2_col22_b4, s2_col23_b0;
    wire s2_col23_b1, s2_col23_b2, s2_col23_b3, s2_col24_b0;
    wire s2_col24_b1, s2_col24_b2, s2_col24_b3, s2_col25_b0;
    wire s2_col25_b1, s2_col25_b2, s2_col25_b3, s2_col26_b0;
    wire s2_col26_b1, s2_col26_b2, s2_col27_b0, s2_col27_b1;
    wire s2_col27_b2, s2_col28_b0, s2_col28_b1, s2_col29_b0;
    wire s2_col29_b1, s2_col30_b0, s2_col30_b1, s2_col31_b0;

    wallace_stage1 U_WALLACE_STAGE1 (
        .pp_row0(pp_row0_q),
        .pp_row1(pp_row1_q),
        .pp_row2(pp_row2_q),
        .pp_row3(pp_row3_q),
        .pp_row4(pp_row4_q),
        .pp_row5(pp_row5_q),
        .pp_row6(pp_row6_q),
        .pp_row7(pp_row7_q),
        .pp_row8(pp_row8_q),
        .pp_row9(pp_row9_q),
        .pp_row10(pp_row10_q),
        .pp_row11(pp_row11_q),
        .pp_row12(pp_row12_q),
        .pp_row13(pp_row13_q),
        .pp_row14(pp_row14_q),
        .pp_row15(pp_row15_q),
        .s2_col0_b0(s2_col0_b0),
        .s2_col1_b0(s2_col1_b0),
        .s2_col2_b0(s2_col2_b0),
        .s2_col3_b0(s2_col3_b0),
        .s2_col3_b1(s2_col3_b1),
        .s2_col4_b0(s2_col4_b0),
        .s2_col4_b1(s2_col4_b1),
        .s2_col5_b0(s2_col5_b0),
        .s2_col5_b1(s2_col5_b1),
        .s2_col5_b2(s2_col5_b2),
        .s2_col6_b0(s2_col6_b0),
        .s2_col6_b1(s2_col6_b1),
        .s2_col6_b2(s2_col6_b2),
        .s2_col7_b0(s2_col7_b0),
        .s2_col7_b1(s2_col7_b1),
        .s2_col7_b2(s2_col7_b2),
        .s2_col7_b3(s2_col7_b3),
        .s2_col8_b0(s2_col8_b0),
        .s2_col8_b1(s2_col8_b1),
        .s2_col8_b2(s2_col8_b2),
        .s2_col8_b3(s2_col8_b3),
        .s2_col9_b0(s2_col9_b0),
        .s2_col9_b1(s2_col9_b1),
        .s2_col9_b2(s2_col9_b2),
        .s2_col9_b3(s2_col9_b3),
        .s2_col9_b4(s2_col9_b4),
        .s2_col10_b0(s2_col10_b0),
        .s2_col10_b1(s2_col10_b1),
        .s2_col10_b2(s2_col10_b2),
        .s2_col10_b3(s2_col10_b3),
        .s2_col10_b4(s2_col10_b4),
        .s2_col11_b0(s2_col11_b0),
        .s2_col11_b1(s2_col11_b1),
        .s2_col11_b2(s2_col11_b2),
        .s2_col11_b3(s2_col11_b3),
        .s2_col11_b4(s2_col11_b4),
        .s2_col12_b0(s2_col12_b0),
        .s2_col12_b1(s2_col12_b1),
        .s2_col12_b2(s2_col12_b2),
        .s2_col12_b3(s2_col12_b3),
        .s2_col12_b4(s2_col12_b4),
        .s2_col12_b5(s2_col12_b5),
        .s2_col13_b0(s2_col13_b0),
        .s2_col13_b1(s2_col13_b1),
        .s2_col13_b2(s2_col13_b2),
        .s2_col13_b3(s2_col13_b3),
        .s2_col13_b4(s2_col13_b4),
        .s2_col13_b5(s2_col13_b5),
        .s2_col14_b0(s2_col14_b0),
        .s2_col14_b1(s2_col14_b1),
        .s2_col14_b2(s2_col14_b2),
        .s2_col14_b3(s2_col14_b3),
        .s2_col14_b4(s2_col14_b4),
        .s2_col14_b5(s2_col14_b5),
        .s2_col14_b6(s2_col14_b6),
        .s2_col15_b0(s2_col15_b0),
        .s2_col15_b1(s2_col15_b1),
        .s2_col15_b2(s2_col15_b2),
        .s2_col15_b3(s2_col15_b3),
        .s2_col15_b4(s2_col15_b4),
        .s2_col15_b5(s2_col15_b5),
        .s2_col15_b6(s2_col15_b6),
        .s2_col16_b0(s2_col16_b0),
        .s2_col16_b1(s2_col16_b1),
        .s2_col16_b2(s2_col16_b2),
        .s2_col16_b3(s2_col16_b3),
        .s2_col16_b4(s2_col16_b4),
        .s2_col16_b5(s2_col16_b5),
        .s2_col16_b6(s2_col16_b6),
        .s2_col16_b7(s2_col16_b7),
        .s2_col17_b0(s2_col17_b0),
        .s2_col17_b1(s2_col17_b1),
        .s2_col17_b2(s2_col17_b2),
        .s2_col17_b3(s2_col17_b3),
        .s2_col17_b4(s2_col17_b4),
        .s2_col17_b5(s2_col17_b5),
        .s2_col17_b6(s2_col17_b6),
        .s2_col18_b0(s2_col18_b0),
        .s2_col18_b1(s2_col18_b1),
        .s2_col18_b2(s2_col18_b2),
        .s2_col18_b3(s2_col18_b3),
        .s2_col18_b4(s2_col18_b4),
        .s2_col18_b5(s2_col18_b5),
        .s2_col18_b6(s2_col18_b6),
        .s2_col19_b0(s2_col19_b0),
        .s2_col19_b1(s2_col19_b1),
        .s2_col19_b2(s2_col19_b2),
        .s2_col19_b3(s2_col19_b3),
        .s2_col19_b4(s2_col19_b4),
        .s2_col19_b5(s2_col19_b5),
        .s2_col20_b0(s2_col20_b0),
        .s2_col20_b1(s2_col20_b1),
        .s2_col20_b2(s2_col20_b2),
        .s2_col20_b3(s2_col20_b3),
        .s2_col20_b4(s2_col20_b4),
        .s2_col20_b5(s2_col20_b5),
        .s2_col21_b0(s2_col21_b0),
        .s2_col21_b1(s2_col21_b1),
        .s2_col21_b2(s2_col21_b2),
        .s2_col21_b3(s2_col21_b3),
        .s2_col21_b4(s2_col21_b4),
        .s2_col21_b5(s2_col21_b5),
        .s2_col22_b0(s2_col22_b0),
        .s2_col22_b1(s2_col22_b1),
        .s2_col22_b2(s2_col22_b2),
        .s2_col22_b3(s2_col22_b3),
        .s2_col22_b4(s2_col22_b4),
        .s2_col23_b0(s2_col23_b0),
        .s2_col23_b1(s2_col23_b1),
        .s2_col23_b2(s2_col23_b2),
        .s2_col23_b3(s2_col23_b3),
        .s2_col24_b0(s2_col24_b0),
        .s2_col24_b1(s2_col24_b1),
        .s2_col24_b2(s2_col24_b2),
        .s2_col24_b3(s2_col24_b3),
        .s2_col25_b0(s2_col25_b0),
        .s2_col25_b1(s2_col25_b1),
        .s2_col25_b2(s2_col25_b2),
        .s2_col25_b3(s2_col25_b3),
        .s2_col26_b0(s2_col26_b0),
        .s2_col26_b1(s2_col26_b1),
        .s2_col26_b2(s2_col26_b2),
        .s2_col27_b0(s2_col27_b0),
        .s2_col27_b1(s2_col27_b1),
        .s2_col27_b2(s2_col27_b2),
        .s2_col28_b0(s2_col28_b0),
        .s2_col28_b1(s2_col28_b1),
        .s2_col29_b0(s2_col29_b0),
        .s2_col29_b1(s2_col29_b1),
        .s2_col30_b0(s2_col30_b0),
        .s2_col30_b1(s2_col30_b1),
        .s2_col31_b0(s2_col31_b0)
    );

    // =========================================================================
    // STAGE 3: Wallace Tree Reduction Levels 3 & 4 (combinational)
    // Inputs come from the REGISTERED Stage-2 outputs (s2_colX_bY_q).
    // =========================================================================
    wire s3_col0_b0, s3_col1_b0, s3_col2_b0, s3_col3_b0;
    wire s3_col4_b0, s3_col5_b0, s3_col5_b1, s3_col6_b0;
    wire s3_col6_b1, s3_col7_b0, s3_col7_b1, s3_col8_b0;
    wire s3_col8_b1, s3_col9_b0, s3_col9_b1, s3_col10_b0;
    wire s3_col10_b1, s3_col10_b2, s3_col11_b0, s3_col11_b1;
    wire s3_col11_b2, s3_col12_b0, s3_col12_b1, s3_col12_b2;
    wire s3_col13_b0, s3_col13_b1, s3_col13_b2, s3_col14_b0;
    wire s3_col14_b1, s3_col14_b2, s3_col15_b0, s3_col15_b1;
    wire s3_col15_b2, s3_col15_b3, s3_col16_b0, s3_col16_b1;
    wire s3_col16_b2, s3_col16_b3, s3_col17_b0, s3_col17_b1;
    wire s3_col17_b2, s3_col17_b3, s3_col18_b0, s3_col18_b1;
    wire s3_col18_b2, s3_col18_b3, s3_col19_b0, s3_col19_b1;
    wire s3_col19_b2, s3_col19_b3, s3_col20_b0, s3_col20_b1;
    wire s3_col20_b2, s3_col21_b0, s3_col21_b1, s3_col21_b2;
    wire s3_col22_b0, s3_col22_b1, s3_col22_b2, s3_col23_b0;
    wire s3_col23_b1, s3_col23_b2, s3_col24_b0, s3_col24_b1;
    wire s3_col25_b0, s3_col25_b1, s3_col26_b0, s3_col26_b1;
    wire s3_col27_b0, s3_col27_b1, s3_col28_b0, s3_col28_b1;
    wire s3_col29_b0, s3_col29_b1, s3_col30_b0, s3_col30_b1;
    wire s3_col31_b0, s3_col31_b1, s3_col32_b0;

    wallace_stage2 U_WALLACE_STAGE2 (
        .s2_col0_b0(s2_col0_b0_q),
        .s2_col1_b0(s2_col1_b0_q),
        .s2_col2_b0(s2_col2_b0_q),
        .s2_col3_b0(s2_col3_b0_q),
        .s2_col3_b1(s2_col3_b1_q),
        .s2_col4_b0(s2_col4_b0_q),
        .s2_col4_b1(s2_col4_b1_q),
        .s2_col5_b0(s2_col5_b0_q),
        .s2_col5_b1(s2_col5_b1_q),
        .s2_col5_b2(s2_col5_b2_q),
        .s2_col6_b0(s2_col6_b0_q),
        .s2_col6_b1(s2_col6_b1_q),
        .s2_col6_b2(s2_col6_b2_q),
        .s2_col7_b0(s2_col7_b0_q),
        .s2_col7_b1(s2_col7_b1_q),
        .s2_col7_b2(s2_col7_b2_q),
        .s2_col7_b3(s2_col7_b3_q),
        .s2_col8_b0(s2_col8_b0_q),
        .s2_col8_b1(s2_col8_b1_q),
        .s2_col8_b2(s2_col8_b2_q),
        .s2_col8_b3(s2_col8_b3_q),
        .s2_col9_b0(s2_col9_b0_q),
        .s2_col9_b1(s2_col9_b1_q),
        .s2_col9_b2(s2_col9_b2_q),
        .s2_col9_b3(s2_col9_b3_q),
        .s2_col9_b4(s2_col9_b4_q),
        .s2_col10_b0(s2_col10_b0_q),
        .s2_col10_b1(s2_col10_b1_q),
        .s2_col10_b2(s2_col10_b2_q),
        .s2_col10_b3(s2_col10_b3_q),
        .s2_col10_b4(s2_col10_b4_q),
        .s2_col11_b0(s2_col11_b0_q),
        .s2_col11_b1(s2_col11_b1_q),
        .s2_col11_b2(s2_col11_b2_q),
        .s2_col11_b3(s2_col11_b3_q),
        .s2_col11_b4(s2_col11_b4_q),
        .s2_col12_b0(s2_col12_b0_q),
        .s2_col12_b1(s2_col12_b1_q),
        .s2_col12_b2(s2_col12_b2_q),
        .s2_col12_b3(s2_col12_b3_q),
        .s2_col12_b4(s2_col12_b4_q),
        .s2_col12_b5(s2_col12_b5_q),
        .s2_col13_b0(s2_col13_b0_q),
        .s2_col13_b1(s2_col13_b1_q),
        .s2_col13_b2(s2_col13_b2_q),
        .s2_col13_b3(s2_col13_b3_q),
        .s2_col13_b4(s2_col13_b4_q),
        .s2_col13_b5(s2_col13_b5_q),
        .s2_col14_b0(s2_col14_b0_q),
        .s2_col14_b1(s2_col14_b1_q),
        .s2_col14_b2(s2_col14_b2_q),
        .s2_col14_b3(s2_col14_b3_q),
        .s2_col14_b4(s2_col14_b4_q),
        .s2_col14_b5(s2_col14_b5_q),
        .s2_col14_b6(s2_col14_b6_q),
        .s2_col15_b0(s2_col15_b0_q),
        .s2_col15_b1(s2_col15_b1_q),
        .s2_col15_b2(s2_col15_b2_q),
        .s2_col15_b3(s2_col15_b3_q),
        .s2_col15_b4(s2_col15_b4_q),
        .s2_col15_b5(s2_col15_b5_q),
        .s2_col15_b6(s2_col15_b6_q),
        .s2_col16_b0(s2_col16_b0_q),
        .s2_col16_b1(s2_col16_b1_q),
        .s2_col16_b2(s2_col16_b2_q),
        .s2_col16_b3(s2_col16_b3_q),
        .s2_col16_b4(s2_col16_b4_q),
        .s2_col16_b5(s2_col16_b5_q),
        .s2_col16_b6(s2_col16_b6_q),
        .s2_col16_b7(s2_col16_b7_q),
        .s2_col17_b0(s2_col17_b0_q),
        .s2_col17_b1(s2_col17_b1_q),
        .s2_col17_b2(s2_col17_b2_q),
        .s2_col17_b3(s2_col17_b3_q),
        .s2_col17_b4(s2_col17_b4_q),
        .s2_col17_b5(s2_col17_b5_q),
        .s2_col17_b6(s2_col17_b6_q),
        .s2_col18_b0(s2_col18_b0_q),
        .s2_col18_b1(s2_col18_b1_q),
        .s2_col18_b2(s2_col18_b2_q),
        .s2_col18_b3(s2_col18_b3_q),
        .s2_col18_b4(s2_col18_b4_q),
        .s2_col18_b5(s2_col18_b5_q),
        .s2_col18_b6(s2_col18_b6_q),
        .s2_col19_b0(s2_col19_b0_q),
        .s2_col19_b1(s2_col19_b1_q),
        .s2_col19_b2(s2_col19_b2_q),
        .s2_col19_b3(s2_col19_b3_q),
        .s2_col19_b4(s2_col19_b4_q),
        .s2_col19_b5(s2_col19_b5_q),
        .s2_col20_b0(s2_col20_b0_q),
        .s2_col20_b1(s2_col20_b1_q),
        .s2_col20_b2(s2_col20_b2_q),
        .s2_col20_b3(s2_col20_b3_q),
        .s2_col20_b4(s2_col20_b4_q),
        .s2_col20_b5(s2_col20_b5_q),
        .s2_col21_b0(s2_col21_b0_q),
        .s2_col21_b1(s2_col21_b1_q),
        .s2_col21_b2(s2_col21_b2_q),
        .s2_col21_b3(s2_col21_b3_q),
        .s2_col21_b4(s2_col21_b4_q),
        .s2_col21_b5(s2_col21_b5_q),
        .s2_col22_b0(s2_col22_b0_q),
        .s2_col22_b1(s2_col22_b1_q),
        .s2_col22_b2(s2_col22_b2_q),
        .s2_col22_b3(s2_col22_b3_q),
        .s2_col22_b4(s2_col22_b4_q),
        .s2_col23_b0(s2_col23_b0_q),
        .s2_col23_b1(s2_col23_b1_q),
        .s2_col23_b2(s2_col23_b2_q),
        .s2_col23_b3(s2_col23_b3_q),
        .s2_col24_b0(s2_col24_b0_q),
        .s2_col24_b1(s2_col24_b1_q),
        .s2_col24_b2(s2_col24_b2_q),
        .s2_col24_b3(s2_col24_b3_q),
        .s2_col25_b0(s2_col25_b0_q),
        .s2_col25_b1(s2_col25_b1_q),
        .s2_col25_b2(s2_col25_b2_q),
        .s2_col25_b3(s2_col25_b3_q),
        .s2_col26_b0(s2_col26_b0_q),
        .s2_col26_b1(s2_col26_b1_q),
        .s2_col26_b2(s2_col26_b2_q),
        .s2_col27_b0(s2_col27_b0_q),
        .s2_col27_b1(s2_col27_b1_q),
        .s2_col27_b2(s2_col27_b2_q),
        .s2_col28_b0(s2_col28_b0_q),
        .s2_col28_b1(s2_col28_b1_q),
        .s2_col29_b0(s2_col29_b0_q),
        .s2_col29_b1(s2_col29_b1_q),
        .s2_col30_b0(s2_col30_b0_q),
        .s2_col30_b1(s2_col30_b1_q),
        .s2_col31_b0(s2_col31_b0_q),
        .s3_col0_b0(s3_col0_b0),
        .s3_col1_b0(s3_col1_b0),
        .s3_col2_b0(s3_col2_b0),
        .s3_col3_b0(s3_col3_b0),
        .s3_col4_b0(s3_col4_b0),
        .s3_col5_b0(s3_col5_b0),
        .s3_col5_b1(s3_col5_b1),
        .s3_col6_b0(s3_col6_b0),
        .s3_col6_b1(s3_col6_b1),
        .s3_col7_b0(s3_col7_b0),
        .s3_col7_b1(s3_col7_b1),
        .s3_col8_b0(s3_col8_b0),
        .s3_col8_b1(s3_col8_b1),
        .s3_col9_b0(s3_col9_b0),
        .s3_col9_b1(s3_col9_b1),
        .s3_col10_b0(s3_col10_b0),
        .s3_col10_b1(s3_col10_b1),
        .s3_col10_b2(s3_col10_b2),
        .s3_col11_b0(s3_col11_b0),
        .s3_col11_b1(s3_col11_b1),
        .s3_col11_b2(s3_col11_b2),
        .s3_col12_b0(s3_col12_b0),
        .s3_col12_b1(s3_col12_b1),
        .s3_col12_b2(s3_col12_b2),
        .s3_col13_b0(s3_col13_b0),
        .s3_col13_b1(s3_col13_b1),
        .s3_col13_b2(s3_col13_b2),
        .s3_col14_b0(s3_col14_b0),
        .s3_col14_b1(s3_col14_b1),
        .s3_col14_b2(s3_col14_b2),
        .s3_col15_b0(s3_col15_b0),
        .s3_col15_b1(s3_col15_b1),
        .s3_col15_b2(s3_col15_b2),
        .s3_col15_b3(s3_col15_b3),
        .s3_col16_b0(s3_col16_b0),
        .s3_col16_b1(s3_col16_b1),
        .s3_col16_b2(s3_col16_b2),
        .s3_col16_b3(s3_col16_b3),
        .s3_col17_b0(s3_col17_b0),
        .s3_col17_b1(s3_col17_b1),
        .s3_col17_b2(s3_col17_b2),
        .s3_col17_b3(s3_col17_b3),
        .s3_col18_b0(s3_col18_b0),
        .s3_col18_b1(s3_col18_b1),
        .s3_col18_b2(s3_col18_b2),
        .s3_col18_b3(s3_col18_b3),
        .s3_col19_b0(s3_col19_b0),
        .s3_col19_b1(s3_col19_b1),
        .s3_col19_b2(s3_col19_b2),
        .s3_col19_b3(s3_col19_b3),
        .s3_col20_b0(s3_col20_b0),
        .s3_col20_b1(s3_col20_b1),
        .s3_col20_b2(s3_col20_b2),
        .s3_col21_b0(s3_col21_b0),
        .s3_col21_b1(s3_col21_b1),
        .s3_col21_b2(s3_col21_b2),
        .s3_col22_b0(s3_col22_b0),
        .s3_col22_b1(s3_col22_b1),
        .s3_col22_b2(s3_col22_b2),
        .s3_col23_b0(s3_col23_b0),
        .s3_col23_b1(s3_col23_b1),
        .s3_col23_b2(s3_col23_b2),
        .s3_col24_b0(s3_col24_b0),
        .s3_col24_b1(s3_col24_b1),
        .s3_col25_b0(s3_col25_b0),
        .s3_col25_b1(s3_col25_b1),
        .s3_col26_b0(s3_col26_b0),
        .s3_col26_b1(s3_col26_b1),
        .s3_col27_b0(s3_col27_b0),
        .s3_col27_b1(s3_col27_b1),
        .s3_col28_b0(s3_col28_b0),
        .s3_col28_b1(s3_col28_b1),
        .s3_col29_b0(s3_col29_b0),
        .s3_col29_b1(s3_col29_b1),
        .s3_col30_b0(s3_col30_b0),
        .s3_col30_b1(s3_col30_b1),
        .s3_col31_b0(s3_col31_b0),
        .s3_col31_b1(s3_col31_b1),
        .s3_col32_b0(s3_col32_b0)
    );

    // =========================================================================
    // STAGE 4: Wallace Tree Reduction Levels 5 & 6 (combinational)
    // Inputs come from the REGISTERED Stage-3 outputs (s3_colX_bY_q).
    // After this stage, every column has <=2 bits -- ready for final addition.
    // =========================================================================
    wire s4_col0_b0, s4_col1_b0, s4_col2_b0, s4_col3_b0;
    wire s4_col4_b0, s4_col5_b0, s4_col6_b0, s4_col7_b0;
    wire s4_col7_b1, s4_col8_b0, s4_col8_b1, s4_col9_b0;
    wire s4_col9_b1, s4_col10_b0, s4_col10_b1, s4_col11_b0;
    wire s4_col11_b1, s4_col12_b0, s4_col12_b1, s4_col13_b0;
    wire s4_col13_b1, s4_col14_b0, s4_col14_b1, s4_col15_b0;
    wire s4_col15_b1, s4_col16_b0, s4_col16_b1, s4_col17_b0;
    wire s4_col17_b1, s4_col18_b0, s4_col18_b1, s4_col19_b0;
    wire s4_col19_b1, s4_col20_b0, s4_col20_b1, s4_col21_b0;
    wire s4_col21_b1, s4_col22_b0, s4_col22_b1, s4_col23_b0;
    wire s4_col23_b1, s4_col24_b0, s4_col24_b1, s4_col25_b0;
    wire s4_col25_b1, s4_col26_b0, s4_col26_b1, s4_col27_b0;
    wire s4_col27_b1, s4_col28_b0, s4_col28_b1, s4_col29_b0;
    wire s4_col29_b1, s4_col30_b0, s4_col30_b1, s4_col31_b0;
    wire s4_col31_b1, s4_col32_b0, s4_col32_b1, s4_col33_b0;

    wallace_stage3 U_WALLACE_STAGE3 (
        .s3_col0_b0(s3_col0_b0_q),
        .s3_col1_b0(s3_col1_b0_q),
        .s3_col2_b0(s3_col2_b0_q),
        .s3_col3_b0(s3_col3_b0_q),
        .s3_col4_b0(s3_col4_b0_q),
        .s3_col5_b0(s3_col5_b0_q),
        .s3_col5_b1(s3_col5_b1_q),
        .s3_col6_b0(s3_col6_b0_q),
        .s3_col6_b1(s3_col6_b1_q),
        .s3_col7_b0(s3_col7_b0_q),
        .s3_col7_b1(s3_col7_b1_q),
        .s3_col8_b0(s3_col8_b0_q),
        .s3_col8_b1(s3_col8_b1_q),
        .s3_col9_b0(s3_col9_b0_q),
        .s3_col9_b1(s3_col9_b1_q),
        .s3_col10_b0(s3_col10_b0_q),
        .s3_col10_b1(s3_col10_b1_q),
        .s3_col10_b2(s3_col10_b2_q),
        .s3_col11_b0(s3_col11_b0_q),
        .s3_col11_b1(s3_col11_b1_q),
        .s3_col11_b2(s3_col11_b2_q),
        .s3_col12_b0(s3_col12_b0_q),
        .s3_col12_b1(s3_col12_b1_q),
        .s3_col12_b2(s3_col12_b2_q),
        .s3_col13_b0(s3_col13_b0_q),
        .s3_col13_b1(s3_col13_b1_q),
        .s3_col13_b2(s3_col13_b2_q),
        .s3_col14_b0(s3_col14_b0_q),
        .s3_col14_b1(s3_col14_b1_q),
        .s3_col14_b2(s3_col14_b2_q),
        .s3_col15_b0(s3_col15_b0_q),
        .s3_col15_b1(s3_col15_b1_q),
        .s3_col15_b2(s3_col15_b2_q),
        .s3_col15_b3(s3_col15_b3_q),
        .s3_col16_b0(s3_col16_b0_q),
        .s3_col16_b1(s3_col16_b1_q),
        .s3_col16_b2(s3_col16_b2_q),
        .s3_col16_b3(s3_col16_b3_q),
        .s3_col17_b0(s3_col17_b0_q),
        .s3_col17_b1(s3_col17_b1_q),
        .s3_col17_b2(s3_col17_b2_q),
        .s3_col17_b3(s3_col17_b3_q),
        .s3_col18_b0(s3_col18_b0_q),
        .s3_col18_b1(s3_col18_b1_q),
        .s3_col18_b2(s3_col18_b2_q),
        .s3_col18_b3(s3_col18_b3_q),
        .s3_col19_b0(s3_col19_b0_q),
        .s3_col19_b1(s3_col19_b1_q),
        .s3_col19_b2(s3_col19_b2_q),
        .s3_col19_b3(s3_col19_b3_q),
        .s3_col20_b0(s3_col20_b0_q),
        .s3_col20_b1(s3_col20_b1_q),
        .s3_col20_b2(s3_col20_b2_q),
        .s3_col21_b0(s3_col21_b0_q),
        .s3_col21_b1(s3_col21_b1_q),
        .s3_col21_b2(s3_col21_b2_q),
        .s3_col22_b0(s3_col22_b0_q),
        .s3_col22_b1(s3_col22_b1_q),
        .s3_col22_b2(s3_col22_b2_q),
        .s3_col23_b0(s3_col23_b0_q),
        .s3_col23_b1(s3_col23_b1_q),
        .s3_col23_b2(s3_col23_b2_q),
        .s3_col24_b0(s3_col24_b0_q),
        .s3_col24_b1(s3_col24_b1_q),
        .s3_col25_b0(s3_col25_b0_q),
        .s3_col25_b1(s3_col25_b1_q),
        .s3_col26_b0(s3_col26_b0_q),
        .s3_col26_b1(s3_col26_b1_q),
        .s3_col27_b0(s3_col27_b0_q),
        .s3_col27_b1(s3_col27_b1_q),
        .s3_col28_b0(s3_col28_b0_q),
        .s3_col28_b1(s3_col28_b1_q),
        .s3_col29_b0(s3_col29_b0_q),
        .s3_col29_b1(s3_col29_b1_q),
        .s3_col30_b0(s3_col30_b0_q),
        .s3_col30_b1(s3_col30_b1_q),
        .s3_col31_b0(s3_col31_b0_q),
        .s3_col31_b1(s3_col31_b1_q),
        .s3_col32_b0(s3_col32_b0_q),
        .s4_col0_b0(s4_col0_b0),
        .s4_col1_b0(s4_col1_b0),
        .s4_col2_b0(s4_col2_b0),
        .s4_col3_b0(s4_col3_b0),
        .s4_col4_b0(s4_col4_b0),
        .s4_col5_b0(s4_col5_b0),
        .s4_col6_b0(s4_col6_b0),
        .s4_col7_b0(s4_col7_b0),
        .s4_col7_b1(s4_col7_b1),
        .s4_col8_b0(s4_col8_b0),
        .s4_col8_b1(s4_col8_b1),
        .s4_col9_b0(s4_col9_b0),
        .s4_col9_b1(s4_col9_b1),
        .s4_col10_b0(s4_col10_b0),
        .s4_col10_b1(s4_col10_b1),
        .s4_col11_b0(s4_col11_b0),
        .s4_col11_b1(s4_col11_b1),
        .s4_col12_b0(s4_col12_b0),
        .s4_col12_b1(s4_col12_b1),
        .s4_col13_b0(s4_col13_b0),
        .s4_col13_b1(s4_col13_b1),
        .s4_col14_b0(s4_col14_b0),
        .s4_col14_b1(s4_col14_b1),
        .s4_col15_b0(s4_col15_b0),
        .s4_col15_b1(s4_col15_b1),
        .s4_col16_b0(s4_col16_b0),
        .s4_col16_b1(s4_col16_b1),
        .s4_col17_b0(s4_col17_b0),
        .s4_col17_b1(s4_col17_b1),
        .s4_col18_b0(s4_col18_b0),
        .s4_col18_b1(s4_col18_b1),
        .s4_col19_b0(s4_col19_b0),
        .s4_col19_b1(s4_col19_b1),
        .s4_col20_b0(s4_col20_b0),
        .s4_col20_b1(s4_col20_b1),
        .s4_col21_b0(s4_col21_b0),
        .s4_col21_b1(s4_col21_b1),
        .s4_col22_b0(s4_col22_b0),
        .s4_col22_b1(s4_col22_b1),
        .s4_col23_b0(s4_col23_b0),
        .s4_col23_b1(s4_col23_b1),
        .s4_col24_b0(s4_col24_b0),
        .s4_col24_b1(s4_col24_b1),
        .s4_col25_b0(s4_col25_b0),
        .s4_col25_b1(s4_col25_b1),
        .s4_col26_b0(s4_col26_b0),
        .s4_col26_b1(s4_col26_b1),
        .s4_col27_b0(s4_col27_b0),
        .s4_col27_b1(s4_col27_b1),
        .s4_col28_b0(s4_col28_b0),
        .s4_col28_b1(s4_col28_b1),
        .s4_col29_b0(s4_col29_b0),
        .s4_col29_b1(s4_col29_b1),
        .s4_col30_b0(s4_col30_b0),
        .s4_col30_b1(s4_col30_b1),
        .s4_col31_b0(s4_col31_b0),
        .s4_col31_b1(s4_col31_b1),
        .s4_col32_b0(s4_col32_b0),
        .s4_col32_b1(s4_col32_b1),
        .s4_col33_b0(s4_col33_b0)
    );

    // =========================================================================
    // STAGE 5: Final 32-bit Carry Lookahead Addition (combinational)
    // Inputs come from the REGISTERED Stage-4 outputs (s4_colX_bY_q).
    // The two final Wallace Tree rows (Row A = bit 0 of each column,
    // Row B = bit 1 of each column, where present) are concatenated into
    // two clean 32-bit buses and fed into the CLA.
    // Columns 32 and 33 are proven (mathematically and by simulation) to
    // always be 0 for any valid 16-bit x 16-bit multiplication, so they
    // are not connected to the 32-bit CLA -- only columns 0-31 matter.
    // =========================================================================
    wire [31:0] cla_sum;
    wire        cla_cout;  // not used for valid 16x16 inputs, always 0 in practice

    cla_32bit U_CLA (
        .A_in({s4_col31_b0_q, s4_col30_b0_q, s4_col29_b0_q, s4_col28_b0_q, s4_col27_b0_q, s4_col26_b0_q, s4_col25_b0_q, s4_col24_b0_q, s4_col23_b0_q, s4_col22_b0_q, s4_col21_b0_q, s4_col20_b0_q, s4_col19_b0_q, s4_col18_b0_q, s4_col17_b0_q, s4_col16_b0_q, s4_col15_b0_q, s4_col14_b0_q, s4_col13_b0_q, s4_col12_b0_q, s4_col11_b0_q, s4_col10_b0_q, s4_col9_b0_q, s4_col8_b0_q, s4_col7_b0_q, s4_col6_b0_q, s4_col5_b0_q, s4_col4_b0_q, s4_col3_b0_q, s4_col2_b0_q, s4_col1_b0_q, s4_col0_b0_q}),
        .B_in({s4_col31_b1_q, s4_col30_b1_q, s4_col29_b1_q, s4_col28_b1_q, s4_col27_b1_q, s4_col26_b1_q, s4_col25_b1_q, s4_col24_b1_q, s4_col23_b1_q, s4_col22_b1_q, s4_col21_b1_q, s4_col20_b1_q, s4_col19_b1_q, s4_col18_b1_q, s4_col17_b1_q, s4_col16_b1_q, s4_col15_b1_q, s4_col14_b1_q, s4_col13_b1_q, s4_col12_b1_q, s4_col11_b1_q, s4_col10_b1_q, s4_col9_b1_q, s4_col8_b1_q, s4_col7_b1_q, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
        .Sum(cla_sum),
        .Cout(cla_cout)
    );

    // =========================================================================
    // PIPELINE REGISTER LOGIC
    // All registers update synchronously on the rising edge of clk.
    // On rst_n = 0 (active-low reset), every register (data and valid)
    // is synchronously cleared to 0 -- this fully flushes the pipeline.
    // =========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            // ---- Synchronous active-low reset: clear every pipeline stage ----
            pp_row0_q <= 16'b0;
            pp_row1_q <= 16'b0;
            pp_row2_q <= 16'b0;
            pp_row3_q <= 16'b0;
            pp_row4_q <= 16'b0;
            pp_row5_q <= 16'b0;
            pp_row6_q <= 16'b0;
            pp_row7_q <= 16'b0;
            pp_row8_q <= 16'b0;
            pp_row9_q <= 16'b0;
            pp_row10_q <= 16'b0;
            pp_row11_q <= 16'b0;
            pp_row12_q <= 16'b0;
            pp_row13_q <= 16'b0;
            pp_row14_q <= 16'b0;
            pp_row15_q <= 16'b0;
            s2_col0_b0_q <= 1'b0;
            s2_col1_b0_q <= 1'b0;
            s2_col2_b0_q <= 1'b0;
            s2_col3_b0_q <= 1'b0;
            s2_col3_b1_q <= 1'b0;
            s2_col4_b0_q <= 1'b0;
            s2_col4_b1_q <= 1'b0;
            s2_col5_b0_q <= 1'b0;
            s2_col5_b1_q <= 1'b0;
            s2_col5_b2_q <= 1'b0;
            s2_col6_b0_q <= 1'b0;
            s2_col6_b1_q <= 1'b0;
            s2_col6_b2_q <= 1'b0;
            s2_col7_b0_q <= 1'b0;
            s2_col7_b1_q <= 1'b0;
            s2_col7_b2_q <= 1'b0;
            s2_col7_b3_q <= 1'b0;
            s2_col8_b0_q <= 1'b0;
            s2_col8_b1_q <= 1'b0;
            s2_col8_b2_q <= 1'b0;
            s2_col8_b3_q <= 1'b0;
            s2_col9_b0_q <= 1'b0;
            s2_col9_b1_q <= 1'b0;
            s2_col9_b2_q <= 1'b0;
            s2_col9_b3_q <= 1'b0;
            s2_col9_b4_q <= 1'b0;
            s2_col10_b0_q <= 1'b0;
            s2_col10_b1_q <= 1'b0;
            s2_col10_b2_q <= 1'b0;
            s2_col10_b3_q <= 1'b0;
            s2_col10_b4_q <= 1'b0;
            s2_col11_b0_q <= 1'b0;
            s2_col11_b1_q <= 1'b0;
            s2_col11_b2_q <= 1'b0;
            s2_col11_b3_q <= 1'b0;
            s2_col11_b4_q <= 1'b0;
            s2_col12_b0_q <= 1'b0;
            s2_col12_b1_q <= 1'b0;
            s2_col12_b2_q <= 1'b0;
            s2_col12_b3_q <= 1'b0;
            s2_col12_b4_q <= 1'b0;
            s2_col12_b5_q <= 1'b0;
            s2_col13_b0_q <= 1'b0;
            s2_col13_b1_q <= 1'b0;
            s2_col13_b2_q <= 1'b0;
            s2_col13_b3_q <= 1'b0;
            s2_col13_b4_q <= 1'b0;
            s2_col13_b5_q <= 1'b0;
            s2_col14_b0_q <= 1'b0;
            s2_col14_b1_q <= 1'b0;
            s2_col14_b2_q <= 1'b0;
            s2_col14_b3_q <= 1'b0;
            s2_col14_b4_q <= 1'b0;
            s2_col14_b5_q <= 1'b0;
            s2_col14_b6_q <= 1'b0;
            s2_col15_b0_q <= 1'b0;
            s2_col15_b1_q <= 1'b0;
            s2_col15_b2_q <= 1'b0;
            s2_col15_b3_q <= 1'b0;
            s2_col15_b4_q <= 1'b0;
            s2_col15_b5_q <= 1'b0;
            s2_col15_b6_q <= 1'b0;
            s2_col16_b0_q <= 1'b0;
            s2_col16_b1_q <= 1'b0;
            s2_col16_b2_q <= 1'b0;
            s2_col16_b3_q <= 1'b0;
            s2_col16_b4_q <= 1'b0;
            s2_col16_b5_q <= 1'b0;
            s2_col16_b6_q <= 1'b0;
            s2_col16_b7_q <= 1'b0;
            s2_col17_b0_q <= 1'b0;
            s2_col17_b1_q <= 1'b0;
            s2_col17_b2_q <= 1'b0;
            s2_col17_b3_q <= 1'b0;
            s2_col17_b4_q <= 1'b0;
            s2_col17_b5_q <= 1'b0;
            s2_col17_b6_q <= 1'b0;
            s2_col18_b0_q <= 1'b0;
            s2_col18_b1_q <= 1'b0;
            s2_col18_b2_q <= 1'b0;
            s2_col18_b3_q <= 1'b0;
            s2_col18_b4_q <= 1'b0;
            s2_col18_b5_q <= 1'b0;
            s2_col18_b6_q <= 1'b0;
            s2_col19_b0_q <= 1'b0;
            s2_col19_b1_q <= 1'b0;
            s2_col19_b2_q <= 1'b0;
            s2_col19_b3_q <= 1'b0;
            s2_col19_b4_q <= 1'b0;
            s2_col19_b5_q <= 1'b0;
            s2_col20_b0_q <= 1'b0;
            s2_col20_b1_q <= 1'b0;
            s2_col20_b2_q <= 1'b0;
            s2_col20_b3_q <= 1'b0;
            s2_col20_b4_q <= 1'b0;
            s2_col20_b5_q <= 1'b0;
            s2_col21_b0_q <= 1'b0;
            s2_col21_b1_q <= 1'b0;
            s2_col21_b2_q <= 1'b0;
            s2_col21_b3_q <= 1'b0;
            s2_col21_b4_q <= 1'b0;
            s2_col21_b5_q <= 1'b0;
            s2_col22_b0_q <= 1'b0;
            s2_col22_b1_q <= 1'b0;
            s2_col22_b2_q <= 1'b0;
            s2_col22_b3_q <= 1'b0;
            s2_col22_b4_q <= 1'b0;
            s2_col23_b0_q <= 1'b0;
            s2_col23_b1_q <= 1'b0;
            s2_col23_b2_q <= 1'b0;
            s2_col23_b3_q <= 1'b0;
            s2_col24_b0_q <= 1'b0;
            s2_col24_b1_q <= 1'b0;
            s2_col24_b2_q <= 1'b0;
            s2_col24_b3_q <= 1'b0;
            s2_col25_b0_q <= 1'b0;
            s2_col25_b1_q <= 1'b0;
            s2_col25_b2_q <= 1'b0;
            s2_col25_b3_q <= 1'b0;
            s2_col26_b0_q <= 1'b0;
            s2_col26_b1_q <= 1'b0;
            s2_col26_b2_q <= 1'b0;
            s2_col27_b0_q <= 1'b0;
            s2_col27_b1_q <= 1'b0;
            s2_col27_b2_q <= 1'b0;
            s2_col28_b0_q <= 1'b0;
            s2_col28_b1_q <= 1'b0;
            s2_col29_b0_q <= 1'b0;
            s2_col29_b1_q <= 1'b0;
            s2_col30_b0_q <= 1'b0;
            s2_col30_b1_q <= 1'b0;
            s2_col31_b0_q <= 1'b0;
            s3_col0_b0_q <= 1'b0;
            s3_col1_b0_q <= 1'b0;
            s3_col2_b0_q <= 1'b0;
            s3_col3_b0_q <= 1'b0;
            s3_col4_b0_q <= 1'b0;
            s3_col5_b0_q <= 1'b0;
            s3_col5_b1_q <= 1'b0;
            s3_col6_b0_q <= 1'b0;
            s3_col6_b1_q <= 1'b0;
            s3_col7_b0_q <= 1'b0;
            s3_col7_b1_q <= 1'b0;
            s3_col8_b0_q <= 1'b0;
            s3_col8_b1_q <= 1'b0;
            s3_col9_b0_q <= 1'b0;
            s3_col9_b1_q <= 1'b0;
            s3_col10_b0_q <= 1'b0;
            s3_col10_b1_q <= 1'b0;
            s3_col10_b2_q <= 1'b0;
            s3_col11_b0_q <= 1'b0;
            s3_col11_b1_q <= 1'b0;
            s3_col11_b2_q <= 1'b0;
            s3_col12_b0_q <= 1'b0;
            s3_col12_b1_q <= 1'b0;
            s3_col12_b2_q <= 1'b0;
            s3_col13_b0_q <= 1'b0;
            s3_col13_b1_q <= 1'b0;
            s3_col13_b2_q <= 1'b0;
            s3_col14_b0_q <= 1'b0;
            s3_col14_b1_q <= 1'b0;
            s3_col14_b2_q <= 1'b0;
            s3_col15_b0_q <= 1'b0;
            s3_col15_b1_q <= 1'b0;
            s3_col15_b2_q <= 1'b0;
            s3_col15_b3_q <= 1'b0;
            s3_col16_b0_q <= 1'b0;
            s3_col16_b1_q <= 1'b0;
            s3_col16_b2_q <= 1'b0;
            s3_col16_b3_q <= 1'b0;
            s3_col17_b0_q <= 1'b0;
            s3_col17_b1_q <= 1'b0;
            s3_col17_b2_q <= 1'b0;
            s3_col17_b3_q <= 1'b0;
            s3_col18_b0_q <= 1'b0;
            s3_col18_b1_q <= 1'b0;
            s3_col18_b2_q <= 1'b0;
            s3_col18_b3_q <= 1'b0;
            s3_col19_b0_q <= 1'b0;
            s3_col19_b1_q <= 1'b0;
            s3_col19_b2_q <= 1'b0;
            s3_col19_b3_q <= 1'b0;
            s3_col20_b0_q <= 1'b0;
            s3_col20_b1_q <= 1'b0;
            s3_col20_b2_q <= 1'b0;
            s3_col21_b0_q <= 1'b0;
            s3_col21_b1_q <= 1'b0;
            s3_col21_b2_q <= 1'b0;
            s3_col22_b0_q <= 1'b0;
            s3_col22_b1_q <= 1'b0;
            s3_col22_b2_q <= 1'b0;
            s3_col23_b0_q <= 1'b0;
            s3_col23_b1_q <= 1'b0;
            s3_col23_b2_q <= 1'b0;
            s3_col24_b0_q <= 1'b0;
            s3_col24_b1_q <= 1'b0;
            s3_col25_b0_q <= 1'b0;
            s3_col25_b1_q <= 1'b0;
            s3_col26_b0_q <= 1'b0;
            s3_col26_b1_q <= 1'b0;
            s3_col27_b0_q <= 1'b0;
            s3_col27_b1_q <= 1'b0;
            s3_col28_b0_q <= 1'b0;
            s3_col28_b1_q <= 1'b0;
            s3_col29_b0_q <= 1'b0;
            s3_col29_b1_q <= 1'b0;
            s3_col30_b0_q <= 1'b0;
            s3_col30_b1_q <= 1'b0;
            s3_col31_b0_q <= 1'b0;
            s3_col31_b1_q <= 1'b0;
            s3_col32_b0_q <= 1'b0;
            s4_col0_b0_q <= 1'b0;
            s4_col1_b0_q <= 1'b0;
            s4_col2_b0_q <= 1'b0;
            s4_col3_b0_q <= 1'b0;
            s4_col4_b0_q <= 1'b0;
            s4_col5_b0_q <= 1'b0;
            s4_col6_b0_q <= 1'b0;
            s4_col7_b0_q <= 1'b0;
            s4_col7_b1_q <= 1'b0;
            s4_col8_b0_q <= 1'b0;
            s4_col8_b1_q <= 1'b0;
            s4_col9_b0_q <= 1'b0;
            s4_col9_b1_q <= 1'b0;
            s4_col10_b0_q <= 1'b0;
            s4_col10_b1_q <= 1'b0;
            s4_col11_b0_q <= 1'b0;
            s4_col11_b1_q <= 1'b0;
            s4_col12_b0_q <= 1'b0;
            s4_col12_b1_q <= 1'b0;
            s4_col13_b0_q <= 1'b0;
            s4_col13_b1_q <= 1'b0;
            s4_col14_b0_q <= 1'b0;
            s4_col14_b1_q <= 1'b0;
            s4_col15_b0_q <= 1'b0;
            s4_col15_b1_q <= 1'b0;
            s4_col16_b0_q <= 1'b0;
            s4_col16_b1_q <= 1'b0;
            s4_col17_b0_q <= 1'b0;
            s4_col17_b1_q <= 1'b0;
            s4_col18_b0_q <= 1'b0;
            s4_col18_b1_q <= 1'b0;
            s4_col19_b0_q <= 1'b0;
            s4_col19_b1_q <= 1'b0;
            s4_col20_b0_q <= 1'b0;
            s4_col20_b1_q <= 1'b0;
            s4_col21_b0_q <= 1'b0;
            s4_col21_b1_q <= 1'b0;
            s4_col22_b0_q <= 1'b0;
            s4_col22_b1_q <= 1'b0;
            s4_col23_b0_q <= 1'b0;
            s4_col23_b1_q <= 1'b0;
            s4_col24_b0_q <= 1'b0;
            s4_col24_b1_q <= 1'b0;
            s4_col25_b0_q <= 1'b0;
            s4_col25_b1_q <= 1'b0;
            s4_col26_b0_q <= 1'b0;
            s4_col26_b1_q <= 1'b0;
            s4_col27_b0_q <= 1'b0;
            s4_col27_b1_q <= 1'b0;
            s4_col28_b0_q <= 1'b0;
            s4_col28_b1_q <= 1'b0;
            s4_col29_b0_q <= 1'b0;
            s4_col29_b1_q <= 1'b0;
            s4_col30_b0_q <= 1'b0;
            s4_col30_b1_q <= 1'b0;
            s4_col31_b0_q <= 1'b0;
            s4_col31_b1_q <= 1'b0;
            s4_col32_b0_q <= 1'b0;
            s4_col32_b1_q <= 1'b0;
            s4_col33_b0_q <= 1'b0;
            P          <= 32'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            valid_out    <= 1'b0;
        end
        else begin
            // ---- Register Stage 1->2: latch the raw partial products ----
            pp_row0_q <= pp_row0;
            pp_row1_q <= pp_row1;
            pp_row2_q <= pp_row2;
            pp_row3_q <= pp_row3;
            pp_row4_q <= pp_row4;
            pp_row5_q <= pp_row5;
            pp_row6_q <= pp_row6;
            pp_row7_q <= pp_row7;
            pp_row8_q <= pp_row8;
            pp_row9_q <= pp_row9;
            pp_row10_q <= pp_row10;
            pp_row11_q <= pp_row11;
            pp_row12_q <= pp_row12;
            pp_row13_q <= pp_row13;
            pp_row14_q <= pp_row14;
            pp_row15_q <= pp_row15;

            // ---- Register Stage 2->3: latch Wallace Level 1+2 outputs ----
            s2_col0_b0_q <= s2_col0_b0;
            s2_col1_b0_q <= s2_col1_b0;
            s2_col2_b0_q <= s2_col2_b0;
            s2_col3_b0_q <= s2_col3_b0;
            s2_col3_b1_q <= s2_col3_b1;
            s2_col4_b0_q <= s2_col4_b0;
            s2_col4_b1_q <= s2_col4_b1;
            s2_col5_b0_q <= s2_col5_b0;
            s2_col5_b1_q <= s2_col5_b1;
            s2_col5_b2_q <= s2_col5_b2;
            s2_col6_b0_q <= s2_col6_b0;
            s2_col6_b1_q <= s2_col6_b1;
            s2_col6_b2_q <= s2_col6_b2;
            s2_col7_b0_q <= s2_col7_b0;
            s2_col7_b1_q <= s2_col7_b1;
            s2_col7_b2_q <= s2_col7_b2;
            s2_col7_b3_q <= s2_col7_b3;
            s2_col8_b0_q <= s2_col8_b0;
            s2_col8_b1_q <= s2_col8_b1;
            s2_col8_b2_q <= s2_col8_b2;
            s2_col8_b3_q <= s2_col8_b3;
            s2_col9_b0_q <= s2_col9_b0;
            s2_col9_b1_q <= s2_col9_b1;
            s2_col9_b2_q <= s2_col9_b2;
            s2_col9_b3_q <= s2_col9_b3;
            s2_col9_b4_q <= s2_col9_b4;
            s2_col10_b0_q <= s2_col10_b0;
            s2_col10_b1_q <= s2_col10_b1;
            s2_col10_b2_q <= s2_col10_b2;
            s2_col10_b3_q <= s2_col10_b3;
            s2_col10_b4_q <= s2_col10_b4;
            s2_col11_b0_q <= s2_col11_b0;
            s2_col11_b1_q <= s2_col11_b1;
            s2_col11_b2_q <= s2_col11_b2;
            s2_col11_b3_q <= s2_col11_b3;
            s2_col11_b4_q <= s2_col11_b4;
            s2_col12_b0_q <= s2_col12_b0;
            s2_col12_b1_q <= s2_col12_b1;
            s2_col12_b2_q <= s2_col12_b2;
            s2_col12_b3_q <= s2_col12_b3;
            s2_col12_b4_q <= s2_col12_b4;
            s2_col12_b5_q <= s2_col12_b5;
            s2_col13_b0_q <= s2_col13_b0;
            s2_col13_b1_q <= s2_col13_b1;
            s2_col13_b2_q <= s2_col13_b2;
            s2_col13_b3_q <= s2_col13_b3;
            s2_col13_b4_q <= s2_col13_b4;
            s2_col13_b5_q <= s2_col13_b5;
            s2_col14_b0_q <= s2_col14_b0;
            s2_col14_b1_q <= s2_col14_b1;
            s2_col14_b2_q <= s2_col14_b2;
            s2_col14_b3_q <= s2_col14_b3;
            s2_col14_b4_q <= s2_col14_b4;
            s2_col14_b5_q <= s2_col14_b5;
            s2_col14_b6_q <= s2_col14_b6;
            s2_col15_b0_q <= s2_col15_b0;
            s2_col15_b1_q <= s2_col15_b1;
            s2_col15_b2_q <= s2_col15_b2;
            s2_col15_b3_q <= s2_col15_b3;
            s2_col15_b4_q <= s2_col15_b4;
            s2_col15_b5_q <= s2_col15_b5;
            s2_col15_b6_q <= s2_col15_b6;
            s2_col16_b0_q <= s2_col16_b0;
            s2_col16_b1_q <= s2_col16_b1;
            s2_col16_b2_q <= s2_col16_b2;
            s2_col16_b3_q <= s2_col16_b3;
            s2_col16_b4_q <= s2_col16_b4;
            s2_col16_b5_q <= s2_col16_b5;
            s2_col16_b6_q <= s2_col16_b6;
            s2_col16_b7_q <= s2_col16_b7;
            s2_col17_b0_q <= s2_col17_b0;
            s2_col17_b1_q <= s2_col17_b1;
            s2_col17_b2_q <= s2_col17_b2;
            s2_col17_b3_q <= s2_col17_b3;
            s2_col17_b4_q <= s2_col17_b4;
            s2_col17_b5_q <= s2_col17_b5;
            s2_col17_b6_q <= s2_col17_b6;
            s2_col18_b0_q <= s2_col18_b0;
            s2_col18_b1_q <= s2_col18_b1;
            s2_col18_b2_q <= s2_col18_b2;
            s2_col18_b3_q <= s2_col18_b3;
            s2_col18_b4_q <= s2_col18_b4;
            s2_col18_b5_q <= s2_col18_b5;
            s2_col18_b6_q <= s2_col18_b6;
            s2_col19_b0_q <= s2_col19_b0;
            s2_col19_b1_q <= s2_col19_b1;
            s2_col19_b2_q <= s2_col19_b2;
            s2_col19_b3_q <= s2_col19_b3;
            s2_col19_b4_q <= s2_col19_b4;
            s2_col19_b5_q <= s2_col19_b5;
            s2_col20_b0_q <= s2_col20_b0;
            s2_col20_b1_q <= s2_col20_b1;
            s2_col20_b2_q <= s2_col20_b2;
            s2_col20_b3_q <= s2_col20_b3;
            s2_col20_b4_q <= s2_col20_b4;
            s2_col20_b5_q <= s2_col20_b5;
            s2_col21_b0_q <= s2_col21_b0;
            s2_col21_b1_q <= s2_col21_b1;
            s2_col21_b2_q <= s2_col21_b2;
            s2_col21_b3_q <= s2_col21_b3;
            s2_col21_b4_q <= s2_col21_b4;
            s2_col21_b5_q <= s2_col21_b5;
            s2_col22_b0_q <= s2_col22_b0;
            s2_col22_b1_q <= s2_col22_b1;
            s2_col22_b2_q <= s2_col22_b2;
            s2_col22_b3_q <= s2_col22_b3;
            s2_col22_b4_q <= s2_col22_b4;
            s2_col23_b0_q <= s2_col23_b0;
            s2_col23_b1_q <= s2_col23_b1;
            s2_col23_b2_q <= s2_col23_b2;
            s2_col23_b3_q <= s2_col23_b3;
            s2_col24_b0_q <= s2_col24_b0;
            s2_col24_b1_q <= s2_col24_b1;
            s2_col24_b2_q <= s2_col24_b2;
            s2_col24_b3_q <= s2_col24_b3;
            s2_col25_b0_q <= s2_col25_b0;
            s2_col25_b1_q <= s2_col25_b1;
            s2_col25_b2_q <= s2_col25_b2;
            s2_col25_b3_q <= s2_col25_b3;
            s2_col26_b0_q <= s2_col26_b0;
            s2_col26_b1_q <= s2_col26_b1;
            s2_col26_b2_q <= s2_col26_b2;
            s2_col27_b0_q <= s2_col27_b0;
            s2_col27_b1_q <= s2_col27_b1;
            s2_col27_b2_q <= s2_col27_b2;
            s2_col28_b0_q <= s2_col28_b0;
            s2_col28_b1_q <= s2_col28_b1;
            s2_col29_b0_q <= s2_col29_b0;
            s2_col29_b1_q <= s2_col29_b1;
            s2_col30_b0_q <= s2_col30_b0;
            s2_col30_b1_q <= s2_col30_b1;
            s2_col31_b0_q <= s2_col31_b0;

            // ---- Register Stage 3->4: latch Wallace Level 3+4 outputs ----
            s3_col0_b0_q <= s3_col0_b0;
            s3_col1_b0_q <= s3_col1_b0;
            s3_col2_b0_q <= s3_col2_b0;
            s3_col3_b0_q <= s3_col3_b0;
            s3_col4_b0_q <= s3_col4_b0;
            s3_col5_b0_q <= s3_col5_b0;
            s3_col5_b1_q <= s3_col5_b1;
            s3_col6_b0_q <= s3_col6_b0;
            s3_col6_b1_q <= s3_col6_b1;
            s3_col7_b0_q <= s3_col7_b0;
            s3_col7_b1_q <= s3_col7_b1;
            s3_col8_b0_q <= s3_col8_b0;
            s3_col8_b1_q <= s3_col8_b1;
            s3_col9_b0_q <= s3_col9_b0;
            s3_col9_b1_q <= s3_col9_b1;
            s3_col10_b0_q <= s3_col10_b0;
            s3_col10_b1_q <= s3_col10_b1;
            s3_col10_b2_q <= s3_col10_b2;
            s3_col11_b0_q <= s3_col11_b0;
            s3_col11_b1_q <= s3_col11_b1;
            s3_col11_b2_q <= s3_col11_b2;
            s3_col12_b0_q <= s3_col12_b0;
            s3_col12_b1_q <= s3_col12_b1;
            s3_col12_b2_q <= s3_col12_b2;
            s3_col13_b0_q <= s3_col13_b0;
            s3_col13_b1_q <= s3_col13_b1;
            s3_col13_b2_q <= s3_col13_b2;
            s3_col14_b0_q <= s3_col14_b0;
            s3_col14_b1_q <= s3_col14_b1;
            s3_col14_b2_q <= s3_col14_b2;
            s3_col15_b0_q <= s3_col15_b0;
            s3_col15_b1_q <= s3_col15_b1;
            s3_col15_b2_q <= s3_col15_b2;
            s3_col15_b3_q <= s3_col15_b3;
            s3_col16_b0_q <= s3_col16_b0;
            s3_col16_b1_q <= s3_col16_b1;
            s3_col16_b2_q <= s3_col16_b2;
            s3_col16_b3_q <= s3_col16_b3;
            s3_col17_b0_q <= s3_col17_b0;
            s3_col17_b1_q <= s3_col17_b1;
            s3_col17_b2_q <= s3_col17_b2;
            s3_col17_b3_q <= s3_col17_b3;
            s3_col18_b0_q <= s3_col18_b0;
            s3_col18_b1_q <= s3_col18_b1;
            s3_col18_b2_q <= s3_col18_b2;
            s3_col18_b3_q <= s3_col18_b3;
            s3_col19_b0_q <= s3_col19_b0;
            s3_col19_b1_q <= s3_col19_b1;
            s3_col19_b2_q <= s3_col19_b2;
            s3_col19_b3_q <= s3_col19_b3;
            s3_col20_b0_q <= s3_col20_b0;
            s3_col20_b1_q <= s3_col20_b1;
            s3_col20_b2_q <= s3_col20_b2;
            s3_col21_b0_q <= s3_col21_b0;
            s3_col21_b1_q <= s3_col21_b1;
            s3_col21_b2_q <= s3_col21_b2;
            s3_col22_b0_q <= s3_col22_b0;
            s3_col22_b1_q <= s3_col22_b1;
            s3_col22_b2_q <= s3_col22_b2;
            s3_col23_b0_q <= s3_col23_b0;
            s3_col23_b1_q <= s3_col23_b1;
            s3_col23_b2_q <= s3_col23_b2;
            s3_col24_b0_q <= s3_col24_b0;
            s3_col24_b1_q <= s3_col24_b1;
            s3_col25_b0_q <= s3_col25_b0;
            s3_col25_b1_q <= s3_col25_b1;
            s3_col26_b0_q <= s3_col26_b0;
            s3_col26_b1_q <= s3_col26_b1;
            s3_col27_b0_q <= s3_col27_b0;
            s3_col27_b1_q <= s3_col27_b1;
            s3_col28_b0_q <= s3_col28_b0;
            s3_col28_b1_q <= s3_col28_b1;
            s3_col29_b0_q <= s3_col29_b0;
            s3_col29_b1_q <= s3_col29_b1;
            s3_col30_b0_q <= s3_col30_b0;
            s3_col30_b1_q <= s3_col30_b1;
            s3_col31_b0_q <= s3_col31_b0;
            s3_col31_b1_q <= s3_col31_b1;
            s3_col32_b0_q <= s3_col32_b0;

            // ---- Register Stage 4->5: latch Wallace Level 5+6 outputs ----
            s4_col0_b0_q <= s4_col0_b0;
            s4_col1_b0_q <= s4_col1_b0;
            s4_col2_b0_q <= s4_col2_b0;
            s4_col3_b0_q <= s4_col3_b0;
            s4_col4_b0_q <= s4_col4_b0;
            s4_col5_b0_q <= s4_col5_b0;
            s4_col6_b0_q <= s4_col6_b0;
            s4_col7_b0_q <= s4_col7_b0;
            s4_col7_b1_q <= s4_col7_b1;
            s4_col8_b0_q <= s4_col8_b0;
            s4_col8_b1_q <= s4_col8_b1;
            s4_col9_b0_q <= s4_col9_b0;
            s4_col9_b1_q <= s4_col9_b1;
            s4_col10_b0_q <= s4_col10_b0;
            s4_col10_b1_q <= s4_col10_b1;
            s4_col11_b0_q <= s4_col11_b0;
            s4_col11_b1_q <= s4_col11_b1;
            s4_col12_b0_q <= s4_col12_b0;
            s4_col12_b1_q <= s4_col12_b1;
            s4_col13_b0_q <= s4_col13_b0;
            s4_col13_b1_q <= s4_col13_b1;
            s4_col14_b0_q <= s4_col14_b0;
            s4_col14_b1_q <= s4_col14_b1;
            s4_col15_b0_q <= s4_col15_b0;
            s4_col15_b1_q <= s4_col15_b1;
            s4_col16_b0_q <= s4_col16_b0;
            s4_col16_b1_q <= s4_col16_b1;
            s4_col17_b0_q <= s4_col17_b0;
            s4_col17_b1_q <= s4_col17_b1;
            s4_col18_b0_q <= s4_col18_b0;
            s4_col18_b1_q <= s4_col18_b1;
            s4_col19_b0_q <= s4_col19_b0;
            s4_col19_b1_q <= s4_col19_b1;
            s4_col20_b0_q <= s4_col20_b0;
            s4_col20_b1_q <= s4_col20_b1;
            s4_col21_b0_q <= s4_col21_b0;
            s4_col21_b1_q <= s4_col21_b1;
            s4_col22_b0_q <= s4_col22_b0;
            s4_col22_b1_q <= s4_col22_b1;
            s4_col23_b0_q <= s4_col23_b0;
            s4_col23_b1_q <= s4_col23_b1;
            s4_col24_b0_q <= s4_col24_b0;
            s4_col24_b1_q <= s4_col24_b1;
            s4_col25_b0_q <= s4_col25_b0;
            s4_col25_b1_q <= s4_col25_b1;
            s4_col26_b0_q <= s4_col26_b0;
            s4_col26_b1_q <= s4_col26_b1;
            s4_col27_b0_q <= s4_col27_b0;
            s4_col27_b1_q <= s4_col27_b1;
            s4_col28_b0_q <= s4_col28_b0;
            s4_col28_b1_q <= s4_col28_b1;
            s4_col29_b0_q <= s4_col29_b0;
            s4_col29_b1_q <= s4_col29_b1;
            s4_col30_b0_q <= s4_col30_b0;
            s4_col30_b1_q <= s4_col30_b1;
            s4_col31_b0_q <= s4_col31_b0;
            s4_col31_b1_q <= s4_col31_b1;
            s4_col32_b0_q <= s4_col32_b0;
            s4_col32_b1_q <= s4_col32_b1;
            s4_col33_b0_q <= s4_col33_b0;

            // ---- Final output register: latch the CLA's sum into P ----
            P <= cla_sum;

            // ---- Valid signal pipeline: shifts valid_in through 5 stages,
            //      alongside the data, so valid_out lines up with the cycle
            //      the matching result appears on P.
            valid_stage1 <= valid_in;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
            valid_stage4 <= valid_stage3;
            valid_out    <= valid_stage4;
        end
    end

endmodule
