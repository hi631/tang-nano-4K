// ==============0ooo===================================================0ooo===========
// =  Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
// =                     All rights reserved.
// ====================================================================================
// 
//  __      __      __
//  \ \    /  \    / /   [File name   ] video_top.v
//   \ \  / /\ \  / /    [Description ] Video demo
//    \ \/ /  \ \/ /     [Timestamp   ] Friday May 26 14:00:30 2019
//     \  /    \  /      [version     ] 1.0.0
//      \/      \/
//
// ==============0ooo===================================================0ooo===========
// Code Revision History :
// ----------------------------------------------------------------------------------
// Ver:    |  Author    | Mod. Date    | Changes Made:
// ----------------------------------------------------------------------------------
// V1.0    | Caojie     | 11/22/19     | Initial version 
// ----------------------------------------------------------------------------------
// ==============0ooo===================================================0ooo===========
`define USE_HD
  
module video_top
(
    input             I_clk           , //27Mhz
    input             I_rst_n         ,
    output     [1:0]  O_led           ,
    inout             SDA             ,
    inout             SCL             ,
    input             VSYNC           ,
    input             HREF            ,
    input      [9:0]  PIXDATA         ,
    input             PIXCLK          ,
    output            XCLK            ,
    //output     [2:0]  tsig,
    output     [0:0]  O_hpram_ck      ,
    output     [0:0]  O_hpram_ck_n    ,
    output     [0:0]  O_hpram_cs_n    ,
    output     [0:0]  O_hpram_reset_n ,
    inout      [7:0]  IO_hpram_dq     ,
    inout      [0:0]  IO_hpram_rwds   ,
    output            O_tmds_clk_p    ,
    output            O_tmds_clk_n    ,
    output     [2:0]  O_tmds_data_p   ,//{r,g,b}
    output     [2:0]  O_tmds_data_n   
);

//==================================================
reg  [31:0] run_cnt;
wire        running;

//--------------------------
wire        tp0_vs_in  ;
wire        tp0_hs_in  ;
wire        tp0_de_in ;
wire [ 7:0] tp0_data_r/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_g/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_b/*synthesis syn_keep=1*/;

reg         vs_r;
reg  [9:0]  cnt_vs;

//--------------------------
reg  [9:0]  pixdata_d1;
reg         hcnt;
wire [15:0] cam_data;

//-------------------------
//frame buffer in
wire        ch0_vfb_clk_in ;
wire        ch0_vfb_vs_in  ;
wire        ch0_vfb_de_in  ;
wire [15:0] ch0_vfb_data_in;

//-------------------
//syn_code
wire        syn_off0_re;  // ofifo read enable signal
wire        syn_off0_vs;
wire        syn_off0_hs;
            
wire        off0_syn_de  ;
wire [15:0] off0_syn_data;

//-------------------------------------
//Hyperram
wire        dma_clk  ; 

wire        memory_clk;
wire        mem_pll_lock  ;

//-------------------------------------------------
//memory interface
wire          cmd           ;
wire          cmd_en        ;
wire [21:0]   addr          ;//[ADDR_WIDTH-1:0]
wire [31:0]   wr_data       ;//[DATA_WIDTH-1:0]
wire [3:0]    data_mask     ;
wire          rd_data_valid ;
wire [31:0]   rd_data       ;//[DATA_WIDTH-1:0]
wire          init_calib    ;

//------------------------------------------
//rgb data
wire        rgb_vs     ;
wire        rgb_hs     ;
wire        rgb_de     ;
wire [23:0] rgb_data   ;  

//------------------------------------
//HDMI TX
wire serial_clk;
wire pll_lock;

wire hdmi_rst_n;

wire pix_clk;

wire clk_12M;

//===================================================
//LED test
always @(posedge I_clk or negedge I_rst_n) //I_clk
begin
    if(!I_rst_n)
        run_cnt <= 32'd0;
    else if(run_cnt >= 32'd27_000_000)
        run_cnt <= 32'd0;
    else
        run_cnt <= run_cnt + 1'b1;
end

assign  running = (run_cnt < 32'd13_500_000) ? 1'b1 : 1'b0;

assign  O_led[0] = running;
assign  O_led[1] = ~init_calib;

assign  XCLK = clk_12M;

//===========================================================================
//testpattern
testpattern testpattern_inst
(
    .I_pxl_clk   (I_clk              ),//pixel clock
    .I_rst_n     (I_rst_n            ),//low active 
    .I_mode      ({1'b0,cnt_vs[7:6]} ),//data select
    .I_single_r  (8'd0               ),
    .I_single_g  (8'd255             ),
    .I_single_b  (8'd0               ),                  //800x600    //1024x768   //1280x720    
    .I_h_total   (16'd1650           ),//hor total time  // 16'd1056  // 16'd1344  // 16'd1650  
    .I_h_sync    (16'd40             ),//hor sync time   // 16'd128   // 16'd136   // 16'd40    
    .I_h_bporch  (16'd220            ),//hor back porch  // 16'd88    // 16'd160   // 16'd220   
    .I_h_res     (16'd640            ),//hor resolution  // 16'd800   // 16'd1024  // 16'd1280  
    .I_v_total   (16'd750            ),//ver total time  // 16'd628   // 16'd806   // 16'd750    
    .I_v_sync    (16'd5              ),//ver sync time   // 16'd4     // 16'd6     // 16'd5     
    .I_v_bporch  (16'd20             ),//ver back porch  // 16'd23    // 16'd29    // 16'd20    
    .I_v_res     (16'd480            ),//ver resolution  // 16'd600   // 16'd768   // 16'd720    
    .I_hs_pol    (1'b1               ),//HS polarity , 0:negetive ploarity，1：positive polarity
    .I_vs_pol    (1'b1               ),//VS polarity , 0:negetive ploarity，1：positive polarity
    .O_de        (tp0_de_in          ),   
    .O_hs        (tp0_hs_in          ),
    .O_vs        (tp0_vs_in          ),
    .O_data_r    (tp0_data_r         ),   
    .O_data_g    (tp0_data_g         ),
    .O_data_b    (tp0_data_b         )
);

always@(posedge I_clk)
begin
    vs_r<=tp0_vs_in;
end

always@(posedge I_clk or negedge I_rst_n)
begin
    if(!I_rst_n)
        cnt_vs<=0;
    else if(cnt_vs==10'h3ff)
        cnt_vs<=cnt_vs;
    else if(vs_r && !tp0_vs_in) //vs24 falling edge
        cnt_vs<=cnt_vs+1;
    else
        cnt_vs<=cnt_vs;
end 

//==============================================================================
OV2640_Controller u_OV2640_Controller
(
    .clk             (clk_12M),         // 24Mhz clock signal
    .resend          (1'b0),            // Reset signal
    .config_finished (), // Flag to indicate that the configuration is finished
    .sioc            (SCL),             // SCCB interface - clock signal
    .siod            (SDA),             // SCCB interface - data signal
    .reset           (),       // RESET signal for OV7670
    .pwdn            ()             // PWDN signal for OV7670
);

reg        PIXCLK565;
reg [15:0] PIXDAT565;
always @(posedge PIXCLK or negedge I_rst_n) //I_clk
begin
    if(!I_rst_n) begin
        pixdata_d1 <= 10'd0;
        PIXCLK565 <= 0;
    end else begin
        pixdata_d1 <= PIXDATA;
        if(~HREF) PIXCLK565 <= 0;
        else begin
            PIXCLK565 <= ~PIXCLK565;    // 1/2
            if(PIXCLK565) PIXDAT565[ 7:0] <= PIXDATA[9:2];
            else          PIXDAT565[15:8] <= PIXDATA[9:2];
        end
    end
end

always @(posedge PIXCLK or negedge I_rst_n) //I_clk
begin
    if(!I_rst_n)
        hcnt <= 1'd0;
    else if(HREF)
        hcnt <= ~hcnt;
    else
        hcnt <= 1'd0;
end

// assign cam_data = {pixdata_d1[9:5],pixdata_d1[4:2],PIXDATA[9:7],PIXDATA[6:2]}; //RGB565
// assign cam_data = {PIXDATA[9:5],PIXDATA[4:2],pixdata_d1[9:7],pixdata_d1[6:2]}; //RGB565
// assign cam_data = {PIXDATA[9:5],PIXDATA[9:4],PIXDATA[9:5]}; //RAW10
assign cam_data = PIXDAT565;

//==============================================
//data width 16bit   
    //assign ch0_vfb_clk_in  = (cnt_vs <= 10'h1ff) ? I_clk : PIXCLK;       
    //assign ch0_vfb_vs_in   = (cnt_vs <= 10'h1ff) ? ~tp0_vs_in : VSYNC;  //negative
    //assign ch0_vfb_de_in   = (cnt_vs <= 10'h1ff) ? tp0_de_in : HREF;//hcnt;  
    //assign ch0_vfb_data_in = (cnt_vs <= 10'h1ff) ? {tp0_data_r[7:3],tp0_data_g[7:2],tp0_data_b[7:3]} : cam_data; // RGB565
// cam_data onry  
    assign ch0_vfb_clk_in  = PIXCLK565; // PIXCLK;       
    assign ch0_vfb_vs_in   = VSYNC;  //negative
    assign ch0_vfb_de_in   = HREF;//hcnt;  
    assign ch0_vfb_data_in = cam_data; // RGB565


//=====================================================
//SRAM 控制模? 
Video_Frame_Buffer_Top Video_Frame_Buffer_Top_inst
( 
    .I_rst_n            (init_calib       ),//rst_n            ),
    .I_dma_clk          (dma_clk          ),   //sram_clk         ),
    .I_wr_halt          (1'd0             ), //1:halt,  0:no halt
    .I_rd_halt          (1'd0             ), //1:halt,  0:no halt
    // video data input           
    .I_vin0_clk         (ch0_vfb_clk_in   ),
    .I_vin0_vs_n        (ch0_vfb_vs_in    ),
    .I_vin0_de          (ch0_vfb_de_in    ),
    .I_vin0_data        (ch0_vfb_data_in  ),
    .O_vin0_fifo_full   (                 ),
    // video data output 
`ifdef USE_HD           
    .I_vout0_clk        (memory_clk       ), // 148.5MHz
