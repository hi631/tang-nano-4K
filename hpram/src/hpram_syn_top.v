`timescale 1ns/1ps

module hpram_syn_top(
               clk,
               rst_n,
               O_hpram_ck,
               O_hpram_ck_n,
               IO_hpram_rwds,
               O_hpram_reset_n,
               IO_hpram_dq,
               O_hpram_cs_n,
               init_calib,
               error,
               LED
               );

parameter CS_WIDTH = 1;
parameter DQ_WIDTH = 8;
parameter ADDR_WIDTH = 22;
parameter MASK_WIDTH = 4;

input clk;
input rst_n;
output[CS_WIDTH-1:0]O_hpram_ck;
output[CS_WIDTH-1:0]O_hpram_ck_n;
inout [CS_WIDTH-1:0]IO_hpram_rwds;
inout [DQ_WIDTH-1:0]IO_hpram_dq;
output[CS_WIDTH-1:0] O_hpram_reset_n;
output[CS_WIDTH-1:0] O_hpram_cs_n;
output  init_calib;
output error;
output LED;

assign LED = error | ~rst_n;

wire [4*DQ_WIDTH-1:0] wr_data;
wire [4*DQ_WIDTH-1:0] rd_data;
wire cmd;
wire cmd_en;
wire [ADDR_WIDTH-1:0] addr;
wire init_done;
wire [CS_WIDTH*MASK_WIDTH-1:0] data_mask;


    Gowin_PLLVR your_instance_name(
        .clkout(memory_clk), //output clkout
        .lock(pll_lock), //output lock
        .reset(~rst_n), //input reset
        .clkin(clk) //input clkin
    );

/*
PLLVR pllvr_inst (
    .CLKOUT(memory_clk),
    .LOCK(pll_lock),
    .CLKOUTP(),
    .CLKOUTD(),
    .CLKOUTD3(),
    .RESET(~rst_n),
    .RESET_P(1'b0),
    .CLKIN(clk),
    .CLKFB(1'b0),
    .FBDSEL({6{1'b0}}),
    .IDSEL({6{1'b0}}),
    .ODSEL({6{1'b0}}),
    .PSDA(4'b0000),
    .DUTYDA(4'b0000),
    .FDLY(4'b0000),
    .VREN(1'b1)
);
*/
defparam pllvr_inst.FCLKIN = "50";
defparam pllvr_inst.DYN_IDIV_SEL = "false";
defparam pllvr_inst.IDIV_SEL = 4;
defparam pllvr_inst.DYN_FBDIV_SEL = "false";
defparam pllvr_inst.FBDIV_SEL = 11;
defparam pllvr_inst.DYN_ODIV_SEL = "false";
defparam pllvr_inst.ODIV_SEL = 4;
defparam pllvr_inst.PSDA_SEL = "0000";
defparam pllvr_inst.DYN_DA_EN = "true"; //
defparam pllvr_inst.DUTYDA_SEL = "1000";
defparam pllvr_inst.CLKOUT_FT_DIR = 1'b1;
defparam pllvr_inst.CLKOUTP_FT_DIR = 1'b1;
defparam pllvr_inst.CLKOUT_DLY_STEP = 0;
defparam pllvr_inst.CLKOUTP_DLY_STEP = 0;
defparam pllvr_inst.CLKFB_SEL = "internal";
defparam pllvr_inst.CLKOUT_BYPASS = "false";
defparam pllvr_inst.CLKOUTP_BYPASS = "false";
defparam pllvr_inst.CLKOUTD_BYPASS = "false";
defparam pllvr_inst.DYN_SDIV_SEL = 2;
defparam pllvr_inst.CLKOUTD_SRC = "CLKOUT";
defparam pllvr_inst.CLKOUTD3_SRC = "CLKOUT";
defparam pllvr_inst.DEVICE = "GW1NSR-4C";



HyperRAM_Memory_Interface_Top  u_hpram_top(
                      .clk(clk),
                      .memory_clk(memory_clk), 
                      .pll_lock(pll_lock),
                      .rst_n(rst_n),
                      .O_hpram_ck(O_hpram_ck),
                      .O_hpram_ck_n(O_hpram_ck_n),
                      .IO_hpram_rwds(IO_hpram_rwds),
                      .IO_hpram_dq(IO_hpram_dq),
                      .O_hpram_reset_n(O_hpram_reset_n),
                      .O_hpram_cs_n(O_hpram_cs_n),
                      .wr_data(wr_data),
                      .rd_data(rd_data),
                      .rd_data_valid(rd_data_valid),
                      .addr(addr),
                      .cmd(cmd),
                      .cmd_en(cmd_en), 
                      .clk_out(clk_x1),
                      .data_mask(data_mask),
                      .init_calib(init_calib) 
                     );
hpram_test u_test(
                  .clk(clk_x1),
                  .rst_n(rst_n),
                  .init_done(init_calib),
                  .cmd(cmd),
                  .cmd_en(cmd_en),
                  .addr(addr),
                  .wr_data(wr_data),
                  .rd_data(rd_data),
                  .rd_data_valid(rd_data_valid),
                  .data_mask(data_mask),
                  .error(error)
                  );
endmodule
