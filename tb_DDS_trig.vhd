
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_DDS_trig is
end;

architecture bench of tb_DDS_trig is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant G_N_SAMPLES : integer := 360;
  constant G_WIDTH     : integer := 12;
  -- Ports
  signal CLK_I    : std_logic := '0';
  signal RST_N_I  : std_logic;
  signal EN_I     : std_logic;
  signal SINE_O   : std_logic_vector(G_WIDTH - 1 downto 0);
  signal COSINE_O : std_logic_vector(G_WIDTH - 1 downto 0);
begin

  DDS_trig_inst : entity work.DDS_trig
    generic map(
      G_INIT_PHASE => 0,
      G_N_SAMPLES => G_N_SAMPLES,
      G_WIDTH     => G_WIDTH
    )
    port map
    (
      CLK_I    => CLK_I,
      RST_N_I  => RST_N_I,
      EN_I     => EN_I,
      SINE_O   => SINE_O,
      COSINE_O => COSINE_O
    );
  CLK_I   <= not CLK_I after clk_period/2;
  RST_N_I <= '0', '1' after 50 ns;
  EN_I    <= '1';

end;