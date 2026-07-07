// =============================================================================
// Module      : wallace_stage2
// Pipeline    : STAGE 3  (second half of Wallace Tree reduction)
// Description : Takes the 132 partially-reduced bits produced by Stage 2
//               (wallace_stage1, after Levels 1 & 2) and performs TWO MORE
//               levels of Wallace Tree reduction (Level 3 and Level 4),
//               again using only Full Adders (3:2 compressors) and Half
//               Adders (2:2 compressors).
//
//               PROGRESS SO FAR (see Wallace Tree Blueprint document):
//                 Before any reduction : up to 16 bits in the widest column
//                 After Stage 2 (L1+L2): up to  8 bits in the widest column
//                 After Stage 3 (L3+L4): up to  4 bits in the widest column
//               Two more levels happen in Stage 4, bringing every column
//               down to <=2 bits, ready for the final 32-bit adder.
//
//               HOW TO READ THIS FILE:
//               Identical structure to wallace_stage1.v: organized strictly
//               column-by-column, in increasing column order, Level 3 first
//               then Level 4. Every column has a heading comment showing
//               its input bit count and FA/HA/passthrough breakdown,
//               matching the project's Wallace Tree Blueprint document.
//
//               NAMING CONVENTION for internal wires:
//                 w_l3_c{col}_fa{n}_s / _c  = Level 3, column {col}, FA #n, sum/carry
//                 w_l3_c{col}_ha{n}_s / _c  = Level 3, column {col}, HA #n, sum/carry
//               (same pattern with "l4" for Level 4)
//
//               OUTPUT NAMING: s3_col{c}_b{n} = Stage 3 output, column c, bit n
// =============================================================================

