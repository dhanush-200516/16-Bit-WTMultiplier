// =============================================================================
// Module      : wallace_stage3
// Pipeline    : STAGE 4  (final reduction stage of the Wallace Tree)
// Description : Takes the 79 partially-reduced bits produced by Stage 3
//               (wallace_stage2, after Levels 3 & 4) and performs the LAST
//               TWO levels of Wallace Tree reduction (Level 5 and Level 6).
//               After this stage, every column holds AT MOST 2 bits -- this
//               is the defining condition that makes the design ready for a
//               normal two-operand final adder (the CLA in Stage 5).
//
//               PROGRESS THROUGH THE FULL TREE (see Wallace Tree Blueprint):
//                 Before any reduction : up to 16 bits in the widest column
//                 After Stage 2 (L1+L2): up to  8 bits in the widest column
//                 After Stage 3 (L3+L4): up to  4 bits in the widest column
//                 After Stage 4 (L5+L6): up to  2 bits in the widest column  <-- DONE
//
//               IMPORTANT NOTE ON OUTPUT WIDTH:
//               Because partial-product columns extend up to column 30, and
//               carries ripple one column further at each reduction level,
//               this stage's outputs span columns 0 through 33 (34 columns),
//               not just 0 through 31. However, it is mathematically
//               guaranteed that for any valid 16-bit x 16-bit unsigned
//               multiplication, the true result never exceeds 32 bits
//               (max product 65535 x 65535 = 4,294,836,225, which needs
//               exactly 32 bits). This means columns 32 and 33 will always
//               evaluate to logic 0 in practice -- they exist in the
//               intermediate reduction structure but carry no real
//               information for valid inputs. They are still wired
//               correctly here (never silently dropped), and the testbench
//               includes a check confirming they stay at 0.
//
//               HOW TO READ THIS FILE:
//               Identical column-by-column structure to wallace_stage1.v
//               and wallace_stage2.v. Level 5 first, then Level 6.
//
//               OUTPUT NAMING: s4_col{c}_b{n} = Stage 4 output, column c, bit n
//               After this stage, each column has at most 2 bits: bit 0 of
//               a column becomes part of "Row A", bit 1 (if present)
//               becomes part of "Row B" -- the two operands for the final
//               Carry Lookahead Adder in Stage 5.
// =============================================================================

