`timescale 1ns / 1ps

module lcd_demo_top #(
    parameter CLK_HZ = 50_000_000
) (
    input  wire clk,
    input  wire reset_n,
    output wire [3:0] lcd_data,
    output wire       lcd_rs,
    output wire       lcd_rw,
    output wire       lcd_en,
    output wire       lcd_on,
    output wire       lcd_blight
);

    localparam integer LINE_LEN = 16;

    localparam [2:0] D_WAIT_INIT  = 3'd0;
    localparam [2:0] D_CMD_LINE0  = 3'd1;
    localparam [2:0] D_LINE0      = 3'd2;
    localparam [2:0] D_CMD_LINE1  = 3'd3;
    localparam [2:0] D_LINE1      = 3'd4;
    localparam [2:0] D_DONE       = 3'd5;

    reg [2:0] driver_state;
    reg [4:0] char_index;
    reg       driver_valid;
    reg       driver_is_cmd;
    reg [7:0] driver_data;

    wire ctrl_data_ready;
    wire ctrl_init_done;
    wire ctrl_busy;

    reg [7:0] line0 [0:LINE_LEN-1];
    reg [7:0] line1 [0:LINE_LEN-1];
    integer i;

    initial begin
        for (i = 0; i < LINE_LEN; i = i + 1) begin
            line0[i] = 8'h20;
            line1[i] = 8'h20;
        end
        line0[0]  = "B";
        line0[1]  = "I";
        line0[2]  = "D";
        line0[3]  = "I";
        line0[4]  = "R";
        line0[5]  = " ";
        line0[6]  = "M";
        line0[7]  = "O";
        line0[8]  = "R";
        line0[9]  = "S";
        line0[10] = "E";
        line0[11] = " ";
        line0[12] = "T";
        line0[13] = "E";
        line0[14] = "S";
        line0[15] = "T";

        line1[0]  = "M";
        line1[1]  = "O";
        line1[2]  = "D";
        line1[3]  = "E";
        line1[4]  = "0";
        line1[5]  = " ";
        line1[6]  = "D";
        line1[7]  = "E";
        line1[8]  = "M";
        line1[9]  = "O";
        line1[10] = " ";
        line1[11] = "L";
        line1[12] = "I";
        line1[13] = "N";
        line1[14] = "E";
        line1[15] = " ";
    end

    text_lcd_ctrl #(
        .CLK_HZ(CLK_HZ)
    ) u_text_lcd_ctrl (
        .clk        (clk),
        .reset_n    (reset_n),
        .data_in    (driver_data),
        .data_valid (driver_valid),
        .is_cmd     (driver_is_cmd),
        .data_ready (ctrl_data_ready),
        .init_done  (ctrl_init_done),
        .busy       (ctrl_busy),
        .lcd_data   (lcd_data),
        .lcd_rs     (lcd_rs),
        .lcd_rw     (lcd_rw),
        .lcd_en     (lcd_en),
        .lcd_on     (lcd_on),
        .lcd_blight (lcd_blight)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            driver_state <= D_WAIT_INIT;
            char_index   <= 5'd0;
            driver_valid <= 1'b0;
            driver_is_cmd <= 1'b0;
            driver_data  <= 8'd0;
        end else begin
            driver_valid <= 1'b0;
            case (driver_state)
                D_WAIT_INIT: begin
                    if (ctrl_init_done)
                        driver_state <= D_CMD_LINE0;
                end

                D_CMD_LINE0: begin
                    if (ctrl_data_ready) begin
                        driver_data  <= 8'h80;
                        driver_is_cmd <= 1'b1;
                        driver_valid <= 1'b1;
                        char_index   <= 5'd0;
                        driver_state <= D_LINE0;
                    end
                end

                D_LINE0: begin
                    if (char_index < LINE_LEN) begin
                        if (ctrl_data_ready) begin
                            driver_data  <= line0[char_index];
                            driver_is_cmd <= 1'b0;
                            driver_valid <= 1'b1;
                            char_index   <= char_index + 1'b1;
                        end
                    end else begin
                        driver_state <= D_CMD_LINE1;
                    end
                end

                D_CMD_LINE1: begin
                    if (ctrl_data_ready) begin
                        driver_data  <= 8'hC0;
                        driver_is_cmd <= 1'b1;
                        driver_valid <= 1'b1;
                        char_index   <= 5'd0;
                        driver_state <= D_LINE1;
                    end
                end

                D_LINE1: begin
                    if (char_index < LINE_LEN) begin
                        if (ctrl_data_ready) begin
                            driver_data  <= line1[char_index];
                            driver_is_cmd <= 1'b0;
                            driver_valid <= 1'b1;
                            char_index   <= char_index + 1'b1;
                        end
                    end else begin
                        driver_state <= D_DONE;
                    end
                end

                default: begin
                    driver_state <= D_DONE;
                end
            endcase
        end
    end

endmodule
