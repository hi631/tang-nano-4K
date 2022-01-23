module video_top (
    input             I_clk           , // 27Mhz
    input             I_rst_n,I_ukey2_n,
    output     [0:0]  O_hpram_ck , O_hpram_ck_n, O_hpram_cs_n, O_hpram_reset_n,
    inout      [7:0]  IO_hpram_dq     ,
    inout      [0:0]  IO_hpram_rwds   ,
    output            O_tmds_clk_p, O_tmds_clk_n,
    output     [2:0]  O_tmds_data_p, O_tmds_data_n,	//{r,g,b}   
    output  		  uart0_txd,
    input   		  uart0_rxd,
    output       	  O_led,
	output [3:0] 	  leds
);

assign O_led = running;
assign leds  = { gpioout[0],psig[2:0]};
//==================================================
//Hyperram
wire        dma_clk, memory_clk, mem_pll_lock  ;
//rgb data
wire        rgb_vs, rgb_hs, rgb_de;
wire [23:0] rgb_data   ;  
// HDMI TX
wire serial_clk, pix_clk, clk_12M;
wire hdmi_rst_n, pll_lock;
//===================================================
wire  running = run_cnt < 24'h10000 ? 1'b1 : 1'b0;
reg [3:0] psig; 
reg  [23:0] run_cnt;
always @(posedge dma_clk or negedge rst_n) begin
    if(!rst_n) begin run_cnt <= 32'd0; psig <= 0; end
	else             run_cnt <= run_cnt + 1'b1;
end
reg  [7:0]  dmadiv;  
always @(posedge dma_clk) begin dmadiv <= dmadiv + 8'd1; end

