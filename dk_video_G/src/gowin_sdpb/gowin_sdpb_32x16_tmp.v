//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8 Education
//Part Number: GW1NSR-LV4CQN48PC6/I5
//Device: GW1NSR-4C
//Created Time: Wed Dec 22 16:54:46 2021

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_SDPB_32x16 your_instance_name(
        .dout(dout_o), //output [15:0] dout
        .clka(clka_i), //input clka
        .cea(cea_i), //input cea
        .reseta(reseta_i), //input reseta
        .clkb(clkb_i), //input clkb
        .ceb(ceb_i), //input ceb
        .resetb(resetb_i), //input resetb
        .oce(oce_i), //input oce
        .ada(ada_i), //input [8:0] ada
        .din(din_i), //input [31:0] din
        .adb(adb_i) //input [9:0] adb
    );

//--------Copy end-------------------
