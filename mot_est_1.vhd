library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
 
entity Mot_est_1 is
    port (
        clk  : in std_logic;
        en   : in std_logic;
		  state: in std_logic_vector(3 downto 0);
        addr : in std_logic_vector(9 downto 0);
        data : out std_logic_vector(87 to 106)
    );
end Mot_est_1;
 
architecture behavioral of Mot_est_1 is
    type memoria_rom is array (43 to 62) of std_logic_vector (87 to 106);
    signal Anim: memoria_rom;
	 signal ROM1 : memoria_rom := (
	 "00000000000000000000",
	 "00000000000000000000",
	 "00000111111111100000",
	 "00000111111111100000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00011000000000011000",
	 "00000111111111100000",
	 "00000111111111100000",
	 "00000000000000000000",
	 "00000000000000000000"
	 );
	signal ROM2 : memoria_rom := (
	 "00000000000000000000",
	 "00000000000000000000",
	 "00011100000000111000",
	 "00011100000000111000",
	 "00001110000001110000",
	 "00001110000001110000",
	 "00000111000011100000",
	 "00000111000011100000",
	 "00000011100111000000",
	 "00000001111110000000",
	 "00000001111110000000",
	 "00000011100111000000",
	 "00000111000011100000",
	 "00000111000011100000",
	 "00001110000001110000",
	 "00001110000001110000",
	 "00011100000000111000",
	 "00011100000000111000",
	 "00000000000000000000",
	 "00000000000000000000"
	 );
	 signal ROM3 : memoria_rom := (
	 "00000000000000000000",
	 "00000000000000000000",
	 "00000000001111111000",
	 "00000000011111110000",
	 "00000000111111100000",
	 "00000001111111000000",
	 "00000011111110000000",
	 "00000111111100000000",
	 "00001111111000000000",
	 "00011111110000000000",
	 "00011111110000000000",
	 "00001111111000000000",
	 "00000111111100000000",
	 "00000011111110000000",
	 "00000001111111000000",
	 "00000000111111100000",
	 "00000000011111110000",
	 "00000000001111111000",
	 "00000000000000000000",
	 "00000000000000000000"
	 );
	 signal ROM4 : memoria_rom := (
	 "00000000000000000000",
	 "00000000000000000000",
	 "00011111110000000000",
	 "00001111111000000000",
	 "00000111111100000000",
	 "00000011111110000000",
	 "00000001111111000000",
	 "00000000111111100000",
	 "00000000011111110000",
	 "00000000001111111000",
	 "00000000001111111000",
	 "00000000011111110000",
	 "00000000111111100000",
	 "00000001111111000000",
	 "00000011111110000000",
	 "00000111111100000000",
	 "00001111111000000000",
	 "00011111110000000000",
	 "00000000000000000000",
	 "00000000000000000000"
	 );
begin
	 anim <= ROM1 when state = "0000" else
				ROM4 when state = "0001" else
				ROM3 when state = "0010" else
				ROM2;
    process (clk) begin
        if rising_edge(clk) then
            if (en = '1') then
                if(addr >=43 and addr <=62) then
						data <= anim(conv_integer(addr));
					 else data <= (others=>'1');
					 end if;
            end if;
        end if;
    end process;
end behavioral;
