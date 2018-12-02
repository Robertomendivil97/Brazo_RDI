library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--Este componente es una memoria de 16 registros de 25 bits que guarda estados
--de las posiciones de cada uno de los motores para su posterior reproducciÃ³n

entity memoria16x100 is
   port ( clk_10Hz : IN STD_LOGIC;
          memWrite : IN STD_LOGIC; --Señal para escribir en la dirección de memoria apuntada por MAR
          MAR : IN integer range 0 to 2**4 - 1; --Registro para almacenar la dirección de memoria de la que se leerá o en la que se escribirá
          MDRin : IN STD_LOGIC_VECTOR(100 downto 1); --Registro que muestra la dirección de memoria apuntada
			 MDRout : OUT STD_LOGIC_VECTOR(100 downto 1) ); --Registro que muestra la dirección de memoria apuntada
end memoria16x100;

architecture Behavioral of memoria16x100 is
	type memory_type is array ( 0 to 2**4 - 1) of std_logic_vector(100 downto 1);
   signal registers : memory_type;
begin
	process(clk_10Hz) begin
		if rising_edge(clk_10Hz) then
         if memWrite = '1' then
            registers(MAR) <= MDRin;
         else
            MDRout <= registers(MAR);
         end if;
		end if;
	end process;

end Behavioral;

