-- ──────────────────────────────────────────────────────────
-- bit_truncator.vhd
-- Tronque les LSB pour simuler une résolution plus faible
-- Sélectionné par un switch (2 bits : 00=8b, 01=6b, 10=4b, 11=2b)
-- ──────────────────────────────────────────────────────────
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_truncator is
  port (
    raw_8bits  : in  std_logic_vector(7 downto 0);
    sel        : in  std_logic_vector(1 downto 0);  -- 00:8b 01:6b 10:4b 11:2b
    truncated  : out std_logic_vector(7 downto 0)
  );
end bit_truncator;

architecture rtl of bit_truncator is
begin
  process(raw_8bits, sel)
  begin
    case sel is
      when "00"   => truncated <= raw_8bits;                     -- 8 bits
      when "01"   => truncated <= raw_8bits(7 downto 1) & '0';   -- 7 bits (troncature 1 LSB)
      when "10"   => truncated <= raw_8bits(7 downto 2) & "00";  -- 6 bits
      when others => truncated <= raw_8bits(7 downto 4) & "0000";-- 4 bits
    end case;
  end process;
end rtl;