`else
    .I_vout0_clk        (pix_clk          ), // 74.25MHz PIXCLKx3
`endif
    .I_vout0_vs_n       (~syn_off0_vs     ),
    .I_vout0_de         (syn_off0_re      ),
    .O_vout0_den        (off0_syn_de      ),
    .O_vout0_data       (off0_syn_data    ),
    .O_vout0_fifo_empty (                 ),
    // ddr write request
    .O_cmd              (cmd              ),
    .O_cmd_en           (cmd_en           ),
    .O_addr             (addr             ),//[ADDR_WIDTH-1:0]
    .O_wr_data          (wr_data          ),//[DATA_WIDTH-1:0]
    .O_data_mask        (data_mask        ),
    .I_rd_data_valid    (rd_data_valid    ),
    .I_rd_data          (rd_data          ),//[DATA_WIDTH-1:0]
    .I_init_calib       (init_calib       )
); 

//================================================
//HyperRAM ip
GW_PLLVR GW_PLLVR_inst
(
    .clkout(memory_clk    ), //output clkout 159MHz(53/9) -> 148.5MHz
    .lock  (mem_pll_lock  ), //output lock
    .clkin (I_clk         )  //input clkin   27MHz
);

HyperRAM_Memory_Interface_Top HyperRAM_Memory_Interface_Top_inst
(
    .clk            (I_clk          ),
    .memory_clk     (memory_clk     ),
    .pll_lock       (mem_pll_lock   ),
    .rst_n          (I_rst_n        ),  //rst_n
    .O_hpram_ck     (O_hpram_ck     ),
    .O_hpram_ck_n   (O_hpram_ck_n   ),
    .IO_hpram_rwds  (IO_hpram_rwds  ),
    .IO_hpram_dq    (IO_hpram_dq    ),
    .O_hpram_reset_n(O_hpram_reset_n),
    .O_hpram_cs_n   (O_hpram_cs_n   ),
    .wr_data        (wr_data        ),
    .rd_data        (rd_data        ),
    .rd_data_valid  (rd_data_valid  ),
    .addr           (addr           ),
    .cmd            (cmd            ),
    .cmd_en         (cmd_en         ),
    .clk_out        (dma_clk        ),
    .data_mask      (data_mask      ),
    .init_calib     (init_calib      )
); 

