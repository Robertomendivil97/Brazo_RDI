--------------------------------------------------------------------------------
-- COMPONENTES PARA DEFINIR RUTINAS:
--
-- Nota: La arquitectura de estos componentes es libre acorde a la rutina que se
-- desee implementar. Sin embargo, los puertos deben de permanecer iguales para
-- facilitar la compatibilidad con otros módulos.
--
-- *Se promueve el uso de máquinas de estado, pero también se pueden manejar
--  unidades de control
-- 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Rutina_1 is
	port ( nextState : in std_logic;
			 reset : in std_logic;
			 currS1, currS2, currS3, currS4,
			 currS5, currS6 : in integer range 0 to 200;
			 nextS1, nextS2, nextS3, nextS4,
			 nextS5, nextS6 : out integer range 0 to 200 := 90);
end Rutina_1;

architecture Behavioral of Rutina_1 is
	signal state : bit := '0';
begin

	process(reset, nextState)
	begin
		if reset = '1' then
			nextS1 <= 90;
			nextS1 <= 90;
			nextS1 <= 90;
			nextS1 <= 90;
			nextS1 <= 90;
			nextS1 <= 90;
			state <= '0';
		elsif rising_edge(nextState) then
			if state = '0' then
				if currS1	< 90 then
					nextS4 <= currS4 + 1;
				elsif currS1 > 90 then
					nextS4 <= currS4 - 1;
				else
					state <= '1';
				end if;
			else
				if currS1 < 45 then
					nextS4 <= currS4+1;
				elsif currS1 > 45 then
					nextS4 <= currS4-1;
				else
					state <= '0';
				end if;
			end if;
		end if;
	end process;

end Behavioral;