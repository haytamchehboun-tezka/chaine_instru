-------------------------------------------------
-- uart_tx.vhd
-- Emetteur UART 8N1, baudrate parametrable
-- Horloge systeme par defaut : 100 MHz
-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic (
    CLK_HZ : integer := 100000000;
    BAUD   : integer := 115200
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    tx_byte  : in  std_logic_vector(7 downto 0);
    tx_start : in  std_logic;
    tx_busy  : out std_logic;
    tx       : out std_logic
  );
end uart_tx;

architecture rtl of uart_tx is
  constant TICKS : integer := CLK_HZ / BAUD;
  type state_t is (IDLE, START, DATA, STOP);
  signal state   : state_t := IDLE;
  signal cnt     : integer range 0 to TICKS-1 := 0;
  signal bit_idx : integer range 0 to 7 := 0;
  signal shift   : std_logic_vector(7 downto 0) := (others => '0');
begin
  process(clk, rst)
  begin
    if rst = '1' then
      state   <= IDLE;
      tx      <= '1';
      tx_busy <= '0';
      cnt     <= 0;
      bit_idx <= 0;
      shift   <= (others => '0');
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          tx      <= '1';
          tx_busy <= '0';
          cnt     <= 0;
          if tx_start = '1' then
            shift   <= tx_byte;
            state   <= START;
            tx_busy <= '1';
          end if;

        when START =>
          tx <= '0';
          if cnt = TICKS-1 then
            cnt     <= 0;
            bit_idx <= 0;
            state   <= DATA;
          else
            cnt <= cnt + 1;
          end if;

        when DATA =>
          tx <= shift(bit_idx);
          if cnt = TICKS-1 then
            cnt <= 0;
            if bit_idx = 7 then
              state <= STOP;
            else
              bit_idx <= bit_idx + 1;
            end if;
          else
            cnt <= cnt + 1;
          end if;

        when STOP =>
          tx <= '1';
          if cnt = TICKS-1 then
            cnt   <= 0;
            state <= IDLE;
          else
            cnt <= cnt + 1;
          end if;
      end case;
    end if;
  end process;
end rtl;