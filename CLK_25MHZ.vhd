----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;

entity divisor_25MHz is
	port ( clk_50MHz : in  STD_LOGIC;
   		   clk_25MHz : out STD_LOGIC );
end divisor_25MHz;
 
architecture Behavioral of divisor_25MHz is
    signal aux: STD_LOGIC_vector(2 downto 0) := "000";
begin
	process (clk_50MHz)
	begin
		if rising_edge(clk_50MHz) then aux <= aux + 1;
       else aux <= aux;
      end if;
   end process;
 
	clk_25MHz <= aux(1);
end Behavioral;
