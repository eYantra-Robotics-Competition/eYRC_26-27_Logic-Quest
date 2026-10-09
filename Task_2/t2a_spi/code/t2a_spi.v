/*
eYRC26-27: Logic Quest
Task 2A: SPI Master Module
Description : Parameterizable SPI master controller supporting all 4 SPI
              modes (via CPOL/CPHA), configurable bit order (MSB/LSB
              first), and configurable word length. Derives SCLK by
              dividing down the 50MHz input clock (HALF_PERIOD sets the
              divide ratio). On `start`, shifts tx_data out on MOSI while
              simultaneously shifting MISO into rx_data; `busy` is high
              for the duration and `cs_out` is driven low for the transfer.
Parameters:
  CPOL             - Clock polarity (0: idle low, 1: idle high)        [default: 0]
  CPHA             - Clock phase (0: sample leading edge,
                      1: sample trailing edge)                        [default: 0]
  LSB_FIRST        - Bit order (0: MSB first, 1: LSB first)           [default: 0]
  SPI_WORD_LENGTH  - Number of bits per transfer                      [default: 8]
  HALF_PERIOD      - clk_50MHz cycles per SCLK half-period.
                      SCLK freq = 50MHz / (2 x HALF_PERIOD)           [default: 25 -> 1MHz]
Ports:
  clk_50MHz    (in )  1 bit               - System clock (50MHz)
  rst_n        (in )  1 bit               - Active-low async reset
  start        (in )  1 bit               - Pulse high (sampled in IDLE) to begin transfer
  tx_data      (in )  SPI_WORD_LENGTH     - Data word to transmit on MOSI
  miso_input   (in )  1 bit               - Serial data in from SPI slave
  sclk_out     (out)  1 bit               - SPI serial clock, idles at CPOL
  cs_out       (out)  1 bit               - Chip select, active-low during transfer
  mosi_output  (out)  1 bit               - Serial data out to SPI slave
  rx_data      (out)  SPI_WORD_LENGTH     - Data received from MISO (valid once busy=0)
  busy         (out)  1 bit               - High for the duration of an active transfer

module t2a_spi
#(
    parameter CPOL             = 1'b0,
    parameter CPHA             = 1'b0,
    parameter LSB_FIRST        = 1'b0,
    parameter SPI_WORD_LENGTH  = 8,
    parameter HALF_PERIOD      = 25   // clk_50MHz cycles per half sclk period
)
(
    input wire clk_50MHz,
    input wire rst_n,

    input wire start,
    input wire [SPI_WORD_LENGTH-1:0] tx_data,
    input wire miso_input,

    output reg sclk_out,
    output reg cs_out,
    output reg mosi_output,

    output reg [SPI_WORD_LENGTH-1:0] rx_data,
    output reg busy
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////


reg [31:0] clk_count;
reg [SPI_WORD_LENGTH-1:0] tx_latched;
integer bit_index;

always @(posedge clk_50MHz or negedge rst_n) begin
    if (!rst_n) begin
        sclk_out  <= CPOL;
        cs_out    <= 1'b1;
        mosi_output <= 1'b0;
        rx_data   <= {SPI_WORD_LENGTH{1'b0}};
        busy      <= 1'b0;
        clk_count <= 0;
        bit_index <= 0;
        tx_latched <= {SPI_WORD_LENGTH{1'b0}};
    end
    else begin
        if (!busy) begin
            sclk_out <= CPOL;
            cs_out   <= 1'b1;
            clk_count <= 0;

            if (start) begin
                tx_latched <= tx_data;
                rx_data <= {SPI_WORD_LENGTH{1'b0}};
                bit_index <= 0;
                busy <= 1'b1;
                cs_out <= 1'b0;

                mosi_output <= LSB_FIRST
                    ? tx_data[0]
                    : tx_data[SPI_WORD_LENGTH-1];
            end
        end
        else begin
            if (clk_count >= HALF_PERIOD - 1) begin
                clk_count <= 0;
                sclk_out <= ~sclk_out;

                if (sclk_out == CPOL) begin
                    // Leading edge
                    if (CPHA == 1'b0) begin
                        // Receive data
                        rx_data[LSB_FIRST
                            ? bit_index
                            : (SPI_WORD_LENGTH-1-bit_index)]
                            <= miso_input;

                        if (bit_index < SPI_WORD_LENGTH-1)
                            bit_index <= bit_index + 1;
                        else
                            bit_index <= SPI_WORD_LENGTH;
                    end
                    else begin
                        // Transmit data
                        if (bit_index < SPI_WORD_LENGTH)
                            mosi_output <= tx_latched[
                                LSB_FIRST
                                ? bit_index
                                : (SPI_WORD_LENGTH-1-bit_index)
                            ];
                    end
                end
                else begin
                    // Trailing edge
                    if (CPHA == 1'b0) begin
                        if (bit_index >= SPI_WORD_LENGTH) begin
                            busy <= 1'b0;
                            cs_out <= 1'b1;
                            sclk_out <= CPOL;
                            mosi_output <= 1'b0;
                        end
                        else begin
                            mosi_output <= tx_latched[
                                LSB_FIRST
                                ? bit_index
                                : (SPI_WORD_LENGTH-1-bit_index)
                            ];
                        end
                    end
                    else begin
                        // Receive data
                        rx_data[LSB_FIRST
                            ? bit_index
                            : (SPI_WORD_LENGTH-1-bit_index)]
                            <= miso_input;

                        if (bit_index == SPI_WORD_LENGTH-1) begin
                            busy <= 1'b0;
                            cs_out <= 1'b1;
                            sclk_out <= CPOL;
                            mosi_output <= 1'b0;
                        end
                        else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end
            end
            else begin
                clk_count <= clk_count + 1;
            end
        end
    end
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
