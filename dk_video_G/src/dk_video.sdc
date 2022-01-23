//Copyright (C)2014-2021 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.7.02 Beta
//Created Time: 2021-06-01 10:34:02
create_clock -name I_clk -period 37.037 -waveform {0 18.518} [get_ports {I_clk}] -add
//create_clock -name serial_clk -period 2.777 -waveform {0 1.388} [get_nets {serial_clk}] -add
//create_clock -name pix_clk -period 13.888 -waveform {0 6.944} [get_nets {pix_clk}] -add
