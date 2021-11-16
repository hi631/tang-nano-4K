module test_mcu_top (
    input   reset_n,
    input   sys_clk,
    output  uart0_txd,
    input   uart0_rxd,
    inout [4:0] gpio
    );

   wire clkmpu;
   Gowin_PLLVR your_instance_name(
        .clkout(clkmpu), //output clkout
        .lock(), //output lock
        .reset(~reset_n), //input reset
        .clkin(sys_clk) //input clkin
    );

	Gowin_EMPU_Top emup(
		.sys_clk(clkmpu), //input sys_clk
		.gpio(gpio), //inout [15:0] gpio
		.uart0_rxd(uart0_rxd), //input uart0_rxd
		.uart0_txd(uart0_txd), //output uart0_txd
		.mosi(), //output mosi
		.miso(), //input miso
		.sclk(), //output sclk
		.nss() , //output nss
		.reset_n(reset_n) //input reset_n
	);

endmodule
