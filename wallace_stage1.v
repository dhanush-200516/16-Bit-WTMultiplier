// =============================================================================
// Module      : wallace_stage1
// Pipeline    : STAGE 2  (first half of Wallace Tree reduction)
// Description : Takes the raw 256 partial-product bits from Stage 1
//               (partial_product_gen) and performs TWO levels of Wallace
//               Tree reduction (Level 1 and Level 2) using only Full Adders
//               (3-bit to 2-bit "3:2 compressors") and Half Adders (2-bit to
//               2-bit "2:2 compressors").
//
//               WHY TWO LEVELS PER STAGE?
//               A full 16x16 Wallace Tree needs 6 reduction levels in total
//               to bring every column down to <=2 bits (ready for a final
//               adder). Rather than registering after every single level
//               (which would need 6+ pipeline stages and add unnecessary
//               latency), we group 2 reduction levels per pipeline stage.
//               This keeps the combinational delay per stage balanced
//               while still meeting the project's pipelining objective.
//
//               HOW TO READ THIS FILE:
//               The code is organized strictly column-by-column, in
//               increasing column order, separately for Level 1 and then
//               Level 2. Every column has a heading comment showing:
//                 - how many bits enter that column
//                 - how many Full Adders (FA) and Half Adders (HA) are used
//                 - how many bits simply pass through (when count < 2)
//               This mirrors the project's Wallace Tree Blueprint document
//               exactly, so you can cross-check any column here against
//               that table.
//
//               NAMING CONVENTION for internal wires:
//                 w_l1_c{col}_fa{n}_s  = Level 1, column {col}, FA number n, SUM output
//                 w_l1_c{col}_fa{n}_c  = Level 1, column {col}, FA number n, CARRY output
//                 w_l1_c{col}_ha{n}_s  = Level 1, column {col}, HA number n, SUM output
//                 w_l1_c{col}_ha{n}_c  = Level 1, column {col}, HA number n, CARRY output
//               (same pattern with "l2" for Level 2)
//
//               OUTPUT NAMING: s2_col{c}_b{n} = Stage 2 output, column c, bit n
//               (multiple bits per column are expected -- a column is only
//               "fully reduced" to <=2 bits once ALL 6 levels are complete,
//               which happens across Stages 2, 3 and 4 combined)
// =============================================================================

