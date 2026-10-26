`timescale 1ns/1ps

module uart_tx_tb;
    parameter integer CLKS_PER_BIT = 4;
    logic clk = 0;
    logic rst = 1;
    logic start = 0;
    logic [7:0] data_in = 0;
    wire tx, busy;

    always #5 clk = ~clk; // 100 MHz simulation clock

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .clk(clk), .rst(rst), .start(start), .data_in(data_in),
        .tx(tx), .busy(busy)
    );

    task automatic check_idle;
        if (tx !== 1'b1 || busy !== 1'b0)
            $fatal(1, "Expected idle: tx=%b busy=%b", tx, busy);
    endtask

    task automatic send_and_check(input logic [7:0] value);
        logic [9:0] frame;
        // Indexed from bit 0: start, D0 through D7, stop.
        frame = {1'b1, value, 1'b0};
        @(negedge clk);
        data_in = value;
        start = 1;
        @(posedge clk); #1;
        fork
            begin
                @(negedge clk);
                start = 0;
                data_in = ~value; // Must not change the saved byte
                repeat (2 * CLKS_PER_BIT) @(negedge clk);
                start = 1; // This request must be ignored while busy
                @(negedge clk);
                start = 0;
            end
            begin
                for (integer bit_no = 0; bit_no < 10; bit_no++) begin
                    for (integer tick = 0; tick < CLKS_PER_BIT; tick++) begin
                        if (tx !== frame[bit_no] || busy !== 1'b1)
                            $fatal(1,
                                "Byte %h, frame bit %0d, tick %0d: tx=%b expected=%b busy=%b",
                                value, bit_no, tick, tx, frame[bit_no], busy);
                        @(posedge clk); #1;
                    end
                end
                check_idle();
            end
        join
        repeat (2) begin
            @(posedge clk); #1;
            check_idle(); // No extra frame from the ignored request
        end
    endtask

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);
        repeat (2) @(posedge clk);
        #1;
        check_idle();
        @(negedge clk); rst = 0;

        send_and_check(8'h55);
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'hA6);
        for (integer value = 0; value < 256; value++)
            send_and_check(value[7:0]);

        // Reset aborts a frame at the next rising clock edge.
        @(negedge clk); data_in = 8'hAA; start = 1;
        @(posedge clk); #1;
        @(negedge clk); start = 0; rst = 1;
        @(posedge clk); #1;
        check_idle();
        @(negedge clk); rst = 0;
        send_and_check(8'h3C);

        $display("PASS: all 256 byte values, input latching, busy requests, reset; CLKS_PER_BIT=%0d", CLKS_PER_BIT);
        $finish;
    end

    initial begin
        #10000000;
        $fatal(1, "Simulation timed out");
    end
endmodule
