module test_mcu_top (
    input   reset_n,
    input   sys_clk,
	input	ukey2_n,
    // SPI (From JTAG)
    input   TCK,
    input   TDI,
    output  TDO,
    output  TMS,
    // SPI (mcu)
    //output  sclk,
    //output  mosi,
    //input   miso,
    // UART0 (Debug)
    output  uart0_txd,
    input   uart0_rxd,
	output [3:0] leds
    );

//assign leds = { gpioout[1:0],leds2s[1:0]};
assign leds = { gpioout[1:0],leds2s[1:0]};

   wire clkmpu;
   Gowin_PLLVR clkgen(
        .clkout(clkmpu),    // 27MHz/3*8=72MHz
        .lock(),            //output lock
        .reset(~reset_n),   //input reset
        .clkin(sys_clk)     //input clkin
    );

wire [15:0] gpioin,gpioout;
assign gpioin[15]   = 0;//jifull;	// JTAG.SPI Input.Busy
assign gpioin[14]   = mifull;	// mcu.spi  Output.Busy
assign gpioin[13]   = ukey2_n; // ~ukey2_n;	// SPI.Mode(USR_KEY2) 
assign gpioin[12:0] = gpioout[12:0];	// Loop.Back

	Gowin_EMPU_Top emup(
		.sys_clk(clkmpu),       //input sys_clk
		.rtc_src_clk(clkmpu),   //input rtc_src_clk
		//.gpio(gpio),            //inout [15:0] gpio
		.gpioin(gpioin), 		//input [15:0] gpioin
		.gpioout(gpioout), 	//output [15:0] gpioout
		.uart0_rxd(uart0_rxd),  //input  uart0_rxd
		.uart0_txd(uart0_txd),  //output uart0_txd
		.uart1_rxd(uart1_rxd),  //input  uart1_rxd
		.uart1_txd(uart1_txd),  //output uart1_txd
		.scl(), //inout scl
		.sda(), //inout sda
		.mosi(mosi), //output mosi
		.miso(miso), //input miso
		.sclk(sclk), //output sclk
		.nss() , //output nss
		.reset_n(reset_n)       //input reset_n
	);

// Make Dumy.Data
reg dtck, dtdi, dsclk,dmosi;
reg [1:0] divct;
reg [7:0] wttim;
reg [7:0] dbdt, dmct; 
always @(posedge clkmpu or negedge reset_n) begin
	if (!reset_n) begin
		wttim <= 8'hfe; dbdt <= 0;
	end else begin
		dbdt <= {dmct[7:4],dmct[7:4]};
		divct <= divct + 1;
		if(divct[0]==0) begin	// 27MNz/2 = 13.5MHz
			//if(wttim!=8'hff) 
				wttim <= wttim - 1;
			if(wttim[7:5]==2'b001 && wttim[4]==1'b0) begin
				dtck  <= wttim[0]; dtdi  <= dbdt[wttim[3:1]];
				dmct <= dmct + 1;
			end else begin
				dtck  <= 0; dtdi  <= 0;
			end
			//if(wttim[7:6]==2'b00)
			//	if(jdused) dsclk <= wttim[0]; else dsclk <= 0;
			dmosi <= 0;
		end
	end
end

wire jifull, mifull;
wire [3:0] leds2s;
    spi_s2s spi_s2s(
		.sys_clk(clkmpu),
		.reset_n(reset_n),
		.miclk(sclk), .misdt(mosi), .mosdt(miso),		// From mcu
		//.miclk(dsclk), .misdt(dmosi), .mosdt(miso),		// From Dumy(mcu)
		.jiclk(TCK), .jisdt(TDI), .josdt(TDO),			// From JTAG 
		//.jiclk(dtck), .jisdt(dtdi), .josdt(dtd0),		// From Dumy(JTAG)
		.mifull(mifull),
		.jifull(jifull),
		.leds(leds2s)
    );

endmodule

module spi_s2s(
	input	sys_clk,
	input	reset_n,
	input	miclk,
	input	misdt,
	output  josdt,
	output reg mifull,
	input	jiclk,
	input	jisdt,
	output	mosdt,
	output reg jifull,
	output [3:0] leds
);

