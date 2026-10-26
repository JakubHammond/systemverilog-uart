module uart_tx #(
    // Must be >= 1. Example: 50 MHz / 115200 baud is about 434.
    parameter integer CLKS_PER_BIT = 4
) (
    input  logic       clk,
    input  logic       rst,       // Synchronous, active-high reset
    input  logic       start,     // One-clock request; ignored while busy
    input  logic [7:0] data_in,
    output logic       tx,
    output logic       busy
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    localparam integer TIMER_WIDTH =
        (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT) : 1;
    logic [TIMER_WIDTH-1:0] bit_timer;
    logic [2:0] bit_index;
    logic [7:0] data_saved;

    always_ff @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            tx         <= 1'b1;
            busy       <= 1'b0;
            bit_timer  <= '0;
            bit_index  <= '0;
            data_saved <= '0;
        end else begin
            case (state)
                IDLE: begin
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    bit_timer <= '0;
                    bit_index <= '0;
                    if (start) begin
                        data_saved <= data_in;
                        tx         <= 1'b0; // Start bit begins now
                        busy       <= 1'b1;
                        state      <= START;
                    end
                end

                START: begin
                    if (bit_timer == CLKS_PER_BIT - 1) begin
                        bit_timer <= '0;
                        tx        <= data_saved[0];
                        state     <= DATA;
                    end else begin
                        bit_timer <= bit_timer + 1'b1;
                    end
                end

                DATA: begin
                    if (bit_timer == CLKS_PER_BIT - 1) begin
                        bit_timer <= '0;
                        if (bit_index == 3'd7) begin
                            tx    <= 1'b1; // Stop bit begins now
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx        <= data_saved[bit_index + 3'd1];
                        end
                    end else begin
                        bit_timer <= bit_timer + 1'b1;
                    end
                end

                STOP: begin
                    if (bit_timer == CLKS_PER_BIT - 1) begin
                        bit_timer <= '0;
                        busy      <= 1'b0;
                        state     <= IDLE;
                    end else begin
                        bit_timer <= bit_timer + 1'b1;
                    end
                end

                default: begin
                    state     <= IDLE;
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    bit_timer <= '0;
                    bit_index <= '0;
                end
            endcase
        end
    end
endmodule
