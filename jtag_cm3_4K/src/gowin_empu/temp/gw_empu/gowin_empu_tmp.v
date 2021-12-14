//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8 Education
//Part Number: GW1NSR-LV4CQN48PC6/I5
//Device: GW1NSR-4C
//Created Time: Sun Dec 05 11:19:27 2021

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Gowin_EMPU_Top your_instance_name(
		.sys_clk(sys_clk_i), //input sys_clk
		.rtc_src_clk(rtc_src_clk_i), //input rtc_src_clk
		.gpioin(gpioin_i), //input [15:0] gpioin
		.gpioout(gpioout_o), //output [15:0] gpioout
		.gpioouten(gpioouten_o), //output [15:0] gpioouten
		.uart0_rxd(uart0_rxd_i), //input uart0_rxd
		.uart0_txd(uart0_txd_o), //output uart0_txd
		.uart1_rxd(uart1_rxd_i), //input uart1_rxd
		.uart1_txd(uart1_txd_o), //output uart1_txd
		.scl(scl_io), //inout scl
		.sda(sda_io), //inout sda
		.mosi(mosi_o), //output mosi
		.miso(miso_i), //input miso
		.sclk(sclk_o), //output sclk
		.nss(nss_o), //output nss
		.reset_n(reset_n_i) //input reset_n
	);

//--------Copy end-------------------
