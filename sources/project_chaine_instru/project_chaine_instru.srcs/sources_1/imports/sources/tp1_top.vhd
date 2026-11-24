-- ──────────────────────────────────────────────────────────
-- tp1_top.vhd
-- Version début de TP : SPI + start_gen uniquement.
-- Nexys A7 : clk_100m
-- ──────────────────────────────────────────────────────────
library ieee;
use ieee.std_logic_1164.all;

entity tp1_top is
  port (
    clk   : in  std_logic;
    rst    : in  std_logic;                     -- bouton reset (actif haut)
    -- SPI ADC
    adc_sclk   : out std_logic;
    adc_cs_n   : out std_logic;
    adc_sdata  : in  std_logic;
    -- Contrôles
    sw_mode    : in  std_logic;                     -- '0' = manuel, '1' = auto
     btn_start  : in  std_logic;                     -- start manuel
    -- Sorties
    led_auto   : out std_logic;                     -- '1' si mode automatique
    led_out    : out std_logic_vector(7 downto 0) ; -- échantillon lu
    tx         : out std_logic
  );
end tp1_top;

architecture rtl of tp1_top is

COMPONENT ila_0
PORT (
	clk : IN STD_LOGIC;
    probe0 : IN STD_LOGIC;
    probe1 : IN STD_LOGIC;
    probe2 : IN STD_LOGIC;
	probe3 : IN STD_LOGIC
);
END COMPONENT  ;

  signal start : std_logic;
  signal data_valid : std_logic;
  signal data_out : std_logic_vector(7 downto 0);
  signal tx_byte : std_logic_vector(7 downto 0);
  signal tx_start : std_logic;
  signal tx_busy : std_logic;  
  
begin

  -- Affichage de l'echantillon sur les LEDs
  led_out <= data_out;
 -- start <= btn_start;

 --  Générateur de start
  u_start: entity work.start_gen
    generic map (CLK_HZ => 100_000_000, FREQ => 1_000)
    port map (
      clk       => clk,
      rst       => rst,
      sw_mode   => sw_mode,
      btn_start => btn_start,
      start     => start,
      led_auto  => led_auto
    );

  -- Interface SPI
  u_adc: entity work.spi_adc081s021
    port map (
      clk        => clk,
      rst        => rst,
      start      => start,
      sclk       => adc_sclk,
      cs_n       => adc_cs_n,
      sdata      => adc_sdata,
      data_out   => data_out,
      data_valid => data_valid,
      busy       => open
    );

uart_sender_inst0: entity work.uart_sender
  port map (
    clk       => clk,
    rst       => rst,
    -- Entree depuis le SPI
    sample    => data_out,
    valid     => data_valid,
    -- Interface UART
    uart_busy  => tx_busy,
    tx_byte => tx_byte,
    tx_start  => tx_start
  );


uart_tx_inst0 : entity work.uart_tx
  generic map (
    CLK_HZ => 100000000,
    BAUD   => 115200
  )
  port map(
    clk     => clk,
    rst     => rst,
    tx_byte  => tx_byte,  
    tx_start => tx_start, 
    tx_busy => tx_busy,
    tx     => tx
  );
  
  ila_inst0: ila_0
  port map(
  clk => clk,
  probe0 => start,
  probe1 => data_valid,
  probe2 => tx_busy,
  probe3 => tx_start
  );

end rtl;