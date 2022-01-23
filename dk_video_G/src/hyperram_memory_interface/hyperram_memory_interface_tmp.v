//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8 Education
//Part Number: GW1NSR-LV4CQN48PC6/I5
//Device: GW1NSR-4C
//Created Time: Fri Dec 24 09:23:11 2021

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	HyperRAM_Memory_Interface_Top your_instance_name(
		.clk(clk_i), //input clk
		.memory_clk(memory_clk_i), //input memory_clk
		.pll_lock(pll_lock_i), //input pll_lock
		.rst_n(rst_n_i), //input rst_n
		.O_hpram_ck(O_hpram_ck_o), //output [0:0] O_hpram_ck
		.O_hpram_ck_n(O_hpram_ck_n_o), //output [0:0] O_hpram_ck_n
		.IO_hpram_dq(IO_hpram_dq_io), //inout [7:0] IO_hpram_dq
		.IO_hpram_rwds(IO_hpram_rwds_io), //inout [0:0] IO_hpram_rwds
		.O_hpram_cs_n(O_hpram_cs_n_o), //output [0:0] O_hpram_cs_n
		.O_hpram_reset_n(O_hpram_reset_n_o), //output [0:0] O_hpram_reset_n
		.wr_data(wr_data_i), //input [31:0] wr_data
		.rd_data(rd_data_o), //output [31:0] rd_data
		.rd_data_valid(rd_data_valid_o), //output rd_data_valid
		.addr(addr_i), //input [21:0] addr
		.cmd(cmd_i), //input cmd
		.cmd_en(cmd_en_i), //input cmd_en
		.init_calib(init_calib_o), //output init_calib
		.clk_out(clk_out_o), //output clk_out
		.data_mask(data_mask_i) //input [3:0] data_mask
	);

//--------Copy end-------------------
