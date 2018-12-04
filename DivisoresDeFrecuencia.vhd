--------------------------------------------------------------------------------
-- DIVISORES DE FRECUENCIA PARA GENERAR SENALES DE RELOJ AUXILIARES:
--
-- Nota: Ajustando la constante 'conLimit' de cada divisor modifica la
--       frecuencia de la senal de reloj generada
--
-- Formula: contLimit = 25(MHz) / desired_freq(Hz)
-- 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity divisor_20Hz is
	port ( clk_50MHz : in  std_logic;
   		 clk_20Hz  : out std_logic );
end divisor_20Hz;
 
architecture Behavioral of divisor_20Hz is
	constant contLimit : integer := 1250000; -- <= 25,000,000(Hz) / desired(Hz)
   signal aux: STD_LOGIC := '0';
   signal counter : integer range 0 to contLimit := 0;
begin

	process (clk_50MHz)
	begin
		if rising_edge(clk_50MHz) then
   		if (counter < contLimit) then
				counter <= counter + 1;
         else
         	aux <= NOT aux;
            counter  <= 0;
         end if;
      end if;
   end process;
 
	clk_20Hz <= aux;

end Behavioral;

--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity divisor_166kHz is
	port ( clk_50MHz  : in  std_logic;
   		 clk_166kHz : out std_logic );
end divisor_166kHz;
 
architecture Behavioral of divisor_166kHz is
	constant contLimit : integer := 150; -- <= 25,000,000(Hz) / desired(Hz)
   signal aux: STD_LOGIC := '0';
   signal counter : integer range 0 to contLimit := 0;
begin

	process (clk_50MHz)
	begin
		if rising_edge(clk_50MHz) then
   		if (counter < contLimit) then
				counter <= counter + 1;
         else
         	aux <= NOT aux;
            counter  <= 0;
         end if;
      end if;
   end process;
 
	clk_166kHz <= aux;

end Behavioral;




