//
// MCP I/O Expander - Unified support for MCP23009 and MCP23017
// Auto-detects which chip is present and provides unified interface
//
module mcp_io_expander
(
	input            clk,

	// MCP23009 compatible interface (works with both chips)
	output reg [2:0] btn,
	input      [2:0] led,
	output reg       flg_sd_cd,
	output reg       flg_present,
	output reg       flg_mode,

	// Additional GPIO for MCP23017 (unused if MCP23009 is present)
	output reg [7:0] spare_out,
	input      [7:0] spare_in,

	output	         scl,
	inout 	         sda
);

// Auto-detection state
reg        use_mcp23017 = 0;
reg        detection_done = 0;
reg [15:0] detect_timer = 0;

// MCP23009 signals
wire [2:0] mcp9_btn;
wire       mcp9_sdcd, mcp9_present, mcp9_mode;
wire       mcp9_scl;
wire       mcp9_sda;

// MCP23017 signals  
wire [2:0] mcp17_btn;
wire       mcp17_sdcd, mcp17_present, mcp17_mode;
wire [2:0] mcp17_spare;
wire [7:0] mcp17_gpiob;
wire       mcp17_scl;
wire       mcp17_sda;

// Instantiate MCP23009 (tries address 0x20)
mcp23009 mcp23009_inst
(
	.clk(clk),
	.btn(mcp9_btn),
	.led(led),
	.flg_sd_cd(mcp9_sdcd),
	.flg_present(mcp9_present),
	.flg_mode(mcp9_mode),
	.scl(mcp9_scl),
	.sda(mcp9_sda)
);

// Instantiate MCP23017 (tries address 0x21)
mcp23017 mcp23017_inst
(
	.clk(clk),
	.btn(mcp17_btn),
	.led(led),
	.flg_sd_cd(mcp17_sdcd),
	.flg_present(mcp17_present),
	.flg_mode(mcp17_mode),
	.gpioa_spare(mcp17_spare),
	.gpioa_spare_in(spare_in[2:0]),
	.gpiob_out(mcp17_gpiob),
	.gpiob_in(spare_in),
	.scl(mcp17_scl),
	.sda(mcp17_sda)
);

// Auto-detection logic
always @(posedge clk) begin
	if (!detection_done) begin
		detect_timer <= detect_timer + 1;
		if (&detect_timer) begin  // After full timer cycle
			detection_done <= 1;
			// Prefer MCP23017 if both respond, otherwise use whichever responds
			if (mcp17_present) begin
				use_mcp23017 <= 1;
			end else if (mcp9_present) begin
				use_mcp23017 <= 0;
			end
		end
	end
end

// Output selection based on detected chip
always @(*) begin
	if (detection_done && use_mcp23017 && mcp17_present) begin
		// Use MCP23017
		btn = mcp17_btn;
		flg_sd_cd = mcp17_sdcd;
		flg_present = mcp17_present;
		flg_mode = mcp17_mode;
		spare_out = {mcp17_spare, mcp17_gpiob[7:3]};  // Combine GPIOA[7:5] + GPIOB[7:3]
	end else begin
		// Use MCP23009 or default
		btn = mcp9_btn;
		flg_sd_cd = mcp9_sdcd;
		flg_present = mcp9_present;
		flg_mode = mcp9_mode;
		spare_out = 8'h00;  // No spare GPIO
	end
end

// I2C signal routing
assign scl = (detection_done && use_mcp23017 && mcp17_present) ? mcp17_scl : mcp9_scl;
assign sda = (detection_done && use_mcp23017 && mcp17_present) ? mcp17_sda : mcp9_sda;

endmodule