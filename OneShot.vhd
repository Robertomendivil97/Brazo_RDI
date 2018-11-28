library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OneShot is
   port( E  : IN STD_LOGIC;
         clk : IN STD_LOGIC;
			S : OUT STD_LOGIC );
end OneShot;

architecture behavioral of OneShot is
	signal Q1,Q2,Q3: STD_LOGIC;
begin
	
	process(clk)
	begin
		if falling_edge(clk) then
			Q1<=E;
			Q2<=Q1;
			Q3<=Q2;
		end if;
	end process;
	
	S <= Q1 and Q2 and not Q3;

end behavioral;