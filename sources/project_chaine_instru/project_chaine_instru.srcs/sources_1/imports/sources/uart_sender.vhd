-------------------------------------------------------------
-- uart_sender.vhd
-- Controleur d'envoi UART.
-- Stocke un echantillon sur valid et l'envoie des que
-- l'UART est libre, sans doublon ni perte en usage cadencé.
--------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_sender is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    -- Entree depuis le SPI
    sample    : in  std_logic_vector(7 downto 0);
    valid     : in  std_logic;
    -- Interface UART
    uart_busy : in  std_logic;
    tx_byte   : out std_logic_vector(7 downto 0);
    tx_start  : out std_logic
  );
end uart_sender;

architecture rtl of uart_sender is
  type state_t is (IDLE, WAIT_TX, START_WAIT);
  signal state  : state_t := IDLE;
  signal stored : std_logic_vector(7 downto 0) := (others => '0');
begin

  process(clk, rst)
  begin
    if rst = '1' then
      state    <= IDLE;
      stored   <= (others => '0');
      tx_byte  <= (others => '0');
      tx_start <= '0';
    elsif rising_edge(clk) then
      tx_start <= '0';

      case state is
        when IDLE =>
          if valid = '1' then
            stored <= sample;
            if uart_busy = '0' then
              tx_byte  <= sample;
              tx_start <= '1';
              state    <= START_WAIT;
            else
              state <= WAIT_TX;
            end if;
          end if;

        when WAIT_TX =>
          if uart_busy = '0' then
            tx_byte  <= stored;
            tx_start <= '1';
            state    <= START_WAIT;
          end if;

        when START_WAIT =>
          -- Laisse le temps a uart_tx de prendre en compte tx_start
          -- et d'activer tx_busy avant de revenir en IDLE
          state <= IDLE;
      end case;
    end if;
  end process;

end rtl;