module wallace_stage3 (
    // ---- Inputs: further-reduced columns from Stage 3 (wallace_stage2) ----
    input  wire s3_col0_b0,
    input  wire s3_col1_b0,
    input  wire s3_col2_b0,
    input  wire s3_col3_b0,
    input  wire s3_col4_b0,
    input  wire s3_col5_b0,
    input  wire s3_col5_b1,
    input  wire s3_col6_b0,
    input  wire s3_col6_b1,
    input  wire s3_col7_b0,
    input  wire s3_col7_b1,
    input  wire s3_col8_b0,
    input  wire s3_col8_b1,
    input  wire s3_col9_b0,
    input  wire s3_col9_b1,
    input  wire s3_col10_b0,
    input  wire s3_col10_b1,
    input  wire s3_col10_b2,
    input  wire s3_col11_b0,
    input  wire s3_col11_b1,
    input  wire s3_col11_b2,
    input  wire s3_col12_b0,
    input  wire s3_col12_b1,
    input  wire s3_col12_b2,
    input  wire s3_col13_b0,
    input  wire s3_col13_b1,
    input  wire s3_col13_b2,
    input  wire s3_col14_b0,
    input  wire s3_col14_b1,
    input  wire s3_col14_b2,
    input  wire s3_col15_b0,
    input  wire s3_col15_b1,
    input  wire s3_col15_b2,
    input  wire s3_col15_b3,
    input  wire s3_col16_b0,
    input  wire s3_col16_b1,
    input  wire s3_col16_b2,
    input  wire s3_col16_b3,
    input  wire s3_col17_b0,
    input  wire s3_col17_b1,
    input  wire s3_col17_b2,
    input  wire s3_col17_b3,
    input  wire s3_col18_b0,
    input  wire s3_col18_b1,
    input  wire s3_col18_b2,
    input  wire s3_col18_b3,
    input  wire s3_col19_b0,
    input  wire s3_col19_b1,
    input  wire s3_col19_b2,
    input  wire s3_col19_b3,
    input  wire s3_col20_b0,
    input  wire s3_col20_b1,
    input  wire s3_col20_b2,
    input  wire s3_col21_b0,
    input  wire s3_col21_b1,
    input  wire s3_col21_b2,
    input  wire s3_col22_b0,
    input  wire s3_col22_b1,
    input  wire s3_col22_b2,
    input  wire s3_col23_b0,
    input  wire s3_col23_b1,
    input  wire s3_col23_b2,
    input  wire s3_col24_b0,
    input  wire s3_col24_b1,
    input  wire s3_col25_b0,
    input  wire s3_col25_b1,
    input  wire s3_col26_b0,
    input  wire s3_col26_b1,
    input  wire s3_col27_b0,
    input  wire s3_col27_b1,
    input  wire s3_col28_b0,
    input  wire s3_col28_b1,
    input  wire s3_col29_b0,
    input  wire s3_col29_b1,
    input  wire s3_col30_b0,
    input  wire s3_col30_b1,
    input  wire s3_col31_b0,
    input  wire s3_col31_b1,
    input  wire s3_col32_b0,

    // ---- Outputs: fully-reduced columns (<=2 bits each), after Levels 5 & 6 ----
    // (see s4_col{c}_b{n} naming convention explained above)
    output wire s4_col0_b0,
    output wire s4_col1_b0,
    output wire s4_col2_b0,
    output wire s4_col3_b0,
    output wire s4_col4_b0,
    output wire s4_col5_b0,
    output wire s4_col6_b0,
    output wire s4_col7_b0,
    output wire s4_col7_b1,
    output wire s4_col8_b0,
    output wire s4_col8_b1,
    output wire s4_col9_b0,
    output wire s4_col9_b1,
    output wire s4_col10_b0,
    output wire s4_col10_b1,
    output wire s4_col11_b0,
    output wire s4_col11_b1,
    output wire s4_col12_b0,
    output wire s4_col12_b1,
    output wire s4_col13_b0,
    output wire s4_col13_b1,
    output wire s4_col14_b0,
    output wire s4_col14_b1,
    output wire s4_col15_b0,
    output wire s4_col15_b1,
    output wire s4_col16_b0,
    output wire s4_col16_b1,
    output wire s4_col17_b0,
    output wire s4_col17_b1,
    output wire s4_col18_b0,
    output wire s4_col18_b1,
    output wire s4_col19_b0,
    output wire s4_col19_b1,
    output wire s4_col20_b0,
    output wire s4_col20_b1,
    output wire s4_col21_b0,
    output wire s4_col21_b1,
    output wire s4_col22_b0,
    output wire s4_col22_b1,
    output wire s4_col23_b0,
    output wire s4_col23_b1,
    output wire s4_col24_b0,
    output wire s4_col24_b1,
    output wire s4_col25_b0,
    output wire s4_col25_b1,
    output wire s4_col26_b0,
    output wire s4_col26_b1,
    output wire s4_col27_b0,
    output wire s4_col27_b1,
    output wire s4_col28_b0,
    output wire s4_col28_b1,
    output wire s4_col29_b0,
    output wire s4_col29_b1,
    output wire s4_col30_b0,
    output wire s4_col30_b1,
    output wire s4_col31_b0,
    output wire s4_col31_b1,
    output wire s4_col32_b0,
    output wire s4_col32_b1,
    output wire s4_col33_b0
);

    // =========================================================================
    // Internal wire declarations
    // =========================================================================
    wire w_l5_c5_ha1_s, w_l5_c5_ha1_c, w_l5_c6_ha1_s, w_l5_c6_ha1_c;
    wire w_l5_c7_ha1_s, w_l5_c7_ha1_c, w_l5_c8_ha1_s, w_l5_c8_ha1_c;
    wire w_l5_c9_ha1_s, w_l5_c9_ha1_c, w_l5_c10_fa1_s, w_l5_c10_fa1_c;
    wire w_l5_c11_fa1_s, w_l5_c11_fa1_c, w_l5_c12_fa1_s, w_l5_c12_fa1_c;
    wire w_l5_c13_fa1_s, w_l5_c13_fa1_c, w_l5_c14_fa1_s, w_l5_c14_fa1_c;
    wire w_l5_c15_fa1_s, w_l5_c15_fa1_c, w_l5_c16_fa1_s, w_l5_c16_fa1_c;
    wire w_l5_c17_fa1_s, w_l5_c17_fa1_c, w_l5_c18_fa1_s, w_l5_c18_fa1_c;
    wire w_l5_c19_fa1_s, w_l5_c19_fa1_c, w_l5_c20_fa1_s, w_l5_c20_fa1_c;
    wire w_l5_c21_fa1_s, w_l5_c21_fa1_c, w_l5_c22_fa1_s, w_l5_c22_fa1_c;
    wire w_l5_c23_fa1_s, w_l5_c23_fa1_c, w_l5_c24_ha1_s, w_l5_c24_ha1_c;
    wire w_l5_c25_ha1_s, w_l5_c25_ha1_c, w_l5_c26_ha1_s, w_l5_c26_ha1_c;
    wire w_l5_c27_ha1_s, w_l5_c27_ha1_c, w_l5_c28_ha1_s, w_l5_c28_ha1_c;
    wire w_l5_c29_ha1_s, w_l5_c29_ha1_c, w_l5_c30_ha1_s, w_l5_c30_ha1_c;
    wire w_l5_c31_ha1_s, w_l5_c31_ha1_c, w_l6_c6_ha1_s, w_l6_c6_ha1_c;
    wire w_l6_c7_ha1_s, w_l6_c7_ha1_c, w_l6_c8_ha1_s, w_l6_c8_ha1_c;
    wire w_l6_c9_ha1_s, w_l6_c9_ha1_c, w_l6_c10_ha1_s, w_l6_c10_ha1_c;
    wire w_l6_c11_ha1_s, w_l6_c11_ha1_c, w_l6_c12_ha1_s, w_l6_c12_ha1_c;
    wire w_l6_c13_ha1_s, w_l6_c13_ha1_c, w_l6_c14_ha1_s, w_l6_c14_ha1_c;
    wire w_l6_c15_fa1_s, w_l6_c15_fa1_c, w_l6_c16_fa1_s, w_l6_c16_fa1_c;
    wire w_l6_c17_fa1_s, w_l6_c17_fa1_c, w_l6_c18_fa1_s, w_l6_c18_fa1_c;
    wire w_l6_c19_fa1_s, w_l6_c19_fa1_c, w_l6_c20_ha1_s, w_l6_c20_ha1_c;
    wire w_l6_c21_ha1_s, w_l6_c21_ha1_c, w_l6_c22_ha1_s, w_l6_c22_ha1_c;
    wire w_l6_c23_ha1_s, w_l6_c23_ha1_c, w_l6_c24_ha1_s, w_l6_c24_ha1_c;
    wire w_l6_c25_ha1_s, w_l6_c25_ha1_c, w_l6_c26_ha1_s, w_l6_c26_ha1_c;
    wire w_l6_c27_ha1_s, w_l6_c27_ha1_c, w_l6_c28_ha1_s, w_l6_c28_ha1_c;
    wire w_l6_c29_ha1_s, w_l6_c29_ha1_c, w_l6_c30_ha1_s, w_l6_c30_ha1_c;
    wire w_l6_c31_ha1_s, w_l6_c31_ha1_c, w_l6_c32_ha1_s, w_l6_c32_ha1_c;


    // =========================================================================
    // LEVEL 5 REDUCTION
    // Input : Stage 3 outputs (up to 4 bits in the widest column)
    // Output: reduced bits (up to 3 bits in the widest column)
    // =========================================================================

    // ---- Column 0: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 0: 1 bit (s3_col0_b0) passes through unchanged (no compressor needed)

    // ---- Column 1: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 1: 1 bit (s3_col1_b0) passes through unchanged (no compressor needed)

    // ---- Column 2: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 2: 1 bit (s3_col2_b0) passes through unchanged (no compressor needed)

    // ---- Column 3: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 3: 1 bit (s3_col3_b0) passes through unchanged (no compressor needed)

    // ---- Column 4: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 4: 1 bit (s3_col4_b0) passes through unchanged (no compressor needed)

    // ---- Column 5: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c5_1 (.a(s3_col5_b0), .b(s3_col5_b1), .sum(w_l5_c5_ha1_s), .cout(w_l5_c5_ha1_c)); // col 5: HA#1 reduces remaining 2 bits -> 1 sum (stays col 5) + 1 carry (-> col 6)

    // ---- Column 6: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c6_1 (.a(s3_col6_b0), .b(s3_col6_b1), .sum(w_l5_c6_ha1_s), .cout(w_l5_c6_ha1_c)); // col 6: HA#1 reduces remaining 2 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)

    // ---- Column 7: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c7_1 (.a(s3_col7_b0), .b(s3_col7_b1), .sum(w_l5_c7_ha1_s), .cout(w_l5_c7_ha1_c)); // col 7: HA#1 reduces remaining 2 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)

    // ---- Column 8: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c8_1 (.a(s3_col8_b0), .b(s3_col8_b1), .sum(w_l5_c8_ha1_s), .cout(w_l5_c8_ha1_c)); // col 8: HA#1 reduces remaining 2 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)

    // ---- Column 9: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c9_1 (.a(s3_col9_b0), .b(s3_col9_b1), .sum(w_l5_c9_ha1_s), .cout(w_l5_c9_ha1_c)); // col 9: HA#1 reduces remaining 2 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)

    // ---- Column 10: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c10_1 (.a(s3_col10_b0), .b(s3_col10_b1), .cin(s3_col10_b2), .sum(w_l5_c10_fa1_s), .cout(w_l5_c10_fa1_c)); // col 10: FA#1 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)

    // ---- Column 11: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c11_1 (.a(s3_col11_b0), .b(s3_col11_b1), .cin(s3_col11_b2), .sum(w_l5_c11_fa1_s), .cout(w_l5_c11_fa1_c)); // col 11: FA#1 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)

    // ---- Column 12: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c12_1 (.a(s3_col12_b0), .b(s3_col12_b1), .cin(s3_col12_b2), .sum(w_l5_c12_fa1_s), .cout(w_l5_c12_fa1_c)); // col 12: FA#1 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)

    // ---- Column 13: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c13_1 (.a(s3_col13_b0), .b(s3_col13_b1), .cin(s3_col13_b2), .sum(w_l5_c13_fa1_s), .cout(w_l5_c13_fa1_c)); // col 13: FA#1 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)

    // ---- Column 14: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c14_1 (.a(s3_col14_b0), .b(s3_col14_b1), .cin(s3_col14_b2), .sum(w_l5_c14_fa1_s), .cout(w_l5_c14_fa1_c)); // col 14: FA#1 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)

    // ---- Column 15: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l5_c15_1 (.a(s3_col15_b0), .b(s3_col15_b1), .cin(s3_col15_b2), .sum(w_l5_c15_fa1_s), .cout(w_l5_c15_fa1_c)); // col 15: FA#1 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    // col 15: 1 bit (s3_col15_b3) passes through unchanged (no compressor needed)

    // ---- Column 16: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l5_c16_1 (.a(s3_col16_b0), .b(s3_col16_b1), .cin(s3_col16_b2), .sum(w_l5_c16_fa1_s), .cout(w_l5_c16_fa1_c)); // col 16: FA#1 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    // col 16: 1 bit (s3_col16_b3) passes through unchanged (no compressor needed)

    // ---- Column 17: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l5_c17_1 (.a(s3_col17_b0), .b(s3_col17_b1), .cin(s3_col17_b2), .sum(w_l5_c17_fa1_s), .cout(w_l5_c17_fa1_c)); // col 17: FA#1 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    // col 17: 1 bit (s3_col17_b3) passes through unchanged (no compressor needed)

    // ---- Column 18: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l5_c18_1 (.a(s3_col18_b0), .b(s3_col18_b1), .cin(s3_col18_b2), .sum(w_l5_c18_fa1_s), .cout(w_l5_c18_fa1_c)); // col 18: FA#1 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    // col 18: 1 bit (s3_col18_b3) passes through unchanged (no compressor needed)

    // ---- Column 19: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l5_c19_1 (.a(s3_col19_b0), .b(s3_col19_b1), .cin(s3_col19_b2), .sum(w_l5_c19_fa1_s), .cout(w_l5_c19_fa1_c)); // col 19: FA#1 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    // col 19: 1 bit (s3_col19_b3) passes through unchanged (no compressor needed)

    // ---- Column 20: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c20_1 (.a(s3_col20_b0), .b(s3_col20_b1), .cin(s3_col20_b2), .sum(w_l5_c20_fa1_s), .cout(w_l5_c20_fa1_c)); // col 20: FA#1 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)

    // ---- Column 21: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c21_1 (.a(s3_col21_b0), .b(s3_col21_b1), .cin(s3_col21_b2), .sum(w_l5_c21_fa1_s), .cout(w_l5_c21_fa1_c)); // col 21: FA#1 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)

    // ---- Column 22: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c22_1 (.a(s3_col22_b0), .b(s3_col22_b1), .cin(s3_col22_b2), .sum(w_l5_c22_fa1_s), .cout(w_l5_c22_fa1_c)); // col 22: FA#1 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)

    // ---- Column 23: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l5_c23_1 (.a(s3_col23_b0), .b(s3_col23_b1), .cin(s3_col23_b2), .sum(w_l5_c23_fa1_s), .cout(w_l5_c23_fa1_c)); // col 23: FA#1 reduces 3 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)

    // ---- Column 24: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c24_1 (.a(s3_col24_b0), .b(s3_col24_b1), .sum(w_l5_c24_ha1_s), .cout(w_l5_c24_ha1_c)); // col 24: HA#1 reduces remaining 2 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)

    // ---- Column 25: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c25_1 (.a(s3_col25_b0), .b(s3_col25_b1), .sum(w_l5_c25_ha1_s), .cout(w_l5_c25_ha1_c)); // col 25: HA#1 reduces remaining 2 bits -> 1 sum (stays col 25) + 1 carry (-> col 26)

    // ---- Column 26: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c26_1 (.a(s3_col26_b0), .b(s3_col26_b1), .sum(w_l5_c26_ha1_s), .cout(w_l5_c26_ha1_c)); // col 26: HA#1 reduces remaining 2 bits -> 1 sum (stays col 26) + 1 carry (-> col 27)

    // ---- Column 27: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c27_1 (.a(s3_col27_b0), .b(s3_col27_b1), .sum(w_l5_c27_ha1_s), .cout(w_l5_c27_ha1_c)); // col 27: HA#1 reduces remaining 2 bits -> 1 sum (stays col 27) + 1 carry (-> col 28)

    // ---- Column 28: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c28_1 (.a(s3_col28_b0), .b(s3_col28_b1), .sum(w_l5_c28_ha1_s), .cout(w_l5_c28_ha1_c)); // col 28: HA#1 reduces remaining 2 bits -> 1 sum (stays col 28) + 1 carry (-> col 29)

    // ---- Column 29: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c29_1 (.a(s3_col29_b0), .b(s3_col29_b1), .sum(w_l5_c29_ha1_s), .cout(w_l5_c29_ha1_c)); // col 29: HA#1 reduces remaining 2 bits -> 1 sum (stays col 29) + 1 carry (-> col 30)

    // ---- Column 30: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c30_1 (.a(s3_col30_b0), .b(s3_col30_b1), .sum(w_l5_c30_ha1_s), .cout(w_l5_c30_ha1_c)); // col 30: HA#1 reduces remaining 2 bits -> 1 sum (stays col 30) + 1 carry (-> col 31)

    // ---- Column 31: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l5_c31_1 (.a(s3_col31_b0), .b(s3_col31_b1), .sum(w_l5_c31_ha1_s), .cout(w_l5_c31_ha1_c)); // col 31: HA#1 reduces remaining 2 bits -> 1 sum (stays col 31) + 1 carry (-> col 32)

    // ---- Column 32: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 32: 1 bit (s3_col32_b0) passes through unchanged (no compressor needed)


    // =========================================================================
    // LEVEL 6 REDUCTION (final reduction level)
    // Input : Level 5 outputs (up to 3 bits in the widest column)
    // Output: <=2 bits in EVERY column -- ready for the final adder
    // =========================================================================

    // ---- Column 0: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 0: 1 bit (s3_col0_b0) passes through unchanged (no compressor needed)

    // ---- Column 1: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 1: 1 bit (s3_col1_b0) passes through unchanged (no compressor needed)

    // ---- Column 2: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 2: 1 bit (s3_col2_b0) passes through unchanged (no compressor needed)

    // ---- Column 3: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 3: 1 bit (s3_col3_b0) passes through unchanged (no compressor needed)

    // ---- Column 4: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 4: 1 bit (s3_col4_b0) passes through unchanged (no compressor needed)

    // ---- Column 5: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 5: 1 bit (w_l5_c5_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 6: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c6_1 (.a(w_l5_c5_ha1_c), .b(w_l5_c6_ha1_s), .sum(w_l6_c6_ha1_s), .cout(w_l6_c6_ha1_c)); // col 6: HA#1 reduces remaining 2 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)

    // ---- Column 7: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c7_1 (.a(w_l5_c6_ha1_c), .b(w_l5_c7_ha1_s), .sum(w_l6_c7_ha1_s), .cout(w_l6_c7_ha1_c)); // col 7: HA#1 reduces remaining 2 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)

    // ---- Column 8: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c8_1 (.a(w_l5_c7_ha1_c), .b(w_l5_c8_ha1_s), .sum(w_l6_c8_ha1_s), .cout(w_l6_c8_ha1_c)); // col 8: HA#1 reduces remaining 2 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)

    // ---- Column 9: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c9_1 (.a(w_l5_c8_ha1_c), .b(w_l5_c9_ha1_s), .sum(w_l6_c9_ha1_s), .cout(w_l6_c9_ha1_c)); // col 9: HA#1 reduces remaining 2 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)

    // ---- Column 10: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c10_1 (.a(w_l5_c9_ha1_c), .b(w_l5_c10_fa1_s), .sum(w_l6_c10_ha1_s), .cout(w_l6_c10_ha1_c)); // col 10: HA#1 reduces remaining 2 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)

    // ---- Column 11: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c11_1 (.a(w_l5_c10_fa1_c), .b(w_l5_c11_fa1_s), .sum(w_l6_c11_ha1_s), .cout(w_l6_c11_ha1_c)); // col 11: HA#1 reduces remaining 2 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)

    // ---- Column 12: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c12_1 (.a(w_l5_c11_fa1_c), .b(w_l5_c12_fa1_s), .sum(w_l6_c12_ha1_s), .cout(w_l6_c12_ha1_c)); // col 12: HA#1 reduces remaining 2 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)

    // ---- Column 13: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c13_1 (.a(w_l5_c12_fa1_c), .b(w_l5_c13_fa1_s), .sum(w_l6_c13_ha1_s), .cout(w_l6_c13_ha1_c)); // col 13: HA#1 reduces remaining 2 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)

    // ---- Column 14: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c14_1 (.a(w_l5_c13_fa1_c), .b(w_l5_c14_fa1_s), .sum(w_l6_c14_ha1_s), .cout(w_l6_c14_ha1_c)); // col 14: HA#1 reduces remaining 2 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)

    // ---- Column 15: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l6_c15_1 (.a(w_l5_c14_fa1_c), .b(w_l5_c15_fa1_s), .cin(s3_col15_b3), .sum(w_l6_c15_fa1_s), .cout(w_l6_c15_fa1_c)); // col 15: FA#1 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)

    // ---- Column 16: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l6_c16_1 (.a(w_l5_c15_fa1_c), .b(w_l5_c16_fa1_s), .cin(s3_col16_b3), .sum(w_l6_c16_fa1_s), .cout(w_l6_c16_fa1_c)); // col 16: FA#1 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)

    // ---- Column 17: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l6_c17_1 (.a(w_l5_c16_fa1_c), .b(w_l5_c17_fa1_s), .cin(s3_col17_b3), .sum(w_l6_c17_fa1_s), .cout(w_l6_c17_fa1_c)); // col 17: FA#1 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)

    // ---- Column 18: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l6_c18_1 (.a(w_l5_c17_fa1_c), .b(w_l5_c18_fa1_s), .cin(s3_col18_b3), .sum(w_l6_c18_fa1_s), .cout(w_l6_c18_fa1_c)); // col 18: FA#1 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)

    // ---- Column 19: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l6_c19_1 (.a(w_l5_c18_fa1_c), .b(w_l5_c19_fa1_s), .cin(s3_col19_b3), .sum(w_l6_c19_fa1_s), .cout(w_l6_c19_fa1_c)); // col 19: FA#1 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)

    // ---- Column 20: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c20_1 (.a(w_l5_c19_fa1_c), .b(w_l5_c20_fa1_s), .sum(w_l6_c20_ha1_s), .cout(w_l6_c20_ha1_c)); // col 20: HA#1 reduces remaining 2 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)

    // ---- Column 21: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c21_1 (.a(w_l5_c20_fa1_c), .b(w_l5_c21_fa1_s), .sum(w_l6_c21_ha1_s), .cout(w_l6_c21_ha1_c)); // col 21: HA#1 reduces remaining 2 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)

    // ---- Column 22: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c22_1 (.a(w_l5_c21_fa1_c), .b(w_l5_c22_fa1_s), .sum(w_l6_c22_ha1_s), .cout(w_l6_c22_ha1_c)); // col 22: HA#1 reduces remaining 2 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)

    // ---- Column 23: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c23_1 (.a(w_l5_c22_fa1_c), .b(w_l5_c23_fa1_s), .sum(w_l6_c23_ha1_s), .cout(w_l6_c23_ha1_c)); // col 23: HA#1 reduces remaining 2 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)

    // ---- Column 24: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c24_1 (.a(w_l5_c23_fa1_c), .b(w_l5_c24_ha1_s), .sum(w_l6_c24_ha1_s), .cout(w_l6_c24_ha1_c)); // col 24: HA#1 reduces remaining 2 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)

    // ---- Column 25: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c25_1 (.a(w_l5_c24_ha1_c), .b(w_l5_c25_ha1_s), .sum(w_l6_c25_ha1_s), .cout(w_l6_c25_ha1_c)); // col 25: HA#1 reduces remaining 2 bits -> 1 sum (stays col 25) + 1 carry (-> col 26)

    // ---- Column 26: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c26_1 (.a(w_l5_c25_ha1_c), .b(w_l5_c26_ha1_s), .sum(w_l6_c26_ha1_s), .cout(w_l6_c26_ha1_c)); // col 26: HA#1 reduces remaining 2 bits -> 1 sum (stays col 26) + 1 carry (-> col 27)

    // ---- Column 27: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c27_1 (.a(w_l5_c26_ha1_c), .b(w_l5_c27_ha1_s), .sum(w_l6_c27_ha1_s), .cout(w_l6_c27_ha1_c)); // col 27: HA#1 reduces remaining 2 bits -> 1 sum (stays col 27) + 1 carry (-> col 28)

    // ---- Column 28: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c28_1 (.a(w_l5_c27_ha1_c), .b(w_l5_c28_ha1_s), .sum(w_l6_c28_ha1_s), .cout(w_l6_c28_ha1_c)); // col 28: HA#1 reduces remaining 2 bits -> 1 sum (stays col 28) + 1 carry (-> col 29)

    // ---- Column 29: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c29_1 (.a(w_l5_c28_ha1_c), .b(w_l5_c29_ha1_s), .sum(w_l6_c29_ha1_s), .cout(w_l6_c29_ha1_c)); // col 29: HA#1 reduces remaining 2 bits -> 1 sum (stays col 29) + 1 carry (-> col 30)

    // ---- Column 30: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c30_1 (.a(w_l5_c29_ha1_c), .b(w_l5_c30_ha1_s), .sum(w_l6_c30_ha1_s), .cout(w_l6_c30_ha1_c)); // col 30: HA#1 reduces remaining 2 bits -> 1 sum (stays col 30) + 1 carry (-> col 31)

    // ---- Column 31: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c31_1 (.a(w_l5_c30_ha1_c), .b(w_l5_c31_ha1_s), .sum(w_l6_c31_ha1_s), .cout(w_l6_c31_ha1_c)); // col 31: HA#1 reduces remaining 2 bits -> 1 sum (stays col 31) + 1 carry (-> col 32)

    // ---- Column 32: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l6_c32_1 (.a(w_l5_c31_ha1_c), .b(s3_col32_b0), .sum(w_l6_c32_ha1_s), .cout(w_l6_c32_ha1_c)); // col 32: HA#1 reduces remaining 2 bits -> 1 sum (stays col 32) + 1 carry (-> col 33)


    // =========================================================================
    // Output assignment: map final Level-6 internal signals to named output
    // ports, organized by column. This is the exact handoff to Stage 5
    // (cla_32bit), which performs the final addition of the two remaining
    // rows to produce the 32-bit product P[31:0].
    // =========================================================================
    assign s4_col0_b0 = s3_col0_b0;  // column 0, bit 0 of 1
    assign s4_col1_b0 = s3_col1_b0;  // column 1, bit 0 of 1
    assign s4_col2_b0 = s3_col2_b0;  // column 2, bit 0 of 1
    assign s4_col3_b0 = s3_col3_b0;  // column 3, bit 0 of 1
    assign s4_col4_b0 = s3_col4_b0;  // column 4, bit 0 of 1
    assign s4_col5_b0 = w_l5_c5_ha1_s;  // column 5, bit 0 of 1
    assign s4_col6_b0 = w_l6_c6_ha1_s;  // column 6, bit 0 of 1
    assign s4_col7_b0 = w_l6_c6_ha1_c;  // column 7, bit 0 of 2
    assign s4_col7_b1 = w_l6_c7_ha1_s;  // column 7, bit 1 of 2
    assign s4_col8_b0 = w_l6_c7_ha1_c;  // column 8, bit 0 of 2
    assign s4_col8_b1 = w_l6_c8_ha1_s;  // column 8, bit 1 of 2
    assign s4_col9_b0 = w_l6_c8_ha1_c;  // column 9, bit 0 of 2
    assign s4_col9_b1 = w_l6_c9_ha1_s;  // column 9, bit 1 of 2
    assign s4_col10_b0 = w_l6_c9_ha1_c;  // column 10, bit 0 of 2
    assign s4_col10_b1 = w_l6_c10_ha1_s;  // column 10, bit 1 of 2
    assign s4_col11_b0 = w_l6_c10_ha1_c;  // column 11, bit 0 of 2
    assign s4_col11_b1 = w_l6_c11_ha1_s;  // column 11, bit 1 of 2
    assign s4_col12_b0 = w_l6_c11_ha1_c;  // column 12, bit 0 of 2
    assign s4_col12_b1 = w_l6_c12_ha1_s;  // column 12, bit 1 of 2
    assign s4_col13_b0 = w_l6_c12_ha1_c;  // column 13, bit 0 of 2
    assign s4_col13_b1 = w_l6_c13_ha1_s;  // column 13, bit 1 of 2
    assign s4_col14_b0 = w_l6_c13_ha1_c;  // column 14, bit 0 of 2
    assign s4_col14_b1 = w_l6_c14_ha1_s;  // column 14, bit 1 of 2
    assign s4_col15_b0 = w_l6_c14_ha1_c;  // column 15, bit 0 of 2
    assign s4_col15_b1 = w_l6_c15_fa1_s;  // column 15, bit 1 of 2
    assign s4_col16_b0 = w_l6_c15_fa1_c;  // column 16, bit 0 of 2
    assign s4_col16_b1 = w_l6_c16_fa1_s;  // column 16, bit 1 of 2
    assign s4_col17_b0 = w_l6_c16_fa1_c;  // column 17, bit 0 of 2
    assign s4_col17_b1 = w_l6_c17_fa1_s;  // column 17, bit 1 of 2
    assign s4_col18_b0 = w_l6_c17_fa1_c;  // column 18, bit 0 of 2
    assign s4_col18_b1 = w_l6_c18_fa1_s;  // column 18, bit 1 of 2
    assign s4_col19_b0 = w_l6_c18_fa1_c;  // column 19, bit 0 of 2
    assign s4_col19_b1 = w_l6_c19_fa1_s;  // column 19, bit 1 of 2
    assign s4_col20_b0 = w_l6_c19_fa1_c;  // column 20, bit 0 of 2
    assign s4_col20_b1 = w_l6_c20_ha1_s;  // column 20, bit 1 of 2
    assign s4_col21_b0 = w_l6_c20_ha1_c;  // column 21, bit 0 of 2
    assign s4_col21_b1 = w_l6_c21_ha1_s;  // column 21, bit 1 of 2
    assign s4_col22_b0 = w_l6_c21_ha1_c;  // column 22, bit 0 of 2
    assign s4_col22_b1 = w_l6_c22_ha1_s;  // column 22, bit 1 of 2
    assign s4_col23_b0 = w_l6_c22_ha1_c;  // column 23, bit 0 of 2
    assign s4_col23_b1 = w_l6_c23_ha1_s;  // column 23, bit 1 of 2
    assign s4_col24_b0 = w_l6_c23_ha1_c;  // column 24, bit 0 of 2
    assign s4_col24_b1 = w_l6_c24_ha1_s;  // column 24, bit 1 of 2
    assign s4_col25_b0 = w_l6_c24_ha1_c;  // column 25, bit 0 of 2
    assign s4_col25_b1 = w_l6_c25_ha1_s;  // column 25, bit 1 of 2
    assign s4_col26_b0 = w_l6_c25_ha1_c;  // column 26, bit 0 of 2
    assign s4_col26_b1 = w_l6_c26_ha1_s;  // column 26, bit 1 of 2
    assign s4_col27_b0 = w_l6_c26_ha1_c;  // column 27, bit 0 of 2
    assign s4_col27_b1 = w_l6_c27_ha1_s;  // column 27, bit 1 of 2
    assign s4_col28_b0 = w_l6_c27_ha1_c;  // column 28, bit 0 of 2
    assign s4_col28_b1 = w_l6_c28_ha1_s;  // column 28, bit 1 of 2
    assign s4_col29_b0 = w_l6_c28_ha1_c;  // column 29, bit 0 of 2
    assign s4_col29_b1 = w_l6_c29_ha1_s;  // column 29, bit 1 of 2
    assign s4_col30_b0 = w_l6_c29_ha1_c;  // column 30, bit 0 of 2
    assign s4_col30_b1 = w_l6_c30_ha1_s;  // column 30, bit 1 of 2
    assign s4_col31_b0 = w_l6_c30_ha1_c;  // column 31, bit 0 of 2
    assign s4_col31_b1 = w_l6_c31_ha1_s;  // column 31, bit 1 of 2
    assign s4_col32_b0 = w_l6_c31_ha1_c;  // column 32, bit 0 of 2
    assign s4_col32_b1 = w_l6_c32_ha1_s;  // column 32, bit 1 of 2
    assign s4_col33_b0 = w_l6_c32_ha1_c;  // column 33, bit 0 of 1

endmodule
