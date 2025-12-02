// ============================================================================
// LCD Controller Module for HBE-Combo 2-DLD
// HD44780 Compatible 16x2 Character LCD (4-bit interface)
// ============================================================================

module lcd_controller (
    clk,           // System clock (typically 50MHz or 100MHz)
    rst_n,         // Reset (active low)
    lcd_rs,        // Register Select (0=Instruction, 1=Data)
    lcd_e,         // Enable signal
    lcd_db,        // Data bus (D7-D4, upper 4 bits)
    char_data,     // ASCII character to display
    cursor_pos,    // Cursor position (0-15 for line 1, 16-31 for line 2)
    write_enable,  // Write enable signal
    ready          // Ready signal (1 when LCD is ready for next command)
);

// Port declarations
input clk;
input rst_n;
output lcd_rs;
output lcd_e;
output [3:0] lcd_db;
input [7:0] char_data;
input [4:0] cursor_pos;
input write_enable;
output ready;

// Register declarations for outputs
reg lcd_rs;
reg lcd_e;
reg [3:0] lcd_db;
reg ready;

// ============================================================================
// Internal Signals
// ============================================================================
localparam CLK_FREQ = 50000000;  // 50MHz clock frequency
localparam DELAY_15MS = CLK_FREQ * 15 / 1000;      // 15ms delay
localparam DELAY_5MS = CLK_FREQ * 5 / 1000;       // 5ms delay
localparam DELAY_100US = CLK_FREQ * 100 / 1000000; // 100us delay
localparam DELAY_40US = CLK_FREQ * 40 / 1000000;   // 40us delay

reg [31:0] delay_counter;
reg [4:0] state;
reg [4:0] next_state;
reg [7:0] instruction;

// State definitions
localparam IDLE           = 4'd0;
localparam INIT_WAIT_15MS = 4'd1;
localparam INIT_FUNC_SET1 = 4'd2;
localparam INIT_WAIT_5MS  = 4'd3;
localparam INIT_FUNC_SET2 = 4'd4;
localparam INIT_WAIT_100US = 4'd5;
localparam INIT_FUNC_SET3 = 4'd6;
localparam INIT_FUNC_SET4 = 4'd7;
localparam INIT_FUNC_SET5 = 4'd8;
localparam INIT_FUNC_SET6 = 4'd9;
localparam INIT_DISP_CTRL1 = 4'd10;
localparam INIT_DISP_CTRL2 = 4'd11;
localparam INIT_DISP_CLR1  = 4'd12;
localparam INIT_DISP_CLR2  = 4'd13;
localparam INIT_ENTRY_MODE1 = 4'd14;
localparam INIT_ENTRY_MODE2 = 4'd15;
localparam INIT_DONE      = 4'd16;
localparam SET_CURSOR1     = 4'd17;
localparam SET_CURSOR2     = 4'd18;
localparam WRITE_CHAR1     = 4'd19;
localparam WRITE_CHAR2     = 4'd20;

// ============================================================================
// State Machine
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        delay_counter <= 0;
        lcd_rs <= 0;
        lcd_e <= 0;
        lcd_db <= 4'b0000;
        ready <= 0;
        instruction <= 8'h00;
    end else begin
        state <= next_state;
        
        case (state)
            IDLE: begin
                delay_counter <= DELAY_15MS;
                ready <= 0;
            end
            
            INIT_WAIT_15MS: begin
                if (delay_counter > 0)
                    delay_counter <= delay_counter - 1;
            end
            
            INIT_FUNC_SET1: begin
                delay_counter <= DELAY_5MS;
            end
            
            INIT_WAIT_5MS: begin
                if (delay_counter > 0)
                    delay_counter <= delay_counter - 1;
            end
            
            INIT_FUNC_SET2: begin
                delay_counter <= DELAY_100US;
            end
            
            INIT_WAIT_100US: begin
                if (delay_counter > 0)
                    delay_counter <= delay_counter - 1;
            end
            
            INIT_FUNC_SET3, INIT_FUNC_SET4, INIT_FUNC_SET5, INIT_FUNC_SET6,
            INIT_DISP_CTRL1, INIT_DISP_CTRL2,
            INIT_DISP_CLR1, INIT_DISP_CLR2,
            INIT_ENTRY_MODE1, INIT_ENTRY_MODE2,
            SET_CURSOR1, SET_CURSOR2,
            WRITE_CHAR1, WRITE_CHAR2: begin
                delay_counter <= DELAY_40US;
            end
            
            INIT_DONE: begin
                ready <= 1;
            end
        endcase
    end
end