//================================================
wire out_de;
syn_gen syn_gen_inst
(
`ifdef USE_HD           
    // 1920x1080
    .I_pxl_clk   (memory_clk      ),//148.5MHz  
    .I_rst_n     (hdmi_rst_n      ),      
    .I_h_total   (16'd2200        ),    
    .I_h_sync    (16'd44          ),    
    .I_h_bporch  (16'd148         ),
    .I_h_res     (16'd1920        ),
    .I_v_total   (16'd1125        ),    
    .I_v_sync    (16'd5           ),  
    .I_v_bporch  (16'd36          ),     
    .I_v_res     (16'd1080        ),      
`else
    .I_pxl_clk   (pix_clk         ),//40MHz      //65MHz      //74.25MHz    
    .I_rst_n     (hdmi_rst_n      ),//800x600    //1024x768   //1280x720       
    .I_h_total   (16'd1650        ),// 16'd1056  // 16'd1344  // 16'd1650    
    .I_h_sync    (16'd40          ),// 16'd128   // 16'd136   // 16'd40     
    .I_h_bporch  (16'd220         ),// 16'd88    // 16'd160   // 16'd220     
    .I_h_res     (16'd1280        ),// 16'd800   // 16'd1024  // 16'd1280    
    .I_v_total   (16'd750         ),// 16'd628   // 16'd806   // 16'd750      
    .I_v_sync    (16'd5           ),// 16'd4     // 16'd6     // 16'd5        
    .I_v_bporch  (16'd20          ),// 16'd23    // 16'd29    // 16'd20        
    .I_v_res     (16'd720         ),// 16'd600   // 16'd768   // 16'd720      
`endif
`ifdef USE_640
    .I_rd_hres   (16'd640         ),
    .I_rd_vres   (16'd480         ),
`endif
`ifdef USE_800 
    .I_rd_hres   (16'd800         ),
    .I_rd_vres   (16'd600         ),
`endif
`ifdef USE_1024 
    .I_rd_hres   (16'd1024        ),
    .I_rd_vres   (16'd768         ),
`endif
    .I_hs_pol    (1'b1            ),//HS polarity , 0:??性，1：正?性
    .I_vs_pol    (1'b1            ),//VS polarity , 0:??性，1：正?性
    .O_rden      (syn_off0_re     ),
    .O_de        (out_de          ),   
    .O_hs        (syn_off0_hs     ),
    .O_vs        (syn_off0_vs     )
);

localparam N = 5; //delay N clocks
                          
reg  [N-1:0]  Pout_hs_dn   ;
reg  [N-1:0]  Pout_vs_dn   ;
reg  [N-1:0]  Pout_de_dn   ;

always@(posedge pix_clk or negedge hdmi_rst_n)
begin
    if(!hdmi_rst_n)
        begin                          
            Pout_hs_dn  <= {N{1'b1}};
            Pout_vs_dn  <= {N{1'b1}}; 
            Pout_de_dn  <= {N{1'b0}}; 
        end
    else 
        begin                          
            Pout_hs_dn  <= {Pout_hs_dn[N-2:0],syn_off0_hs};
            Pout_vs_dn  <= {Pout_vs_dn[N-2:0],syn_off0_vs}; 
            Pout_de_dn  <= {Pout_de_dn[N-2:0],out_de}; 
        end
end

//==============================================================================
//TMDS TX
assign rgb_data    = off0_syn_de ? {off0_syn_data[15:11],3'd0,off0_syn_data[10:5],2'd0,off0_syn_data[4:0],3'd0} : 24'h0000ff;//{r,g,b}
assign rgb_vs      = Pout_vs_dn[4];//syn_off0_vs;
assign rgb_hs      = Pout_hs_dn[4];//syn_off0_hs;
assign rgb_de      = Pout_de_dn[4];//off0_syn_de;

//assign tsig[0] = I_clk;     // (27.00MHz)     XTAL 
//assign tsig[1] = pix_clk;   // (74.25MHz)  <- I_clkx2.75(11/4)
//assign tsig[2] = PIXCLK;    // (24.75MHz)  <- pix_clk/3
//assign tsig[3] = XCLK;      // (12.375MHz) <- PIXCLK/2
//assign tsig[4] = serial_clk;// (371.25MHz) <- pix_clkx5

TMDS_PLLVR TMDS_PLLVR_inst
(.clkin     (I_clk     )     //input clk     (27M) 
,.clkout    (serial_clk)     //output clk    (371.25MHz) 55/4
,.clkoutd   (clk_12M   )     //output clkoutd(12.375MHz)
,.lock      (pll_lock  )     //output lock
);

assign hdmi_rst_n = I_rst_n & pll_lock;

CLKDIV u_clkdiv
(.RESETN(hdmi_rst_n)
,.HCLKIN(serial_clk) //clk  x5
,.CLKOUT(pix_clk)    //clk  x1
,.CALIB (1'b1)
);
defparam u_clkdiv.DIV_MODE="5";

DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n       (hdmi_rst_n   ),  //asynchronous reset, low active
    .I_serial_clk  (serial_clk    ),
    .I_rgb_clk     (pix_clk       ),  //pixel clock
    .I_rgb_vs      (rgb_vs        ), 
    .I_rgb_hs      (rgb_hs        ),    
    .I_rgb_de      (rgb_de        ), 
    .I_rgb_r       (rgb_data[23:16]    ),  
    .I_rgb_g       (rgb_data[15: 8]    ),  
    .I_rgb_b       (rgb_data[ 7: 0]    ),  
    .O_tmds_clk_p  (O_tmds_clk_p  ),
    .O_tmds_clk_n  (O_tmds_clk_n  ),
    .O_tmds_data_p (O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n )
);



endmodule