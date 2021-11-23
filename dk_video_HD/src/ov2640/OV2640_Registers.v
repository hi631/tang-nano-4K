module OV2640_Registers (
    input clk, 
    input resend, 
    input advance, 
    output [15:0] command, 
    output finished
);

    // Internal signals
    reg [15:0] sreg;
    reg finished_temp;
    reg [8:0] address = {9{1'b0}};
    
    // Assign values to outputs
    assign command = sreg; 
    assign finished = finished_temp;
    
    // When register and value is FFFF
    // a flag is asserted indicating the configuration is finished
    always @ (sreg) begin
        if(sreg == 16'hFFFF) begin
            finished_temp <= 1;
        end
        else begin
            finished_temp <= 0;
        end
    end
 
    
    // Get value out of the LUT
    always @ (posedge clk) begin
        if(resend == 1) begin           // reset the configuration
            address <= {8{1'b0}};
        end
        else if(advance == 1) begin     // Get the next value
            address <= address+1;
        end
           
        case (address) 
          000 : sreg <= 16'hFF_01;
          001 : sreg <= 16'h12_80;
          002 : sreg <= 16'hFF_00;
          003 : sreg <= 16'h2c_ff;
          004 : sreg <= 16'h2e_df;
          005 : sreg <= 16'hFF_01;
          006 : sreg <= 16'h3c_32;
          007 : sreg <= 16'h11_80;/* Set PCLK divider */
          008 : sreg <= 16'h09_02;/* Output drive x2 */
          009 : sreg <= 16'h04_28;
          010 : sreg <= 16'h13_E5;
          011 : sreg <= 16'h14_48;
          012 : sreg <= 16'h15_00;//Invert VSYNC
          013 : sreg <= 16'h2c_0c;
          014 : sreg <= 16'h33_78;
          015 : sreg <= 16'h3a_33;
          016 : sreg <= 16'h3b_fb;
          017 : sreg <= 16'h3e_00;
          018 : sreg <= 16'h43_11;
          019 : sreg <= 16'h16_10;
          020 : sreg <= 16'h39_02;
          021 : sreg <= 16'h35_88;
          022 : sreg <= 16'h22_0a;
          023 : sreg <= 16'h37_40;
          024 : sreg <= 16'h23_00;
          025 : sreg <= 16'h34_a0;
          026 : sreg <= 16'h06_02;
          027 : sreg <= 16'h06_88;
          028 : sreg <= 16'h07_c0;
          029 : sreg <= 16'h0d_b7;
          030 : sreg <= 16'h0e_01;
          031 : sreg <= 16'h4c_00;
          032 : sreg <= 16'h4a_81;
          033 : sreg <= 16'h21_99;
          034 : sreg <= 16'h24_40;
          035 : sreg <= 16'h25_38;
          036 : sreg <= 16'h26_82;/* AGC/AEC fast mode operating region */	
          037 : sreg <= 16'h48_00;/* Zoom control 2 MSBs */
          038 : sreg <= 16'h49_00;/* Zoom control 8 MSBs */
          039 : sreg <= 16'h5c_00;
          040 : sreg <= 16'h63_00;
          041 : sreg <= 16'h46_00;
          042 : sreg <= 16'h47_00;
          043 : sreg <= 16'h0C_3A;/* Set banding filter */
          044 : sreg <= 16'h5D_55;
          045 : sreg <= 16'h5E_7d;
          046 : sreg <= 16'h5F_7d;
          047 : sreg <= 16'h60_55;
          048 : sreg <= 16'h61_70;
          049 : sreg <= 16'h62_80;
          050 : sreg <= 16'h7c_05;
          051 : sreg <= 16'h20_80;
          052 : sreg <= 16'h28_30;
          053 : sreg <= 16'h6c_00;
          054 : sreg <= 16'h6d_80;
          055 : sreg <= 16'h6e_00;
          056 : sreg <= 16'h70_02;
          057 : sreg <= 16'h71_94;
          058 : sreg <= 16'h73_c1;
          059 : sreg <= 16'h3d_34;
          060 : sreg <= 16'h5a_57;
          061 : sreg <= 16'h4F_bb;
          062 : sreg <= 16'h50_9c;
          063 : sreg <= 16'hFF_00;
          064 : sreg <= 16'he5_7f;
          065 : sreg <= 16'hF9_C0;
          066 : sreg <= 16'h41_24;
          067 : sreg <= 16'hE0_14;
          068 : sreg <= 16'h76_ff;
          069 : sreg <= 16'h33_a0;
          070 : sreg <= 16'h42_20;
          071 : sreg <= 16'h43_18;
          072 : sreg <= 16'h4c_00;
          073 : sreg <= 16'h87_D0;
          074 : sreg <= 16'h88_3f;
          075 : sreg <= 16'hd7_03;
          076 : sreg <= 16'hd9_10;
          077 : sreg <= 16'hD3_82;
          078 : sreg <= 16'hc8_08;
          079 : sreg <= 16'hc9_80;
          080 : sreg <= 16'h7C_00;
          081 : sreg <= 16'h7D_00;
          082 : sreg <= 16'h7C_03;
          083 : sreg <= 16'h7D_48;
          084 : sreg <= 16'h7D_48;
          085 : sreg <= 16'h7C_08;
          086 : sreg <= 16'h7D_20;
          087 : sreg <= 16'h7D_10;
          088 : sreg <= 16'h7D_0e;
          089 : sreg <= 16'h90_00;
          090 : sreg <= 16'h91_0e;
          091 : sreg <= 16'h91_1a;
          092 : sreg <= 16'h91_31;
          093 : sreg <= 16'h91_5a;
          094 : sreg <= 16'h91_69;
          095 : sreg <= 16'h91_75;
          096 : sreg <= 16'h91_7e;
          097 : sreg <= 16'h91_88;
          098 : sreg <= 16'h91_8f;
          099 : sreg <= 16'h91_96;
          100 : sreg <= 16'h91_a3;
          101 : sreg <= 16'h91_af;
          102 : sreg <= 16'h91_c4;
          103 : sreg <= 16'h91_d7;
          104 : sreg <= 16'h91_e8;
          105 : sreg <= 16'h91_20;
          106 : sreg <= 16'h92_00;
          107 : sreg <= 16'h93_06;
          108 : sreg <= 16'h93_e3;
          109 : sreg <= 16'h93_03;
          110 : sreg <= 16'h93_03;
          111 : sreg <= 16'h93_00;
          112 : sreg <= 16'h93_02;
          113 : sreg <= 16'h93_00;
          114 : sreg <= 16'h93_00;
          115 : sreg <= 16'h93_00;
          116 : sreg <= 16'h93_00;
          117 : sreg <= 16'h93_00;
          118 : sreg <= 16'h93_00;
          119 : sreg <= 16'h93_00;
          120 : sreg <= 16'h96_00;
          121 : sreg <= 16'h97_08;
          122 : sreg <= 16'h97_19;
          123 : sreg <= 16'h97_02;
          124 : sreg <= 16'h97_0c;
          125 : sreg <= 16'h97_24;
          126 : sreg <= 16'h97_30;
          127 : sreg <= 16'h97_28;
          128 : sreg <= 16'h97_26;
          129 : sreg <= 16'h97_02;
          130 : sreg <= 16'h97_98;
          131 : sreg <= 16'h97_80;
          132 : sreg <= 16'h97_00;
          133 : sreg <= 16'h97_00;
          134 : sreg <= 16'ha4_00;
          135 : sreg <= 16'ha8_00;
          136 : sreg <= 16'hc5_11;
          137 : sreg <= 16'hc6_51;
          138 : sreg <= 16'hbf_80;
          139 : sreg <= 16'hc7_10;
          140 : sreg <= 16'hb6_66;
          141 : sreg <= 16'hb8_A5;
          142 : sreg <= 16'hb7_64;
          143 : sreg <= 16'hb9_7C;
          144 : sreg <= 16'hb3_af;
          145 : sreg <= 16'hb4_97;
          146 : sreg <= 16'hb5_FF;
          147 : sreg <= 16'hb0_C5;
          148 : sreg <= 16'hb1_94;
          149 : sreg <= 16'hb2_0f;
          150 : sreg <= 16'hc4_5c;
          151 : sreg <= 16'ha6_00;
          152 : sreg <= 16'ha7_20;
          153 : sreg <= 16'ha7_d8;
          154 : sreg <= 16'ha7_1b;
          155 : sreg <= 16'ha7_31;
          156 : sreg <= 16'ha7_00;
          157 : sreg <= 16'ha7_18;
          158 : sreg <= 16'ha7_20;
          159 : sreg <= 16'ha7_d8;
          160 : sreg <= 16'ha7_19;
          161 : sreg <= 16'ha7_31;
          162 : sreg <= 16'ha7_00;
          163 : sreg <= 16'ha7_18;
          164 : sreg <= 16'ha7_20;
          165 : sreg <= 16'ha7_d8;
          166 : sreg <= 16'ha7_19;
          167 : sreg <= 16'ha7_31;
          168 : sreg <= 16'ha7_00;
          169 : sreg <= 16'ha7_18;
          170 : sreg <= 16'h7f_00;
          171 : sreg <= 16'he5_1f;
          172 : sreg <= 16'he1_77;
          173 : sreg <= 16'hdd_7f;
          174 : sreg <= 16'hC2_0E;
          175 : sreg <= 16'hFF_01;
          176 : sreg <= 16'hFF_00;
          177 : sreg <= 16'hE0_04;
          178 : sreg <= 16'hDA_08;//08:RGB565  04:RAW10
          179 : sreg <= 16'hD7_03;
          180 : sreg <= 16'hE1_77;
          181 : sreg <= 16'hE0_00;
          182 : sreg <= 16'hFF_00;
          183 : sreg <= 16'h05_01;
          184 : sreg <= 16'h5A_A0;//(w>>2)&0xFF	//28:w=160 //A0:w=640 //C8:w=800
          185 : sreg <= 16'h5B_78;//(h>>2)&0xFF	//1E:h=120 //78:h=480 //96:h=600
          186 : sreg <= 16'h5C_00;//((h>>8)&0x04)|((w>>10)&0x03)		
          187 : sreg <= 16'hFF_01;
          188 : sreg <= 16'h11_80;//clkrc=0x83 for resolution <= SVGA		
          189 : sreg <= 16'hFF_01;
          // normal 16'h12_40 <-> color bar 16'h12_42 
          190 : sreg <= 16'h12_40;/* DSP input image resoultion and window size control */
          191 : sreg <= 16'h03_0A;/* UXGA=0x0F, SVGA=0x0A, CIF=0x06 */
          192 : sreg <= 16'h32_09;/* UXGA=0x36, SVGA/CIF=0x09 */
          193 : sreg <= 16'h17_11;/* UXGA=0x11, SVGA/CIF=0x11 */
          194 : sreg <= 16'h18_43;/* UXGA=0x75, SVGA/CIF=0x43 */
          195 : sreg <= 16'h19_00;/* UXGA=0x01, SVGA/CIF=0x00 */
          196 : sreg <= 16'h1A_4b;/* UXGA=0x97, SVGA/CIF=0x4b */
          197 : sreg <= 16'h3d_38;/* UXGA=0x34, SVGA/CIF=0x38 */
          198 : sreg <= 16'h35_da;
          199 : sreg <= 16'h22_1a;
          200 : sreg <= 16'h37_c3;
          201 : sreg <= 16'h34_c0;
          202 : sreg <= 16'h06_88;
          203 : sreg <= 16'h0d_87;
          204 : sreg <= 16'h0e_41;
          205 : sreg <= 16'h42_03;
          206 : sreg <= 16'hFF_00;/* Set DSP input image size and offset. The sensor output image can be scaled with OUTW/OUTH */
          207 : sreg <= 16'h05_01;
          208 : sreg <= 16'hE0_04;
          209 : sreg <= 16'hC0_64;/* Image Horizontal Size 0x51[10:3] */  //11_0010_0000 = 800
          210 : sreg <= 16'hC1_4B;/* Image Vertiacl Size 0x52[10:3] */    //10_0101_1000 = 600   
          211 : sreg <= 16'h8C_00;/* {0x51[11], 0x51[2:0], 0x52[2:0]} */
          212 : sreg <= 16'h53_00;/* OFFSET_X[7:0] */
          213 : sreg <= 16'h54_00;/* OFFSET_Y[7:0] */
          214 : sreg <= 16'h51_C8;/* H_SIZE[7:0]= 0x51/4 */ //200
          215 : sreg <= 16'h52_96;/* V_SIZE[7:0]= 0x52/4 */ //150       
          216 : sreg <= 16'h55_00;/* V_SIZE[8]/OFFSET_Y[10:8]/H_SIZE[8]/OFFSET_X[10:8] */
          217 : sreg <= 16'h57_00;/* H_SIZE[9] */
          218 : sreg <= 16'h86_3D;
          219 : sreg <= 16'h50_80;/* H_DIVIDER/V_DIVIDER */        
          220 : sreg <= 16'hD3_80;/* DVP prescalar */
          221 : sreg <= 16'h05_00;
          222 : sreg <= 16'hE0_00;
          223 : sreg <= 16'hFF_00;
          224 : sreg <= 16'h05_00;
          225 : sreg <= 16'hFF_00;
          226 : sreg <= 16'hE0_04;
          227 : sreg <= 16'hDA_08;//08:RGB565  04:RAW10
          228 : sreg <= 16'hD7_03;
          229 : sreg <= 16'hE1_77;
          230 : sreg <= 16'hE0_00;            

          // 640x480以上にする場合、下記の該当項目を有効にする。
          // video_top.vのsyn_gen_instのI_rd_hres,I_rd_vresを併せて変更

          // 800x600,1024x768共通部
          231 : sreg <= 16'hff_01;
          232 : sreg <= 16'h11_01;
          233 : sreg <= 16'h12_00; // Bit[6:4]: Resolution selection //0x02 color bar
          234 : sreg <= 16'h17_11; // HREFST[10:3]
          235 : sreg <= 16'h18_75; // HREFEND[10:3]
          236 : sreg <= 16'h32_36; // Bit[5:3]: HREFEND[2:0]; Bit[2:0]: HREFST[2:0]
          237 : sreg <= 16'h19_01; // VSTRT[9:2]
          238 : sreg <= 16'h1a_97; // VEND[9:2]
          239 : sreg <= 16'h03_0f; // Bit[3:2]: VEND[1:0]; Bit[1:0]: VSTRT[1:0]
          240 : sreg <= 16'h37_40;
          241 : sreg <= 16'h4f_bb;
          242 : sreg <= 16'h50_9c;
          243 : sreg <= 16'h5a_57;
          244 : sreg <= 16'h6d_80;
          245 : sreg <= 16'h3d_34;
          246 : sreg <= 16'h39_02;
          247 : sreg <= 16'h35_88;
          248 : sreg <= 16'h22_0a;
          249 : sreg <= 16'h37_40;
          250 : sreg <= 16'h34_a0;
          251 : sreg <= 16'h06_02;
          252 : sreg <= 16'h0d_b7;
          253 : sreg <= 16'h0e_01;
/*
          // Set 800x600
          254 : sreg <= 16'hff_00;
          255 : sreg <= 16'he0_04;
          256 : sreg <= 16'hc0_c8;
          257 : sreg <= 16'hc1_96;
          258 : sreg <= 16'h86_35;
          259 : sreg <= 16'h50_89;
          260 : sreg <= 16'h51_90;
          261 : sreg <= 16'h52_2c;
          262 : sreg <= 16'h53_00;
          263 : sreg <= 16'h54_00;
          264 : sreg <= 16'h55_88;
          265 : sreg <= 16'h57_00;
          266 : sreg <= 16'h5a_c8;
          267 : sreg <= 16'h5b_96;
          268 : sreg <= 16'h5c_00;
          269 : sreg <= 16'hd3_02;
          270 : sreg <= 16'he0_00;
*/
          // Set 1024x768
          254 : sreg <= 16'hff_00;
          255 : sreg <= 16'hc0_C8;
          256 : sreg <= 16'hc1_96;
          257 : sreg <= 16'h8c_00;
          258 : sreg <= 16'h86_3D;
          259 : sreg <= 16'h50_00;
          260 : sreg <= 16'h51_90;
          261 : sreg <= 16'h52_2C;
          262 : sreg <= 16'h53_00;
          263 : sreg <= 16'h54_00;
          264 : sreg <= 16'h55_88;
          265 : sreg <= 16'h5a_00;
          266 : sreg <= 16'h5b_C0;
          267 : sreg <= 16'h5c_01;
          268 : sreg <= 16'hd3_02;

          default : sreg <= 16'hFF_FF;    // End configuration
        endcase  
            
    end 
endmodule
