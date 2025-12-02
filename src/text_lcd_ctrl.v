`timescale 1ns / 1ps

module text_lcd_ctrl #(
    parameter CLK_HZ = 50_000_000,
    parameter FIFO_DEPTH = 32
) (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  data_in,
    input  wire        data_valid,
    input  wire        is_cmd,
    output wire        data_ready,
    output reg         init_done,
    output reg         busy,
    output reg  [3:0]  lcd_data,
    output reg         lcd_rs,
    output wire        lcd_rw,
    output reg         lcd_en,
    output wire        lcd_on,
    output wire        lcd_blight
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            clog2 = i;
        end
    endfunction

    localparam integer CLK_DIV_VALUE = (CLK_HZ < 1_000_000) ? 1 : (CLK_HZ / 1_000_000);
    localparam integer CLK_DIV_WIDTH = (CLK_DIV_VALUE <= 1) ? 1 : clog2(CLK_DIV_VALUE);
    localparam integer FIFO_AW       = (FIFO_DEPTH <= 1) ? 1 : clog2(FIFO_DEPTH);
    localparam integer RESET_WAIT_US = 15_000;
    localparam integer INIT_WAIT_LONG_US = 4_100;
    localparam integer INIT_WAIT_SHORT_US = 100;
    localparam integer ENABLE_PULSE_US = 2;
    localparam integer POST_WRITE_SHORT_US = 40;
    localparam integer POST_WRITE_LONG_US  = 1_700;

    localparam [3:0] S_RESET_WAIT    = 4'd0;
    localparam [3:0] S_INIT_FUNC_LOAD = 4'd1;
    localparam [3:0] S_INIT_CMD_LOAD = 4'd2;
    localparam [3:0] S_IDLE          = 4'd3;
    localparam [3:0] S_LOAD_BYTE     = 4'd4;
    localparam [3:0] S_SEND_HIGH     = 4'd5;
    localparam [3:0] S_POST_HIGH     = 4'd6;
    localparam [3:0] S_SEND_LOW      = 4'd7;
    localparam [3:0] S_POST_LOW      = 4'd8;
    localparam [3:0] S_WRITE_WAIT    = 4'd9;

    localparam [1:0] CTX_INIT_NIBBLE = 2'd0;
    localparam [1:0] CTX_INIT_CMD    = 2'd1;
    localparam [1:0] CTX_RUNTIME     = 2'd2;

    assign lcd_on     = 1'b1;
    assign lcd_blight = 1'b1;
    assign lcd_rw     = 1'b0;

    reg [CLK_DIV_WIDTH-1:0] clk_div_cnt;
    reg tick_1us;

    reg [3:0] state;
    reg [3:0] next_state;

    reg [23:0] delay_counter;
    reg [23:0] next_delay_counter;

    reg [1:0] write_context;
    reg [1:0] next_write_context;

    reg [1:0] init_step;
    reg [1:0] next_init_step;

    reg [2:0] init_cmd_idx;
    reg [2:0] next_init_cmd_idx;

    reg [7:0] init_cmd_rom [0:3];

    reg skip_low_nibble;
    reg next_skip_low_nibble;

    reg [7:0] current_byte;
    reg [7:0] next_current_byte;

    reg current_is_cmd;
    reg next_current_is_cmd;

    reg [15:0] wait_after_write;
    reg [15:0] next_wait_after_write;

    reg [3:0] next_lcd_data;
    reg next_lcd_en;
    reg next_lcd_rs;

    reg next_init_done;
    reg next_busy;

    reg [7:0] nibble_byte;
    reg [15:0] nibble_wait;

    reg [FIFO_AW:0] wr_ptr;
    reg [FIFO_AW:0] rd_ptr;
    wire fifo_empty = (wr_ptr == rd_ptr);
    wire fifo_full  = (wr_ptr[FIFO_AW] != rd_ptr[FIFO_AW]) &&
                      (wr_ptr[FIFO_AW-1:0] == rd_ptr[FIFO_AW-1:0]);

    assign data_ready = ~fifo_full;

    reg [7:0] fifo_data [0:FIFO_DEPTH-1];
    reg fifo_cmd [0:FIFO_DEPTH-1];

    wire [FIFO_AW-1:0] rd_index = rd_ptr[FIFO_AW-1:0];

    reg pop_fifo;

    initial begin
        init_cmd_rom[0] = 8'h28;
        init_cmd_rom[1] = 8'h0C;
        init_cmd_rom[2] = 8'h06;
        init_cmd_rom[3] = 8'h01;
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            clk_div_cnt <= {CLK_DIV_WIDTH{1'b0}};
            tick_1us    <= 1'b0;
        end else begin
            if (clk_div_cnt == (CLK_DIV_VALUE - 1)) begin
                clk_div_cnt <= {CLK_DIV_WIDTH{1'b0}};
                tick_1us    <= 1'b1;
            end else begin
                clk_div_cnt <= clk_div_cnt + {{(CLK_DIV_WIDTH-1){1'b0}}, 1'b1};
                tick_1us    <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr <= { (FIFO_AW+1){1'b0} };
            rd_ptr <= { (FIFO_AW+1){1'b0} };
        end else begin
            if (data_valid && ~fifo_full) begin
                fifo_data[wr_ptr[FIFO_AW-1:0]] <= data_in;
                fifo_cmd[wr_ptr[FIFO_AW-1:0]]  <= is_cmd;
                wr_ptr <= wr_ptr + {{FIFO_AW{1'b0}}, 1'b1};
            end
            if (pop_fifo && ~fifo_empty) begin
                rd_ptr <= rd_ptr + {{FIFO_AW{1'b0}}, 1'b1};
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state             <= S_RESET_WAIT;
            delay_counter     <= 24'd0;
            write_context     <= CTX_INIT_NIBBLE;
            init_step         <= 2'd0;
            init_cmd_idx      <= 3'd0;
            skip_low_nibble   <= 1'b1;
            current_byte      <= 8'd0;
            current_is_cmd    <= 1'b1;
            wait_after_write  <= 16'd0;
            lcd_data          <= 4'd0;
            lcd_rs            <= 1'b0;
            lcd_en            <= 1'b0;
            init_done         <= 1'b0;
            busy              <= 1'b1;
        end else begin
            state             <= next_state;
            delay_counter     <= next_delay_counter;
            write_context     <= next_write_context;
            init_step         <= next_init_step;
            init_cmd_idx      <= next_init_cmd_idx;
            skip_low_nibble   <= next_skip_low_nibble;
            current_byte      <= next_current_byte;
            current_is_cmd    <= next_current_is_cmd;
            wait_after_write  <= next_wait_after_write;
            lcd_data          <= next_lcd_data;
            lcd_rs            <= next_lcd_rs;
            lcd_en            <= next_lcd_en;
            init_done         <= next_init_done;
            busy              <= next_busy;
        end
    end

    always @(*) begin
        next_state            = state;
        next_delay_counter    = delay_counter;
        next_write_context    = write_context;
        next_init_step        = init_step;
        next_init_cmd_idx     = init_cmd_idx;
        next_skip_low_nibble  = skip_low_nibble;
        next_current_byte     = current_byte;
        next_current_is_cmd   = current_is_cmd;
        next_wait_after_write = wait_after_write;
        next_lcd_data         = lcd_data;
        next_lcd_en           = 1'b0;
        next_lcd_rs           = lcd_rs;
        next_init_done        = init_done;
        next_busy             = 1'b1;
        pop_fifo              = 1'b0;

        case (state)
            S_RESET_WAIT: begin
                next_lcd_rs = 1'b0;
                if (delay_counter == 0)
                    next_delay_counter = RESET_WAIT_US;
                else if (tick_1us && delay_counter != 0)
                    next_delay_counter = delay_counter - 1'b1;
                if (tick_1us && delay_counter == 1) begin
                    next_delay_counter = 24'd0;
                    next_state = S_INIT_FUNC_LOAD;
                    next_init_step = 2'd0;
                end
            end

            S_INIT_FUNC_LOAD: begin
                nibble_byte = 8'h30;
                nibble_wait = INIT_WAIT_SHORT_US;
                case (init_step)
                    2'd0: begin
                        nibble_byte = 8'h30;
                        nibble_wait = INIT_WAIT_LONG_US;
                    end
                    2'd1: begin
                        nibble_byte = 8'h30;
                        nibble_wait = INIT_WAIT_SHORT_US;
                    end
                    2'd2: begin
                        nibble_byte = 8'h30;
                        nibble_wait = INIT_WAIT_SHORT_US;
                    end
                    2'd3: begin
                        nibble_byte = 8'h20;
                        nibble_wait = INIT_WAIT_SHORT_US;
                    end
                    default: begin
                        nibble_byte = 8'h20;
                        nibble_wait = INIT_WAIT_SHORT_US;
                    end
                endcase
                next_current_byte     = nibble_byte;
                next_current_is_cmd   = 1'b1;
                next_skip_low_nibble  = 1'b1;
                next_wait_after_write = nibble_wait[15:0];
                next_write_context    = CTX_INIT_NIBBLE;
                next_lcd_rs           = 1'b0;
                next_state            = S_SEND_HIGH;
            end

            S_INIT_CMD_LOAD: begin
                if (init_cmd_idx < 3'd4) begin
                    next_current_byte     = init_cmd_rom[init_cmd_idx];
                    next_current_is_cmd   = 1'b1;
                    next_skip_low_nibble  = 1'b0;
                    next_wait_after_write = (init_cmd_rom[init_cmd_idx] == 8'h01) ?
                                             POST_WRITE_LONG_US[15:0] : POST_WRITE_SHORT_US[15:0];
                    next_write_context    = CTX_INIT_CMD;
                    next_lcd_rs           = 1'b0;
                    next_state            = S_SEND_HIGH;
                end else begin
                    next_state     = S_IDLE;
                    next_init_done = 1'b1;
                    next_busy      = fifo_empty ? 1'b0 : 1'b1;
                end
            end

            S_IDLE: begin
                next_busy = fifo_empty ? 1'b0 : 1'b1;
                next_lcd_en = 1'b0;
                if (~fifo_empty)
                    next_state = S_LOAD_BYTE;
            end

            S_LOAD_BYTE: begin
                next_current_byte     = fifo_data[rd_index];
                next_current_is_cmd   = fifo_cmd[rd_index];
                next_skip_low_nibble  = 1'b0;
                next_wait_after_write = ((fifo_data[rd_index] == 8'h01) || (fifo_data[rd_index] == 8'h02)) ?
                                         POST_WRITE_LONG_US[15:0] : POST_WRITE_SHORT_US[15:0];
                next_write_context    = CTX_RUNTIME;
                next_state            = S_SEND_HIGH;
                pop_fifo              = 1'b1;
            end

            S_SEND_HIGH: begin
                next_lcd_rs   = current_is_cmd ? 1'b0 : 1'b1;
                next_lcd_en   = 1'b1;
                next_lcd_data = current_byte[7:4];
                if (delay_counter == 0)
                    next_delay_counter = ENABLE_PULSE_US;
                else if (tick_1us && delay_counter != 0)
                    next_delay_counter = delay_counter - 1'b1;
                if (tick_1us && delay_counter == 1) begin
                    next_delay_counter = 24'd0;
                    next_state = S_POST_HIGH;
                end
            end

            S_POST_HIGH: begin
                next_lcd_en = 1'b0;
                if (delay_counter == 0)
                    next_delay_counter = ENABLE_PULSE_US;
                else if (tick_1us && delay_counter != 0)
                    next_delay_counter = delay_counter - 1'b1;
                if (tick_1us && delay_counter == 1) begin
                    next_delay_counter = 24'd0;
                    if (skip_low_nibble)
                        next_state = S_WRITE_WAIT;
                    else
                        next_state = S_SEND_LOW;
                end
            end

            S_SEND_LOW: begin
                next_lcd_rs   = current_is_cmd ? 1'b0 : 1'b1;
                next_lcd_en   = 1'b1;
                next_lcd_data = current_byte[3:0];
                if (delay_counter == 0)
                    next_delay_counter = ENABLE_PULSE_US;
                else if (tick_1us && delay_counter != 0)
                    next_delay_counter = delay_counter - 1'b1;
                if (tick_1us && delay_counter == 1) begin
                    next_delay_counter = 24'd0;
                    next_state = S_POST_LOW;
                end
            end

            S_POST_LOW: begin
                next_lcd_en = 1'b0;
                if (delay_counter == 0)
                    next_delay_counter = ENABLE_PULSE_US;
                else if (tick_1us && delay_counter != 0)
                    next_delay_counter = delay_counter - 1'b1;
                if (tick_1us && delay_counter == 1) begin
                    next_delay_counter = 24'd0;
                    next_state = S_WRITE_WAIT;
                end
            end

            S_WRITE_WAIT: begin
                next_lcd_en = 1'b0;
                if (delay_counter == 0)
                    next_delay_counter = {8'd0, wait_after_write};
                else if (tick_1us && delay_counter != 0)
                    next_delay_counter = delay_counter - 1'b1;
                if (tick_1us && delay_counter == 1) begin
                    next_delay_counter = 24'd0;
                    case (write_context)
                        CTX_INIT_NIBBLE: begin
                            if (init_step < 2'd3) begin
                                next_init_step = init_step + 1'b1;
                                next_state     = S_INIT_FUNC_LOAD;
                            end else begin
                                if (init_step == 2'd3) begin
                                    next_init_step    = 2'd3;
                                    next_init_cmd_idx = 3'd0;
                                    next_state        = S_INIT_CMD_LOAD;
                                end else begin
                                    next_state = S_INIT_CMD_LOAD;
                                end
                            end
                        end
                        CTX_INIT_CMD: begin
                            if (init_cmd_idx < 3'd3) begin
                                next_init_cmd_idx = init_cmd_idx + 1'b1;
                                next_state        = S_INIT_CMD_LOAD;
                            end else begin
                                next_init_cmd_idx = 3'd4;
                                next_init_done    = 1'b1;
                                next_state        = S_IDLE;
                                next_busy         = fifo_empty ? 1'b0 : 1'b1;
                            end
                        end
                        default: begin
                            next_state = S_IDLE;
                            next_busy  = fifo_empty ? 1'b0 : 1'b1;
                        end
                    endcase
                end
            end

            default: begin
                next_state = S_RESET_WAIT;
            end
        endcase
    end

endmodule
