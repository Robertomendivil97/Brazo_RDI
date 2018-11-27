library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity divisor_5Hz is
	port ( clk_50MHz : in  STD_LOGIC;
   		   clk_5Hz : out STD_LOGIC );
end divisor_5Hz;
 
architecture Behavioral of divisor_5Hz is
    signal aux: STD_LOGIC := '0';
    signal counter : integer range 0 to 5000000 := 0;
begin
	process (clk_50MHz)
	begin
		if rising_edge(clk_50MHz) then
   		if (counter = 5000000) then
         	aux <= NOT aux;
            counter  <= 0;
         else
         	counter <= counter + 1;
         end if;
      end if;
   end process;
 
	clk_5Hz <= aux;
end Behavioral;