// Next state logic
always @(*) begin
    next_state = state;
    
    case (state)
        IDLE: begin
            next_state = INIT_WAIT_15MS;
        end
        
        INIT_WAIT_15MS: begin
            if (delay_counter == 0)
                next_state = INIT_FUNC_SET1;
        end
        
        INIT_FUNC_SET1: begin
            if (delay_counter == 0)
                next_state = INIT_WAIT_5MS;
        end
        
        INIT_WAIT_5MS: begin
            if (delay_counter == 0)
                next_state = INIT_FUNC_SET2;
        end
        
        INIT_FUNC_SET2: begin
            if (delay_counter == 0)
                next_state = INIT_WAIT_100US;
        end
        
        INIT_WAIT_100US: begin
            if (delay_counter == 0)
                next_state = INIT_FUNC_SET3;
        end
        
        INIT_FUNC_SET3: begin
            if (delay_counter == 0)
                next_state = INIT_FUNC_SET4;
        end
        
        INIT_FUNC_SET4: begin
            if (delay_counter == 0)
                next_state = INIT_FUNC_SET5;
        end
        
        INIT_FUNC_SET5: begin
            if (delay_counter == 0)
                next_state = INIT_FUNC_SET6;
        end
        
        INIT_FUNC_SET6: begin
            if (delay_counter == 0)
                next_state = INIT_DISP_CTRL1;
        end
        
        INIT_DISP_CTRL1: begin
            if (delay_counter == 0)
                next_state = INIT_DISP_CTRL2;
        end
        
        INIT_DISP_CTRL2: begin
            if (delay_counter == 0)
                next_state = INIT_DISP_CLR1;
        end
        
        INIT_DISP_CLR1: begin
            if (delay_counter == 0)
                next_state = INIT_DISP_CLR2;
        end
        
        INIT_DISP_CLR2: begin
            if (delay_counter == 0)
                next_state = INIT_ENTRY_MODE1;
        end
        
        INIT_ENTRY_MODE1: begin
            if (delay_counter == 0)
                next_state = INIT_ENTRY_MODE2;
        end
        
        INIT_ENTRY_MODE2: begin
            if (delay_counter == 0)
                next_state = INIT_DONE;
        end
        
        INIT_DONE: begin
            if (write_enable) begin
                next_state = SET_CURSOR1;
            end
        end
        
        SET_CURSOR1: begin
            if (delay_counter == 0)
                next_state = SET_CURSOR2;
        end
        
        SET_CURSOR2: begin
            if (delay_counter == 0)
                next_state = WRITE_CHAR1;
        end
        
        WRITE_CHAR1: begin
            if (delay_counter == 0)
                next_state = WRITE_CHAR2;
        end
        
        WRITE_CHAR2: begin
            if (delay_counter == 0)
                next_state = INIT_DONE;
        end
        
        default: begin
            next_state = IDLE;
        end
    endcase
end

// Output logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lcd_rs <= 0;
        lcd_e <= 0;
        lcd_db <= 4'b0000;
        instruction <= 8'h00;
    end else begin
        case (state)
            INIT_FUNC_SET1, INIT_FUNC_SET2, INIT_FUNC_SET3: begin
                // Function Set: 8-bit mode (0x30) - upper nibble only
                lcd_rs <= 0;
                lcd_db <= 4'b0011;
                lcd_e <= 1;
            end
            
            INIT_FUNC_SET4: begin
                // Function Set: Switch to 4-bit mode (0x20) - upper nibble only
                lcd_rs <= 0;
                lcd_db <= 4'b0010;
                lcd_e <= 1;
            end
            
            INIT_FUNC_SET5: begin
                // Function Set: 4-bit mode, 2 lines, 5x8 font (0x28)
                // Upper nibble: 0x2
                lcd_rs <= 0;
                lcd_db <= 4'b0010;
                lcd_e <= 1;
            end
            
            INIT_FUNC_SET6: begin
                // Lower nibble: 0x8
                lcd_rs <= 0;
                lcd_db <= 4'b1000;
                lcd_e <= 1;
            end
            
            INIT_DISP_CTRL1: begin
                // Display Control: Display ON, Cursor OFF, Blink OFF (0x0C)
                // Upper nibble: 0x0
                lcd_rs <= 0;
                lcd_db <= 4'b0000;
                lcd_e <= 1;
            end
            
            INIT_DISP_CTRL2: begin
                // Lower nibble: 0xC
                lcd_rs <= 0;
                lcd_db <= 4'b1100;
                lcd_e <= 1;
            end
            
            INIT_DISP_CLR1: begin
                // Display Clear (0x01)
                // Upper nibble: 0x0
                lcd_rs <= 0;
                lcd_db <= 4'b0000;
                lcd_e <= 1;
            end
            
            INIT_DISP_CLR2: begin
                // Lower nibble: 0x1
                lcd_rs <= 0;
                lcd_db <= 4'b0001;
                lcd_e <= 1;
            end
            
            INIT_ENTRY_MODE1: begin
                // Entry Mode Set: Increment cursor, No shift (0x06)
                // Upper nibble: 0x0
                lcd_rs <= 0;
                lcd_db <= 4'b0000;
                lcd_e <= 1;
            end
            
            INIT_ENTRY_MODE2: begin
                // Lower nibble: 0x6
                lcd_rs <= 0;
                lcd_db <= 4'b0110;
                lcd_e <= 1;
            end
            
            SET_CURSOR1: begin
                // Set DDRAM Address (cursor position)
                // Calculate DDRAM address
                if (cursor_pos < 16)
                    instruction <= 8'h80 + cursor_pos;  // Line 1: 0x80-0x8F
                else
                    instruction <= 8'hC0 + (cursor_pos - 16);  // Line 2: 0xC0-0xCF
                
                lcd_rs <= 0;
                lcd_db <= instruction[7:4];  // Upper nibble
                lcd_e <= 1;
            end
            
            SET_CURSOR2: begin
                lcd_rs <= 0;
                lcd_db <= instruction[3:0];  // Lower nibble
                lcd_e <= 1;
            end
            
            WRITE_CHAR1: begin
                // Write character data - upper nibble
                lcd_rs <= 1;
                lcd_db <= char_data[7:4];
                lcd_e <= 1;
            end
            
            WRITE_CHAR2: begin
                // Write character data - lower nibble
                lcd_rs <= 1;
                lcd_db <= char_data[3:0];
                lcd_e <= 1;
            end
            
            default: begin
                lcd_e <= 0;
            end
        endcase
    end
end

endmodule
