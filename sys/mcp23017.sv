//
// MCP23017 - 16-bit I/O Expander
// Based on MCP23009 by Alexey Melnikov
// 
// This module provides a core-level interface to an MCP23017 I2C I/O expander.
// Unlike the MCP23009 which is part of the MiSTer framework, this module can be
// instantiated by individual cores that need additional I/O pins.
//
// Usage:
// - Connect SCL/SDA to external I2C pins (e.g., USER_OUT pins)
// - Set gpioa_in/gpiob_in to desired output values
// - Read gpioa_out/gpiob_out for input pin states
// - Check 'present' flag to verify device is connected and responding
//
module mcp23017
(
	input            clk,

	// MCP23009 compatible interface
	output reg [2:0] btn,            // Button inputs (compatible with MCP23009)
	input      [2:0] led,            // LED outputs (compatible with MCP23009)
	output reg       flg_sd_cd,      // SD card detect flag
	output reg       flg_present,    // Device present flag
	output reg       flg_mode,       // Mode flag

	// Additional MCP23017 GPIO (spare pins)
	output reg [2:0] gpioa_spare,    // GPIOA spare pins [7:5] (pins 4-0 used for MCP23009 compatibility)
	input      [2:0] gpioa_spare_in, // GPIOA spare inputs
	output reg [7:0] gpiob_out,      // GPIOB full port (8 additional pins)
	input      [7:0] gpiob_in,       // GPIOB inputs

	output	         scl,
	inout 	         sda
);


reg        start = 0;
wire       ready;
wire       error;
reg        rw;
wire [7:0] dout;
reg [15:0] din;

i2c #(50_000_000, 400_000) i2c
(
	.CLK(clk),
	.START(start),
	.READ(rw),
	.I2C_ADDR('h21),        // Different from MCP23009 (0x20) to allow coexistence
	.I2C_WLEN(1),
	.I2C_WDATA1(din[15:8]),
	.I2C_WDATA2(din[7:0]),
	.I2C_RDATA(dout),
	.END(ready),
	.ACK(error),
	.I2C_SCL(scl),
 	.I2C_SDA(sda)
);

always@(posedge clk) begin
	reg  [4:0] idx = 0;
	reg  [1:0] state = 0;
	reg [15:0] timeout = 0;
	reg  [1:0] port_idx = 0;

	if(~&timeout) begin
		timeout <= timeout + 1'd1;
		start   <= 0;
		state   <= 0;
		idx     <= 0;
		port_idx <= 0;
		btn     <= 0;
		gpioa_spare <= 0;
		gpiob_out <= 0;
		rw      <= 0;
		flg_sd_cd   <= 1;
		flg_present <= 0;
		flg_mode    <= 1;
	end
	else begin
		if(~&init_data[idx]) begin
			case(state)
			0:	begin
					start <= 1;
					state <= 1;
					din   <= init_data[idx];
				end
			1: if(~ready) state <= 2;
			2:	begin
					start <= 0;
					if(ready) begin
						state <= 0;
						if(!error) idx <= idx + 1'd1;
					end
				end
			endcase
		end
		else begin
			case(state)
			0:	begin
					start <= 1;
					state <= 1;
					case(port_idx)
						0: din <= {8'h14, gpioa_spare_in, led};  // Write OLATA (3 spare pins [7:5] + 3 LEDs [2:0])
						1: din <= {8'h15, gpiob_in};                            // Write OLATB (full port B)
						2: begin
							din <= {8'h12, 8'h00};     // Read GPIOA
							rw <= 1;
						end
						3: begin
							din <= {8'h13, 8'h00};     // Read GPIOB
							rw <= 1;
						end
					endcase
				end
			1: if(~ready) state <= 2;
			2:	begin
					start <= 0;
					if(ready) begin
						state <= 0;
						if(!error) begin
							flg_present <= 1;
							if(rw) begin
								case(port_idx)
									2: begin
										// MCP23009 compatible mapping: {flg_sd_cd, flg_mode, btn[2:0]} = dout[7:3]
										{flg_sd_cd, flg_mode, btn} <= dout[7:3];
										gpioa_spare <= dout[7:5];  // Spare pins [7:5]
									end
									3: gpiob_out <= dout;
								endcase
							end
							port_idx <= port_idx + 1'd1;
						end
						rw <= 0;
					end
				end
			endcase
		end
	end
end

// MCP23017 initialization sequence
// Register addresses for BANK=0 (default)
wire [15:0] init_data[19] = 
'{
	// Configure both ports
	16'h00FF,  // IODIRA: All pins as inputs
	16'h01FF,  // IODIRB: All pins as inputs
	16'h02FF,  // IPOLA: Input polarity normal
	16'h03FF,  // IPOLB: Input polarity normal
	16'h04FF,  // GPINTENA: Interrupt on change disabled
	16'h05FF,  // GPINTENB: Interrupt on change disabled
	16'h0600,  // DEFVALA: Default value register
	16'h0700,  // DEFVALB: Default value register
	16'h0800,  // INTCONA: Interrupt control
	16'h0900,  // INTCONB: Interrupt control
	16'h0A00,  // IOCON: Configuration (BANK=0, MIRROR=0, SEQOP=0, etc.)
	16'h0B00,  // IOCON: Same as 0x0A (mirrored in BANK=0)
	16'h0CFF,  // GPPUA: Pull-up resistors enabled
	16'h0DFF,  // GPPUB: Pull-up resistors enabled
	16'h0E00,  // INTFA: Interrupt flag register
	16'h0F00,  // INTFB: Interrupt flag register
	16'h1000,  // INTCAPA: Interrupt capture register
	16'h1100,  // INTCAPB: Interrupt capture register
	16'hFFFF   // End marker
};

endmodule