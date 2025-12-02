// ============================================================================
// LCD Test Top Module for HBE-Combo 2-DLD
// Test module for LCD Controller
// ============================================================================

module lcd_test_top (
    input wire clk,           // System clock (50MHz)
    input wire rst_n,         // Reset button (active low)
    
    // LCD Interface
    output wire lcd_rs,       // Register Select
    output wire lcd_e,        // Enable
    output wire [3:0] lcd_db, // Data bus (D7-D4)
    
    // Test control (optional - can use switches or buttons)
    input wire test_start     // Start test sequence (can be tied to 1 for auto-start)
);

// ============================================================================
// Internal Signals
// ============================================================================
reg [7:0] char_data;
reg [4:0] cursor_pos;
reg write_enable;
wire lcd_ready;

reg [3:0] test_state;
reg [31:0] delay_counter;
reg [4:0] char_index;

// Test message: "HELLO WORLD" on line 1, "FPGA TEST" on line 2
reg [7:0] message_line1 [0:10];  // "HELLO WORLD" (11 chars)
reg [7:0] message_line2 [0:8];   // "FPGA TEST" (9 chars)

// State definitions
localparam IDLE = 4'd0;
localparam WAIT_READY = 4'd1;
localparam SET_CURSOR = 4'd2;
localparam WRITE_CHAR = 4'd3;
localparam NEXT_CHAR = 4'd4;
localparam LINE2_START = 4'd5;
localparam DONE = 4'd6;

// ============================================================================
// Initialize test messages
// ============================================================================
initial begin
    // Line 1: "HELLO WORLD"
    message_line1[0] = 8'h48;  // H
    message_line1[1] = 8'h45;  // E
    message_line1[2] = 8'h4C;  // L
    message_line1[3] = 8'h4C;  // L
    message_line1[4] = 8'h4F;  // O
    message_line1[5] = 8'h20;  // Space
    message_line1[6] = 8'h57;  // W
    message_line1[7] = 8'h4F;  // O
    message_line1[8] = 8'h52;  // R
    message_line1[9] = 8'h4C;  // L
    message_line1[10] = 8'h44; // D
    
    // Line 2: "FPGA TEST"
    message_line2[0] = 8'h46;  // F
    message_line2[1] = 8'h50;  // P
    message_line2[2] = 8'h47;  // G
    message_line2[3] = 8'h41;  // A
    message_line2[4] = 8'h20;  // Space
    message_line2[5] = 8'h54;  // T
    message_line2[6] = 8'h45;  // E
    message_line2[7] = 8'h53;  // S
    message_line2[8] = 8'h54;  // T
end

// ============================================================================
// LCD Controller Instance
// ============================================================================
lcd_controller lcd_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .lcd_rs(lcd_rs),
    .lcd_e(lcd_e),
    .lcd_db(lcd_db),
    .char_data(char_data),
    .cursor_pos(cursor_pos),
    .write_enable(write_enable),
    .ready(lcd_ready)
);

// ============================================================================
// Test State Machine
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        test_state <= IDLE;
        char_data <= 8'h00;
        cursor_pos <= 5'd0;
        write_enable <= 1'b0;
        delay_counter <= 0;
        char_index <= 0;
    end else begin
        case (test_state)
            IDLE: begin
                write_enable <= 1'b0;
                char_index <= 0;
                // Wait for LCD initialization and test_start signal
                if (lcd_ready) begin
                    if (test_start) begin
                        delay_counter <= 50_000_000;  // 1 second delay before starting
                        test_state <= WAIT_READY;
                    end
                end
            end
            
            WAIT_READY: begin
                if (delay_counter > 0) begin
                    delay_counter <= delay_counter - 1;
                end else begin
                    test_state <= SET_CURSOR;
                end
            end
            
            SET_CURSOR: begin
                if (char_index < 11) begin
                    // Line 1: positions 0-10
                    cursor_pos <= char_index;
                end else begin
                    // Line 2: positions 16-24
                    cursor_pos <= 16 + (char_index - 11);
                end
                delay_counter <= 50_000_000 / 1000;  // 1ms delay
                test_state <= WRITE_CHAR;
            end
            
            WRITE_CHAR: begin
                if (delay_counter > 0) begin
                    delay_counter <= delay_counter - 1;
                end else begin
                    if (char_index < 11) begin
                        char_data <= message_line1[char_index];
                    end else if (char_index < 20) begin
                        char_data <= message_line2[char_index - 11];
                    end
                    write_enable <= 1'b1;
                    test_state <= NEXT_CHAR;
                end
            end
            
            NEXT_CHAR: begin
                write_enable <= 1'b0;
                char_index <= char_index + 1;
                
                if (char_index == 10) begin
                    // Finished line 1, move to line 2
                    delay_counter <= 50_000_000 / 10;  // 100ms delay
                    test_state <= LINE2_START;
                end else if (char_index == 19) begin
                    // Finished all characters
                    test_state <= DONE;
                end else begin
                    delay_counter <= 50_000_000 / 1000;  // 1ms delay
                    test_state <= SET_CURSOR;
                end
            end
            
            LINE2_START: begin
                if (delay_counter > 0) begin
                    delay_counter <= delay_counter - 1;
                end else begin
                    test_state <= SET_CURSOR;
                end
            end
            
            DONE: begin
                write_enable <= 1'b0;
                // Stay in DONE state
            end
        endcase
    end
end

endmodule
