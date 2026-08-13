// SPI Slave FSM Interface
module spi_slave #(
    parameter ADDR_SIZE = 8
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       SS_n,
    input  wire       MOSI,
    input  wire [ADDR_SIZE-1:0] tx_data,
    input  wire       tx_valid,
    output reg  [ADDR_SIZE+1:0] rx_data,
    output reg        rx_valid,
    output reg        MISO
);
    // 1.FSM state encoding
    // local parameters for the SPI states 
    // gray  logic for the SPI Slave FSM
    // 1. FSM state encoding (gray)

    (* encoding = "gray" *) 
    reg [2:0] curr_state, next_state;

    localparam [2:0] IDLE      = 3'b000;
    localparam [2:0] CHK_CMD   = 3'b001;
    localparam [2:0] WRITE     = 3'b011;
    localparam [2:0] READ_ADD  = 3'b010;
    localparam [2:0] READ_DATA = 3'b110;
    reg [3:0]           bit_counter;
    reg [ADDR_SIZE+1:0] rx_shift_reg;
    // 10 bit shift register for transmitting data
    reg [ADDR_SIZE-1:0] tx_shift_reg;     
    // Flag to track read address step
    reg                 rd_addr_received; 


    // 1. counter & shift in Logic (MOSI -> rx_data) & shift out Logic (RAM -> MISO)
    // (Synchronous Reset) 
    always @(posedge clk ) begin
            if (!rst_n) begin
            rx_data         <= {(ADDR_SIZE+2){1'b0}};
            rx_shift_reg    <= {(ADDR_SIZE+2){1'b0}};
            tx_shift_reg    <= {(ADDR_SIZE){1'b0}};
            MISO            <= 1'b0;
            bit_counter     <= 4'd0;
            rd_addr_received <= 1'b0;
        end
        else begin
            if (SS_n) begin
            bit_counter <= 4'd0;
            MISO        <= 1'b0;
            end
            else begin
                rx_shift_reg <= {rx_shift_reg[ADDR_SIZE:0],MOSI};
                //shift in  MOSI data
                if (bit_counter == 4'd9) begin
                    rx_data     <= {rx_shift_reg[ADDR_SIZE:0],MOSI};
                    bit_counter <= 4'd0;

                    if (rx_shift_reg[ADDR_SIZE] == 1'b1 && rx_shift_reg[ADDR_SIZE-1] == 1'b0)
                         rd_addr_received <= 1'b1;
                    
                    else if (rx_shift_reg[ADDR_SIZE] == 1'b1 && rx_shift_reg[ADDR_SIZE-1] == 1'b1)
                         rd_addr_received <= 1'b0;
                end
                else begin
                    bit_counter <= bit_counter + 1'b1;
                end
                // shift out 
                if (curr_state == READ_DATA) begin
                    if (tx_valid) begin
                        MISO         <= tx_data[ADDR_SIZE-1];
                        tx_shift_reg <= {tx_data[ADDR_SIZE-2:0], 1'b0}; 
                    end
                    else begin
                        MISO         <= tx_shift_reg[ADDR_SIZE-1];
                        tx_shift_reg <= {tx_shift_reg[ADDR_SIZE-2:0], 1'b0};
                    end
                end
                else begin
                    MISO <= 1'b0;
                end

            end
        end
    end

    // 2. STATE MEM
    always @(posedge clk ) begin
      if (!rst_n) begin
        curr_state <= IDLE;         
      end
      else begin
        curr_state <= next_state;
      end
    end

   

    // 3. Next state logic
    always @(*) begin
        case (curr_state)
            IDLE: begin
                if (!SS_n)                      next_state = CHK_CMD;
                else                            next_state = IDLE;
            end 
            CHK_CMD: begin
                if (SS_n) 
                    next_state = IDLE;
                else if (bit_counter == 4'd9) begin
                    // MOSI is sampled on posedge, checking incoming bit:
                    if (rx_shift_reg[ADDR_SIZE] == 1'b0) 
                        next_state = WRITE;
                    else begin
                        if (rx_shift_reg[ADDR_SIZE-1] == 1'b0) 
                            next_state = READ_ADD;
                        else 
                            next_state = READ_DATA;
                    end
                end
                else 
                    next_state = CHK_CMD;
            end
            WRITE:begin
                if(SS_n)                            next_state = IDLE;
                else                                next_state = WRITE;
            end                            

            READ_ADD:begin
                if(SS_n)                            next_state = IDLE;
                else                                next_state = READ_ADD;
            end 
            READ_DATA:begin
                if(SS_n )                           next_state = IDLE;
                else                                next_state = READ_DATA;
            end 

            default:                                next_state = IDLE;
        endcase
    end
   
    // 4. output logic
    always @(posedge clk) begin
        if (!rst_n) rx_valid <= 1'b0;
        else begin
            if (!SS_n && curr_state == CHK_CMD && bit_counter == 4'd9)               
                        rx_valid <= 1'b1;
            else                                  rx_valid <= 1'b0;
        end
    end
endmodule
