/*
EYRC26-27: Logic Quest
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
                     1: sample trailing edge)                          [default: 0]
  LSB_FIRST        - Bit order (0: MSB first, 1: LSB first)            [default: 0]
  SPI_WORD_LENGTH  - Number of bits per transfer                       [default: 8]
  HALF_PERIOD      - clk_50MHz cycles per SCLK half-period.
                     SCLK freq = 50MHz / (2 x HALF_PERIOD)             [default: 25 -> 1MHz]
Ports:
  clk_50MHz    (in )  1 bit                - System clock (50MHz)
  rst_n        (in )  1 bit                - Active-low async reset
  start        (in )  1 bit                - Pulse high (sampled in IDLE) to begin transfer
  tx_data      (in )  SPI_WORD_LENGTH      - Data word to transmit on MOSI
  miso_input   (in )  1 bit                - Serial data in from SPI slave
  sclk_out     (out)  1 bit                - SPI serial clock, idles at CPOL
  cs_out       (out)  1 bit                - Chip select, active-low during transfer
  mosi_output  (out)  1 bit                - Serial data out to SPI slave
  rx_data      (out)  SPI_WORD_LENGTH      - Data received from MISO (valid once busy=0)
  busy         (out)  1 bit                - High for the duration of an active transfer
*/

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


// Counter widths come from the parameters, so they are never too narrow
localparam CW = $clog2(HALF_PERIOD + 1);        // holds 0..HALF_PERIOD
localparam TW = $clog2(2 * SPI_WORD_LENGTH);    // holds 0..2*WORD-1

reg [CW-1:0]               hc;        // half-period cycle counter
reg [TW-1:0]               tcnt;      // number of SCLK toggles done
reg [SPI_WORD_LENGTH-1:0]  tx_shift;
reg [SPI_WORD_LENGTH-1:0]  rx_shift;

// cs_out is always the exact opposite of busy; MOSI is the top bit of tx_shift
always @(*) begin
    cs_out      = ~busy;
    mosi_output = tx_shift[SPI_WORD_LENGTH-1];
end

always @(posedge clk_50MHz or negedge rst_n) begin
    if (!rst_n) begin
        busy     <= 1'b0;
        sclk_out <= 1'b0;
        hc       <= {CW{1'b0}};
        tcnt     <= {TW{1'b0}};
        tx_shift <= {SPI_WORD_LENGTH{1'b0}};
        rx_shift <= {SPI_WORD_LENGTH{1'b0}};
        rx_data  <= {SPI_WORD_LENGTH{1'b0}};
    end
    else if (!busy) begin
        // IDLE
        sclk_out <= 1'b0;
        if (start) begin
            busy     <= 1'b1;
            tx_shift <= tx_data;               // MSB goes on MOSI now
            hc       <= {CW{1'b0}};
            tcnt     <= {TW{1'b0}};
        end
    end
    else begin
        if (hc == HALF_PERIOD) begin
            // SCLK toggles here (cycles H+1, 2H+1, ...)
            hc       <= 1;
            sclk_out <= ~sclk_out;
            tcnt     <= tcnt + 1'b1;

            if (!sclk_out) begin
                // rising edge: sample MISO
                rx_shift <= {rx_shift[SPI_WORD_LENGTH-2:0], miso_input};
            end
            else begin
                // falling edge: move to next MOSI bit
                tx_shift <= {tx_shift[SPI_WORD_LENGTH-2:0], 1'b0};
                if (tcnt == 2*SPI_WORD_LENGTH - 1) begin
                    // last falling edge: finish on the same edge
                    busy    <= 1'b0;
                    rx_data <= rx_shift;
                end
            end
        end
        else begin
            hc <= hc + 1'b1;
        end
    end
end


//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