module wallace_stage2 (
    // ---- Inputs: partially-reduced columns from Stage 2 (wallace_stage1) ----
    input  wire s2_col0_b0,
    input  wire s2_col1_b0,
    input  wire s2_col2_b0,
    input  wire s2_col3_b0,
    input  wire s2_col3_b1,
    input  wire s2_col4_b0,
    input  wire s2_col4_b1,
    input  wire s2_col5_b0,
    input  wire s2_col5_b1,
    input  wire s2_col5_b2,
    input  wire s2_col6_b0,
    input  wire s2_col6_b1,
    input  wire s2_col6_b2,
    input  wire s2_col7_b0,
    input  wire s2_col7_b1,
    input  wire s2_col7_b2,
    input  wire s2_col7_b3,
    input  wire s2_col8_b0,
    input  wire s2_col8_b1,
    input  wire s2_col8_b2,
    input  wire s2_col8_b3,
    input  wire s2_col9_b0,
    input  wire s2_col9_b1,
    input  wire s2_col9_b2,
    input  wire s2_col9_b3,
    input  wire s2_col9_b4,
    input  wire s2_col10_b0,
    input  wire s2_col10_b1,
    input  wire s2_col10_b2,
    input  wire s2_col10_b3,
    input  wire s2_col10_b4,
    input  wire s2_col11_b0,
    input  wire s2_col11_b1,
    input  wire s2_col11_b2,
    input  wire s2_col11_b3,
    input  wire s2_col11_b4,
    input  wire s2_col12_b0,
    input  wire s2_col12_b1,
    input  wire s2_col12_b2,
    input  wire s2_col12_b3,
    input  wire s2_col12_b4,
    input  wire s2_col12_b5,
    input  wire s2_col13_b0,
    input  wire s2_col13_b1,
    input  wire s2_col13_b2,
    input  wire s2_col13_b3,
    input  wire s2_col13_b4,
    input  wire s2_col13_b5,
    input  wire s2_col14_b0,
    input  wire s2_col14_b1,
    input  wire s2_col14_b2,
    input  wire s2_col14_b3,
    input  wire s2_col14_b4,
    input  wire s2_col14_b5,
    input  wire s2_col14_b6,
    input  wire s2_col15_b0,
    input  wire s2_col15_b1,
    input  wire s2_col15_b2,
    input  wire s2_col15_b3,
    input  wire s2_col15_b4,
    input  wire s2_col15_b5,
    input  wire s2_col15_b6,
    input  wire s2_col16_b0,
    input  wire s2_col16_b1,
    input  wire s2_col16_b2,
    input  wire s2_col16_b3,
    input  wire s2_col16_b4,
    input  wire s2_col16_b5,
    input  wire s2_col16_b6,
    input  wire s2_col16_b7,
    input  wire s2_col17_b0,
    input  wire s2_col17_b1,
    input  wire s2_col17_b2,
    input  wire s2_col17_b3,
    input  wire s2_col17_b4,
    input  wire s2_col17_b5,
    input  wire s2_col17_b6,
    input  wire s2_col18_b0,
    input  wire s2_col18_b1,
    input  wire s2_col18_b2,
    input  wire s2_col18_b3,
    input  wire s2_col18_b4,
    input  wire s2_col18_b5,
    input  wire s2_col18_b6,
    input  wire s2_col19_b0,
    input  wire s2_col19_b1,
    input  wire s2_col19_b2,
    input  wire s2_col19_b3,
    input  wire s2_col19_b4,
    input  wire s2_col19_b5,
    input  wire s2_col20_b0,
    input  wire s2_col20_b1,
    input  wire s2_col20_b2,
    input  wire s2_col20_b3,
    input  wire s2_col20_b4,
    input  wire s2_col20_b5,
    input  wire s2_col21_b0,
    input  wire s2_col21_b1,
    input  wire s2_col21_b2,
    input  wire s2_col21_b3,
    input  wire s2_col21_b4,
    input  wire s2_col21_b5,
    input  wire s2_col22_b0,
    input  wire s2_col22_b1,
    input  wire s2_col22_b2,
    input  wire s2_col22_b3,
    input  wire s2_col22_b4,
    input  wire s2_col23_b0,
    input  wire s2_col23_b1,
    input  wire s2_col23_b2,
    input  wire s2_col23_b3,
    input  wire s2_col24_b0,
    input  wire s2_col24_b1,
    input  wire s2_col24_b2,
    input  wire s2_col24_b3,
    input  wire s2_col25_b0,
    input  wire s2_col25_b1,
    input  wire s2_col25_b2,
    input  wire s2_col25_b3,
    input  wire s2_col26_b0,
    input  wire s2_col26_b1,
    input  wire s2_col26_b2,
    input  wire s2_col27_b0,
    input  wire s2_col27_b1,
    input  wire s2_col27_b2,
    input  wire s2_col28_b0,
    input  wire s2_col28_b1,
    input  wire s2_col29_b0,
    input  wire s2_col29_b1,
    input  wire s2_col30_b0,
    input  wire s2_col30_b1,
    input  wire s2_col31_b0,

    // ---- Outputs: further-reduced columns, after Levels 3 & 4 ----
    // (see s3_col{c}_b{n} naming convention explained above)
    output wire s3_col0_b0,
    output wire s3_col1_b0,
    output wire s3_col2_b0,
    output wire s3_col3_b0,
    output wire s3_col4_b0,
    output wire s3_col5_b0,
    output wire s3_col5_b1,
    output wire s3_col6_b0,
    output wire s3_col6_b1,
    output wire s3_col7_b0,
    output wire s3_col7_b1,
    output wire s3_col8_b0,
    output wire s3_col8_b1,
    output wire s3_col9_b0,
    output wire s3_col9_b1,
    output wire s3_col10_b0,
    output wire s3_col10_b1,
    output wire s3_col10_b2,
    output wire s3_col11_b0,
    output wire s3_col11_b1,
    output wire s3_col11_b2,
    output wire s3_col12_b0,
    output wire s3_col12_b1,
    output wire s3_col12_b2,
    output wire s3_col13_b0,
    output wire s3_col13_b1,
    output wire s3_col13_b2,
    output wire s3_col14_b0,
    output wire s3_col14_b1,
    output wire s3_col14_b2,
    output wire s3_col15_b0,
    output wire s3_col15_b1,
    output wire s3_col15_b2,
    output wire s3_col15_b3,
    output wire s3_col16_b0,
    output wire s3_col16_b1,
    output wire s3_col16_b2,
    output wire s3_col16_b3,
    output wire s3_col17_b0,
    output wire s3_col17_b1,
    output wire s3_col17_b2,
    output wire s3_col17_b3,
    output wire s3_col18_b0,
    output wire s3_col18_b1,
    output wire s3_col18_b2,
    output wire s3_col18_b3,
    output wire s3_col19_b0,
    output wire s3_col19_b1,
    output wire s3_col19_b2,
    output wire s3_col19_b3,
    output wire s3_col20_b0,
    output wire s3_col20_b1,
    output wire s3_col20_b2,
    output wire s3_col21_b0,
    output wire s3_col21_b1,
    output wire s3_col21_b2,
    output wire s3_col22_b0,
    output wire s3_col22_b1,
    output wire s3_col22_b2,
    output wire s3_col23_b0,
    output wire s3_col23_b1,
    output wire s3_col23_b2,
    output wire s3_col24_b0,
    output wire s3_col24_b1,
    output wire s3_col25_b0,
    output wire s3_col25_b1,
    output wire s3_col26_b0,
    output wire s3_col26_b1,
    output wire s3_col27_b0,
    output wire s3_col27_b1,
    output wire s3_col28_b0,
    output wire s3_col28_b1,
    output wire s3_col29_b0,
    output wire s3_col29_b1,
    output wire s3_col30_b0,
    output wire s3_col30_b1,
    output wire s3_col31_b0,
    output wire s3_col31_b1,
    output wire s3_col32_b0
);

    // =========================================================================
    // Internal wire declarations
    // =========================================================================
    wire w_l3_c3_ha1_s, w_l3_c3_ha1_c, w_l3_c4_ha1_s, w_l3_c4_ha1_c;
    wire w_l3_c5_fa1_s, w_l3_c5_fa1_c, w_l3_c6_fa1_s, w_l3_c6_fa1_c;
    wire w_l3_c7_fa1_s, w_l3_c7_fa1_c, w_l3_c8_fa1_s, w_l3_c8_fa1_c;
    wire w_l3_c9_fa1_s, w_l3_c9_fa1_c, w_l3_c9_ha1_s, w_l3_c9_ha1_c;
    wire w_l3_c10_fa1_s, w_l3_c10_fa1_c, w_l3_c10_ha1_s, w_l3_c10_ha1_c;
    wire w_l3_c11_fa1_s, w_l3_c11_fa1_c, w_l3_c11_ha1_s, w_l3_c11_ha1_c;
    wire w_l3_c12_fa1_s, w_l3_c12_fa1_c, w_l3_c12_fa2_s, w_l3_c12_fa2_c;
    wire w_l3_c13_fa1_s, w_l3_c13_fa1_c, w_l3_c13_fa2_s, w_l3_c13_fa2_c;
    wire w_l3_c14_fa1_s, w_l3_c14_fa1_c, w_l3_c14_fa2_s, w_l3_c14_fa2_c;
    wire w_l3_c15_fa1_s, w_l3_c15_fa1_c, w_l3_c15_fa2_s, w_l3_c15_fa2_c;
    wire w_l3_c16_fa1_s, w_l3_c16_fa1_c, w_l3_c16_fa2_s, w_l3_c16_fa2_c;
    wire w_l3_c16_ha1_s, w_l3_c16_ha1_c, w_l3_c17_fa1_s, w_l3_c17_fa1_c;
    wire w_l3_c17_fa2_s, w_l3_c17_fa2_c, w_l3_c18_fa1_s, w_l3_c18_fa1_c;
    wire w_l3_c18_fa2_s, w_l3_c18_fa2_c, w_l3_c19_fa1_s, w_l3_c19_fa1_c;
    wire w_l3_c19_fa2_s, w_l3_c19_fa2_c, w_l3_c20_fa1_s, w_l3_c20_fa1_c;
    wire w_l3_c20_fa2_s, w_l3_c20_fa2_c, w_l3_c21_fa1_s, w_l3_c21_fa1_c;
    wire w_l3_c21_fa2_s, w_l3_c21_fa2_c, w_l3_c22_fa1_s, w_l3_c22_fa1_c;
    wire w_l3_c22_ha1_s, w_l3_c22_ha1_c, w_l3_c23_fa1_s, w_l3_c23_fa1_c;
    wire w_l3_c24_fa1_s, w_l3_c24_fa1_c, w_l3_c25_fa1_s, w_l3_c25_fa1_c;
    wire w_l3_c26_fa1_s, w_l3_c26_fa1_c, w_l3_c27_fa1_s, w_l3_c27_fa1_c;
    wire w_l3_c28_ha1_s, w_l3_c28_ha1_c, w_l3_c29_ha1_s, w_l3_c29_ha1_c;
    wire w_l3_c30_ha1_s, w_l3_c30_ha1_c, w_l4_c4_ha1_s, w_l4_c4_ha1_c;
    wire w_l4_c5_ha1_s, w_l4_c5_ha1_c, w_l4_c6_ha1_s, w_l4_c6_ha1_c;
    wire w_l4_c7_fa1_s, w_l4_c7_fa1_c, w_l4_c8_fa1_s, w_l4_c8_fa1_c;
    wire w_l4_c9_fa1_s, w_l4_c9_fa1_c, w_l4_c10_fa1_s, w_l4_c10_fa1_c;
    wire w_l4_c11_fa1_s, w_l4_c11_fa1_c, w_l4_c12_fa1_s, w_l4_c12_fa1_c;
    wire w_l4_c13_fa1_s, w_l4_c13_fa1_c, w_l4_c14_fa1_s, w_l4_c14_fa1_c;
    wire w_l4_c14_ha1_s, w_l4_c14_ha1_c, w_l4_c15_fa1_s, w_l4_c15_fa1_c;
    wire w_l4_c15_ha1_s, w_l4_c15_ha1_c, w_l4_c16_fa1_s, w_l4_c16_fa1_c;
    wire w_l4_c16_ha1_s, w_l4_c16_ha1_c, w_l4_c17_fa1_s, w_l4_c17_fa1_c;
    wire w_l4_c17_fa2_s, w_l4_c17_fa2_c, w_l4_c18_fa1_s, w_l4_c18_fa1_c;
    wire w_l4_c18_ha1_s, w_l4_c18_ha1_c, w_l4_c19_fa1_s, w_l4_c19_fa1_c;
    wire w_l4_c20_fa1_s, w_l4_c20_fa1_c, w_l4_c21_fa1_s, w_l4_c21_fa1_c;
    wire w_l4_c22_fa1_s, w_l4_c22_fa1_c, w_l4_c23_fa1_s, w_l4_c23_fa1_c;
    wire w_l4_c24_fa1_s, w_l4_c24_fa1_c, w_l4_c25_fa1_s, w_l4_c25_fa1_c;
    wire w_l4_c26_ha1_s, w_l4_c26_ha1_c, w_l4_c27_ha1_s, w_l4_c27_ha1_c;
    wire w_l4_c28_ha1_s, w_l4_c28_ha1_c, w_l4_c29_ha1_s, w_l4_c29_ha1_c;
    wire w_l4_c30_ha1_s, w_l4_c30_ha1_c, w_l4_c31_ha1_s, w_l4_c31_ha1_c;


    // =========================================================================
    // LEVEL 3 REDUCTION
    // Input : Stage 2 outputs (up to 8 bits in the widest column)
    // Output: reduced bits (up to 6 bits in the widest column)
    // =========================================================================

    // ---- Column 0: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 0: 1 bit (s2_col0_b0) passes through unchanged (no compressor needed)

    // ---- Column 1: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 1: 1 bit (s2_col1_b0) passes through unchanged (no compressor needed)

    // ---- Column 2: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 2: 1 bit (s2_col2_b0) passes through unchanged (no compressor needed)

    // ---- Column 3: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l3_c3_1 (.a(s2_col3_b0), .b(s2_col3_b1), .sum(w_l3_c3_ha1_s), .cout(w_l3_c3_ha1_c)); // col 3: HA#1 reduces remaining 2 bits -> 1 sum (stays col 3) + 1 carry (-> col 4)

    // ---- Column 4: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l3_c4_1 (.a(s2_col4_b0), .b(s2_col4_b1), .sum(w_l3_c4_ha1_s), .cout(w_l3_c4_ha1_c)); // col 4: HA#1 reduces remaining 2 bits -> 1 sum (stays col 4) + 1 carry (-> col 5)

    // ---- Column 5: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c5_1 (.a(s2_col5_b0), .b(s2_col5_b1), .cin(s2_col5_b2), .sum(w_l3_c5_fa1_s), .cout(w_l3_c5_fa1_c)); // col 5: FA#1 reduces 3 bits -> 1 sum (stays col 5) + 1 carry (-> col 6)

    // ---- Column 6: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c6_1 (.a(s2_col6_b0), .b(s2_col6_b1), .cin(s2_col6_b2), .sum(w_l3_c6_fa1_s), .cout(w_l3_c6_fa1_c)); // col 6: FA#1 reduces 3 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)

    // ---- Column 7: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c7_1 (.a(s2_col7_b0), .b(s2_col7_b1), .cin(s2_col7_b2), .sum(w_l3_c7_fa1_s), .cout(w_l3_c7_fa1_c)); // col 7: FA#1 reduces 3 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)
    // col 7: 1 bit (s2_col7_b3) passes through unchanged (no compressor needed)

    // ---- Column 8: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c8_1 (.a(s2_col8_b0), .b(s2_col8_b1), .cin(s2_col8_b2), .sum(w_l3_c8_fa1_s), .cout(w_l3_c8_fa1_c)); // col 8: FA#1 reduces 3 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)
    // col 8: 1 bit (s2_col8_b3) passes through unchanged (no compressor needed)

    // ---- Column 9: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l3_c9_1 (.a(s2_col9_b0), .b(s2_col9_b1), .cin(s2_col9_b2), .sum(w_l3_c9_fa1_s), .cout(w_l3_c9_fa1_c)); // col 9: FA#1 reduces 3 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)
    half_adder HA_l3_c9_1 (.a(s2_col9_b3), .b(s2_col9_b4), .sum(w_l3_c9_ha1_s), .cout(w_l3_c9_ha1_c)); // col 9: HA#1 reduces remaining 2 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)

    // ---- Column 10: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l3_c10_1 (.a(s2_col10_b0), .b(s2_col10_b1), .cin(s2_col10_b2), .sum(w_l3_c10_fa1_s), .cout(w_l3_c10_fa1_c)); // col 10: FA#1 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)
    half_adder HA_l3_c10_1 (.a(s2_col10_b3), .b(s2_col10_b4), .sum(w_l3_c10_ha1_s), .cout(w_l3_c10_ha1_c)); // col 10: HA#1 reduces remaining 2 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)

    // ---- Column 11: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l3_c11_1 (.a(s2_col11_b0), .b(s2_col11_b1), .cin(s2_col11_b2), .sum(w_l3_c11_fa1_s), .cout(w_l3_c11_fa1_c)); // col 11: FA#1 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)
    half_adder HA_l3_c11_1 (.a(s2_col11_b3), .b(s2_col11_b4), .sum(w_l3_c11_ha1_s), .cout(w_l3_c11_ha1_c)); // col 11: HA#1 reduces remaining 2 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)

    // ---- Column 12: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c12_1 (.a(s2_col12_b0), .b(s2_col12_b1), .cin(s2_col12_b2), .sum(w_l3_c12_fa1_s), .cout(w_l3_c12_fa1_c)); // col 12: FA#1 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    full_adder FA_l3_c12_2 (.a(s2_col12_b3), .b(s2_col12_b4), .cin(s2_col12_b5), .sum(w_l3_c12_fa2_s), .cout(w_l3_c12_fa2_c)); // col 12: FA#2 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)

    // ---- Column 13: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c13_1 (.a(s2_col13_b0), .b(s2_col13_b1), .cin(s2_col13_b2), .sum(w_l3_c13_fa1_s), .cout(w_l3_c13_fa1_c)); // col 13: FA#1 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    full_adder FA_l3_c13_2 (.a(s2_col13_b3), .b(s2_col13_b4), .cin(s2_col13_b5), .sum(w_l3_c13_fa2_s), .cout(w_l3_c13_fa2_c)); // col 13: FA#2 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)

    // ---- Column 14: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c14_1 (.a(s2_col14_b0), .b(s2_col14_b1), .cin(s2_col14_b2), .sum(w_l3_c14_fa1_s), .cout(w_l3_c14_fa1_c)); // col 14: FA#1 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    full_adder FA_l3_c14_2 (.a(s2_col14_b3), .b(s2_col14_b4), .cin(s2_col14_b5), .sum(w_l3_c14_fa2_s), .cout(w_l3_c14_fa2_c)); // col 14: FA#2 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    // col 14: 1 bit (s2_col14_b6) passes through unchanged (no compressor needed)

    // ---- Column 15: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c15_1 (.a(s2_col15_b0), .b(s2_col15_b1), .cin(s2_col15_b2), .sum(w_l3_c15_fa1_s), .cout(w_l3_c15_fa1_c)); // col 15: FA#1 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    full_adder FA_l3_c15_2 (.a(s2_col15_b3), .b(s2_col15_b4), .cin(s2_col15_b5), .sum(w_l3_c15_fa2_s), .cout(w_l3_c15_fa2_c)); // col 15: FA#2 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    // col 15: 1 bit (s2_col15_b6) passes through unchanged (no compressor needed)

    // ---- Column 16: 8 input bit(s) -> 2 FA, 1 HA, 0 passthrough ----
    full_adder FA_l3_c16_1 (.a(s2_col16_b0), .b(s2_col16_b1), .cin(s2_col16_b2), .sum(w_l3_c16_fa1_s), .cout(w_l3_c16_fa1_c)); // col 16: FA#1 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    full_adder FA_l3_c16_2 (.a(s2_col16_b3), .b(s2_col16_b4), .cin(s2_col16_b5), .sum(w_l3_c16_fa2_s), .cout(w_l3_c16_fa2_c)); // col 16: FA#2 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    half_adder HA_l3_c16_1 (.a(s2_col16_b6), .b(s2_col16_b7), .sum(w_l3_c16_ha1_s), .cout(w_l3_c16_ha1_c)); // col 16: HA#1 reduces remaining 2 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)

    // ---- Column 17: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c17_1 (.a(s2_col17_b0), .b(s2_col17_b1), .cin(s2_col17_b2), .sum(w_l3_c17_fa1_s), .cout(w_l3_c17_fa1_c)); // col 17: FA#1 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    full_adder FA_l3_c17_2 (.a(s2_col17_b3), .b(s2_col17_b4), .cin(s2_col17_b5), .sum(w_l3_c17_fa2_s), .cout(w_l3_c17_fa2_c)); // col 17: FA#2 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    // col 17: 1 bit (s2_col17_b6) passes through unchanged (no compressor needed)

    // ---- Column 18: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c18_1 (.a(s2_col18_b0), .b(s2_col18_b1), .cin(s2_col18_b2), .sum(w_l3_c18_fa1_s), .cout(w_l3_c18_fa1_c)); // col 18: FA#1 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    full_adder FA_l3_c18_2 (.a(s2_col18_b3), .b(s2_col18_b4), .cin(s2_col18_b5), .sum(w_l3_c18_fa2_s), .cout(w_l3_c18_fa2_c)); // col 18: FA#2 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    // col 18: 1 bit (s2_col18_b6) passes through unchanged (no compressor needed)

    // ---- Column 19: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c19_1 (.a(s2_col19_b0), .b(s2_col19_b1), .cin(s2_col19_b2), .sum(w_l3_c19_fa1_s), .cout(w_l3_c19_fa1_c)); // col 19: FA#1 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    full_adder FA_l3_c19_2 (.a(s2_col19_b3), .b(s2_col19_b4), .cin(s2_col19_b5), .sum(w_l3_c19_fa2_s), .cout(w_l3_c19_fa2_c)); // col 19: FA#2 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)

    // ---- Column 20: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c20_1 (.a(s2_col20_b0), .b(s2_col20_b1), .cin(s2_col20_b2), .sum(w_l3_c20_fa1_s), .cout(w_l3_c20_fa1_c)); // col 20: FA#1 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)
    full_adder FA_l3_c20_2 (.a(s2_col20_b3), .b(s2_col20_b4), .cin(s2_col20_b5), .sum(w_l3_c20_fa2_s), .cout(w_l3_c20_fa2_c)); // col 20: FA#2 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)

    // ---- Column 21: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c21_1 (.a(s2_col21_b0), .b(s2_col21_b1), .cin(s2_col21_b2), .sum(w_l3_c21_fa1_s), .cout(w_l3_c21_fa1_c)); // col 21: FA#1 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)
    full_adder FA_l3_c21_2 (.a(s2_col21_b3), .b(s2_col21_b4), .cin(s2_col21_b5), .sum(w_l3_c21_fa2_s), .cout(w_l3_c21_fa2_c)); // col 21: FA#2 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)

    // ---- Column 22: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l3_c22_1 (.a(s2_col22_b0), .b(s2_col22_b1), .cin(s2_col22_b2), .sum(w_l3_c22_fa1_s), .cout(w_l3_c22_fa1_c)); // col 22: FA#1 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)
    half_adder HA_l3_c22_1 (.a(s2_col22_b3), .b(s2_col22_b4), .sum(w_l3_c22_ha1_s), .cout(w_l3_c22_ha1_c)); // col 22: HA#1 reduces remaining 2 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)

    // ---- Column 23: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c23_1 (.a(s2_col23_b0), .b(s2_col23_b1), .cin(s2_col23_b2), .sum(w_l3_c23_fa1_s), .cout(w_l3_c23_fa1_c)); // col 23: FA#1 reduces 3 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)
    // col 23: 1 bit (s2_col23_b3) passes through unchanged (no compressor needed)

    // ---- Column 24: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c24_1 (.a(s2_col24_b0), .b(s2_col24_b1), .cin(s2_col24_b2), .sum(w_l3_c24_fa1_s), .cout(w_l3_c24_fa1_c)); // col 24: FA#1 reduces 3 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)
    // col 24: 1 bit (s2_col24_b3) passes through unchanged (no compressor needed)

    // ---- Column 25: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l3_c25_1 (.a(s2_col25_b0), .b(s2_col25_b1), .cin(s2_col25_b2), .sum(w_l3_c25_fa1_s), .cout(w_l3_c25_fa1_c)); // col 25: FA#1 reduces 3 bits -> 1 sum (stays col 25) + 1 carry (-> col 26)
    // col 25: 1 bit (s2_col25_b3) passes through unchanged (no compressor needed)

    // ---- Column 26: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c26_1 (.a(s2_col26_b0), .b(s2_col26_b1), .cin(s2_col26_b2), .sum(w_l3_c26_fa1_s), .cout(w_l3_c26_fa1_c)); // col 26: FA#1 reduces 3 bits -> 1 sum (stays col 26) + 1 carry (-> col 27)

    // ---- Column 27: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l3_c27_1 (.a(s2_col27_b0), .b(s2_col27_b1), .cin(s2_col27_b2), .sum(w_l3_c27_fa1_s), .cout(w_l3_c27_fa1_c)); // col 27: FA#1 reduces 3 bits -> 1 sum (stays col 27) + 1 carry (-> col 28)

    // ---- Column 28: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l3_c28_1 (.a(s2_col28_b0), .b(s2_col28_b1), .sum(w_l3_c28_ha1_s), .cout(w_l3_c28_ha1_c)); // col 28: HA#1 reduces remaining 2 bits -> 1 sum (stays col 28) + 1 carry (-> col 29)

    // ---- Column 29: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l3_c29_1 (.a(s2_col29_b0), .b(s2_col29_b1), .sum(w_l3_c29_ha1_s), .cout(w_l3_c29_ha1_c)); // col 29: HA#1 reduces remaining 2 bits -> 1 sum (stays col 29) + 1 carry (-> col 30)

    // ---- Column 30: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l3_c30_1 (.a(s2_col30_b0), .b(s2_col30_b1), .sum(w_l3_c30_ha1_s), .cout(w_l3_c30_ha1_c)); // col 30: HA#1 reduces remaining 2 bits -> 1 sum (stays col 30) + 1 carry (-> col 31)

    // ---- Column 31: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 31: 1 bit (s2_col31_b0) passes through unchanged (no compressor needed)


    // =========================================================================
    // LEVEL 4 REDUCTION
    // Input : Level 3 outputs (up to 6 bits in the widest column)
    // Output: reduced bits (up to 4 bits in the widest column)
    // =========================================================================

    // ---- Column 0: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 0: 1 bit (s2_col0_b0) passes through unchanged (no compressor needed)

    // ---- Column 1: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 1: 1 bit (s2_col1_b0) passes through unchanged (no compressor needed)

    // ---- Column 2: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 2: 1 bit (s2_col2_b0) passes through unchanged (no compressor needed)

    // ---- Column 3: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 3: 1 bit (w_l3_c3_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 4: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c4_1 (.a(w_l3_c3_ha1_c), .b(w_l3_c4_ha1_s), .sum(w_l4_c4_ha1_s), .cout(w_l4_c4_ha1_c)); // col 4: HA#1 reduces remaining 2 bits -> 1 sum (stays col 4) + 1 carry (-> col 5)

    // ---- Column 5: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c5_1 (.a(w_l3_c4_ha1_c), .b(w_l3_c5_fa1_s), .sum(w_l4_c5_ha1_s), .cout(w_l4_c5_ha1_c)); // col 5: HA#1 reduces remaining 2 bits -> 1 sum (stays col 5) + 1 carry (-> col 6)

    // ---- Column 6: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c6_1 (.a(w_l3_c5_fa1_c), .b(w_l3_c6_fa1_s), .sum(w_l4_c6_ha1_s), .cout(w_l4_c6_ha1_c)); // col 6: HA#1 reduces remaining 2 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)

    // ---- Column 7: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l4_c7_1 (.a(w_l3_c6_fa1_c), .b(w_l3_c7_fa1_s), .cin(s2_col7_b3), .sum(w_l4_c7_fa1_s), .cout(w_l4_c7_fa1_c)); // col 7: FA#1 reduces 3 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)

    // ---- Column 8: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l4_c8_1 (.a(w_l3_c7_fa1_c), .b(w_l3_c8_fa1_s), .cin(s2_col8_b3), .sum(w_l4_c8_fa1_s), .cout(w_l4_c8_fa1_c)); // col 8: FA#1 reduces 3 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)

    // ---- Column 9: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l4_c9_1 (.a(w_l3_c8_fa1_c), .b(w_l3_c9_fa1_s), .cin(w_l3_c9_ha1_s), .sum(w_l4_c9_fa1_s), .cout(w_l4_c9_fa1_c)); // col 9: FA#1 reduces 3 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)

    // ---- Column 10: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c10_1 (.a(w_l3_c9_fa1_c), .b(w_l3_c9_ha1_c), .cin(w_l3_c10_fa1_s), .sum(w_l4_c10_fa1_s), .cout(w_l4_c10_fa1_c)); // col 10: FA#1 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)
    // col 10: 1 bit (w_l3_c10_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 11: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c11_1 (.a(w_l3_c10_fa1_c), .b(w_l3_c10_ha1_c), .cin(w_l3_c11_fa1_s), .sum(w_l4_c11_fa1_s), .cout(w_l4_c11_fa1_c)); // col 11: FA#1 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)
    // col 11: 1 bit (w_l3_c11_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 12: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c12_1 (.a(w_l3_c11_fa1_c), .b(w_l3_c11_ha1_c), .cin(w_l3_c12_fa1_s), .sum(w_l4_c12_fa1_s), .cout(w_l4_c12_fa1_c)); // col 12: FA#1 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    // col 12: 1 bit (w_l3_c12_fa2_s) passes through unchanged (no compressor needed)

    // ---- Column 13: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c13_1 (.a(w_l3_c12_fa1_c), .b(w_l3_c12_fa2_c), .cin(w_l3_c13_fa1_s), .sum(w_l4_c13_fa1_s), .cout(w_l4_c13_fa1_c)); // col 13: FA#1 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    // col 13: 1 bit (w_l3_c13_fa2_s) passes through unchanged (no compressor needed)

    // ---- Column 14: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l4_c14_1 (.a(w_l3_c13_fa1_c), .b(w_l3_c13_fa2_c), .cin(w_l3_c14_fa1_s), .sum(w_l4_c14_fa1_s), .cout(w_l4_c14_fa1_c)); // col 14: FA#1 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    half_adder HA_l4_c14_1 (.a(w_l3_c14_fa2_s), .b(s2_col14_b6), .sum(w_l4_c14_ha1_s), .cout(w_l4_c14_ha1_c)); // col 14: HA#1 reduces remaining 2 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)

    // ---- Column 15: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l4_c15_1 (.a(w_l3_c14_fa1_c), .b(w_l3_c14_fa2_c), .cin(w_l3_c15_fa1_s), .sum(w_l4_c15_fa1_s), .cout(w_l4_c15_fa1_c)); // col 15: FA#1 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    half_adder HA_l4_c15_1 (.a(w_l3_c15_fa2_s), .b(s2_col15_b6), .sum(w_l4_c15_ha1_s), .cout(w_l4_c15_ha1_c)); // col 15: HA#1 reduces remaining 2 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)

    // ---- Column 16: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l4_c16_1 (.a(w_l3_c15_fa1_c), .b(w_l3_c15_fa2_c), .cin(w_l3_c16_fa1_s), .sum(w_l4_c16_fa1_s), .cout(w_l4_c16_fa1_c)); // col 16: FA#1 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    half_adder HA_l4_c16_1 (.a(w_l3_c16_fa2_s), .b(w_l3_c16_ha1_s), .sum(w_l4_c16_ha1_s), .cout(w_l4_c16_ha1_c)); // col 16: HA#1 reduces remaining 2 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)

    // ---- Column 17: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l4_c17_1 (.a(w_l3_c16_fa1_c), .b(w_l3_c16_fa2_c), .cin(w_l3_c16_ha1_c), .sum(w_l4_c17_fa1_s), .cout(w_l4_c17_fa1_c)); // col 17: FA#1 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    full_adder FA_l4_c17_2 (.a(w_l3_c17_fa1_s), .b(w_l3_c17_fa2_s), .cin(s2_col17_b6), .sum(w_l4_c17_fa2_s), .cout(w_l4_c17_fa2_c)); // col 17: FA#2 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)

    // ---- Column 18: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l4_c18_1 (.a(w_l3_c17_fa1_c), .b(w_l3_c17_fa2_c), .cin(w_l3_c18_fa1_s), .sum(w_l4_c18_fa1_s), .cout(w_l4_c18_fa1_c)); // col 18: FA#1 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    half_adder HA_l4_c18_1 (.a(w_l3_c18_fa2_s), .b(s2_col18_b6), .sum(w_l4_c18_ha1_s), .cout(w_l4_c18_ha1_c)); // col 18: HA#1 reduces remaining 2 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)

    // ---- Column 19: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c19_1 (.a(w_l3_c18_fa1_c), .b(w_l3_c18_fa2_c), .cin(w_l3_c19_fa1_s), .sum(w_l4_c19_fa1_s), .cout(w_l4_c19_fa1_c)); // col 19: FA#1 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    // col 19: 1 bit (w_l3_c19_fa2_s) passes through unchanged (no compressor needed)

    // ---- Column 20: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c20_1 (.a(w_l3_c19_fa1_c), .b(w_l3_c19_fa2_c), .cin(w_l3_c20_fa1_s), .sum(w_l4_c20_fa1_s), .cout(w_l4_c20_fa1_c)); // col 20: FA#1 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)
    // col 20: 1 bit (w_l3_c20_fa2_s) passes through unchanged (no compressor needed)

    // ---- Column 21: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c21_1 (.a(w_l3_c20_fa1_c), .b(w_l3_c20_fa2_c), .cin(w_l3_c21_fa1_s), .sum(w_l4_c21_fa1_s), .cout(w_l4_c21_fa1_c)); // col 21: FA#1 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)
    // col 21: 1 bit (w_l3_c21_fa2_s) passes through unchanged (no compressor needed)

    // ---- Column 22: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c22_1 (.a(w_l3_c21_fa1_c), .b(w_l3_c21_fa2_c), .cin(w_l3_c22_fa1_s), .sum(w_l4_c22_fa1_s), .cout(w_l4_c22_fa1_c)); // col 22: FA#1 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)
    // col 22: 1 bit (w_l3_c22_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 23: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l4_c23_1 (.a(w_l3_c22_fa1_c), .b(w_l3_c22_ha1_c), .cin(w_l3_c23_fa1_s), .sum(w_l4_c23_fa1_s), .cout(w_l4_c23_fa1_c)); // col 23: FA#1 reduces 3 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)
    // col 23: 1 bit (s2_col23_b3) passes through unchanged (no compressor needed)

    // ---- Column 24: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l4_c24_1 (.a(w_l3_c23_fa1_c), .b(w_l3_c24_fa1_s), .cin(s2_col24_b3), .sum(w_l4_c24_fa1_s), .cout(w_l4_c24_fa1_c)); // col 24: FA#1 reduces 3 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)

    // ---- Column 25: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l4_c25_1 (.a(w_l3_c24_fa1_c), .b(w_l3_c25_fa1_s), .cin(s2_col25_b3), .sum(w_l4_c25_fa1_s), .cout(w_l4_c25_fa1_c)); // col 25: FA#1 reduces 3 bits -> 1 sum (stays col 25) + 1 carry (-> col 26)

    // ---- Column 26: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c26_1 (.a(w_l3_c25_fa1_c), .b(w_l3_c26_fa1_s), .sum(w_l4_c26_ha1_s), .cout(w_l4_c26_ha1_c)); // col 26: HA#1 reduces remaining 2 bits -> 1 sum (stays col 26) + 1 carry (-> col 27)

    // ---- Column 27: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c27_1 (.a(w_l3_c26_fa1_c), .b(w_l3_c27_fa1_s), .sum(w_l4_c27_ha1_s), .cout(w_l4_c27_ha1_c)); // col 27: HA#1 reduces remaining 2 bits -> 1 sum (stays col 27) + 1 carry (-> col 28)

    // ---- Column 28: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c28_1 (.a(w_l3_c27_fa1_c), .b(w_l3_c28_ha1_s), .sum(w_l4_c28_ha1_s), .cout(w_l4_c28_ha1_c)); // col 28: HA#1 reduces remaining 2 bits -> 1 sum (stays col 28) + 1 carry (-> col 29)

    // ---- Column 29: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c29_1 (.a(w_l3_c28_ha1_c), .b(w_l3_c29_ha1_s), .sum(w_l4_c29_ha1_s), .cout(w_l4_c29_ha1_c)); // col 29: HA#1 reduces remaining 2 bits -> 1 sum (stays col 29) + 1 carry (-> col 30)

    // ---- Column 30: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c30_1 (.a(w_l3_c29_ha1_c), .b(w_l3_c30_ha1_s), .sum(w_l4_c30_ha1_s), .cout(w_l4_c30_ha1_c)); // col 30: HA#1 reduces remaining 2 bits -> 1 sum (stays col 30) + 1 carry (-> col 31)

    // ---- Column 31: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l4_c31_1 (.a(w_l3_c30_ha1_c), .b(s2_col31_b0), .sum(w_l4_c31_ha1_s), .cout(w_l4_c31_ha1_c)); // col 31: HA#1 reduces remaining 2 bits -> 1 sum (stays col 31) + 1 carry (-> col 32)


    // =========================================================================
    // Output assignment: map final Level-4 internal signals to named output
    // ports, organized by column. This is the exact handoff to Stage 4
    // (wallace_stage3), which continues reduction with Levels 5 & 6 -- the
    // final two reduction levels before the Carry Lookahead Adder.
    // =========================================================================
    assign s3_col0_b0 = s2_col0_b0;  // column 0, bit 0 of 1
    assign s3_col1_b0 = s2_col1_b0;  // column 1, bit 0 of 1
    assign s3_col2_b0 = s2_col2_b0;  // column 2, bit 0 of 1
    assign s3_col3_b0 = w_l3_c3_ha1_s;  // column 3, bit 0 of 1
    assign s3_col4_b0 = w_l4_c4_ha1_s;  // column 4, bit 0 of 1
    assign s3_col5_b0 = w_l4_c4_ha1_c;  // column 5, bit 0 of 2
    assign s3_col5_b1 = w_l4_c5_ha1_s;  // column 5, bit 1 of 2
    assign s3_col6_b0 = w_l4_c5_ha1_c;  // column 6, bit 0 of 2
    assign s3_col6_b1 = w_l4_c6_ha1_s;  // column 6, bit 1 of 2
    assign s3_col7_b0 = w_l4_c6_ha1_c;  // column 7, bit 0 of 2
    assign s3_col7_b1 = w_l4_c7_fa1_s;  // column 7, bit 1 of 2
    assign s3_col8_b0 = w_l4_c7_fa1_c;  // column 8, bit 0 of 2
    assign s3_col8_b1 = w_l4_c8_fa1_s;  // column 8, bit 1 of 2
    assign s3_col9_b0 = w_l4_c8_fa1_c;  // column 9, bit 0 of 2
    assign s3_col9_b1 = w_l4_c9_fa1_s;  // column 9, bit 1 of 2
    assign s3_col10_b0 = w_l4_c9_fa1_c;  // column 10, bit 0 of 3
    assign s3_col10_b1 = w_l4_c10_fa1_s;  // column 10, bit 1 of 3
    assign s3_col10_b2 = w_l3_c10_ha1_s;  // column 10, bit 2 of 3
    assign s3_col11_b0 = w_l4_c10_fa1_c;  // column 11, bit 0 of 3
    assign s3_col11_b1 = w_l4_c11_fa1_s;  // column 11, bit 1 of 3
    assign s3_col11_b2 = w_l3_c11_ha1_s;  // column 11, bit 2 of 3
    assign s3_col12_b0 = w_l4_c11_fa1_c;  // column 12, bit 0 of 3
    assign s3_col12_b1 = w_l4_c12_fa1_s;  // column 12, bit 1 of 3
    assign s3_col12_b2 = w_l3_c12_fa2_s;  // column 12, bit 2 of 3
    assign s3_col13_b0 = w_l4_c12_fa1_c;  // column 13, bit 0 of 3
    assign s3_col13_b1 = w_l4_c13_fa1_s;  // column 13, bit 1 of 3
    assign s3_col13_b2 = w_l3_c13_fa2_s;  // column 13, bit 2 of 3
    assign s3_col14_b0 = w_l4_c13_fa1_c;  // column 14, bit 0 of 3
    assign s3_col14_b1 = w_l4_c14_fa1_s;  // column 14, bit 1 of 3
    assign s3_col14_b2 = w_l4_c14_ha1_s;  // column 14, bit 2 of 3
    assign s3_col15_b0 = w_l4_c14_fa1_c;  // column 15, bit 0 of 4
    assign s3_col15_b1 = w_l4_c14_ha1_c;  // column 15, bit 1 of 4
    assign s3_col15_b2 = w_l4_c15_fa1_s;  // column 15, bit 2 of 4
    assign s3_col15_b3 = w_l4_c15_ha1_s;  // column 15, bit 3 of 4
    assign s3_col16_b0 = w_l4_c15_fa1_c;  // column 16, bit 0 of 4
    assign s3_col16_b1 = w_l4_c15_ha1_c;  // column 16, bit 1 of 4
    assign s3_col16_b2 = w_l4_c16_fa1_s;  // column 16, bit 2 of 4
    assign s3_col16_b3 = w_l4_c16_ha1_s;  // column 16, bit 3 of 4
    assign s3_col17_b0 = w_l4_c16_fa1_c;  // column 17, bit 0 of 4
    assign s3_col17_b1 = w_l4_c16_ha1_c;  // column 17, bit 1 of 4
    assign s3_col17_b2 = w_l4_c17_fa1_s;  // column 17, bit 2 of 4
    assign s3_col17_b3 = w_l4_c17_fa2_s;  // column 17, bit 3 of 4
    assign s3_col18_b0 = w_l4_c17_fa1_c;  // column 18, bit 0 of 4
    assign s3_col18_b1 = w_l4_c17_fa2_c;  // column 18, bit 1 of 4
    assign s3_col18_b2 = w_l4_c18_fa1_s;  // column 18, bit 2 of 4
    assign s3_col18_b3 = w_l4_c18_ha1_s;  // column 18, bit 3 of 4
    assign s3_col19_b0 = w_l4_c18_fa1_c;  // column 19, bit 0 of 4
    assign s3_col19_b1 = w_l4_c18_ha1_c;  // column 19, bit 1 of 4
    assign s3_col19_b2 = w_l4_c19_fa1_s;  // column 19, bit 2 of 4
    assign s3_col19_b3 = w_l3_c19_fa2_s;  // column 19, bit 3 of 4
    assign s3_col20_b0 = w_l4_c19_fa1_c;  // column 20, bit 0 of 3
    assign s3_col20_b1 = w_l4_c20_fa1_s;  // column 20, bit 1 of 3
    assign s3_col20_b2 = w_l3_c20_fa2_s;  // column 20, bit 2 of 3
    assign s3_col21_b0 = w_l4_c20_fa1_c;  // column 21, bit 0 of 3
    assign s3_col21_b1 = w_l4_c21_fa1_s;  // column 21, bit 1 of 3
    assign s3_col21_b2 = w_l3_c21_fa2_s;  // column 21, bit 2 of 3
    assign s3_col22_b0 = w_l4_c21_fa1_c;  // column 22, bit 0 of 3
    assign s3_col22_b1 = w_l4_c22_fa1_s;  // column 22, bit 1 of 3
    assign s3_col22_b2 = w_l3_c22_ha1_s;  // column 22, bit 2 of 3
    assign s3_col23_b0 = w_l4_c22_fa1_c;  // column 23, bit 0 of 3
    assign s3_col23_b1 = w_l4_c23_fa1_s;  // column 23, bit 1 of 3
    assign s3_col23_b2 = s2_col23_b3;  // column 23, bit 2 of 3
    assign s3_col24_b0 = w_l4_c23_fa1_c;  // column 24, bit 0 of 2
    assign s3_col24_b1 = w_l4_c24_fa1_s;  // column 24, bit 1 of 2
    assign s3_col25_b0 = w_l4_c24_fa1_c;  // column 25, bit 0 of 2
    assign s3_col25_b1 = w_l4_c25_fa1_s;  // column 25, bit 1 of 2
    assign s3_col26_b0 = w_l4_c25_fa1_c;  // column 26, bit 0 of 2
    assign s3_col26_b1 = w_l4_c26_ha1_s;  // column 26, bit 1 of 2
    assign s3_col27_b0 = w_l4_c26_ha1_c;  // column 27, bit 0 of 2
    assign s3_col27_b1 = w_l4_c27_ha1_s;  // column 27, bit 1 of 2
    assign s3_col28_b0 = w_l4_c27_ha1_c;  // column 28, bit 0 of 2
    assign s3_col28_b1 = w_l4_c28_ha1_s;  // column 28, bit 1 of 2
    assign s3_col29_b0 = w_l4_c28_ha1_c;  // column 29, bit 0 of 2
    assign s3_col29_b1 = w_l4_c29_ha1_s;  // column 29, bit 1 of 2
    assign s3_col30_b0 = w_l4_c29_ha1_c;  // column 30, bit 0 of 2
    assign s3_col30_b1 = w_l4_c30_ha1_s;  // column 30, bit 1 of 2
    assign s3_col31_b0 = w_l4_c30_ha1_c;  // column 31, bit 0 of 2
    assign s3_col31_b1 = w_l4_c31_ha1_s;  // column 31, bit 1 of 2
    assign s3_col32_b0 = w_l4_c31_ha1_c;  // column 32, bit 0 of 1

endmodule
