// Single-Port Synchronous RAM
module ram #(
    parameter MEM_DEPTH = 256,
    parameter ADDR_SIZE = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [ADDR_SIZE+1:0] din,
    input  wire                 rx_valid,
    output reg  [ADDR_SIZE-1:0] dout,
    output reg                  tx_valid
);
    // State encoding for the SPI commands
    localparam WRITE_ADDR = 2'b00 ;
    localparam WRITE_DATA = 2'b01 ;
    localparam READ_ADDR  = 2'b10 ;
    localparam READ_DATA  = 2'b11 ;
    // RAM memory array
    reg [ADDR_SIZE-1:0] RAM [MEM_DEPTH-1:0];
    // Address registers for read and write operations
    reg [ADDR_SIZE-1:0] rx_addr;
    reg [ADDR_SIZE-1:0] wr_addr;
    // Sequential logic for handling read and write operations
    always @(posedge clk) begin
        if (!rst_n) begin                       // reset condition
            dout <= {ADDR_SIZE{1'b0}};
            tx_valid <= 1'b0;
            wr_addr <= {ADDR_SIZE{1'b0}};
            rx_addr <= {ADDR_SIZE{1'b0}};

        end
        else begin
            // default value
            tx_valid <= 1'b0;
            if (rx_valid) begin
                case (din[ADDR_SIZE+1:ADDR_SIZE])
                    WRITE_ADDR : wr_addr <= din[ADDR_SIZE-1:0];         // store the write address
                    WRITE_DATA : RAM[wr_addr] <= din[ADDR_SIZE-1:0];    // write data to RAM at the stored address
                    READ_ADDR  : rx_addr <= din[ADDR_SIZE-1:0];         // store the read address
                    READ_DATA  : begin                                  // read data from RAM at the stored address
                            dout <= RAM [rx_addr];
                            tx_valid <= 1'b1;
                            end
                            default : ; 
                endcase
            end
        end
    end
endmodule

