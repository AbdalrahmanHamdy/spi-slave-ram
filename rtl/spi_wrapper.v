// Top Level Wrapper connecting SPI Slave and RAM
module spi_wrapper (
    input  wire clk,
    input  wire rst_n,
    input  wire SS_n,
    input  wire MOSI,
    output wire MISO
);

    wire [9:0] rx_data_wire;
    wire       rx_valid_wire;
    wire [7:0] tx_data_wire;
    wire       tx_valid_wire;
   

    // SPI Slave Instance
    spi_slave #(.ADDR_SIZE(8))
    u_spi_slave (
        .clk(clk),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .MOSI(MOSI),
        .rx_data(rx_data_wire),
        .rx_valid(rx_valid_wire),
        .tx_data(tx_data_wire),
        .tx_valid(tx_valid_wire),
        .MISO(MISO)
    );

    // Single Port RAM Instance
    ram #(.MEM_DEPTH(256),
        .ADDR_SIZE(8)) 
    u_ram (
        .clk(clk),
        .rst_n(rst_n),
        .din(rx_data_wire),
        .rx_valid(rx_valid_wire),
        .dout(tx_data_wire),
        .tx_valid(tx_valid_wire)

    );

endmodule
