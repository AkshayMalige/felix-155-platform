//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
//Date        : Sun Feb  1 12:20:14 2026
//Host        : synthara-Super-Server running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target ext_platform_part_wrapper.bd
//Design      : ext_platform_part_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ext_platform_part_wrapper
   (CH0_DDR4_0_0_act_n,
    CH0_DDR4_0_0_adr,
    CH0_DDR4_0_0_ba,
    CH0_DDR4_0_0_bg,
    CH0_DDR4_0_0_ck_c,
    CH0_DDR4_0_0_ck_t,
    CH0_DDR4_0_0_cke,
    CH0_DDR4_0_0_cs_n,
    CH0_DDR4_0_0_dm_n,
    CH0_DDR4_0_0_dq,
    CH0_DDR4_0_0_dqs_c,
    CH0_DDR4_0_0_dqs_t,
    CH0_DDR4_0_0_odt,
    CH0_DDR4_0_0_reset_n,
    sys_clk0_0_clk_n,
    sys_clk0_0_clk_p);
  output [0:0]CH0_DDR4_0_0_act_n;
  output [16:0]CH0_DDR4_0_0_adr;
  output [1:0]CH0_DDR4_0_0_ba;
  output [1:0]CH0_DDR4_0_0_bg;
  output [0:0]CH0_DDR4_0_0_ck_c;
  output [0:0]CH0_DDR4_0_0_ck_t;
  output [0:0]CH0_DDR4_0_0_cke;
  output [0:0]CH0_DDR4_0_0_cs_n;
  inout [8:0]CH0_DDR4_0_0_dm_n;
  inout [71:0]CH0_DDR4_0_0_dq;
  inout [8:0]CH0_DDR4_0_0_dqs_c;
  inout [8:0]CH0_DDR4_0_0_dqs_t;
  output [0:0]CH0_DDR4_0_0_odt;
  output [0:0]CH0_DDR4_0_0_reset_n;
  input [0:0]sys_clk0_0_clk_n;
  input [0:0]sys_clk0_0_clk_p;

  wire [0:0]CH0_DDR4_0_0_act_n;
  wire [16:0]CH0_DDR4_0_0_adr;
  wire [1:0]CH0_DDR4_0_0_ba;
  wire [1:0]CH0_DDR4_0_0_bg;
  wire [0:0]CH0_DDR4_0_0_ck_c;
  wire [0:0]CH0_DDR4_0_0_ck_t;
  wire [0:0]CH0_DDR4_0_0_cke;
  wire [0:0]CH0_DDR4_0_0_cs_n;
  wire [8:0]CH0_DDR4_0_0_dm_n;
  wire [71:0]CH0_DDR4_0_0_dq;
  wire [8:0]CH0_DDR4_0_0_dqs_c;
  wire [8:0]CH0_DDR4_0_0_dqs_t;
  wire [0:0]CH0_DDR4_0_0_odt;
  wire [0:0]CH0_DDR4_0_0_reset_n;
  wire [0:0]sys_clk0_0_clk_n;
  wire [0:0]sys_clk0_0_clk_p;

  ext_platform_part ext_platform_part_i
       (.CH0_DDR4_0_0_act_n(CH0_DDR4_0_0_act_n),
        .CH0_DDR4_0_0_adr(CH0_DDR4_0_0_adr),
        .CH0_DDR4_0_0_ba(CH0_DDR4_0_0_ba),
        .CH0_DDR4_0_0_bg(CH0_DDR4_0_0_bg),
        .CH0_DDR4_0_0_ck_c(CH0_DDR4_0_0_ck_c),
        .CH0_DDR4_0_0_ck_t(CH0_DDR4_0_0_ck_t),
        .CH0_DDR4_0_0_cke(CH0_DDR4_0_0_cke),
        .CH0_DDR4_0_0_cs_n(CH0_DDR4_0_0_cs_n),
        .CH0_DDR4_0_0_dm_n(CH0_DDR4_0_0_dm_n),
        .CH0_DDR4_0_0_dq(CH0_DDR4_0_0_dq),
        .CH0_DDR4_0_0_dqs_c(CH0_DDR4_0_0_dqs_c),
        .CH0_DDR4_0_0_dqs_t(CH0_DDR4_0_0_dqs_t),
        .CH0_DDR4_0_0_odt(CH0_DDR4_0_0_odt),
        .CH0_DDR4_0_0_reset_n(CH0_DDR4_0_0_reset_n),
        .sys_clk0_0_clk_n(sys_clk0_0_clk_n),
        .sys_clk0_0_clk_p(sys_clk0_0_clk_p));
endmodule
