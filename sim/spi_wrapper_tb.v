`timescale 1ns / 1ps

module spi_wrapper_tb;

    reg clk;
    reg rst_n;
    reg SS_n;
    reg MOSI;
    wire MISO;

    integer error_count = 0;
    integer test_count  = 0;

    // Instantiate Top Level Module (Wrapper)
    spi_wrapper uut (
        .clk(clk),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .MOSI(MOSI),
        .MISO(MISO)
    );

    // Clock Generation (100MHz -> 10ns period)
    always #5 clk = ~clk;

    // Task 1: Send 10 bits serially over MOSI
    task send_10bit(input [9:0] data_in);
        integer i;
        begin
            @(negedge clk);
            #1;
            SS_n = 1'b0;          // Activate slave
            
            for (i = 9; i >= 0; i = i - 1) begin 
                MOSI = data_in[i];
                @(negedge clk);
                #1;
            end
        end
    endtask

    // Task 2: Read data from MISO with aligned sampling
    task receive_and_check_8bit(input [7:0] expected_data);
        integer i;
        reg [7:0] rx_byte;
        begin
            rx_byte = 8'h00;

            repeat(2)   @(posedge clk);
            #1;

            for (i = 7; i >= 0; i = i - 1) begin
                rx_byte[i] = MISO;
                if (i > 0) begin
                    @(posedge clk);
                    #1;
                end
            end

            @(negedge clk);
            #1;
            SS_n = 1'b1;

            test_count = test_count + 1;
            if (rx_byte === expected_data) begin
                $display("\033[1;32m [PASS] Test %0d: Expected = 0x%0h | Read = 0x%0h \033[0m", test_count, expected_data, rx_byte);
            end else begin
                $display(" [FAIL] Test %0d: Expected = 0x%0h | Read = 0x%0h", test_count, expected_data, rx_byte);
                error_count = error_count + 1;
            end

            repeat (2) @(negedge clk); 
            #1;
        end
    endtask
    
    // Task 3: Complete SPI Transaction Sequence
    task run_spi_transaction(input [7:0] addr, input [7:0] write_data);
        begin
            $display("\033[1;36m\n---> Transaction: Addr=0x%0h Data=0x%0h\033[0m", addr, write_data);

            send_10bit({2'b00, addr});
            SS_n = 1'b1;
            repeat (2) @(negedge clk); #1;

            send_10bit({2'b01, write_data});
            SS_n = 1'b1;
            repeat (2) @(negedge clk); #1;

            send_10bit({2'b10, addr});
            SS_n = 1'b1;
            repeat (2) @(negedge clk); #1;

            send_10bit(10'b11_00000000);
            receive_and_check_8bit(write_data);
        end
    endtask

    // Initial Block - Explicit 25 Directed Test Cases Execution
    initial begin
        clk   = 0;
        rst_n = 0;
        SS_n  = 1;
        MOSI  = 0;

        #25;
        rst_n = 1;
        #25;
        
        $display("==================================================");
        $display("       STARTING AUTOMATED SELF-CHECKING TB        ");
        $display("==================================================");

        // LEVEL 1: BASIC SANITY TESTS
        $display("\n---> [LEVEL 1] Basic Sanity Tests");
        run_spi_transaction(8'h01, 8'h10); // Test 1
        run_spi_transaction(8'h02, 8'h20); // Test 2
        run_spi_transaction(8'h05, 8'h0F); // Test 3
        run_spi_transaction(8'h0A, 8'h05); // Test 4
        run_spi_transaction(8'h0F, 8'h33); // Test 5

        // LEVEL 2: CORNER BOUNDARIES
        $display("\n---> [LEVEL 2] Corner Boundaries");
        run_spi_transaction(8'h00, 8'h00); // Test 6
        run_spi_transaction(8'hFF, 8'hFF); // Test 7
        run_spi_transaction(8'h00, 8'hFF); // Test 8
        run_spi_transaction(8'hFF, 8'h00); // Test 9
        run_spi_transaction(8'h01, 8'h80); // Test 10
        run_spi_transaction(8'h80, 8'h01); // Test 11
        run_spi_transaction(8'h7F, 8'h80); // Test 12

        // LEVEL 3: SIGNAL TOGGLING
        $display("\n---> [LEVEL 3] Signal Toggling");
        run_spi_transaction(8'hAA, 8'h55); // Test 13
        run_spi_transaction(8'h55, 8'hAA); // Test 14
        run_spi_transaction(8'hC3, 8'h3C); // Test 15
        run_spi_transaction(8'hF0, 8'h0F); // Test 16
        run_spi_transaction(8'hE7, 8'h18); // Test 17
        run_spi_transaction(8'h81, 8'h7E); // Test 18
        run_spi_transaction(8'h69, 8'h96); // Test 19

        // LEVEL 4: STRESS TESTS
        $display("\n---> [LEVEL 4] Stress Tests");
        run_spi_transaction(8'h13, 8'hA7); // Test 20
        run_spi_transaction(8'hB4, 8'h2E); // Test 21
        run_spi_transaction(8'h4D, 8'hB2); // Test 22
        run_spi_transaction(8'h9A, 8'h6C); // Test 23
        run_spi_transaction(8'hDE, 8'hAD); // Test 24
        run_spi_transaction(8'hBE, 8'hEF); // Test 25

        // FINAL SUMMARY REPORT
        #100;
        $display("\n==================================================");
        $display("               TEST SUMMARY RESULT                ");
        $display("==================================================");
        $display(" Total Tests Executed : %0d", test_count);
        if (error_count == 0) begin
            $display(" STATUS               : ALL 25 TESTS PASSED! 🎉");
        end else begin
            $display(" STATUS               : FAILED WITH %0d ERRORS ❌", error_count);
        end
        $display("==================================================\n");

        $finish;
    end

endmodule
