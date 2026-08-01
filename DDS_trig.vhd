library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity DDS_trig is
  generic (
    --! Fase inicial de las señales.
    G_INIT_PHASE : integer range 0 to 359;
    --! Número de muestras a generar.
    G_N_SAMPLES : integer := 360;
    --! Tamaño en bits de la señal de salida.
    G_WIDTH : integer := 12
  );
  port (
    --! Reloj de entrada del módulo.
    CLK_I : in std_logic;
    --! Reset de entrada del módulo. Activo a nivel bajo.
    RST_N_I : in std_logic;
    --! Puerto de habilitación del módulo. Activo a nivel alto.
    EN_I : in std_logic;
    --! Señal seno de salida.
    SINE_O : out std_logic_vector(G_WIDTH - 1 downto 0);
    --! Señal coseno de salida.
    COSINE_O : out std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity DDS_trig;

architecture rtl of DDS_trig is
  --! Type para generar la memoria del DDS.
  type t_array_trig is array (0 to G_N_SAMPLES - 1) of std_logic_vector(G_WIDTH - 1 downto 0);
  --! Declaración de la función seno
  function generar_tabla_seno (puntos : integer) return t_array_trig is
    variable tabla_temporal             : t_array_trig;
    variable angulo                     : real;
    variable desfase                    : real;
    variable sine                       : real;
    variable sin_abs                    : real;
    variable sin_range                  : real;
  begin
    for i in 0 to puntos - 1 loop
      -- Fórmula: sin(2 * pi * i / N)
      -- Cálculo del ángulo.
      angulo := 2.0 * MATH_PI * (real(i) / real(puntos));
      -- Cálculo del desfase.
      desfase := 2.0 * MATH_PI * (real(G_INIT_PHASE)/real(360));
      -- Cálculo del valor del seno.
      sine := sin(angulo + desfase);
      -- Normalización del seno para que vaya de [0, 1].
      sin_abs := (sine + 1.0)/2.0;
      -- Conversión a nivel binario [0, 2^G_WIDTH-1].
      sin_range := sin_abs * real(2 ** G_WIDTH - 1);
      -- Conversión de real a std_logic_vector.
      tabla_temporal(i) := std_logic_vector(to_unsigned(integer(sin_range), G_WIDTH));
    end loop;
    -- Retorno de la tabla de valores con el DDS.
    return tabla_temporal;
  end function;

  --! Declaración de la función coseno
  function generar_tabla_coseno (puntos : integer) return t_array_trig is
    variable tabla_temporal               : t_array_trig;
    variable angulo                       : real;
    variable desfase                    : real;
    variable cose                         : real;
    variable cos_abs                      : real;
    variable cos_range                    : real;
  begin
    for i in 0 to puntos - 1 loop
      -- Fórmula: cos(2 * pi * i / N)
      -- Cálculo del ángulo.
      angulo := 2.0 * MATH_PI * (real(i) / real(puntos));
      -- Cálculo del desfase.
      desfase := 2.0 * MATH_PI * (real(G_INIT_PHASE)/real(360));
      -- Cálculo del valor del coseno.
      cose := cos(angulo + desfase);
      -- Normalización del coseno para que vaya de [0, 1].
      cos_abs := (cose + 1.0)/2.0;
      -- Conversión a nivel binario [0, 2^G_WIDTH-1].
      cos_range := cos_abs * real(2 ** G_WIDTH - 1);
      -- Conversión de real a std_logic_vector.
      tabla_temporal(i) := std_logic_vector(to_unsigned(integer(cos_range), G_WIDTH));
    end loop;
    -- Retorno de la tabla de valores con el DDS.
    return tabla_temporal;
  end function;
  --! Array con la tabla de senos.
  constant t_TABLE_SAMPLES_SIN : t_array_trig := generar_tabla_seno(G_N_SAMPLES);
  --! Array con la table de cosenos.
  constant t_TABLE_SAMPLES_COS : t_array_trig := generar_tabla_coseno(G_N_SAMPLES);

  --! Contador para sacar las muestras.
  signal r_cont : unsigned(G_WIDTH - 1 downto 0);

begin
  --! Valor de salida del seno.
  SINE : SINE_O <= t_TABLE_SAMPLES_SIN(to_integer(r_cont));

  --! Valor de salida del coseno.
  COSINE : COSINE_O <= t_TABLE_SAMPLES_COS(to_integer(r_cont));

  --! Generador de indices para el seno y el coseno.
  COUNTER : process (CLK_I)
  begin
    if rising_edge(CLK_I) then
      if RST_N_I = '0' then
        r_cont <= (others => '0');
      elsif EN_I = '1' then
        r_cont <= r_cont + 1;
        if r_cont >= G_N_SAMPLES - 1 then
          r_cont <= (others => '0');
        end if;
      end if;
    end if;
  end process;

end architecture;