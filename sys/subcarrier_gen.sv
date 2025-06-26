//============================================================================
// NTSC/PAL Subcarrier Generator
// Generates subcarrier for composite video using Sony CXA2075
// NTSC: 3.579545 MHz, PAL: 4.433619 MHz
//============================================================================

module subcarrier_gen
(
	input         clk,
	input  [39:0] PHASE_INC,
	input         subcarrier_enable, // 0=disabled, 1=enabled
	input         pal_en,            // 0=NTSC, 1=PAL
	output        subcarrier_out
);

// 40-bit phase accumulator (same as YC module)
logic [39:0] phase_accum;

// 8-bit sine LUT (same as YC module)
wire signed [10:0] sine_LUT[256] = '{
	11'h000, 11'h006, 11'h00C, 11'h012, 11'h018, 11'h01F, 11'h025, 11'h02B, 11'h031, 11'h037, 11'h03D, 11'h044, 11'h04A, 11'h04F, 
	11'h055, 11'h05B, 11'h061, 11'h067, 11'h06D, 11'h072, 11'h078, 11'h07D, 11'h083, 11'h088, 11'h08D, 11'h092, 11'h097, 11'h09C, 
	11'h0A1, 11'h0A6, 11'h0AB, 11'h0AF, 11'h0B4, 11'h0B8, 11'h0BC, 11'h0C1, 11'h0C5, 11'h0C9, 11'h0CC, 11'h0D0, 11'h0D4, 11'h0D7, 
	11'h0DA, 11'h0DD, 11'h0E0, 11'h0E3, 11'h0E6, 11'h0E9, 11'h0EB, 11'h0ED, 11'h0F0, 11'h0F2, 11'h0F4, 11'h0F5, 11'h0F7, 11'h0F8, 
	11'h0FA, 11'h0FB, 11'h0FC, 11'h0FD, 11'h0FD, 11'h0FE, 11'h0FE, 11'h0FE, 11'h0FF, 11'h0FE, 11'h0FE, 11'h0FE, 11'h0FD, 11'h0FD, 
	11'h0FC, 11'h0FB, 11'h0FA, 11'h0F8, 11'h0F7, 11'h0F5, 11'h0F4, 11'h0F2, 11'h0F0, 11'h0ED, 11'h0EB, 11'h0E9, 11'h0E6, 11'h0E3, 
	11'h0E0, 11'h0DD, 11'h0DA, 11'h0D7, 11'h0D4, 11'h0D0, 11'h0CC, 11'h0C9, 11'h0C5, 11'h0C1, 11'h0BC, 11'h0B8, 11'h0B4, 11'h0AF, 
	11'h0AB, 11'h0A6, 11'h0A1, 11'h09C, 11'h097, 11'h092, 11'h08D, 11'h088, 11'h083, 11'h07D, 11'h078, 11'h072, 11'h06D, 11'h067, 
	11'h061, 11'h05B, 11'h055, 11'h04F, 11'h04A, 11'h044, 11'h03D, 11'h037, 11'h031, 11'h02B, 11'h025, 11'h01F, 11'h018, 11'h012, 
	11'h00C, 11'h006, 11'h000, 11'h7F9, 11'h7F3, 11'h7ED, 11'h7E7, 11'h7E0, 11'h7DA, 11'h7D4, 11'h7CE, 11'h7C8, 11'h7C2, 11'h7BB, 
	11'h7B5, 11'h7B0, 11'h7AA, 11'h7A4, 11'h79E, 11'h798, 11'h792, 11'h78D, 11'h787, 11'h782, 11'h77C, 11'h777, 11'h772, 11'h76D, 
	11'h768, 11'h763, 11'h75E, 11'h759, 11'h754, 11'h750, 11'h74B, 11'h747, 11'h743, 11'h73E, 11'h73A, 11'h736, 11'h733, 11'h72F, 
	11'h72B, 11'h728, 11'h725, 11'h722, 11'h71F, 11'h71C, 11'h719, 11'h716, 11'h714, 11'h712, 11'h70F, 11'h70D, 11'h70B, 11'h70A, 
	11'h708, 11'h707, 11'h705, 11'h704, 11'h703, 11'h702, 11'h702, 11'h701, 11'h701, 11'h701, 11'h701, 11'h701, 11'h701, 11'h701, 
	11'h702, 11'h702, 11'h703, 11'h704, 11'h705, 11'h707, 11'h708, 11'h70A, 11'h70B, 11'h70D, 11'h70F, 11'h712, 11'h714, 11'h716, 
	11'h719, 11'h71C, 11'h71F, 11'h722, 11'h725, 11'h728, 11'h72B, 11'h72F, 11'h733, 11'h736, 11'h73A, 11'h73E, 11'h743, 11'h747, 
	11'h74B, 11'h750, 11'h754, 11'h759, 11'h75E, 11'h763, 11'h768, 11'h76D, 11'h772, 11'h777, 11'h77C, 11'h782, 11'h787, 11'h78D, 
	11'h792, 11'h798, 11'h79E, 11'h7A4, 11'h7AA, 11'h7B0, 11'h7B5, 11'h7BB, 11'h7C2, 11'h7C8, 11'h7CE, 11'h7D4, 11'h7DA, 11'h7E0, 
	11'h7E7, 11'h7ED, 11'h7F3, 11'h7F9
};

logic [7:0] lut_index;
logic signed [10:0] sine_value;
logic [39:0] phase_inc_adjusted;

// Adjust phase increment for NTSC vs PAL
// PAL subcarrier is ~1.24x higher than NTSC (4.433619/3.579545)
// Multiply by 1.24 ≈ multiply by 5/4 = multiply by 5, then divide by 4
always_comb begin
	if (subcarrier_enable) begin
		if (pal_en)
			phase_inc_adjusted = (PHASE_INC * 5) >> 2;           // PAL: multiply by 1.25
		else
			phase_inc_adjusted = PHASE_INC;                      // NTSC: use as-is
	end else begin
		phase_inc_adjusted = 40'd0;                              // Disabled
	end
end

always_ff @(posedge clk) begin
	// Phase accumulator
	if (subcarrier_enable)
		phase_accum <= phase_accum + phase_inc_adjusted;
	else
		phase_accum <= 40'd0;
	
	// Use upper 8 bits as LUT index
	lut_index <= phase_accum[39:32];
	
	// Get sine value from LUT
	sine_value <= sine_LUT[lut_index];
end

// Convert to digital output (MSB for square wave approximation)
assign subcarrier_out = subcarrier_enable ? sine_value[10] : 1'b0;

endmodule