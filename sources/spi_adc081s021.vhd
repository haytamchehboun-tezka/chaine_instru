--------------------------------------------------------------
-- spi_adc081s021.vhd
-- Lecture de l'ADC081S021 via SPI (mode 0, CPOL=0, CPHA=0)
-- Format : 16 bits (3 header + 1 null + 8 data + 4 trailing)
-- Horloge systeme : 100 MHz, SCLK = 100 / (2*3) ≈ 16.7 MHz
---------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_adc081s021 is
  generic (
    DIV : integer := 3
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    start      : in  std_logic;
    -- Interface SPI
    sclk       : out std_logic;
    cs_n       : out std_logic;
    sdata      : in  std_logic;
    -- Sortie vers le controleur UART
    data_out   : out std_logic_vector(7 downto 0);
    data_valid : out std_logic;
    busy       : out std_logic
  );
end spi_adc081s021;

architecture rtl of spi_adc081s021 is
  type state_t is (IDLE, CONV, DONE);
  signal state     : state_t := IDLE;
  signal bit_cnt   : integer range 0 to 15 := 0;
  signal sclk_div  : integer range 0 to DIV-1 := 0;
  signal sclk_rise : std_logic := '0';
  signal sclk_fall : std_logic := '0';
  signal shift_reg : std_logic_vector(15 downto 0) := (others => '0');
  signal cs_n_int  : std_logic := '1';
  signal sclk_int  : std_logic := '0';
begin

  -- Generation de l'horloge SPI et des fronts
  process(clk, rst)
  begin
    if rst = '1' then
      sclk_div  <= 0;
      sclk_int  <= '0';
      sclk_rise <= '0';
      sclk_fall <= '0';
    elsif rising_edge(clk) then
      sclk_rise <= '0';
      sclk_fall <= '0';

      if cs_n_int = '0' then
        if sclk_div = DIV - 1 then
          sclk_div <= 0;
          sclk_int <= not sclk_int;
          if sclk_int = '0' then
            sclk_rise <= '1';
          else
            sclk_fall <= '1';
          end if;
        else
          sclk_div <= sclk_div + 1;
        end if;
      else
        sclk_int <= '0';
        sclk_div <= 0;
      end if;
    end if;
  end process;

  sclk <= sclk_int;
  cs_n <= cs_n_int;

  -- Machine d'etat de lecture SPI (16 bits)
  process(clk, rst)
  begin
    if rst = '1' then
      state      <= IDLE;
      cs_n_int   <= '1';
      bit_cnt    <= 0;
      shift_reg  <= (others => '0');
      data_out   <= (others => '0');
      data_valid <= '0';
      busy       <= '0';
    elsif rising_edge(clk) then
      data_valid <= '0';

      case state is
        when IDLE =>
          cs_n_int <= '1';
          busy     <= '0';
          bit_cnt  <= 0;
          if start = '1' then
            cs_n_int  <= '0';
            shift_reg <= (others => '0');
            busy      <= '1';
            state     <= CONV;
          end if;

        when CONV =>
          if sclk_rise = '1' then
            shift_reg <= shift_reg(14 downto 0) & sdata;
            if bit_cnt = 15 then
              bit_cnt <= 0;
              state   <= DONE;
            else
              bit_cnt <= bit_cnt + 1;
            end if;
          end if;

        when DONE =>
          cs_n_int   <= '1';
          data_out   <= shift_reg(11 downto 4);
          data_valid <= '1';
          busy       <= '0';
          state      <= IDLE;
      end case;
    end if;
  end process;

end rtl;