module wallace_stage1 (
    // ---- Inputs: raw partial product rows from Stage 1 ----
    input  wire [15:0] pp_row0,
    input  wire [15:0] pp_row1,
    input  wire [15:0] pp_row2,
    input  wire [15:0] pp_row3,
    input  wire [15:0] pp_row4,
    input  wire [15:0] pp_row5,
    input  wire [15:0] pp_row6,
    input  wire [15:0] pp_row7,
    input  wire [15:0] pp_row8,
    input  wire [15:0] pp_row9,
    input  wire [15:0] pp_row10,
    input  wire [15:0] pp_row11,
    input  wire [15:0] pp_row12,
    input  wire [15:0] pp_row13,
    input  wire [15:0] pp_row14,
    input  wire [15:0] pp_row15,

    // ---- Outputs: partially-reduced columns, after Levels 1 & 2 ----
    // (see s2_col{c}_b{n} naming convention explained above)
    output wire s2_col0_b0,
    output wire s2_col1_b0,
    output wire s2_col2_b0,
    output wire s2_col3_b0,
    output wire s2_col3_b1,
    output wire s2_col4_b0,
    output wire s2_col4_b1,
    output wire s2_col5_b0,
    output wire s2_col5_b1,
    output wire s2_col5_b2,
    output wire s2_col6_b0,
    output wire s2_col6_b1,
    output wire s2_col6_b2,
    output wire s2_col7_b0,
    output wire s2_col7_b1,
    output wire s2_col7_b2,
    output wire s2_col7_b3,
    output wire s2_col8_b0,
    output wire s2_col8_b1,
    output wire s2_col8_b2,
    output wire s2_col8_b3,
    output wire s2_col9_b0,
    output wire s2_col9_b1,
    output wire s2_col9_b2,
    output wire s2_col9_b3,
    output wire s2_col9_b4,
    output wire s2_col10_b0,
    output wire s2_col10_b1,
    output wire s2_col10_b2,
    output wire s2_col10_b3,
    output wire s2_col10_b4,
    output wire s2_col11_b0,
    output wire s2_col11_b1,
    output wire s2_col11_b2,
    output wire s2_col11_b3,
    output wire s2_col11_b4,
    output wire s2_col12_b0,
    output wire s2_col12_b1,
    output wire s2_col12_b2,
    output wire s2_col12_b3,
    output wire s2_col12_b4,
    output wire s2_col12_b5,
    output wire s2_col13_b0,
    output wire s2_col13_b1,
    output wire s2_col13_b2,
    output wire s2_col13_b3,
    output wire s2_col13_b4,
    output wire s2_col13_b5,
    output wire s2_col14_b0,
    output wire s2_col14_b1,
    output wire s2_col14_b2,
    output wire s2_col14_b3,
    output wire s2_col14_b4,
    output wire s2_col14_b5,
    output wire s2_col14_b6,
    output wire s2_col15_b0,
    output wire s2_col15_b1,
    output wire s2_col15_b2,
    output wire s2_col15_b3,
    output wire s2_col15_b4,
    output wire s2_col15_b5,
    output wire s2_col15_b6,
    output wire s2_col16_b0,
    output wire s2_col16_b1,
    output wire s2_col16_b2,
    output wire s2_col16_b3,
    output wire s2_col16_b4,
    output wire s2_col16_b5,
    output wire s2_col16_b6,
    output wire s2_col16_b7,
    output wire s2_col17_b0,
    output wire s2_col17_b1,
    output wire s2_col17_b2,
    output wire s2_col17_b3,
    output wire s2_col17_b4,
    output wire s2_col17_b5,
    output wire s2_col17_b6,
    output wire s2_col18_b0,
    output wire s2_col18_b1,
    output wire s2_col18_b2,
    output wire s2_col18_b3,
    output wire s2_col18_b4,
    output wire s2_col18_b5,
    output wire s2_col18_b6,
    output wire s2_col19_b0,
    output wire s2_col19_b1,
    output wire s2_col19_b2,
    output wire s2_col19_b3,
    output wire s2_col19_b4,
    output wire s2_col19_b5,
    output wire s2_col20_b0,
    output wire s2_col20_b1,
    output wire s2_col20_b2,
    output wire s2_col20_b3,
    output wire s2_col20_b4,
    output wire s2_col20_b5,
    output wire s2_col21_b0,
    output wire s2_col21_b1,
    output wire s2_col21_b2,
    output wire s2_col21_b3,
    output wire s2_col21_b4,
    output wire s2_col21_b5,
    output wire s2_col22_b0,
    output wire s2_col22_b1,
    output wire s2_col22_b2,
    output wire s2_col22_b3,
    output wire s2_col22_b4,
    output wire s2_col23_b0,
    output wire s2_col23_b1,
    output wire s2_col23_b2,
    output wire s2_col23_b3,
    output wire s2_col24_b0,
    output wire s2_col24_b1,
    output wire s2_col24_b2,
    output wire s2_col24_b3,
    output wire s2_col25_b0,
    output wire s2_col25_b1,
    output wire s2_col25_b2,
    output wire s2_col25_b3,
    output wire s2_col26_b0,
    output wire s2_col26_b1,
    output wire s2_col26_b2,
    output wire s2_col27_b0,
    output wire s2_col27_b1,
    output wire s2_col27_b2,
    output wire s2_col28_b0,
    output wire s2_col28_b1,
    output wire s2_col29_b0,
    output wire s2_col29_b1,
    output wire s2_col30_b0,
    output wire s2_col30_b1,
    output wire s2_col31_b0
);

    // =========================================================================
    // Internal wire declarations
    // All intermediate FA/HA sum and carry signals used during Level 1 and
    // Level 2 reduction. Grouped here for clarity; each is used exactly once
    // as an output of one adder and exactly once as an input to the next.
    // =========================================================================
    wire w_l1_c1_ha1_s, w_l1_c1_ha1_c, w_l1_c2_fa1_s, w_l1_c2_fa1_c;
    wire w_l1_c3_fa1_s, w_l1_c3_fa1_c, w_l1_c4_fa1_s, w_l1_c4_fa1_c;
    wire w_l1_c4_ha1_s, w_l1_c4_ha1_c, w_l1_c5_fa1_s, w_l1_c5_fa1_c;
    wire w_l1_c5_fa2_s, w_l1_c5_fa2_c, w_l1_c6_fa1_s, w_l1_c6_fa1_c;
    wire w_l1_c6_fa2_s, w_l1_c6_fa2_c, w_l1_c7_fa1_s, w_l1_c7_fa1_c;
    wire w_l1_c7_fa2_s, w_l1_c7_fa2_c, w_l1_c7_ha1_s, w_l1_c7_ha1_c;
    wire w_l1_c8_fa1_s, w_l1_c8_fa1_c, w_l1_c8_fa2_s, w_l1_c8_fa2_c;
    wire w_l1_c8_fa3_s, w_l1_c8_fa3_c, w_l1_c9_fa1_s, w_l1_c9_fa1_c;
    wire w_l1_c9_fa2_s, w_l1_c9_fa2_c, w_l1_c9_fa3_s, w_l1_c9_fa3_c;
    wire w_l1_c10_fa1_s, w_l1_c10_fa1_c, w_l1_c10_fa2_s, w_l1_c10_fa2_c;
    wire w_l1_c10_fa3_s, w_l1_c10_fa3_c, w_l1_c10_ha1_s, w_l1_c10_ha1_c;
    wire w_l1_c11_fa1_s, w_l1_c11_fa1_c, w_l1_c11_fa2_s, w_l1_c11_fa2_c;
    wire w_l1_c11_fa3_s, w_l1_c11_fa3_c, w_l1_c11_fa4_s, w_l1_c11_fa4_c;
    wire w_l1_c12_fa1_s, w_l1_c12_fa1_c, w_l1_c12_fa2_s, w_l1_c12_fa2_c;
    wire w_l1_c12_fa3_s, w_l1_c12_fa3_c, w_l1_c12_fa4_s, w_l1_c12_fa4_c;
    wire w_l1_c13_fa1_s, w_l1_c13_fa1_c, w_l1_c13_fa2_s, w_l1_c13_fa2_c;
    wire w_l1_c13_fa3_s, w_l1_c13_fa3_c, w_l1_c13_fa4_s, w_l1_c13_fa4_c;
    wire w_l1_c13_ha1_s, w_l1_c13_ha1_c, w_l1_c14_fa1_s, w_l1_c14_fa1_c;
    wire w_l1_c14_fa2_s, w_l1_c14_fa2_c, w_l1_c14_fa3_s, w_l1_c14_fa3_c;
    wire w_l1_c14_fa4_s, w_l1_c14_fa4_c, w_l1_c14_fa5_s, w_l1_c14_fa5_c;
    wire w_l1_c15_fa1_s, w_l1_c15_fa1_c, w_l1_c15_fa2_s, w_l1_c15_fa2_c;
    wire w_l1_c15_fa3_s, w_l1_c15_fa3_c, w_l1_c15_fa4_s, w_l1_c15_fa4_c;
    wire w_l1_c15_fa5_s, w_l1_c15_fa5_c, w_l1_c16_fa1_s, w_l1_c16_fa1_c;
    wire w_l1_c16_fa2_s, w_l1_c16_fa2_c, w_l1_c16_fa3_s, w_l1_c16_fa3_c;
    wire w_l1_c16_fa4_s, w_l1_c16_fa4_c, w_l1_c16_fa5_s, w_l1_c16_fa5_c;
    wire w_l1_c17_fa1_s, w_l1_c17_fa1_c, w_l1_c17_fa2_s, w_l1_c17_fa2_c;
    wire w_l1_c17_fa3_s, w_l1_c17_fa3_c, w_l1_c17_fa4_s, w_l1_c17_fa4_c;
    wire w_l1_c17_ha1_s, w_l1_c17_ha1_c, w_l1_c18_fa1_s, w_l1_c18_fa1_c;
    wire w_l1_c18_fa2_s, w_l1_c18_fa2_c, w_l1_c18_fa3_s, w_l1_c18_fa3_c;
    wire w_l1_c18_fa4_s, w_l1_c18_fa4_c, w_l1_c19_fa1_s, w_l1_c19_fa1_c;
    wire w_l1_c19_fa2_s, w_l1_c19_fa2_c, w_l1_c19_fa3_s, w_l1_c19_fa3_c;
    wire w_l1_c19_fa4_s, w_l1_c19_fa4_c, w_l1_c20_fa1_s, w_l1_c20_fa1_c;
    wire w_l1_c20_fa2_s, w_l1_c20_fa2_c, w_l1_c20_fa3_s, w_l1_c20_fa3_c;
    wire w_l1_c20_ha1_s, w_l1_c20_ha1_c, w_l1_c21_fa1_s, w_l1_c21_fa1_c;
    wire w_l1_c21_fa2_s, w_l1_c21_fa2_c, w_l1_c21_fa3_s, w_l1_c21_fa3_c;
    wire w_l1_c22_fa1_s, w_l1_c22_fa1_c, w_l1_c22_fa2_s, w_l1_c22_fa2_c;
    wire w_l1_c22_fa3_s, w_l1_c22_fa3_c, w_l1_c23_fa1_s, w_l1_c23_fa1_c;
    wire w_l1_c23_fa2_s, w_l1_c23_fa2_c, w_l1_c23_ha1_s, w_l1_c23_ha1_c;
    wire w_l1_c24_fa1_s, w_l1_c24_fa1_c, w_l1_c24_fa2_s, w_l1_c24_fa2_c;
    wire w_l1_c25_fa1_s, w_l1_c25_fa1_c, w_l1_c25_fa2_s, w_l1_c25_fa2_c;
    wire w_l1_c26_fa1_s, w_l1_c26_fa1_c, w_l1_c26_ha1_s, w_l1_c26_ha1_c;
    wire w_l1_c27_fa1_s, w_l1_c27_fa1_c, w_l1_c28_fa1_s, w_l1_c28_fa1_c;
    wire w_l1_c29_ha1_s, w_l1_c29_ha1_c, w_l2_c2_ha1_s, w_l2_c2_ha1_c;
    wire w_l2_c3_fa1_s, w_l2_c3_fa1_c, w_l2_c4_fa1_s, w_l2_c4_fa1_c;
    wire w_l2_c5_fa1_s, w_l2_c5_fa1_c, w_l2_c6_fa1_s, w_l2_c6_fa1_c;
    wire w_l2_c6_ha1_s, w_l2_c6_ha1_c, w_l2_c7_fa1_s, w_l2_c7_fa1_c;
    wire w_l2_c7_ha1_s, w_l2_c7_ha1_c, w_l2_c8_fa1_s, w_l2_c8_fa1_c;
    wire w_l2_c8_fa2_s, w_l2_c8_fa2_c, w_l2_c9_fa1_s, w_l2_c9_fa1_c;
    wire w_l2_c9_fa2_s, w_l2_c9_fa2_c, w_l2_c10_fa1_s, w_l2_c10_fa1_c;
    wire w_l2_c10_fa2_s, w_l2_c10_fa2_c, w_l2_c11_fa1_s, w_l2_c11_fa1_c;
    wire w_l2_c11_fa2_s, w_l2_c11_fa2_c, w_l2_c11_ha1_s, w_l2_c11_ha1_c;
    wire w_l2_c12_fa1_s, w_l2_c12_fa1_c, w_l2_c12_fa2_s, w_l2_c12_fa2_c;
    wire w_l2_c12_fa3_s, w_l2_c12_fa3_c, w_l2_c13_fa1_s, w_l2_c13_fa1_c;
    wire w_l2_c13_fa2_s, w_l2_c13_fa2_c, w_l2_c13_fa3_s, w_l2_c13_fa3_c;
    wire w_l2_c14_fa1_s, w_l2_c14_fa1_c, w_l2_c14_fa2_s, w_l2_c14_fa2_c;
    wire w_l2_c14_fa3_s, w_l2_c14_fa3_c, w_l2_c15_fa1_s, w_l2_c15_fa1_c;
    wire w_l2_c15_fa2_s, w_l2_c15_fa2_c, w_l2_c15_fa3_s, w_l2_c15_fa3_c;
    wire w_l2_c15_ha1_s, w_l2_c15_ha1_c, w_l2_c16_fa1_s, w_l2_c16_fa1_c;
    wire w_l2_c16_fa2_s, w_l2_c16_fa2_c, w_l2_c16_fa3_s, w_l2_c16_fa3_c;
    wire w_l2_c17_fa1_s, w_l2_c17_fa1_c, w_l2_c17_fa2_s, w_l2_c17_fa2_c;
    wire w_l2_c17_fa3_s, w_l2_c17_fa3_c, w_l2_c18_fa1_s, w_l2_c18_fa1_c;
    wire w_l2_c18_fa2_s, w_l2_c18_fa2_c, w_l2_c18_fa3_s, w_l2_c18_fa3_c;
    wire w_l2_c19_fa1_s, w_l2_c19_fa1_c, w_l2_c19_fa2_s, w_l2_c19_fa2_c;
    wire w_l2_c19_ha1_s, w_l2_c19_ha1_c, w_l2_c20_fa1_s, w_l2_c20_fa1_c;
    wire w_l2_c20_fa2_s, w_l2_c20_fa2_c, w_l2_c20_ha1_s, w_l2_c20_ha1_c;
    wire w_l2_c21_fa1_s, w_l2_c21_fa1_c, w_l2_c21_fa2_s, w_l2_c21_fa2_c;
    wire w_l2_c21_ha1_s, w_l2_c21_ha1_c, w_l2_c22_fa1_s, w_l2_c22_fa1_c;
    wire w_l2_c22_fa2_s, w_l2_c22_fa2_c, w_l2_c23_fa1_s, w_l2_c23_fa1_c;
    wire w_l2_c23_fa2_s, w_l2_c23_fa2_c, w_l2_c24_fa1_s, w_l2_c24_fa1_c;
    wire w_l2_c24_fa2_s, w_l2_c24_fa2_c, w_l2_c25_fa1_s, w_l2_c25_fa1_c;
    wire w_l2_c26_fa1_s, w_l2_c26_fa1_c, w_l2_c27_fa1_s, w_l2_c27_fa1_c;
    wire w_l2_c28_ha1_s, w_l2_c28_ha1_c, w_l2_c29_ha1_s, w_l2_c29_ha1_c;
    wire w_l2_c30_ha1_s, w_l2_c30_ha1_c;


    // =========================================================================
    // LEVEL 1 REDUCTION
    // Input : raw partial product bits (up to 16 bits in the widest column)
    // Output: reduced bits (up to 11 bits in the widest column)
    // =========================================================================

    // ---- Column 0: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 0: 1 bit (pp_row0[0]) passes through unchanged (no compressor needed)

    // ---- Column 1: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l1_c1_1 (.a(pp_row0[1]), .b(pp_row1[0]), .sum(w_l1_c1_ha1_s), .cout(w_l1_c1_ha1_c)); // col 1: HA#1 reduces remaining 2 bits -> 1 sum (stays col 1) + 1 carry (-> col 2)

    // ---- Column 2: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c2_1 (.a(pp_row0[2]), .b(pp_row1[1]), .cin(pp_row2[0]), .sum(w_l1_c2_fa1_s), .cout(w_l1_c2_fa1_c)); // col 2: FA#1 reduces 3 bits -> 1 sum (stays col 2) + 1 carry (-> col 3)

    // ---- Column 3: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c3_1 (.a(pp_row0[3]), .b(pp_row1[2]), .cin(pp_row2[1]), .sum(w_l1_c3_fa1_s), .cout(w_l1_c3_fa1_c)); // col 3: FA#1 reduces 3 bits -> 1 sum (stays col 3) + 1 carry (-> col 4)
    // col 3: 1 bit (pp_row3[0]) passes through unchanged (no compressor needed)

    // ---- Column 4: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c4_1 (.a(pp_row0[4]), .b(pp_row1[3]), .cin(pp_row2[2]), .sum(w_l1_c4_fa1_s), .cout(w_l1_c4_fa1_c)); // col 4: FA#1 reduces 3 bits -> 1 sum (stays col 4) + 1 carry (-> col 5)
    half_adder HA_l1_c4_1 (.a(pp_row3[1]), .b(pp_row4[0]), .sum(w_l1_c4_ha1_s), .cout(w_l1_c4_ha1_c)); // col 4: HA#1 reduces remaining 2 bits -> 1 sum (stays col 4) + 1 carry (-> col 5)

    // ---- Column 5: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c5_1 (.a(pp_row0[5]), .b(pp_row1[4]), .cin(pp_row2[3]), .sum(w_l1_c5_fa1_s), .cout(w_l1_c5_fa1_c)); // col 5: FA#1 reduces 3 bits -> 1 sum (stays col 5) + 1 carry (-> col 6)
    full_adder FA_l1_c5_2 (.a(pp_row3[2]), .b(pp_row4[1]), .cin(pp_row5[0]), .sum(w_l1_c5_fa2_s), .cout(w_l1_c5_fa2_c)); // col 5: FA#2 reduces 3 bits -> 1 sum (stays col 5) + 1 carry (-> col 6)

    // ---- Column 6: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c6_1 (.a(pp_row0[6]), .b(pp_row1[5]), .cin(pp_row2[4]), .sum(w_l1_c6_fa1_s), .cout(w_l1_c6_fa1_c)); // col 6: FA#1 reduces 3 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)
    full_adder FA_l1_c6_2 (.a(pp_row3[3]), .b(pp_row4[2]), .cin(pp_row5[1]), .sum(w_l1_c6_fa2_s), .cout(w_l1_c6_fa2_c)); // col 6: FA#2 reduces 3 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)
    // col 6: 1 bit (pp_row6[0]) passes through unchanged (no compressor needed)

    // ---- Column 7: 8 input bit(s) -> 2 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c7_1 (.a(pp_row0[7]), .b(pp_row1[6]), .cin(pp_row2[5]), .sum(w_l1_c7_fa1_s), .cout(w_l1_c7_fa1_c)); // col 7: FA#1 reduces 3 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)
    full_adder FA_l1_c7_2 (.a(pp_row3[4]), .b(pp_row4[3]), .cin(pp_row5[2]), .sum(w_l1_c7_fa2_s), .cout(w_l1_c7_fa2_c)); // col 7: FA#2 reduces 3 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)
    half_adder HA_l1_c7_1 (.a(pp_row6[1]), .b(pp_row7[0]), .sum(w_l1_c7_ha1_s), .cout(w_l1_c7_ha1_c)); // col 7: HA#1 reduces remaining 2 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)

    // ---- Column 8: 9 input bit(s) -> 3 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c8_1 (.a(pp_row0[8]), .b(pp_row1[7]), .cin(pp_row2[6]), .sum(w_l1_c8_fa1_s), .cout(w_l1_c8_fa1_c)); // col 8: FA#1 reduces 3 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)
    full_adder FA_l1_c8_2 (.a(pp_row3[5]), .b(pp_row4[4]), .cin(pp_row5[3]), .sum(w_l1_c8_fa2_s), .cout(w_l1_c8_fa2_c)); // col 8: FA#2 reduces 3 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)
    full_adder FA_l1_c8_3 (.a(pp_row6[2]), .b(pp_row7[1]), .cin(pp_row8[0]), .sum(w_l1_c8_fa3_s), .cout(w_l1_c8_fa3_c)); // col 8: FA#3 reduces 3 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)

    // ---- Column 9: 10 input bit(s) -> 3 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c9_1 (.a(pp_row0[9]), .b(pp_row1[8]), .cin(pp_row2[7]), .sum(w_l1_c9_fa1_s), .cout(w_l1_c9_fa1_c)); // col 9: FA#1 reduces 3 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)
    full_adder FA_l1_c9_2 (.a(pp_row3[6]), .b(pp_row4[5]), .cin(pp_row5[4]), .sum(w_l1_c9_fa2_s), .cout(w_l1_c9_fa2_c)); // col 9: FA#2 reduces 3 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)
    full_adder FA_l1_c9_3 (.a(pp_row6[3]), .b(pp_row7[2]), .cin(pp_row8[1]), .sum(w_l1_c9_fa3_s), .cout(w_l1_c9_fa3_c)); // col 9: FA#3 reduces 3 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)
    // col 9: 1 bit (pp_row9[0]) passes through unchanged (no compressor needed)

    // ---- Column 10: 11 input bit(s) -> 3 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c10_1 (.a(pp_row0[10]), .b(pp_row1[9]), .cin(pp_row2[8]), .sum(w_l1_c10_fa1_s), .cout(w_l1_c10_fa1_c)); // col 10: FA#1 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)
    full_adder FA_l1_c10_2 (.a(pp_row3[7]), .b(pp_row4[6]), .cin(pp_row5[5]), .sum(w_l1_c10_fa2_s), .cout(w_l1_c10_fa2_c)); // col 10: FA#2 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)
    full_adder FA_l1_c10_3 (.a(pp_row6[4]), .b(pp_row7[3]), .cin(pp_row8[2]), .sum(w_l1_c10_fa3_s), .cout(w_l1_c10_fa3_c)); // col 10: FA#3 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)
    half_adder HA_l1_c10_1 (.a(pp_row9[1]), .b(pp_row10[0]), .sum(w_l1_c10_ha1_s), .cout(w_l1_c10_ha1_c)); // col 10: HA#1 reduces remaining 2 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)

    // ---- Column 11: 12 input bit(s) -> 4 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c11_1 (.a(pp_row0[11]), .b(pp_row1[10]), .cin(pp_row2[9]), .sum(w_l1_c11_fa1_s), .cout(w_l1_c11_fa1_c)); // col 11: FA#1 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)
    full_adder FA_l1_c11_2 (.a(pp_row3[8]), .b(pp_row4[7]), .cin(pp_row5[6]), .sum(w_l1_c11_fa2_s), .cout(w_l1_c11_fa2_c)); // col 11: FA#2 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)
    full_adder FA_l1_c11_3 (.a(pp_row6[5]), .b(pp_row7[4]), .cin(pp_row8[3]), .sum(w_l1_c11_fa3_s), .cout(w_l1_c11_fa3_c)); // col 11: FA#3 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)
    full_adder FA_l1_c11_4 (.a(pp_row9[2]), .b(pp_row10[1]), .cin(pp_row11[0]), .sum(w_l1_c11_fa4_s), .cout(w_l1_c11_fa4_c)); // col 11: FA#4 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)

    // ---- Column 12: 13 input bit(s) -> 4 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c12_1 (.a(pp_row0[12]), .b(pp_row1[11]), .cin(pp_row2[10]), .sum(w_l1_c12_fa1_s), .cout(w_l1_c12_fa1_c)); // col 12: FA#1 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    full_adder FA_l1_c12_2 (.a(pp_row3[9]), .b(pp_row4[8]), .cin(pp_row5[7]), .sum(w_l1_c12_fa2_s), .cout(w_l1_c12_fa2_c)); // col 12: FA#2 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    full_adder FA_l1_c12_3 (.a(pp_row6[6]), .b(pp_row7[5]), .cin(pp_row8[4]), .sum(w_l1_c12_fa3_s), .cout(w_l1_c12_fa3_c)); // col 12: FA#3 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    full_adder FA_l1_c12_4 (.a(pp_row9[3]), .b(pp_row10[2]), .cin(pp_row11[1]), .sum(w_l1_c12_fa4_s), .cout(w_l1_c12_fa4_c)); // col 12: FA#4 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    // col 12: 1 bit (pp_row12[0]) passes through unchanged (no compressor needed)

    // ---- Column 13: 14 input bit(s) -> 4 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c13_1 (.a(pp_row0[13]), .b(pp_row1[12]), .cin(pp_row2[11]), .sum(w_l1_c13_fa1_s), .cout(w_l1_c13_fa1_c)); // col 13: FA#1 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    full_adder FA_l1_c13_2 (.a(pp_row3[10]), .b(pp_row4[9]), .cin(pp_row5[8]), .sum(w_l1_c13_fa2_s), .cout(w_l1_c13_fa2_c)); // col 13: FA#2 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    full_adder FA_l1_c13_3 (.a(pp_row6[7]), .b(pp_row7[6]), .cin(pp_row8[5]), .sum(w_l1_c13_fa3_s), .cout(w_l1_c13_fa3_c)); // col 13: FA#3 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    full_adder FA_l1_c13_4 (.a(pp_row9[4]), .b(pp_row10[3]), .cin(pp_row11[2]), .sum(w_l1_c13_fa4_s), .cout(w_l1_c13_fa4_c)); // col 13: FA#4 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    half_adder HA_l1_c13_1 (.a(pp_row12[1]), .b(pp_row13[0]), .sum(w_l1_c13_ha1_s), .cout(w_l1_c13_ha1_c)); // col 13: HA#1 reduces remaining 2 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)

    // ---- Column 14: 15 input bit(s) -> 5 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c14_1 (.a(pp_row0[14]), .b(pp_row1[13]), .cin(pp_row2[12]), .sum(w_l1_c14_fa1_s), .cout(w_l1_c14_fa1_c)); // col 14: FA#1 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    full_adder FA_l1_c14_2 (.a(pp_row3[11]), .b(pp_row4[10]), .cin(pp_row5[9]), .sum(w_l1_c14_fa2_s), .cout(w_l1_c14_fa2_c)); // col 14: FA#2 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    full_adder FA_l1_c14_3 (.a(pp_row6[8]), .b(pp_row7[7]), .cin(pp_row8[6]), .sum(w_l1_c14_fa3_s), .cout(w_l1_c14_fa3_c)); // col 14: FA#3 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    full_adder FA_l1_c14_4 (.a(pp_row9[5]), .b(pp_row10[4]), .cin(pp_row11[3]), .sum(w_l1_c14_fa4_s), .cout(w_l1_c14_fa4_c)); // col 14: FA#4 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    full_adder FA_l1_c14_5 (.a(pp_row12[2]), .b(pp_row13[1]), .cin(pp_row14[0]), .sum(w_l1_c14_fa5_s), .cout(w_l1_c14_fa5_c)); // col 14: FA#5 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)

    // ---- Column 15: 16 input bit(s) -> 5 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c15_1 (.a(pp_row0[15]), .b(pp_row1[14]), .cin(pp_row2[13]), .sum(w_l1_c15_fa1_s), .cout(w_l1_c15_fa1_c)); // col 15: FA#1 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    full_adder FA_l1_c15_2 (.a(pp_row3[12]), .b(pp_row4[11]), .cin(pp_row5[10]), .sum(w_l1_c15_fa2_s), .cout(w_l1_c15_fa2_c)); // col 15: FA#2 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    full_adder FA_l1_c15_3 (.a(pp_row6[9]), .b(pp_row7[8]), .cin(pp_row8[7]), .sum(w_l1_c15_fa3_s), .cout(w_l1_c15_fa3_c)); // col 15: FA#3 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    full_adder FA_l1_c15_4 (.a(pp_row9[6]), .b(pp_row10[5]), .cin(pp_row11[4]), .sum(w_l1_c15_fa4_s), .cout(w_l1_c15_fa4_c)); // col 15: FA#4 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    full_adder FA_l1_c15_5 (.a(pp_row12[3]), .b(pp_row13[2]), .cin(pp_row14[1]), .sum(w_l1_c15_fa5_s), .cout(w_l1_c15_fa5_c)); // col 15: FA#5 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    // col 15: 1 bit (pp_row15[0]) passes through unchanged (no compressor needed)

    // ---- Column 16: 15 input bit(s) -> 5 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c16_1 (.a(pp_row1[15]), .b(pp_row2[14]), .cin(pp_row3[13]), .sum(w_l1_c16_fa1_s), .cout(w_l1_c16_fa1_c)); // col 16: FA#1 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    full_adder FA_l1_c16_2 (.a(pp_row4[12]), .b(pp_row5[11]), .cin(pp_row6[10]), .sum(w_l1_c16_fa2_s), .cout(w_l1_c16_fa2_c)); // col 16: FA#2 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    full_adder FA_l1_c16_3 (.a(pp_row7[9]), .b(pp_row8[8]), .cin(pp_row9[7]), .sum(w_l1_c16_fa3_s), .cout(w_l1_c16_fa3_c)); // col 16: FA#3 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    full_adder FA_l1_c16_4 (.a(pp_row10[6]), .b(pp_row11[5]), .cin(pp_row12[4]), .sum(w_l1_c16_fa4_s), .cout(w_l1_c16_fa4_c)); // col 16: FA#4 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    full_adder FA_l1_c16_5 (.a(pp_row13[3]), .b(pp_row14[2]), .cin(pp_row15[1]), .sum(w_l1_c16_fa5_s), .cout(w_l1_c16_fa5_c)); // col 16: FA#5 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)

    // ---- Column 17: 14 input bit(s) -> 4 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c17_1 (.a(pp_row2[15]), .b(pp_row3[14]), .cin(pp_row4[13]), .sum(w_l1_c17_fa1_s), .cout(w_l1_c17_fa1_c)); // col 17: FA#1 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    full_adder FA_l1_c17_2 (.a(pp_row5[12]), .b(pp_row6[11]), .cin(pp_row7[10]), .sum(w_l1_c17_fa2_s), .cout(w_l1_c17_fa2_c)); // col 17: FA#2 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    full_adder FA_l1_c17_3 (.a(pp_row8[9]), .b(pp_row9[8]), .cin(pp_row10[7]), .sum(w_l1_c17_fa3_s), .cout(w_l1_c17_fa3_c)); // col 17: FA#3 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    full_adder FA_l1_c17_4 (.a(pp_row11[6]), .b(pp_row12[5]), .cin(pp_row13[4]), .sum(w_l1_c17_fa4_s), .cout(w_l1_c17_fa4_c)); // col 17: FA#4 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    half_adder HA_l1_c17_1 (.a(pp_row14[3]), .b(pp_row15[2]), .sum(w_l1_c17_ha1_s), .cout(w_l1_c17_ha1_c)); // col 17: HA#1 reduces remaining 2 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)

    // ---- Column 18: 13 input bit(s) -> 4 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c18_1 (.a(pp_row3[15]), .b(pp_row4[14]), .cin(pp_row5[13]), .sum(w_l1_c18_fa1_s), .cout(w_l1_c18_fa1_c)); // col 18: FA#1 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    full_adder FA_l1_c18_2 (.a(pp_row6[12]), .b(pp_row7[11]), .cin(pp_row8[10]), .sum(w_l1_c18_fa2_s), .cout(w_l1_c18_fa2_c)); // col 18: FA#2 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    full_adder FA_l1_c18_3 (.a(pp_row9[9]), .b(pp_row10[8]), .cin(pp_row11[7]), .sum(w_l1_c18_fa3_s), .cout(w_l1_c18_fa3_c)); // col 18: FA#3 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    full_adder FA_l1_c18_4 (.a(pp_row12[6]), .b(pp_row13[5]), .cin(pp_row14[4]), .sum(w_l1_c18_fa4_s), .cout(w_l1_c18_fa4_c)); // col 18: FA#4 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    // col 18: 1 bit (pp_row15[3]) passes through unchanged (no compressor needed)

    // ---- Column 19: 12 input bit(s) -> 4 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c19_1 (.a(pp_row4[15]), .b(pp_row5[14]), .cin(pp_row6[13]), .sum(w_l1_c19_fa1_s), .cout(w_l1_c19_fa1_c)); // col 19: FA#1 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    full_adder FA_l1_c19_2 (.a(pp_row7[12]), .b(pp_row8[11]), .cin(pp_row9[10]), .sum(w_l1_c19_fa2_s), .cout(w_l1_c19_fa2_c)); // col 19: FA#2 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    full_adder FA_l1_c19_3 (.a(pp_row10[9]), .b(pp_row11[8]), .cin(pp_row12[7]), .sum(w_l1_c19_fa3_s), .cout(w_l1_c19_fa3_c)); // col 19: FA#3 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    full_adder FA_l1_c19_4 (.a(pp_row13[6]), .b(pp_row14[5]), .cin(pp_row15[4]), .sum(w_l1_c19_fa4_s), .cout(w_l1_c19_fa4_c)); // col 19: FA#4 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)

    // ---- Column 20: 11 input bit(s) -> 3 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c20_1 (.a(pp_row5[15]), .b(pp_row6[14]), .cin(pp_row7[13]), .sum(w_l1_c20_fa1_s), .cout(w_l1_c20_fa1_c)); // col 20: FA#1 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)
    full_adder FA_l1_c20_2 (.a(pp_row8[12]), .b(pp_row9[11]), .cin(pp_row10[10]), .sum(w_l1_c20_fa2_s), .cout(w_l1_c20_fa2_c)); // col 20: FA#2 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)
    full_adder FA_l1_c20_3 (.a(pp_row11[9]), .b(pp_row12[8]), .cin(pp_row13[7]), .sum(w_l1_c20_fa3_s), .cout(w_l1_c20_fa3_c)); // col 20: FA#3 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)
    half_adder HA_l1_c20_1 (.a(pp_row14[6]), .b(pp_row15[5]), .sum(w_l1_c20_ha1_s), .cout(w_l1_c20_ha1_c)); // col 20: HA#1 reduces remaining 2 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)

    // ---- Column 21: 10 input bit(s) -> 3 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c21_1 (.a(pp_row6[15]), .b(pp_row7[14]), .cin(pp_row8[13]), .sum(w_l1_c21_fa1_s), .cout(w_l1_c21_fa1_c)); // col 21: FA#1 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)
    full_adder FA_l1_c21_2 (.a(pp_row9[12]), .b(pp_row10[11]), .cin(pp_row11[10]), .sum(w_l1_c21_fa2_s), .cout(w_l1_c21_fa2_c)); // col 21: FA#2 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)
    full_adder FA_l1_c21_3 (.a(pp_row12[9]), .b(pp_row13[8]), .cin(pp_row14[7]), .sum(w_l1_c21_fa3_s), .cout(w_l1_c21_fa3_c)); // col 21: FA#3 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)
    // col 21: 1 bit (pp_row15[6]) passes through unchanged (no compressor needed)

    // ---- Column 22: 9 input bit(s) -> 3 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c22_1 (.a(pp_row7[15]), .b(pp_row8[14]), .cin(pp_row9[13]), .sum(w_l1_c22_fa1_s), .cout(w_l1_c22_fa1_c)); // col 22: FA#1 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)
    full_adder FA_l1_c22_2 (.a(pp_row10[12]), .b(pp_row11[11]), .cin(pp_row12[10]), .sum(w_l1_c22_fa2_s), .cout(w_l1_c22_fa2_c)); // col 22: FA#2 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)
    full_adder FA_l1_c22_3 (.a(pp_row13[9]), .b(pp_row14[8]), .cin(pp_row15[7]), .sum(w_l1_c22_fa3_s), .cout(w_l1_c22_fa3_c)); // col 22: FA#3 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)

    // ---- Column 23: 8 input bit(s) -> 2 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c23_1 (.a(pp_row8[15]), .b(pp_row9[14]), .cin(pp_row10[13]), .sum(w_l1_c23_fa1_s), .cout(w_l1_c23_fa1_c)); // col 23: FA#1 reduces 3 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)
    full_adder FA_l1_c23_2 (.a(pp_row11[12]), .b(pp_row12[11]), .cin(pp_row13[10]), .sum(w_l1_c23_fa2_s), .cout(w_l1_c23_fa2_c)); // col 23: FA#2 reduces 3 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)
    half_adder HA_l1_c23_1 (.a(pp_row14[9]), .b(pp_row15[8]), .sum(w_l1_c23_ha1_s), .cout(w_l1_c23_ha1_c)); // col 23: HA#1 reduces remaining 2 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)

    // ---- Column 24: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c24_1 (.a(pp_row9[15]), .b(pp_row10[14]), .cin(pp_row11[13]), .sum(w_l1_c24_fa1_s), .cout(w_l1_c24_fa1_c)); // col 24: FA#1 reduces 3 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)
    full_adder FA_l1_c24_2 (.a(pp_row12[12]), .b(pp_row13[11]), .cin(pp_row14[10]), .sum(w_l1_c24_fa2_s), .cout(w_l1_c24_fa2_c)); // col 24: FA#2 reduces 3 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)
    // col 24: 1 bit (pp_row15[9]) passes through unchanged (no compressor needed)

    // ---- Column 25: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c25_1 (.a(pp_row10[15]), .b(pp_row11[14]), .cin(pp_row12[13]), .sum(w_l1_c25_fa1_s), .cout(w_l1_c25_fa1_c)); // col 25: FA#1 reduces 3 bits -> 1 sum (stays col 25) + 1 carry (-> col 26)
    full_adder FA_l1_c25_2 (.a(pp_row13[12]), .b(pp_row14[11]), .cin(pp_row15[10]), .sum(w_l1_c25_fa2_s), .cout(w_l1_c25_fa2_c)); // col 25: FA#2 reduces 3 bits -> 1 sum (stays col 25) + 1 carry (-> col 26)

    // ---- Column 26: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l1_c26_1 (.a(pp_row11[15]), .b(pp_row12[14]), .cin(pp_row13[13]), .sum(w_l1_c26_fa1_s), .cout(w_l1_c26_fa1_c)); // col 26: FA#1 reduces 3 bits -> 1 sum (stays col 26) + 1 carry (-> col 27)
    half_adder HA_l1_c26_1 (.a(pp_row14[12]), .b(pp_row15[11]), .sum(w_l1_c26_ha1_s), .cout(w_l1_c26_ha1_c)); // col 26: HA#1 reduces remaining 2 bits -> 1 sum (stays col 26) + 1 carry (-> col 27)

    // ---- Column 27: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l1_c27_1 (.a(pp_row12[15]), .b(pp_row13[14]), .cin(pp_row14[13]), .sum(w_l1_c27_fa1_s), .cout(w_l1_c27_fa1_c)); // col 27: FA#1 reduces 3 bits -> 1 sum (stays col 27) + 1 carry (-> col 28)
    // col 27: 1 bit (pp_row15[12]) passes through unchanged (no compressor needed)

    // ---- Column 28: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l1_c28_1 (.a(pp_row13[15]), .b(pp_row14[14]), .cin(pp_row15[13]), .sum(w_l1_c28_fa1_s), .cout(w_l1_c28_fa1_c)); // col 28: FA#1 reduces 3 bits -> 1 sum (stays col 28) + 1 carry (-> col 29)

    // ---- Column 29: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l1_c29_1 (.a(pp_row14[15]), .b(pp_row15[14]), .sum(w_l1_c29_ha1_s), .cout(w_l1_c29_ha1_c)); // col 29: HA#1 reduces remaining 2 bits -> 1 sum (stays col 29) + 1 carry (-> col 30)

    // ---- Column 30: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 30: 1 bit (pp_row15[15]) passes through unchanged (no compressor needed)


    // =========================================================================
    // LEVEL 2 REDUCTION
    // Input : Level 1 outputs (up to 11 bits in the widest column)
    // Output: reduced bits (up to 8 bits in the widest column)
    // =========================================================================

    // ---- Column 0: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 0: 1 bit (pp_row0[0]) passes through unchanged (no compressor needed)

    // ---- Column 1: 1 input bit(s) -> 0 FA, 0 HA, 1 passthrough ----
    // col 1: 1 bit (w_l1_c1_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 2: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l2_c2_1 (.a(w_l1_c1_ha1_c), .b(w_l1_c2_fa1_s), .sum(w_l2_c2_ha1_s), .cout(w_l2_c2_ha1_c)); // col 2: HA#1 reduces remaining 2 bits -> 1 sum (stays col 2) + 1 carry (-> col 3)

    // ---- Column 3: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c3_1 (.a(w_l1_c2_fa1_c), .b(w_l1_c3_fa1_s), .cin(pp_row3[0]), .sum(w_l2_c3_fa1_s), .cout(w_l2_c3_fa1_c)); // col 3: FA#1 reduces 3 bits -> 1 sum (stays col 3) + 1 carry (-> col 4)

    // ---- Column 4: 3 input bit(s) -> 1 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c4_1 (.a(w_l1_c3_fa1_c), .b(w_l1_c4_fa1_s), .cin(w_l1_c4_ha1_s), .sum(w_l2_c4_fa1_s), .cout(w_l2_c4_fa1_c)); // col 4: FA#1 reduces 3 bits -> 1 sum (stays col 4) + 1 carry (-> col 5)

    // ---- Column 5: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c5_1 (.a(w_l1_c4_fa1_c), .b(w_l1_c4_ha1_c), .cin(w_l1_c5_fa1_s), .sum(w_l2_c5_fa1_s), .cout(w_l2_c5_fa1_c)); // col 5: FA#1 reduces 3 bits -> 1 sum (stays col 5) + 1 carry (-> col 6)
    // col 5: 1 bit (w_l1_c5_fa2_s) passes through unchanged (no compressor needed)

    // ---- Column 6: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l2_c6_1 (.a(w_l1_c5_fa1_c), .b(w_l1_c5_fa2_c), .cin(w_l1_c6_fa1_s), .sum(w_l2_c6_fa1_s), .cout(w_l2_c6_fa1_c)); // col 6: FA#1 reduces 3 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)
    half_adder HA_l2_c6_1 (.a(w_l1_c6_fa2_s), .b(pp_row6[0]), .sum(w_l2_c6_ha1_s), .cout(w_l2_c6_ha1_c)); // col 6: HA#1 reduces remaining 2 bits -> 1 sum (stays col 6) + 1 carry (-> col 7)

    // ---- Column 7: 5 input bit(s) -> 1 FA, 1 HA, 0 passthrough ----
    full_adder FA_l2_c7_1 (.a(w_l1_c6_fa1_c), .b(w_l1_c6_fa2_c), .cin(w_l1_c7_fa1_s), .sum(w_l2_c7_fa1_s), .cout(w_l2_c7_fa1_c)); // col 7: FA#1 reduces 3 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)
    half_adder HA_l2_c7_1 (.a(w_l1_c7_fa2_s), .b(w_l1_c7_ha1_s), .sum(w_l2_c7_ha1_s), .cout(w_l2_c7_ha1_c)); // col 7: HA#1 reduces remaining 2 bits -> 1 sum (stays col 7) + 1 carry (-> col 8)

    // ---- Column 8: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c8_1 (.a(w_l1_c7_fa1_c), .b(w_l1_c7_fa2_c), .cin(w_l1_c7_ha1_c), .sum(w_l2_c8_fa1_s), .cout(w_l2_c8_fa1_c)); // col 8: FA#1 reduces 3 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)
    full_adder FA_l2_c8_2 (.a(w_l1_c8_fa1_s), .b(w_l1_c8_fa2_s), .cin(w_l1_c8_fa3_s), .sum(w_l2_c8_fa2_s), .cout(w_l2_c8_fa2_c)); // col 8: FA#2 reduces 3 bits -> 1 sum (stays col 8) + 1 carry (-> col 9)

    // ---- Column 9: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c9_1 (.a(w_l1_c8_fa1_c), .b(w_l1_c8_fa2_c), .cin(w_l1_c8_fa3_c), .sum(w_l2_c9_fa1_s), .cout(w_l2_c9_fa1_c)); // col 9: FA#1 reduces 3 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)
    full_adder FA_l2_c9_2 (.a(w_l1_c9_fa1_s), .b(w_l1_c9_fa2_s), .cin(w_l1_c9_fa3_s), .sum(w_l2_c9_fa2_s), .cout(w_l2_c9_fa2_c)); // col 9: FA#2 reduces 3 bits -> 1 sum (stays col 9) + 1 carry (-> col 10)
    // col 9: 1 bit (pp_row9[0]) passes through unchanged (no compressor needed)

    // ---- Column 10: 7 input bit(s) -> 2 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c10_1 (.a(w_l1_c9_fa1_c), .b(w_l1_c9_fa2_c), .cin(w_l1_c9_fa3_c), .sum(w_l2_c10_fa1_s), .cout(w_l2_c10_fa1_c)); // col 10: FA#1 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)
    full_adder FA_l2_c10_2 (.a(w_l1_c10_fa1_s), .b(w_l1_c10_fa2_s), .cin(w_l1_c10_fa3_s), .sum(w_l2_c10_fa2_s), .cout(w_l2_c10_fa2_c)); // col 10: FA#2 reduces 3 bits -> 1 sum (stays col 10) + 1 carry (-> col 11)
    // col 10: 1 bit (w_l1_c10_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 11: 8 input bit(s) -> 2 FA, 1 HA, 0 passthrough ----
    full_adder FA_l2_c11_1 (.a(w_l1_c10_fa1_c), .b(w_l1_c10_fa2_c), .cin(w_l1_c10_fa3_c), .sum(w_l2_c11_fa1_s), .cout(w_l2_c11_fa1_c)); // col 11: FA#1 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)
    full_adder FA_l2_c11_2 (.a(w_l1_c10_ha1_c), .b(w_l1_c11_fa1_s), .cin(w_l1_c11_fa2_s), .sum(w_l2_c11_fa2_s), .cout(w_l2_c11_fa2_c)); // col 11: FA#2 reduces 3 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)
    half_adder HA_l2_c11_1 (.a(w_l1_c11_fa3_s), .b(w_l1_c11_fa4_s), .sum(w_l2_c11_ha1_s), .cout(w_l2_c11_ha1_c)); // col 11: HA#1 reduces remaining 2 bits -> 1 sum (stays col 11) + 1 carry (-> col 12)

    // ---- Column 12: 9 input bit(s) -> 3 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c12_1 (.a(w_l1_c11_fa1_c), .b(w_l1_c11_fa2_c), .cin(w_l1_c11_fa3_c), .sum(w_l2_c12_fa1_s), .cout(w_l2_c12_fa1_c)); // col 12: FA#1 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    full_adder FA_l2_c12_2 (.a(w_l1_c11_fa4_c), .b(w_l1_c12_fa1_s), .cin(w_l1_c12_fa2_s), .sum(w_l2_c12_fa2_s), .cout(w_l2_c12_fa2_c)); // col 12: FA#2 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)
    full_adder FA_l2_c12_3 (.a(w_l1_c12_fa3_s), .b(w_l1_c12_fa4_s), .cin(pp_row12[0]), .sum(w_l2_c12_fa3_s), .cout(w_l2_c12_fa3_c)); // col 12: FA#3 reduces 3 bits -> 1 sum (stays col 12) + 1 carry (-> col 13)

    // ---- Column 13: 9 input bit(s) -> 3 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c13_1 (.a(w_l1_c12_fa1_c), .b(w_l1_c12_fa2_c), .cin(w_l1_c12_fa3_c), .sum(w_l2_c13_fa1_s), .cout(w_l2_c13_fa1_c)); // col 13: FA#1 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    full_adder FA_l2_c13_2 (.a(w_l1_c12_fa4_c), .b(w_l1_c13_fa1_s), .cin(w_l1_c13_fa2_s), .sum(w_l2_c13_fa2_s), .cout(w_l2_c13_fa2_c)); // col 13: FA#2 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)
    full_adder FA_l2_c13_3 (.a(w_l1_c13_fa3_s), .b(w_l1_c13_fa4_s), .cin(w_l1_c13_ha1_s), .sum(w_l2_c13_fa3_s), .cout(w_l2_c13_fa3_c)); // col 13: FA#3 reduces 3 bits -> 1 sum (stays col 13) + 1 carry (-> col 14)

    // ---- Column 14: 10 input bit(s) -> 3 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c14_1 (.a(w_l1_c13_fa1_c), .b(w_l1_c13_fa2_c), .cin(w_l1_c13_fa3_c), .sum(w_l2_c14_fa1_s), .cout(w_l2_c14_fa1_c)); // col 14: FA#1 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    full_adder FA_l2_c14_2 (.a(w_l1_c13_fa4_c), .b(w_l1_c13_ha1_c), .cin(w_l1_c14_fa1_s), .sum(w_l2_c14_fa2_s), .cout(w_l2_c14_fa2_c)); // col 14: FA#2 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    full_adder FA_l2_c14_3 (.a(w_l1_c14_fa2_s), .b(w_l1_c14_fa3_s), .cin(w_l1_c14_fa4_s), .sum(w_l2_c14_fa3_s), .cout(w_l2_c14_fa3_c)); // col 14: FA#3 reduces 3 bits -> 1 sum (stays col 14) + 1 carry (-> col 15)
    // col 14: 1 bit (w_l1_c14_fa5_s) passes through unchanged (no compressor needed)

    // ---- Column 15: 11 input bit(s) -> 3 FA, 1 HA, 0 passthrough ----
    full_adder FA_l2_c15_1 (.a(w_l1_c14_fa1_c), .b(w_l1_c14_fa2_c), .cin(w_l1_c14_fa3_c), .sum(w_l2_c15_fa1_s), .cout(w_l2_c15_fa1_c)); // col 15: FA#1 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    full_adder FA_l2_c15_2 (.a(w_l1_c14_fa4_c), .b(w_l1_c14_fa5_c), .cin(w_l1_c15_fa1_s), .sum(w_l2_c15_fa2_s), .cout(w_l2_c15_fa2_c)); // col 15: FA#2 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    full_adder FA_l2_c15_3 (.a(w_l1_c15_fa2_s), .b(w_l1_c15_fa3_s), .cin(w_l1_c15_fa4_s), .sum(w_l2_c15_fa3_s), .cout(w_l2_c15_fa3_c)); // col 15: FA#3 reduces 3 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)
    half_adder HA_l2_c15_1 (.a(w_l1_c15_fa5_s), .b(pp_row15[0]), .sum(w_l2_c15_ha1_s), .cout(w_l2_c15_ha1_c)); // col 15: HA#1 reduces remaining 2 bits -> 1 sum (stays col 15) + 1 carry (-> col 16)

    // ---- Column 16: 10 input bit(s) -> 3 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c16_1 (.a(w_l1_c15_fa1_c), .b(w_l1_c15_fa2_c), .cin(w_l1_c15_fa3_c), .sum(w_l2_c16_fa1_s), .cout(w_l2_c16_fa1_c)); // col 16: FA#1 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    full_adder FA_l2_c16_2 (.a(w_l1_c15_fa4_c), .b(w_l1_c15_fa5_c), .cin(w_l1_c16_fa1_s), .sum(w_l2_c16_fa2_s), .cout(w_l2_c16_fa2_c)); // col 16: FA#2 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    full_adder FA_l2_c16_3 (.a(w_l1_c16_fa2_s), .b(w_l1_c16_fa3_s), .cin(w_l1_c16_fa4_s), .sum(w_l2_c16_fa3_s), .cout(w_l2_c16_fa3_c)); // col 16: FA#3 reduces 3 bits -> 1 sum (stays col 16) + 1 carry (-> col 17)
    // col 16: 1 bit (w_l1_c16_fa5_s) passes through unchanged (no compressor needed)

    // ---- Column 17: 10 input bit(s) -> 3 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c17_1 (.a(w_l1_c16_fa1_c), .b(w_l1_c16_fa2_c), .cin(w_l1_c16_fa3_c), .sum(w_l2_c17_fa1_s), .cout(w_l2_c17_fa1_c)); // col 17: FA#1 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    full_adder FA_l2_c17_2 (.a(w_l1_c16_fa4_c), .b(w_l1_c16_fa5_c), .cin(w_l1_c17_fa1_s), .sum(w_l2_c17_fa2_s), .cout(w_l2_c17_fa2_c)); // col 17: FA#2 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    full_adder FA_l2_c17_3 (.a(w_l1_c17_fa2_s), .b(w_l1_c17_fa3_s), .cin(w_l1_c17_fa4_s), .sum(w_l2_c17_fa3_s), .cout(w_l2_c17_fa3_c)); // col 17: FA#3 reduces 3 bits -> 1 sum (stays col 17) + 1 carry (-> col 18)
    // col 17: 1 bit (w_l1_c17_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 18: 10 input bit(s) -> 3 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c18_1 (.a(w_l1_c17_fa1_c), .b(w_l1_c17_fa2_c), .cin(w_l1_c17_fa3_c), .sum(w_l2_c18_fa1_s), .cout(w_l2_c18_fa1_c)); // col 18: FA#1 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    full_adder FA_l2_c18_2 (.a(w_l1_c17_fa4_c), .b(w_l1_c17_ha1_c), .cin(w_l1_c18_fa1_s), .sum(w_l2_c18_fa2_s), .cout(w_l2_c18_fa2_c)); // col 18: FA#2 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    full_adder FA_l2_c18_3 (.a(w_l1_c18_fa2_s), .b(w_l1_c18_fa3_s), .cin(w_l1_c18_fa4_s), .sum(w_l2_c18_fa3_s), .cout(w_l2_c18_fa3_c)); // col 18: FA#3 reduces 3 bits -> 1 sum (stays col 18) + 1 carry (-> col 19)
    // col 18: 1 bit (pp_row15[3]) passes through unchanged (no compressor needed)

    // ---- Column 19: 8 input bit(s) -> 2 FA, 1 HA, 0 passthrough ----
    full_adder FA_l2_c19_1 (.a(w_l1_c18_fa1_c), .b(w_l1_c18_fa2_c), .cin(w_l1_c18_fa3_c), .sum(w_l2_c19_fa1_s), .cout(w_l2_c19_fa1_c)); // col 19: FA#1 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    full_adder FA_l2_c19_2 (.a(w_l1_c18_fa4_c), .b(w_l1_c19_fa1_s), .cin(w_l1_c19_fa2_s), .sum(w_l2_c19_fa2_s), .cout(w_l2_c19_fa2_c)); // col 19: FA#2 reduces 3 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)
    half_adder HA_l2_c19_1 (.a(w_l1_c19_fa3_s), .b(w_l1_c19_fa4_s), .sum(w_l2_c19_ha1_s), .cout(w_l2_c19_ha1_c)); // col 19: HA#1 reduces remaining 2 bits -> 1 sum (stays col 19) + 1 carry (-> col 20)

    // ---- Column 20: 8 input bit(s) -> 2 FA, 1 HA, 0 passthrough ----
    full_adder FA_l2_c20_1 (.a(w_l1_c19_fa1_c), .b(w_l1_c19_fa2_c), .cin(w_l1_c19_fa3_c), .sum(w_l2_c20_fa1_s), .cout(w_l2_c20_fa1_c)); // col 20: FA#1 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)
    full_adder FA_l2_c20_2 (.a(w_l1_c19_fa4_c), .b(w_l1_c20_fa1_s), .cin(w_l1_c20_fa2_s), .sum(w_l2_c20_fa2_s), .cout(w_l2_c20_fa2_c)); // col 20: FA#2 reduces 3 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)
    half_adder HA_l2_c20_1 (.a(w_l1_c20_fa3_s), .b(w_l1_c20_ha1_s), .sum(w_l2_c20_ha1_s), .cout(w_l2_c20_ha1_c)); // col 20: HA#1 reduces remaining 2 bits -> 1 sum (stays col 20) + 1 carry (-> col 21)

    // ---- Column 21: 8 input bit(s) -> 2 FA, 1 HA, 0 passthrough ----
    full_adder FA_l2_c21_1 (.a(w_l1_c20_fa1_c), .b(w_l1_c20_fa2_c), .cin(w_l1_c20_fa3_c), .sum(w_l2_c21_fa1_s), .cout(w_l2_c21_fa1_c)); // col 21: FA#1 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)
    full_adder FA_l2_c21_2 (.a(w_l1_c20_ha1_c), .b(w_l1_c21_fa1_s), .cin(w_l1_c21_fa2_s), .sum(w_l2_c21_fa2_s), .cout(w_l2_c21_fa2_c)); // col 21: FA#2 reduces 3 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)
    half_adder HA_l2_c21_1 (.a(w_l1_c21_fa3_s), .b(pp_row15[6]), .sum(w_l2_c21_ha1_s), .cout(w_l2_c21_ha1_c)); // col 21: HA#1 reduces remaining 2 bits -> 1 sum (stays col 21) + 1 carry (-> col 22)

    // ---- Column 22: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c22_1 (.a(w_l1_c21_fa1_c), .b(w_l1_c21_fa2_c), .cin(w_l1_c21_fa3_c), .sum(w_l2_c22_fa1_s), .cout(w_l2_c22_fa1_c)); // col 22: FA#1 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)
    full_adder FA_l2_c22_2 (.a(w_l1_c22_fa1_s), .b(w_l1_c22_fa2_s), .cin(w_l1_c22_fa3_s), .sum(w_l2_c22_fa2_s), .cout(w_l2_c22_fa2_c)); // col 22: FA#2 reduces 3 bits -> 1 sum (stays col 22) + 1 carry (-> col 23)

    // ---- Column 23: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c23_1 (.a(w_l1_c22_fa1_c), .b(w_l1_c22_fa2_c), .cin(w_l1_c22_fa3_c), .sum(w_l2_c23_fa1_s), .cout(w_l2_c23_fa1_c)); // col 23: FA#1 reduces 3 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)
    full_adder FA_l2_c23_2 (.a(w_l1_c23_fa1_s), .b(w_l1_c23_fa2_s), .cin(w_l1_c23_ha1_s), .sum(w_l2_c23_fa2_s), .cout(w_l2_c23_fa2_c)); // col 23: FA#2 reduces 3 bits -> 1 sum (stays col 23) + 1 carry (-> col 24)

    // ---- Column 24: 6 input bit(s) -> 2 FA, 0 HA, 0 passthrough ----
    full_adder FA_l2_c24_1 (.a(w_l1_c23_fa1_c), .b(w_l1_c23_fa2_c), .cin(w_l1_c23_ha1_c), .sum(w_l2_c24_fa1_s), .cout(w_l2_c24_fa1_c)); // col 24: FA#1 reduces 3 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)
    full_adder FA_l2_c24_2 (.a(w_l1_c24_fa1_s), .b(w_l1_c24_fa2_s), .cin(pp_row15[9]), .sum(w_l2_c24_fa2_s), .cout(w_l2_c24_fa2_c)); // col 24: FA#2 reduces 3 bits -> 1 sum (stays col 24) + 1 carry (-> col 25)

    // ---- Column 25: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c25_1 (.a(w_l1_c24_fa1_c), .b(w_l1_c24_fa2_c), .cin(w_l1_c25_fa1_s), .sum(w_l2_c25_fa1_s), .cout(w_l2_c25_fa1_c)); // col 25: FA#1 reduces 3 bits -> 1 sum (stays col 25) + 1 carry (-> col 26)
    // col 25: 1 bit (w_l1_c25_fa2_s) passes through unchanged (no compressor needed)

    // ---- Column 26: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c26_1 (.a(w_l1_c25_fa1_c), .b(w_l1_c25_fa2_c), .cin(w_l1_c26_fa1_s), .sum(w_l2_c26_fa1_s), .cout(w_l2_c26_fa1_c)); // col 26: FA#1 reduces 3 bits -> 1 sum (stays col 26) + 1 carry (-> col 27)
    // col 26: 1 bit (w_l1_c26_ha1_s) passes through unchanged (no compressor needed)

    // ---- Column 27: 4 input bit(s) -> 1 FA, 0 HA, 1 passthrough ----
    full_adder FA_l2_c27_1 (.a(w_l1_c26_fa1_c), .b(w_l1_c26_ha1_c), .cin(w_l1_c27_fa1_s), .sum(w_l2_c27_fa1_s), .cout(w_l2_c27_fa1_c)); // col 27: FA#1 reduces 3 bits -> 1 sum (stays col 27) + 1 carry (-> col 28)
    // col 27: 1 bit (pp_row15[12]) passes through unchanged (no compressor needed)

    // ---- Column 28: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l2_c28_1 (.a(w_l1_c27_fa1_c), .b(w_l1_c28_fa1_s), .sum(w_l2_c28_ha1_s), .cout(w_l2_c28_ha1_c)); // col 28: HA#1 reduces remaining 2 bits -> 1 sum (stays col 28) + 1 carry (-> col 29)

    // ---- Column 29: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l2_c29_1 (.a(w_l1_c28_fa1_c), .b(w_l1_c29_ha1_s), .sum(w_l2_c29_ha1_s), .cout(w_l2_c29_ha1_c)); // col 29: HA#1 reduces remaining 2 bits -> 1 sum (stays col 29) + 1 carry (-> col 30)

    // ---- Column 30: 2 input bit(s) -> 0 FA, 1 HA, 0 passthrough ----
    half_adder HA_l2_c30_1 (.a(w_l1_c29_ha1_c), .b(pp_row15[15]), .sum(w_l2_c30_ha1_s), .cout(w_l2_c30_ha1_c)); // col 30: HA#1 reduces remaining 2 bits -> 1 sum (stays col 30) + 1 carry (-> col 31)


    // =========================================================================
    // Output assignment: map final Level-2 internal signals to named output
    // ports, organized by column. This is the exact handoff to Stage 3
    // (wallace_stage2), which continues reduction with Levels 3 & 4.
    // =========================================================================
    assign s2_col0_b0 = pp_row0[0];  // column 0, bit 0 of 1
    assign s2_col1_b0 = w_l1_c1_ha1_s;  // column 1, bit 0 of 1
    assign s2_col2_b0 = w_l2_c2_ha1_s;  // column 2, bit 0 of 1
    assign s2_col3_b0 = w_l2_c2_ha1_c;  // column 3, bit 0 of 2
    assign s2_col3_b1 = w_l2_c3_fa1_s;  // column 3, bit 1 of 2
    assign s2_col4_b0 = w_l2_c3_fa1_c;  // column 4, bit 0 of 2
    assign s2_col4_b1 = w_l2_c4_fa1_s;  // column 4, bit 1 of 2
    assign s2_col5_b0 = w_l2_c4_fa1_c;  // column 5, bit 0 of 3
    assign s2_col5_b1 = w_l2_c5_fa1_s;  // column 5, bit 1 of 3
    assign s2_col5_b2 = w_l1_c5_fa2_s;  // column 5, bit 2 of 3
    assign s2_col6_b0 = w_l2_c5_fa1_c;  // column 6, bit 0 of 3
    assign s2_col6_b1 = w_l2_c6_fa1_s;  // column 6, bit 1 of 3
    assign s2_col6_b2 = w_l2_c6_ha1_s;  // column 6, bit 2 of 3
    assign s2_col7_b0 = w_l2_c6_fa1_c;  // column 7, bit 0 of 4
    assign s2_col7_b1 = w_l2_c6_ha1_c;  // column 7, bit 1 of 4
    assign s2_col7_b2 = w_l2_c7_fa1_s;  // column 7, bit 2 of 4
    assign s2_col7_b3 = w_l2_c7_ha1_s;  // column 7, bit 3 of 4
    assign s2_col8_b0 = w_l2_c7_fa1_c;  // column 8, bit 0 of 4
    assign s2_col8_b1 = w_l2_c7_ha1_c;  // column 8, bit 1 of 4
    assign s2_col8_b2 = w_l2_c8_fa1_s;  // column 8, bit 2 of 4
    assign s2_col8_b3 = w_l2_c8_fa2_s;  // column 8, bit 3 of 4
    assign s2_col9_b0 = w_l2_c8_fa1_c;  // column 9, bit 0 of 5
    assign s2_col9_b1 = w_l2_c8_fa2_c;  // column 9, bit 1 of 5
    assign s2_col9_b2 = w_l2_c9_fa1_s;  // column 9, bit 2 of 5
    assign s2_col9_b3 = w_l2_c9_fa2_s;  // column 9, bit 3 of 5
    assign s2_col9_b4 = pp_row9[0];  // column 9, bit 4 of 5
    assign s2_col10_b0 = w_l2_c9_fa1_c;  // column 10, bit 0 of 5
    assign s2_col10_b1 = w_l2_c9_fa2_c;  // column 10, bit 1 of 5
    assign s2_col10_b2 = w_l2_c10_fa1_s;  // column 10, bit 2 of 5
    assign s2_col10_b3 = w_l2_c10_fa2_s;  // column 10, bit 3 of 5
    assign s2_col10_b4 = w_l1_c10_ha1_s;  // column 10, bit 4 of 5
    assign s2_col11_b0 = w_l2_c10_fa1_c;  // column 11, bit 0 of 5
    assign s2_col11_b1 = w_l2_c10_fa2_c;  // column 11, bit 1 of 5
    assign s2_col11_b2 = w_l2_c11_fa1_s;  // column 11, bit 2 of 5
    assign s2_col11_b3 = w_l2_c11_fa2_s;  // column 11, bit 3 of 5
    assign s2_col11_b4 = w_l2_c11_ha1_s;  // column 11, bit 4 of 5
    assign s2_col12_b0 = w_l2_c11_fa1_c;  // column 12, bit 0 of 6
    assign s2_col12_b1 = w_l2_c11_fa2_c;  // column 12, bit 1 of 6
    assign s2_col12_b2 = w_l2_c11_ha1_c;  // column 12, bit 2 of 6
    assign s2_col12_b3 = w_l2_c12_fa1_s;  // column 12, bit 3 of 6
    assign s2_col12_b4 = w_l2_c12_fa2_s;  // column 12, bit 4 of 6
    assign s2_col12_b5 = w_l2_c12_fa3_s;  // column 12, bit 5 of 6
    assign s2_col13_b0 = w_l2_c12_fa1_c;  // column 13, bit 0 of 6
    assign s2_col13_b1 = w_l2_c12_fa2_c;  // column 13, bit 1 of 6
    assign s2_col13_b2 = w_l2_c12_fa3_c;  // column 13, bit 2 of 6
    assign s2_col13_b3 = w_l2_c13_fa1_s;  // column 13, bit 3 of 6
    assign s2_col13_b4 = w_l2_c13_fa2_s;  // column 13, bit 4 of 6
    assign s2_col13_b5 = w_l2_c13_fa3_s;  // column 13, bit 5 of 6
    assign s2_col14_b0 = w_l2_c13_fa1_c;  // column 14, bit 0 of 7
    assign s2_col14_b1 = w_l2_c13_fa2_c;  // column 14, bit 1 of 7
    assign s2_col14_b2 = w_l2_c13_fa3_c;  // column 14, bit 2 of 7
    assign s2_col14_b3 = w_l2_c14_fa1_s;  // column 14, bit 3 of 7
    assign s2_col14_b4 = w_l2_c14_fa2_s;  // column 14, bit 4 of 7
    assign s2_col14_b5 = w_l2_c14_fa3_s;  // column 14, bit 5 of 7
    assign s2_col14_b6 = w_l1_c14_fa5_s;  // column 14, bit 6 of 7
    assign s2_col15_b0 = w_l2_c14_fa1_c;  // column 15, bit 0 of 7
    assign s2_col15_b1 = w_l2_c14_fa2_c;  // column 15, bit 1 of 7
    assign s2_col15_b2 = w_l2_c14_fa3_c;  // column 15, bit 2 of 7
    assign s2_col15_b3 = w_l2_c15_fa1_s;  // column 15, bit 3 of 7
    assign s2_col15_b4 = w_l2_c15_fa2_s;  // column 15, bit 4 of 7
    assign s2_col15_b5 = w_l2_c15_fa3_s;  // column 15, bit 5 of 7
    assign s2_col15_b6 = w_l2_c15_ha1_s;  // column 15, bit 6 of 7
    assign s2_col16_b0 = w_l2_c15_fa1_c;  // column 16, bit 0 of 8
    assign s2_col16_b1 = w_l2_c15_fa2_c;  // column 16, bit 1 of 8
    assign s2_col16_b2 = w_l2_c15_fa3_c;  // column 16, bit 2 of 8
    assign s2_col16_b3 = w_l2_c15_ha1_c;  // column 16, bit 3 of 8
    assign s2_col16_b4 = w_l2_c16_fa1_s;  // column 16, bit 4 of 8
    assign s2_col16_b5 = w_l2_c16_fa2_s;  // column 16, bit 5 of 8
    assign s2_col16_b6 = w_l2_c16_fa3_s;  // column 16, bit 6 of 8
    assign s2_col16_b7 = w_l1_c16_fa5_s;  // column 16, bit 7 of 8
    assign s2_col17_b0 = w_l2_c16_fa1_c;  // column 17, bit 0 of 7
    assign s2_col17_b1 = w_l2_c16_fa2_c;  // column 17, bit 1 of 7
    assign s2_col17_b2 = w_l2_c16_fa3_c;  // column 17, bit 2 of 7
    assign s2_col17_b3 = w_l2_c17_fa1_s;  // column 17, bit 3 of 7
    assign s2_col17_b4 = w_l2_c17_fa2_s;  // column 17, bit 4 of 7
    assign s2_col17_b5 = w_l2_c17_fa3_s;  // column 17, bit 5 of 7
    assign s2_col17_b6 = w_l1_c17_ha1_s;  // column 17, bit 6 of 7
    assign s2_col18_b0 = w_l2_c17_fa1_c;  // column 18, bit 0 of 7
    assign s2_col18_b1 = w_l2_c17_fa2_c;  // column 18, bit 1 of 7
    assign s2_col18_b2 = w_l2_c17_fa3_c;  // column 18, bit 2 of 7
    assign s2_col18_b3 = w_l2_c18_fa1_s;  // column 18, bit 3 of 7
    assign s2_col18_b4 = w_l2_c18_fa2_s;  // column 18, bit 4 of 7
    assign s2_col18_b5 = w_l2_c18_fa3_s;  // column 18, bit 5 of 7
    assign s2_col18_b6 = pp_row15[3];  // column 18, bit 6 of 7
    assign s2_col19_b0 = w_l2_c18_fa1_c;  // column 19, bit 0 of 6
    assign s2_col19_b1 = w_l2_c18_fa2_c;  // column 19, bit 1 of 6
    assign s2_col19_b2 = w_l2_c18_fa3_c;  // column 19, bit 2 of 6
    assign s2_col19_b3 = w_l2_c19_fa1_s;  // column 19, bit 3 of 6
    assign s2_col19_b4 = w_l2_c19_fa2_s;  // column 19, bit 4 of 6
    assign s2_col19_b5 = w_l2_c19_ha1_s;  // column 19, bit 5 of 6
    assign s2_col20_b0 = w_l2_c19_fa1_c;  // column 20, bit 0 of 6
    assign s2_col20_b1 = w_l2_c19_fa2_c;  // column 20, bit 1 of 6
    assign s2_col20_b2 = w_l2_c19_ha1_c;  // column 20, bit 2 of 6
    assign s2_col20_b3 = w_l2_c20_fa1_s;  // column 20, bit 3 of 6
    assign s2_col20_b4 = w_l2_c20_fa2_s;  // column 20, bit 4 of 6
    assign s2_col20_b5 = w_l2_c20_ha1_s;  // column 20, bit 5 of 6
    assign s2_col21_b0 = w_l2_c20_fa1_c;  // column 21, bit 0 of 6
    assign s2_col21_b1 = w_l2_c20_fa2_c;  // column 21, bit 1 of 6
    assign s2_col21_b2 = w_l2_c20_ha1_c;  // column 21, bit 2 of 6
    assign s2_col21_b3 = w_l2_c21_fa1_s;  // column 21, bit 3 of 6
    assign s2_col21_b4 = w_l2_c21_fa2_s;  // column 21, bit 4 of 6
    assign s2_col21_b5 = w_l2_c21_ha1_s;  // column 21, bit 5 of 6
    assign s2_col22_b0 = w_l2_c21_fa1_c;  // column 22, bit 0 of 5
    assign s2_col22_b1 = w_l2_c21_fa2_c;  // column 22, bit 1 of 5
    assign s2_col22_b2 = w_l2_c21_ha1_c;  // column 22, bit 2 of 5
    assign s2_col22_b3 = w_l2_c22_fa1_s;  // column 22, bit 3 of 5
    assign s2_col22_b4 = w_l2_c22_fa2_s;  // column 22, bit 4 of 5
    assign s2_col23_b0 = w_l2_c22_fa1_c;  // column 23, bit 0 of 4
    assign s2_col23_b1 = w_l2_c22_fa2_c;  // column 23, bit 1 of 4
    assign s2_col23_b2 = w_l2_c23_fa1_s;  // column 23, bit 2 of 4
    assign s2_col23_b3 = w_l2_c23_fa2_s;  // column 23, bit 3 of 4
    assign s2_col24_b0 = w_l2_c23_fa1_c;  // column 24, bit 0 of 4
    assign s2_col24_b1 = w_l2_c23_fa2_c;  // column 24, bit 1 of 4
    assign s2_col24_b2 = w_l2_c24_fa1_s;  // column 24, bit 2 of 4
    assign s2_col24_b3 = w_l2_c24_fa2_s;  // column 24, bit 3 of 4
    assign s2_col25_b0 = w_l2_c24_fa1_c;  // column 25, bit 0 of 4
    assign s2_col25_b1 = w_l2_c24_fa2_c;  // column 25, bit 1 of 4
    assign s2_col25_b2 = w_l2_c25_fa1_s;  // column 25, bit 2 of 4
    assign s2_col25_b3 = w_l1_c25_fa2_s;  // column 25, bit 3 of 4
    assign s2_col26_b0 = w_l2_c25_fa1_c;  // column 26, bit 0 of 3
    assign s2_col26_b1 = w_l2_c26_fa1_s;  // column 26, bit 1 of 3
    assign s2_col26_b2 = w_l1_c26_ha1_s;  // column 26, bit 2 of 3
    assign s2_col27_b0 = w_l2_c26_fa1_c;  // column 27, bit 0 of 3
    assign s2_col27_b1 = w_l2_c27_fa1_s;  // column 27, bit 1 of 3
    assign s2_col27_b2 = pp_row15[12];  // column 27, bit 2 of 3
    assign s2_col28_b0 = w_l2_c27_fa1_c;  // column 28, bit 0 of 2
    assign s2_col28_b1 = w_l2_c28_ha1_s;  // column 28, bit 1 of 2
    assign s2_col29_b0 = w_l2_c28_ha1_c;  // column 29, bit 0 of 2
    assign s2_col29_b1 = w_l2_c29_ha1_s;  // column 29, bit 1 of 2
    assign s2_col30_b0 = w_l2_c29_ha1_c;  // column 30, bit 0 of 2
    assign s2_col30_b1 = w_l2_c30_ha1_s;  // column 30, bit 1 of 2
    assign s2_col31_b0 = w_l2_c30_ha1_c;  // column 31, bit 0 of 1

endmodule