wire   rst_n = I_rst_n && mem_pll_lock && pll_lock;
assign XCLK  = clk_12M;
//================================================
GW_PLLVR GW_PLLVR_inst(
    .clkout(memory_clk    ), //output clkout 159MHz(53/9) -> 148.5MH(11/2)z
    .lock  (mem_pll_lock  ), //output lock
    .clkin (I_clk         )  //input clkin   27MHz
);
TMDS_PLLVR TMDS_PLLVR_inst(		// in=27M out=360M outd=12M lock
	.clkin      (I_clk     )    //input clk      27M 
	,.clkout    (serial_clk)    //output clk     371.25MHz(55/4) -> 360MHz
	,.clkoutd   (clk_12M   )    //output clkoutd 12.375MHz       -> 12MHz  ForUSB
	,.lock      (pll_lock  )    //output lock
);
CLKDIV u_clkdiv(
	.RESETN(hdmi_rst_n)
	,.HCLKIN(serial_clk) //clk  x5
	,.CLKOUT(pix_clk)    //clk  x1
	,.CALIB (1'b1)
);
defparam u_clkdiv.DIV_MODE="5";
// VRAM Control
wire cmd     = runseq==1 ? cmd1    : hpwexe ? cmd3    : cmd2;
wire cmd_en  = runseq==1 ? cmd1_en : hpwexe ? cmd3_en : cmd2_en; 
wire [31:0] wr_data   = runseq==1 ? wr1_data : wr2_data; 
wire [19:0] hprwadr   = ~hpwexe ? runseq==1 ? hpiadr : hpradr : hpwadr; 
wire  [3:0] data_mask = (maskbit[hpwdct] || runseq==1) ? 4'b0000 : 4'b1111 ;
//wire [15:0] bit2cd = ifcgdtw[15] ? 16'hffff : 16'h0000;
wire [15:0] bit2cd = ifcgdtw[15] ? fcolor : bcolor;

reg			cmd1, cmd1_en, cmd2, cmd2_en, cmd3, cmd3_en;
reg         hpwexe,hpwen, rgb_vsd, rgb_vsc;
wire        rd_data_valid, init_calib;
wire [31:0] rd_data;
reg  [19:0]	hpradr, hpiadr, hpwadr, hpnadr;	// 22bit -> 20
reg  [5:0]  cgadct;
reg  [2:0]  hpwdct, hpwlct;

reg  [31:0] wr1_data, wr2_data;
reg         wr_wait; 
reg  [15:0] wr_loop;
reg  [7:0]  wr_line;
reg  [6:0]  blkct, blkct1, blkctx, linct;
reg  [1:0]  runseq, runseq_ret, hpwseq;
reg         maskmd;
reg  [7:0]  maskbit;

// mcu.I/F
reg  [31:0] ifwlbf [0:8];
reg  [19:0] msadr, mdadr, mdlen;
reg  [15:0] colptn, fcolor, bcolor;
reg   [7:0] ifwmask, pspos;
reg  [15:0] ifcgdtw, ifbitd, ifbitt;
reg   [5:0] ifrwbfp;
reg   [3:0] ifrwseq;
reg   [3:0] ifbitlp;
reg         mcuclkd, mcudird, ifwreq, ifrreq, ifwexe, ifrreqf;
reg         mmmdrw, mmmdexe, mmmdfil,mmmdch;
reg         mmmdps, mmmdpsw, mmmdpg;
reg         ifwexed;
reg         mcuclk, mcudir;
wire [15:0] gpioin;		// mcu.input  mcu <- fpga
wire [15:0] gpioout;	// mcu.output mcu -> fpga
wire [7:0]  mcuin  = gpioout[7:0];	// mcu <- fpga
wire [7:0]  mcuout;					// mcu -> fpga
assign gpioin[7:0] = mcudir ? 8'hz : mcuout;
assign mcuout = ifrwseq!=6 ? { 7'h00, ifwexe || mmmdexe || mmmdpsw} :
				ifrwbfp[1:0]==2'b00 ? ifwlbf[ifrwbfp[5:2]][ 7: 0] :
				ifrwbfp[1:0]==2'b01 ? ifwlbf[ifrwbfp[5:2]][15: 8] :
				ifrwbfp[1:0]==2'b10 ? ifwlbf[ifrwbfp[5:2]][23:16] :
				                      ifwlbf[ifrwbfp[5:2]][31:24] ;

always @(posedge dma_clk or negedge rst_n) begin
    if(!rst_n) begin
		ifrwseq <= 0; ifrwbfp <= 0; ifwreq <= 0; ifrreq <= 0; ifrreqf <= 0;
		mmmdrw <= 0; mdlen <= 0; mmmdexe <= 0; mmmdch <= 0; 
		mmmdps <= 0; mmmdpsw <= 0; mmmdpg <= 0;
		fcolor <= 16'hffff; bcolor <= 16'h0000;
		ifbitlp <= 0;
	end else begin
		mcuclk <= gpioout[8]; mcudir <= gpioout[9];	// 0:mcu.in  1:mcu.out
		mcuclkd <= mcuclk; mcudird <= mcudir; ifwexed <= ifwexe;
		//
		if(mcudir && ~mcudird) begin ifrwseq <= 1; ifrwbfp <= 0; end
		if(ifrwseq==0) begin
			if(cmd3_en) begin
				if(ifrreqf) begin ifrreqf <= 0; ifrwbfp <= 0; ifrwbfp <= 4; ifrwseq <= 4; end 
				if(mmmdch) begin mmmdch <= 0; end 
				if(mmmdpsw) begin mmmdps <= 0; mmmdpsw <= 0; end
			end
			//
			if(mdlen!=0) begin 
				if(~ifwexe && ~ifrreqf) begin
					if(~mmmdfil && mmmdrw==0) begin 
						ifwlbf[0] <= msadr; msadr <= msadr +  20'd32;
						ifrreq <= 1; ifrreqf <= 1; ifrwseq <= 2; 
					end else begin
						ifwlbf[0] <= mdadr; mdadr <= mdadr + 20'd32; 
						mdlen <= mdlen - 20'd32; 
						ifwmask <= 8'hff; ifwreq <= 1; ifrwseq <= 2; 
					end
					mmmdrw <= ~mmmdrw;
				end
			end else 
				if(ifwexe) begin mmmdexe <= 0; mmmdfil <= 0; end
		end
		//
		case(ifrwseq)
			4'h1: 
				if(mcudir) begin 
					if(mcuclk && ~mcuclkd) begin
						case(ifrwbfp[1:0])
							2'b00: ifwlbf[ifrwbfp[5:2]][ 7: 0] <= mcuin;
							2'b01: ifwlbf[ifrwbfp[5:2]][15: 8] <= mcuin;
							2'b10: ifwlbf[ifrwbfp[5:2]][23:16] <= mcuin;
							2'b11: ifwlbf[ifrwbfp[5:2]][31:24] <= mcuin;
						endcase
						ifwmask <= mcuin;	// if [37]
						ifrwbfp <= ifrwbfp + 6'd1;
					end
				end else
					if(ifrwbfp==37) begin 									// 37 set_vram
							ifwreq <= 1; ifrwseq <= 2;
					end else if(ifrwbfp==4)  begin							//  4 get_vram 
						ifrreq <= 1; ifrreqf <= 1; ifrwseq <= 2;
					end else if(ifrwbfp==5) begin							//  5 pget adr(4)+bitpos(1)
						mmmdpg <= 1; ifrreq <= 1; ifrreqf <= 1; ifrwseq <= 2;
						pspos <= ifwlbf[1][7:0];
					end else if(ifrwbfp==6) begin							//  6 disp.font adr(4)+cgdata(1)+mask(1)
						mmmdch <= 1;
						ifcgdtw <= {ifwlbf[1][7:0],ifwlbf[1][7:0]}; ifwmask <= ifwlbf[1][15:8];
						ifbitlp <= 0; ifrwseq <= 3;
					end else if(ifrwbfp==7) begin							//  7 pset adr(4)+ptn(2)+bitpos(1)
						mmmdps <= 1;
						colptn <= ifwlbf[1][15:0]; pspos <=  ifwlbf[1][23:16]; 
						ifrreq <= 1; ifrreqf <= 1; ifrwseq <= 2;
					end else if(ifrwbfp==8) begin							//  8 F.Color B.olor
							fcolor <= ifwlbf[1][15:0]; bcolor <= ifwlbf[1][31:16];
					end else if(ifrwbfp==10 || ifrwbfp==12) begin			// 10 12 Move or Clear
						if(ifrwbfp==10) begin mmmdfil <= 1; colptn <= ifwlbf[2][15:0]; end 
						else                  mmmdfil <= 0; 
						mmmdexe <= 1;
						mdadr <= ifwlbf[0][19:0]; mdlen <= ifwlbf[1][19:0]; 
						msadr <= ifwlbf[2][19:0]; mmmdrw <= 0; ifrwseq <= 0;
					end else ifrwseq <= 0;
			//
			4'h2: if(ifwexe) begin ifwreq <= 0; ifrreq <= 0; ifrwseq <= 0; end
			//
			4'h3: begin
					ifbitd <= bit2cd;
					if(ifbitlp[0]) ifwlbf[ifbitlp[3:1]+1] <= {bit2cd,ifbitd};
					ifcgdtw <= {ifcgdtw[14:0],1'b0};
					ifbitlp <= ifbitlp + 4'd1;
					if(ifbitlp==4'd15) begin ifwreq <= 1; ifrwseq <= 2; end
				end
			//
			4'h4: begin
				if(rd_data_valid) begin
					ifwlbf[ifrwbfp[5:2]] <= rd_data;
					ifrwbfp[5:2] <= ifrwbfp[5:2] + 4'd1;
				end else
				if(ifrwbfp==6'd36)
					if     (mmmdps)     ifrwseq <= 7; 
					else if(mmmdexe==0) ifrwseq <= 5; 
					else                ifrwseq <= 0; 
			end
			4'h5: begin
				if(mcuclk && ~mcuclkd)  begin 
					ifrwbfp <= 4; ifrwseq <= 6;
					if(mmmdpg) 
						if(~pspos[0]) ifwlbf[1][15:0] <= ifwlbf[pspos[4:1]+1][15: 0];
 						else          ifwlbf[1][15:0] <= ifwlbf[pspos[4:1]+1][31:16];
 				end	
			end
			4'h6: begin
				if(mcuclk && ~mcuclkd) ifrwbfp <= ifrwbfp + 6'd1;
				if(~mcuclk && mcuclkd) begin
					if(ifrwbfp==6'd35) ifrwseq <= 0;
					if(ifrwbfp==6'd5 && mmmdpg) begin mmmdpg<= 0; ifrwseq <= 0; end
				end
				ifrreqf <= 0; 
			end
			4'h7: begin
				if(~pspos[0]) ifwlbf[pspos[4:1]+1][15: 0] <= colptn;
 				else          ifwlbf[pspos[4:1]+1][31:16] <= colptn;
				ifwmask <= 8'hff; ifwreq <= 1; mmmdpsw <= 1; ifrwseq <= 2;
			end
		endcase
		//
	end
end

reg  [4:0]  cmd_bsyc;
reg  cmd_bsyd;
wire cmd_bsy = cmd_en || cmd_bsyd || rd_data_valid;
always @(posedge dma_clk or negedge rst_n) begin
    if(!rst_n) begin
		cmd_bsyc <= 0; cmd_bsyd <= 0;
	end else begin
		if(cmd_en) begin cmd_bsyc <= 19-4; cmd_bsyd <= 1; end
		else
			if(cmd_bsyc!=0) cmd_bsyc <= cmd_bsyc - 5'd1;	
			else            cmd_bsyd <= 0;
	end
end
localparam hpramtop = 0;
always @(posedge dma_clk or negedge rst_n) begin
    if(!rst_n) begin
		cmd3 <= 0; cmd3_en <= 0; hpwseq <= 0; hpwadr <= hpramtop;
		hpwexe <= 0; hpwen <= 0; hpnadr <= hpramtop; 
		ifwexe <= 0;
	end else begin
		// Write
		if(runseq>1) begin
			if(hpwen || ifwreq || ifrreq) begin
				hpwen <= 0; hpwseq <= 1; hpwlct <= 0; cgadct <= 0; 
				if(ifwreq) begin maskbit <= ifwmask; hpwadr <= ifwlbf[0][19:0]; ifwexe <= 1; cmd3 <= 1; end
				else if(ifrreq) begin maskbit <= ifwmask; hpwadr <= ifwlbf[0][19:0]; ifwexe <= 1; cmd3 <= 0; end
				else maskbit <= 8'h0f;
			end
			else
			//
			case(hpwseq)
				2'd1: if(~cmd_bsy && ~vrambsy) begin 
						cmd3_en <= 1; hpwexe <= 1; hpwdct <= 7;
						cgadct <= cgadct + 6'd1; hpwseq <= 2; 
					end
 				2'd2: begin 
					cmd3_en <= 0; hpwdct <= hpwdct - 3'd1; 
					if(hpwdct==0) begin
						hpwlct <= hpwlct + 3'd1; hpwadr <= hpwadr + 20'd1280; // (640*2);	
						if(hpwlct==7 || ifwexe) hpwseq <= 3; 
						else		  hpwseq <= 1;
					end
				end
				2'd3: begin 
					hpwexe <= 0; hpwseq <= 0; 
					if(ifwmask[3:0]==4'h0) hpnadr <= hpwadr;
					else                   hpnadr <= hpwadr + 20'd16; 
					//hpwadr <= hpwadr - 20'd10208; // + 32 - (640*2*8); 
					//hpwadr <= hpwadr - 20'd10768; // + 32 - (640*2*10); 
					if(ifwexe) ifwexe <= 0;
				end 
			endcase
			if(cgadct[2:0]!=0) cgadct <= cgadct + 6'd1;
			if(~mmmdfil) wr2_data <= ifwlbf[cgadct+1];
			else         wr2_data <= {colptn,colptn}; 
		end
	end
end

wire rgbfull = dbradrc[dbrbs-1:4]==dbwadr_next[dbwbs-1:3] ? 1 : 0;
reg  rgbfulld, vrambsy, rgb_hsc, rgb_hsd, linoe, start_de;
wire rgb_hs_upm = (rgb_hsc && ~rgb_hsd);
wire rgb_hs_dnm = (~rgb_hsc && rgb_hsd);
always @(posedge dma_clk or negedge rst_n) begin
    if(!rst_n) begin
		runseq <= 0; cmd2 <= 0; cmd2_en <= 0;   
		hpradr <= hpramtop; blkct <= 0; linct <= 0; linoe <= 0; vrambsy <= 0; 
	end else begin
		rgb_vsc <= rgb_vs; rgb_vsd <= rgb_vsc; dbradrc <= dbradr;
		rgbfulld <= rgbfull; 
		rgb_hsc <= rgb_hs; rgb_hsd <= rgb_hsc;
		if(rgb_hs_upm && ~linoe) vrambsy <= 1;
		if(rgb_hs_dnm) begin blkct <= 0; linoe <= ~linoe; end
		
		if(rgb_vs) start_de <= 0;
		if(rgb_de) start_de <= 1;
 
		case (runseq)
			2'd0: if(init_calib) begin runseq <= 1; end
			2'd1: runseq <= 2; //runseq <= runseq_ret; // Write Dumy.Data
			2'd2: begin
				hpradr <= hpramtop;  
				if(~rgb_vsc && rgb_vsd) begin blkct <= 0; linct <= 0; runseq <= 3; end 
			end
			2'd3: if(rgb_vsc) runseq <= 2;
				else begin
				// VRAM Read
				if( ~cmd_bsy && blkct<40 && linoe && start_de) begin
					cmd2_en <= 1; cmd2 <= 0;	// 0:Read
					 
				end else
				if(cmd2_en) begin 
					cmd2_en <= 0; 
					//if(blkct>=79) begin blkct <= 0; linct <= linct + 7'd1; end
					//else          
					blkct <= blkct + 7'd1;
					if(blkct==39) vrambsy <= 0;
					//if(blkct==39) hpradr <= hpradr - 20'd1248; // + 32 - 640*2;	// Re.Read
					//else          hpradr <= hpradr + 20'd32;			// Next.Block
					hpradr <= hpradr + 32; 
				end
			end
		endcase
	end 
end

localparam dbrbs = 10;	// max=10
localparam dbwbs = dbrbs - 1;
wire [15:0] dbfout;
reg         rd_rdy, rd_data_validd, trigf;
reg         rgb_hsp, rgb_hspd;
reg  [dbrbs-1:0] dbradr,dbradrc;	// 2048/2=1024=3FF
reg  [dbwbs-1:0] dbwadr;
wire [dbwbs-1:0] dbwadr_next = dbwadr + 9'd8;

always @(negedge dma_clk or negedge rst_n) begin
	if(!rst_n) begin dbwadr <= 0; rd_rdy <= 0; end
	else begin
		rd_data_validd <= rd_data_valid;
		rgb_hsp <= rgb_hs; rgb_hspd <= rgb_hsp;
		if(cmd2_en) rd_rdy <= 1;
		else
			if(~rd_data_valid && rd_data_validd) rd_rdy <= 0;
		if(rgb_vsc || rgb_hs_dnm) dbwadr <= 0;
		else
			if(rd_data_valid && rd_rdy) dbwadr <= dbwadr + 9'd1;
	end			
end

reg  [11:0] scanx; 
reg  [19:0] scany;
wire [19:0] csradr = scany+{8'h00,scanx};
wire csrval = csrvalr && run_cnt[23];
reg  [3:0]  csrvalc; 
reg         rgb_ded, csrvalr, hsharf, vsharf;
always @(posedge pix_clk or negedge rst_n) begin
    if(!rst_n) begin 
		dbradr <= 0; vsharf <= 0; hsharf <= 1; scanx <= 0; scany <= 0;
	end else begin
		hsharf <= ~hsharf; rgb_ded <= rgb_de;
		if(rgb_hs) dbradr <= 0; ;
		if(rgb_vs ) begin 
			vsharf <= 0; hsharf <= 1; scanx <= 0; scany <= 0; 
		end else 
			if(rgb_de && hsharf) dbradr <= dbradr + 10'd1;	// 16bit/pix
		//
		if(rgb_de && ~rgb_ded) begin 
			if(vsharf) scany <= scany + 20'd1280; 
			scanx <= 0;	vsharf <= ~vsharf; 
		end else if(rgb_de && hsharf) scanx <= scanx + 12'd2;
		//
		if(ifrwseq==0) begin
			if((hpnadr[19:2]+3)==csradr[19:2]) begin csrvalr <= 1; csrvalc <= 15; end
			if(csrvalc!=0) csrvalc <= csrvalc - 4'd1; 
			else csrvalr <= 0;
		end
	end
end

//================================================
Gowin_EMPU_Top empu(
	.reset_n(rst_n), .sys_clk(pix_clk),
	.gpioin(gpioin), .gpioout(gpioout), .gpioouten(),
	.uart0_rxd(uart0_rxd), .uart0_txd(uart0_txd),
	.uart1_rxd(1'b0), .uart1_txd(uart1_txd)
);

Gowin_SDPB_32x16 vramtmp(	// input=32bit  output=16bit
	.reseta(~rst_n), .cea(rd_data_valid), .clka(~dma_clk), 
	.ada(dbwadr), .din(rd_data),
	.resetb(~rst_n), .ceb(1'b1), .oce(1'b1),  .clkb(pix_clk),
	.adb(dbradr),  .dout(dbfout)
);

//HyperRAM ip
HyperRAM_Memory_Interface_Top HyperRAM_Memory_Interface_Top_inst (
    .rst_n(rst_n && I_ukey2_n), 
	.clk(I_clk),.memory_clk(memory_clk     ),
    .clk_out(dma_clk), .pll_lock(mem_pll_lock),
    .O_hpram_reset_n(O_hpram_reset_n), .O_hpram_ck(O_hpram_ck),
    .O_hpram_ck_n(O_hpram_ck_n), .O_hpram_cs_n(O_hpram_cs_n),
    .IO_hpram_rwds(IO_hpram_rwds), .IO_hpram_dq(IO_hpram_dq),
    .addr({2'b00,hprwadr[19:0]}), .wr_data(wr_data), .rd_data(rd_data), .rd_data_valid(rd_data_valid),
    .cmd(cmd), .cmd_en(cmd_en), .data_mask(data_mask), .init_calib(init_calib)
); 
//================================================
wire out_de;
syn_gen syn_gen_inst (	//1280x720 74.25MHz
    .I_pxl_clk(pix_clk), .I_rst_n(hdmi_rst_n), 
    .I_h_total(16'd1650), .I_h_sync(16'd40), .I_h_bporch(16'd220), .I_h_res(16'd1280),
    .I_v_total(16'd750), .I_v_sync(16'd5), .I_v_bporch(16'd20), .I_v_res(16'd720),
    .I_rd_hres(16'd1280), .I_rd_vres(16'd720 ),
    .I_hs_pol(1'b1), .I_vs_pol(1'b1),
    .O_rden(syn_off0_re), .O_de(out_de), .O_hs(syn_off0_hs), .O_vs(syn_off0_vs)
);

localparam N = 5; //delay N clocks
reg  [N-1:0]  Pout_hs_dn   ;
reg  [N-1:0]  Pout_vs_dn   ;
reg  [N-1:0]  Pout_de_dn   ;
always@(posedge pix_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) begin                          
		Pout_hs_dn  <= {N{1'b1}}; Pout_vs_dn  <= {N{1'b1}}; Pout_de_dn  <= {N{1'b0}}; 
	end else begin                          
		Pout_hs_dn <= {Pout_hs_dn[N-2:0],syn_off0_hs}; Pout_vs_dn <= {Pout_vs_dn[N-2:0],syn_off0_vs}; Pout_de_dn  <= {Pout_de_dn[N-2:0],out_de}; 
	end
end
//==============================================================================
//TMDS TX
assign rgb_data    = csrval ? 24'h00ffff : {dbfout[15:11],3'd0,dbfout[10:5],2'd0,dbfout[4:0],3'd0};
assign rgb_vs      = Pout_vs_dn[4];//syn_off0_vs;
assign rgb_hs      = Pout_hs_dn[4];//syn_off0_hs;
assign rgb_de      = Pout_de_dn[4];//off0_syn_de;

assign hdmi_rst_n = rst_n & pll_lock;
DVI_TX_Top DVI_TX_Top_inst (
    .I_rst_n(hdmi_rst_n), .I_serial_clk(serial_clk), .I_rgb_clk(pix_clk), .I_rgb_vs(rgb_vs), .I_rgb_hs(rgb_hs), .I_rgb_de(rgb_de), 
    .I_rgb_r(rgb_data[23:16]), .I_rgb_g(rgb_data[15: 8]), .I_rgb_b(rgb_data[ 7: 0]),  
    .O_tmds_clk_p(O_tmds_clk_p), .O_tmds_clk_n(O_tmds_clk_n), .O_tmds_data_p(O_tmds_data_p), .O_tmds_data_n(O_tmds_data_n)
);
/*
always @(posedge dma_clk or negedge rst_n) begin
    if(!rst_n) begin
		cmd1 <= 0; cmd1_en <= 0; runseq_ret <= 1;
		wr_wait <= 0; wr_loop <= 0; wr_line = 0; blkct1 <= 0;
		wr1_data <= 0; hpiadr <= hpramtop;
	end else begin
		if(runseq==1) begin
			if(cmd1_en) begin cmd1_en <= 0; cmd1 <= 0; end
			wr_wait <= 1;//wr_wait + 1;
			if(wr_wait!=0 && ~cmd_bsy) begin
				wr_wait <= 0; wr_loop <= wr_loop + 16'd1;
				hpiadr <= hpiadr + 22'd32;
				if(wr_loop>=(1280*720)/32-1) runseq_ret <= 2; 
			end else begin
				if(wr_wait==0 ) begin 
					cmd1_en <= 1; cmd1 <= 1;	// 1:write
					if(blkct1>=39) begin wr_line <= wr_line + 8'd1 ; blkct1 <= 0; end
					else           blkct1 <= blkct1 + 7'd1;
					blkctx <= blkct1 + 7'd12;
					case(blkct1[1:0])
						2'b00:  wr1_data <= 32'h7bef7bef;
						2'b01:  wr1_data <= 32'h78007800;
						2'b10:  wr1_data <= 32'h03e003e0;
						2'b11:  wr1_data <= 32'h000f000f;
					endcase
				end else
					wr1_data <= {5'h0,blkctx[6:1],wr_line[5:1],5'h0,blkctx[6:1],wr_line[5:1]};
					//wr1_data <= 32'h00070007;
			end
		end
	end
end
*/

endmodule
