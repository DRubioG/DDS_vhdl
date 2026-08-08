--! Diagramas de tiempo
--! ==

--! G_TYPE = CONT
--! --
--! { signal: [
--!     { name: "CLK_I",      wave: "p........." },
--!     { name: "EN_I",       wave: "0.1..0.1.0" },
--!     { name: "SINE_O",     wave: "0.333..33.", "data": ["s1", "s2", "s3", "s4", "s5"] },
--!     { name: "COSINE_O",   wave: "0.444..44.", "data": ["c1", "c2", "c3", "c4", "c5"] },
--! ]}
--! G_TYPE = PHASE
--! --
--! { signal: [
--!     { name: "CLK_I",      wave: "p........." },
--!     { name: "EN_I",       wave: "0.1..0.1.0"},
--!     { name: "PHASE_I",    wave: "0.555x.55x", data: ["ph1", "ph2", "ph3", "ph4", "ph5"] },
--!     { name: "SINE_O",     wave: "0.333..33.", "data": ["s1", "s2", "s3", "s4", "s5"] },
--!     { name: "COSINE_O",   wave: "0.444..44.", "data": ["c1", "c2", "c3", "c4", "c5"] },
--! ]}

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity DDS_trig is
  generic (
    --! Número de muestras a generar.
    G_N_SAMPLES : integer := 360;
    --! Fase inicial de las señales. Rango[0, G_N_SAMPLES-1]
    G_INIT_PHASE : integer range 0 to G_N_SAMPLES - 1;
    --! Tamaño en bits de la señal de salida.
    G_WIDTH : integer := 12;
    --! Tipo de salida de muestras:
    --! 
    --! - **_"CONT"_**: forma continua, cuando *EN_I* está a '1' libera una muestra en el flanco de reloj.
    --!
    --! - **_"PHASE"_**: forma en la que el usuario puede elegir la muestra de salida. Para ello pone el
    --! indice de la muestra en el puerto *PHASE_I*
    G_TYPE : string := "CONT";
    --! Tipo de muestras generadas:
    --!
    --! - **_"POS"_**: Todas las muestras son positivas y van de [0, 2^G_WIDTH-1].
    --!
    --! - **_"POS_NEG"_**: Todas las muestras son positivas y negativas y van de [-2^(G_WIDTH-1), 2^(G_WIDTH-1)-1].
    --! (_NOTA_: el valor 0 se considera positivo).
    G_POS_NEG : string := "POS"
  );
  port (
    --! Reloj de entrada del módulo.
    CLK_I : in std_logic;
    --! Reset de entrada del módulo. Activo a nivel bajo.
    RST_N_I : in std_logic;
    --! Puerto de habilitación del módulo. Activo a nivel alto.
    EN_I : in std_logic;
    --! Este puerto permite selecionar el valor del índice para sacar la muestra. Para
    --! que este puerto funcione es necesario tiene el genérico *G_TYPE* en **_PHASE_**.
    --! 
    --! El valor de la fase es el indice de la muestra que se quiere sacar de la DDS.
    PHASE_I : in std_logic_vector(integer(log2(real(G_N_SAMPLES))) downto 0);
    --! Señal seno de salida.
    SINE_O : out std_logic_vector(G_WIDTH - 1 downto 0);
    --! Señal coseno de salida.
    COSINE_O : out std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity DDS_trig;

architecture rtl of DDS_trig is

  --! Type para generar la memoria del DDS.
  type t_array_trig is array (0 to G_N_SAMPLES - 1) of std_logic_vector(G_WIDTH - 1 downto 0);

  --! Índice para sacar las muestras.
  signal r_index : unsigned(integer(log2(real(G_N_SAMPLES))) downto 0);

begin

  POSITIVE_SAMPLES : if G_POS_NEG = "POS" generate

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
        -- Fórmula: sin((2 * pi * i / N) + (2 * pi * desfase / N))
        -- Cálculo del ángulo.
        angulo := 2.0 * MATH_PI * (real(i) / real(puntos));
        -- Cálculo del desfase.
        desfase := 2.0 * MATH_PI * (real(G_INIT_PHASE)/real(puntos));
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
      variable desfase                      : real;
      variable cose                         : real;
      variable cos_abs                      : real;
      variable cos_range                    : real;
    begin
      for i in 0 to puntos - 1 loop
        -- Fórmula: cos(2 * pi * i / N)
        -- Cálculo del ángulo.
        angulo := 2.0 * MATH_PI * (real(i) / real(puntos));
        -- Cálculo del desfase.
        desfase := 2.0 * MATH_PI * (real(G_INIT_PHASE)/real(puntos));
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

  begin
    --! Valor de salida del seno.
    SINE : SINE_O <= t_TABLE_SAMPLES_SIN(to_integer(r_index));

    --! Valor de salida del coseno.
    COSINE : COSINE_O <= t_TABLE_SAMPLES_COS(to_integer(r_index));

  elsif G_POS_NEG = "POS_NEG" generate

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
          -- Fórmula: sin((2 * pi * i / N) + (2 * pi * desfase / N))
          -- Cálculo del ángulo.
          angulo := 2.0 * MATH_PI * (real(i) / real(puntos));
          -- Cálculo del desfase.
          desfase := 2.0 * MATH_PI * (real(G_INIT_PHASE)/real(puntos));
          -- Cálculo del valor del seno.
          sine := sin(angulo + desfase);
          -- Normalización del seno para que vaya de [-0.5, 0.5].
          sin_abs := (sine)/2.0;
          -- Conversión a nivel binario [-2^(G_WIDTH-1), 2^(G_WIDTH-1)-1].
          -- Nota: el 0.5 es para compensar que el valor 0 está en el rango positivo.
          sin_range := sin_abs * real(2 ** G_WIDTH - 1) - 0.5;
          -- -- Conversión de real a std_logic_vector.
          tabla_temporal(i) := std_logic_vector(to_signed(integer(sin_range), G_WIDTH));
        end loop;
        -- Retorno de la tabla de valores con el DDS.
        return tabla_temporal;
      end function;

      --! Declaración de la función coseno
      function generar_tabla_coseno (puntos : integer) return t_array_trig is
        variable tabla_temporal               : t_array_trig;
        variable angulo                       : real;
        variable desfase                      : real;
        variable cose                         : real;
        variable cos_abs                      : real;
        variable cos_range                    : real;
      begin
        for i in 0 to puntos - 1 loop
          -- Fórmula: cos(2 * pi * i / N)
          -- Cálculo del ángulo.
          angulo := 2.0 * MATH_PI * (real(i) / real(puntos));
          -- Cálculo del desfase.
          desfase := 2.0 * MATH_PI * (real(G_INIT_PHASE)/real(puntos));
          -- Cálculo del valor del coseno.
          cose := cos(angulo + desfase);
          -- Normalización del coseno para que vaya de [-0.5, 0.5].
          cos_abs := (cose)/2.0;
          -- Conversión a nivel binario [-2^(G_WIDTH-1), 2^(G_WIDTH-1)-1].
          -- Nota: el 0.5 es para compensar que el valor 0 está en el rango positivo.
          cos_range := cos_abs * real(2 ** G_WIDTH - 1) - 0.5;
          -- Conversión de real a std_logic_vector.
          tabla_temporal(i) := std_logic_vector(to_signed(integer(cos_range), G_WIDTH));
        end loop;
        -- Retorno de la tabla de valores con el DDS.
        return tabla_temporal;
      end function;

      --! Array con la tabla de senos.
      constant t_TABLE_SAMPLES_SIN : t_array_trig := generar_tabla_seno(G_N_SAMPLES);

      --! Array con la table de cosenos.
      constant t_TABLE_SAMPLES_COS : t_array_trig := generar_tabla_coseno(G_N_SAMPLES);

    begin

      --! Valor de salida del seno.
      SINE : SINE_O <= t_TABLE_SAMPLES_SIN(to_integer(r_index));
      --! Valor de salida del coseno.
      COSINE : COSINE_O <= t_TABLE_SAMPLES_COS(to_integer(r_index));

    end generate;

    CONTINUOUS_gen : if G_TYPE = "CONT" generate
      --! Generador de indices para el seno y el coseno.
      COUNTER : process (CLK_I)
      begin
        if rising_edge(CLK_I) then
          if RST_N_I = '0' then
            r_index <= (others => '0');
          elsif EN_I = '1' then
            r_index <= r_index + 1;
            if r_index >= G_N_SAMPLES - 1 then
              r_index <= (others => '0');
            end if;
          end if;
        end if;
      end process;

    elsif G_TYPE = "PHASE" generate
        --! Selector de muestra de salida de la DDS.
        --! Para evitar problemas a nivel de que el usuario solicite una muestra
        --! fuera del rango de la tabla, el índice retorna a 0.
        PHASE_INDEX : process (CLK_I)
        begin
          if rising_edge(CLK_I) then
            if RST_N_I = '0' then
              r_index <= (others => '0');
            elsif EN_I = '1' then
              if to_integer(unsigned(PHASE_I)) < G_N_SAMPLES - 1 then
                r_index <= unsigned(PHASE_I);
              else
                r_index <= (others => '0');
              end if;
            end if;
          end if;
        end process;

      end generate;

    end architecture;