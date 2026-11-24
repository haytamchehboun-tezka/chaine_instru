-- ──────────────────────────────────────────────────────────
-- threshold.vhd
-- Comparateur de seuil avec hystérésis pour classification
-- binaire clair/obscur.
-- ──────────────────────────────────────────────────────────
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity threshold is
  generic (
    THRESHOLD : integer := 125;
    HYSTERESIS : integer := 5
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    data_in   : in  std_logic_vector(7 downto 0);
    valid     : in  std_logic;
    dark      : out std_logic   -- '1' si obscurité
  );
end threshold;

architecture rtl of threshold is
  signal dark_int : std_logic := '0';
begin
  process(clk, rst)
  begin
    if rst = '1' then
      dark_int <= '0';
    elsif rising_edge(clk) then
      if valid = '1' then
        if to_integer(unsigned(data_in)) < THRESHOLD - HYSTERESIS then
          dark_int <= '1';
        elsif to_integer(unsigned(data_in)) > THRESHOLD + HYSTERESIS then
          dark_int <= '0';
        end if;
      end if;
    end if;
  end process;
  dark <= dark_int;
end rtl;