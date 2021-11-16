//Copyright (C)2014-2020 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.6.01 Beta
//Created Time: 2020-08-04 14:24:01
create_clock -name clk_x1 -period 10 -waveform {0 5} [get_nets {clk_x1}]
create_clock -name clk_x2 -period 5 -waveform {0 2.5} [get_nets {memory_clk}]
set_clock_groups -exclusive -group [get_clocks {clk_x1 clk_x2}]
