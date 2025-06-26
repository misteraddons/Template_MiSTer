//============================================================================
// User I/O Module - Controls loaned GPIO pins from HPS
// Demonstrates loanIO functionality with LEDs and buttons
//============================================================================

module user_io
(
	input  wire        clk,
	input  wire        reset_n,
	
	// Loaned GPIO pins from HPS
	output wire [3:0]  user_led,     // 4 LEDs on GPIO 48-51
	input  wire [1:0]  user_btn,     // 2 buttons on GPIO 52-53
	
	// Internal signals for core logic
	output wire [1:0]  btn_pressed,  // Debounced button presses (edge detect)
	input  wire [3:0]  led_pattern   // LED pattern from core logic
);

// Button debouncing and edge detection
reg [1:0] btn_sync [2:0];
reg [1:0] btn_stable;
reg [1:0] btn_prev;

always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		btn_sync[0] <= 2'b11;
		btn_sync[1] <= 2'b11; 
		btn_sync[2] <= 2'b11;
		btn_stable <= 2'b11;
		btn_prev <= 2'b11;
	end else begin
		// 3-stage synchronizer for button inputs
		// Buttons are active low (pull-up resistors)
		btn_sync[0] <= ~user_btn;
		btn_sync[1] <= btn_sync[0];
		btn_sync[2] <= btn_sync[1];
		
		// Debounce: only update when all stages agree
		if (btn_sync[2] == btn_sync[1] && btn_sync[1] == btn_sync[0])
			btn_stable <= btn_sync[2];
			
		btn_prev <= btn_stable;
	end
end

// Edge detection for button presses (rising edge of debounced signal)
assign btn_pressed = btn_stable & ~btn_prev;

// LED blink generation
reg [24:0] blink_counter;
wire blink_slow = blink_counter[24];     // ~1.5Hz at 50MHz
wire blink_fast = blink_counter[22];     // ~6Hz at 50MHz

always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		blink_counter <= 0;
	else
		blink_counter <= blink_counter + 1;
end

// LED output logic with different blink patterns
assign user_led[0] = led_pattern[0] ? 1'b1 : 1'b0;           // Solid on/off
assign user_led[1] = led_pattern[1] ? blink_slow : 1'b0;     // Slow blink
assign user_led[2] = led_pattern[2] ? blink_fast : 1'b0;     // Fast blink
assign user_led[3] = led_pattern[3] ? ~blink_fast : 1'b0;    // Inverted fast blink

endmodule