assign josdt = mdused==1 ? mrbdt[jiclkct] : 0;
assign mosdt = jdused==1 ? jrbdt[miclkct] : 0;
assign leds = {2'b00,jdused,mdused};
reg [2:0] miclkct, jiclkct; 
reg [7:0] mwbdt, mrbdt, jwbdt, jrbdt;
reg       mdused, mdtemp, mclkt7, jdused, jdtemp, jclkt7;
reg [7:0] jclkchk, mclkchk;
always @(posedge miclk) begin
	mwbdt <= {mwbdt[6:0],misdt}; // byte <- bit(8) miclk _|
end
always @(negedge miclk or negedge reset_n) begin
	if (!reset_n) begin miclkct <= 7; mclkt7 <= 0; end
	else begin
		if(miclkadj) miclkct <= 6; // Fix Clock Error
		else begin
			//if(mdbwp[1]==1'b1 && miclkct==5) miclkct <= 1; else // use Debug
			miclkct <= miclkct - 1;
			if(miclkct!=0) mclkt7 <= 0;
			else           mclkt7 <= 1;
		end
	end
end

always @(posedge jiclk) begin
	jwbdt <= {jwbdt[6:0],jisdt}; // byte <- bit(8) jiclk _|
end
always @(negedge jiclkd or negedge reset_n) begin
	if (!reset_n) begin jiclkct <= 7; jclkt7 <= 0; end
	else begin
		if(jiclkadj) jiclkct <= 6; // Fix Clock Error
		else begin
			//if(jdbwp[1]==1'b1 && jiclkct==5) jiclkct <= 1; else // use Debug
			jiclkct <= jiclkct - 1;
			if(jiclkct!=0) jclkt7 <= 0;
			else           jclkt7 <= 1;
		end
	end
end

reg miclkc, jiclkc, miclkd, jiclkd;
reg mclkt7d, jclkt7d, mclkt7c, jclkt7c, mclkt7p, jclkt7p;
reg jiclkadj, miclkadj;
reg [7:0] jdbuf[0:15], mdbuf[0:15];
reg [3:0] jdbwp, jdbrp, jdbwn, mdbwp, mdbrp,mdbwn;
reg       trigf;
always @(posedge sys_clk or negedge reset_n) begin
	if (!reset_n) begin
		jdused <= 0; mdused <= 0; jifull <= 0; mifull <= 0;
		jdbwp <= 0; jdbrp <= 0; mdbwp <= 0; mdbrp <= 0;
		jclkchk <= 0; mclkchk <= 0; jiclkadj <= 0; miclkadj <= 0;
		jdbwn <= 8'h02; mdbwn <= 8'h02;
	end else begin
		miclkc <= miclk; miclkd <= miclkc;
		jiclkc <= jiclk; jiclkd <= jiclkc;
		mclkt7c <= mclkt7; mclkt7d <= mclkt7c;
		if(mclkt7c && ~mclkt7d) mclkt7p <= 1; else mclkt7p <= 0; //posedge
		jclkt7c <= jclkt7; jclkt7d <= jclkt7c;
		if(jclkt7c && ~jclkt7d) jclkt7p <= 1; else jclkt7p <= 0; //posedge

		// mdbuf.write & jdbuf.read
		if(mclkt7p) begin
			if(mdbwn==mdbrp) mifull <= 1; 
			if(mwbdt!=0) begin 
				mdbuf[mdbwp] <= mwbdt; mdbwn <= mdbwn + 1; mdbwp <= mdbwp + 1; end
			//if(jdbrp!=jdbwp) jdbrp <= jdbrp + 1;	// jdbuf.rp
			if(jdbwp!=jdbrp) begin
				jrbdt <= jdbuf[jdbrp]; jdbrp <= jdbrp + 1;
				 jdused <= 1; jifull <= 0;
			end else jdused <= 0;
		end
		// jdbuf write & mdbuf read
		if(jclkt7p) begin
			if(jdbwn==jdbrp) jifull <= 1; 
			if(jwbdt!=0) begin 
				jdbuf[jdbwp] <= jwbdt; jdbwn <= jdbwn + 1; jdbwp <= jdbwp + 1; end
			if(mdbwp!=mdbrp) begin
				mrbdt <= mdbuf[mdbrp]; mdbrp <= mdbrp + 1; 
				mdused <= 1; mifull <= 0;
			end else mdused <= 0;
			//if(jwbdt==8'h35) trigf <= 1; else trigf <=0;	// trigger
		end

		// miclk miss check
		if(miclkd && ~miclkc) mclkchk <= 0;
		else begin
			if(mclkchk<8'h1f) begin
				mclkchk <= mclkchk + 1;
				if(mclkchk==8'h00) miclkadj <= 0;
			end else
				if(miclkct!=3'h7)  miclkadj <= 1;
		end 
		// jiclk misss check
		if(jiclkd && ~jiclkc) jclkchk <= 0;
		else begin
			if(jclkchk<8'h3f) begin
				jclkchk <= jclkchk + 1;
				if(jclkchk==8'h00) jiclkadj <= 0;
			end else
				if(jiclkct!=3'h7)  jiclkadj <= 1;
		end 
	end
end



endmodule
