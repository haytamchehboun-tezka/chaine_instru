------------------------------------------------------------
-- start_gen.vhd
-- Genere une impulsion start en mode manuel (bouton actif
-- a l'etat bas, detecteur de front) ou automatique (1 kHz).
-- Selectionne par sw_mode.
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity start_gen is
  generic (
    CLK_HZ : integer := 100000000;
    FREQ   : integer := 1000          -- frequence auto en Hz
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    sw_mode   : in  std_logic;         -- '0' = manuel, '1' = auto
    btn_start : in  std_logic;         -- bouton actif a l'etat bas ('0' = appuye)
    start     : out std_logic;         -- impulsion start (un cycle)
    led_auto  : out std_logic          -- '1' si mode auto
  );
end start_gen;

architecture rtl of start_gen is

  constant DIV_N : integer := CLK_HZ / FREQ - 1;
  signal div_cnt    : integer range 0 to DIV_N := 0;
  signal start_auto : std_logic := '0';

  -- Synchronisation et detection de front descendant sur btn_start (actif bas)
  signal btn_sync_0   : std_logic := '1';
  signal btn_sync_1   : std_logic := '1';
  signal btn_prev     : std_logic := '1';
  signal start_manual : std_logic := '0';
  
begin

  -- Diviseur pour le mode automatique
  process(clk, rst)
  begin
    if rst = '1' then
      div_cnt    <= 0;
      start_auto <= '0';
    elsif rising_edge(clk) then
      start_auto <= '0';
      if div_cnt = DIV_N then
        div_cnt    <= 0;
        start_auto <= '1';
      else
        div_cnt <= div_cnt + 1;
      end if;
    end if;
  end process;

  -- Detecteur de front descendant sur btn_start ('1' -> '0')
  process(clk, rst)
  begin
    if rst = '1' then
      btn_sync_0   <= '1';
      btn_sync_1   <= '1';
      btn_prev     <= '1';
      start_manual <= '0';
    elsif rising_edge(clk) then
      btn_sync_0   <= btn_start;
      btn_sync_1   <= btn_sync_0;
      btn_prev     <= btn_sync_1;
      start_manual <= '0';

      if (btn_prev = '1') and (btn_sync_1 = '0') then
        start_manual <= '1';
      end if;
    end if;
  end process;

  -- Selecteur de mode (les deux sources sont deja synchronisees sur 1 cycle de clk)
  start    <= start_manual when sw_mode = '0' else start_auto;
  led_auto <= sw_mode;

end rtl;