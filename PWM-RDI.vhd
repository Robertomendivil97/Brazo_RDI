library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwmg is
    generic( N : integer := 16);
    port( clk : in STD_LOGIC;
            switch : in STD_LOGIC;          
            pwm : out STD_LOGIC );
end pwmg;

architecture behavioral of pwmg is
    signal count : std_logic_vector(19 downto 0) :=   "00000000000000000000";  --range 10^6 to 0
    signal duty : std_logic_vector(19 downto 0)  :=   "00000000000000000000"; --range 10^6 to 0
    signal period : std_logic_vector(19 downto 0):=   "11110100001001000000"; --range 10^6 to 0
begin

    cntN: process (clk) begin --50MHz
        if clk'event and clk = '1' then
            if count = period - 1 then
                count <= (others => '0');
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    state: duty <= "00011000011010100000" when switch = '1' else -- 180 grados 2.36ms - -> 118000 ->00011100110011110000->100000-- 11000011010100000
						 "00000110101100001000";								 -- 0 grados 548 micros -> 27400
    
    pwmout: pwm <= '1' when (count < duty) else '0';
            
end behavioral;


