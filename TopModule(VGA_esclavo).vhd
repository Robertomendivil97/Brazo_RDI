library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main_vga is
port ( clk_50MHz : in std_logic;
			state_arm, state_claw, state_mod: in std_logic_vector(1 downto 0):="00";
			 state_ROTATE, state_m: in std_logic_vector(2 downto 0):="000";
			 R, G, B : out std_logic;
			 H, V: out std_logic
			);
end main_vga;

architecture Behavioral of main_vga is
	
	--Senales y componentes VGA
	component Arm_ROM is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(3 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(47 to 238)
		 );
	end component;

	component motor1_estatus is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(1 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(47 to 86)
		 );
	end component;

	component Modo is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(1 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(47 to 66)
		 );
	end component;
	component rotate_ROM is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(2 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(240 to 389)
		 );
	end component;
	component claw_anim is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(1 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(401 to 592)
		 );
	end component;

	component sync
		port (
			CK: in std_logic;
			HS, VS: out std_logic;
			GO: out std_logic;
			X: out std_logic_vector(9 downto 0);
			Y: out std_logic_vector(9 downto 0) 
		);
	end component;

	component Mot_est_1 is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(3 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(87 to 106)
		 );
	end component;

	component Mot_est_2 is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(3 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(87 to 106)
		 );
	end component;
	component Mot_est_3 is
		 port (
			  clk  : in std_logic;
			  en   : in std_logic;
			  state: in std_logic_vector(3 downto 0);
			  addr : in std_logic_vector(9 downto 0);
			  data : out std_logic_vector(87 to 106)
		 );
	end component;
component divisor_25MHz is
		port ( clk_50MHz : in  STD_LOGIC;
					clk_25MHz : out STD_LOGIC );
	end component;
signal CLK25MAux, clock, ENArm,nextM,change: std_logic;
	signal dat: std_logic_vector(47 to 238);
	signal datS: std_logic_vector(47 to 66);
	signal datM: std_logic_vector(47 to 86);
	signal p1:  std_logic_vector (0 to 239);
	signal p2:  std_logic_vector (390 to 679);
	signal dat3: std_logic_vector (240 to 389);
	signal datM1,datm2,datM3: std_logic_vector(87 to 106);
	signal aux: std_logic_vector(67 to 679):=(others=>'0');
	signal aux2: std_logic_vector(107 to 679):=(others=>'0');
	signal dat2: std_logic_vector(401 to 592);
	signal data0: std_logic_vector(239 to 400):=(others=>'0');
	signal data1: std_logic_vector(0 to 46):=(others=>'0');
	signal data2: std_logic_vector(593 to 679):=(others=>'0');
	signal img: std_logic_vector(0 to 679):=(others=>'0');
	signal HSyncAux, VSyncAux: std_logic;
	Signal HAux, VAux: std_logic_vector(9 downto 0):="0000000000";
	
	signal state: std_logic_vector(1 downto 0):="10";
	
	signal state_arm2,gr,state_current: std_logic_vector(3 downto 0):="0000"; 
Signal vidAux, rSign_arm, gSign_arm, rSign_claw, gSign_claw, rSign_rotate, gSign_rotate: std_logic:='0';
begin
 -- procesos de vga
	state<=state_mod;
	rotate: rotate_rom port map(CLK25MAux,enarm,state_rotate,vaux,dat3);
	motor1: Mot_est_1 port map(CLK25MAux,enarm,state_current,vaux,datM1);
	motor2: Mot_est_2 port map(CLK25MAux,enarm,state_current,vaux,datM2);
	motor3: Mot_est_3 port map(CLK25MAux,enarm,state_current,vaux,datM3);
	state_arm2 <= (state_arm&state_claw);
	monitorclk: divisor_25MHz port map(clk_50MHz,CLK25MAux);
	arm: arm_rom port map(CLK25MAux,ENArm,state_Arm2,VAux,dat);
	claw: claw_anim port map(CLK25MAux,ENArm,state_claw,VAux,dat2);
	mode: modo port map(clk_50MHz,ENArm,state,VAux,datS);
	VGA: sync port map(clk_50MHz,HSyncAux,VSyncAux,vidaux,HAux,VAux);
	current_motor: motor1_estatus port map(CLK25MAux,'1',"00",VAux,datM);
	ENArm <= '1' when ((VAux > 286 and VAux < 439) and (HAux > 46 and HAux < 239)) or (VAux > 20 and VAux < 41) or (VAux >= 137 and VAux <= 286)else
				'0';
	
	
	img <= data1&dat&data0&dat2&data2 when (VAux > 286 and VAux < 439) else
			 data1&datS&aux when (VAux > 20 and VAux < 41) else
			 data1&datM&datM1&aux2 when (VAux > 42 and VAux <= 63) else
			 data1&datM&datM2&aux2 when (VAux > 63 and VAux <= 83) else
			 data1&datM&datM3&aux2 when (VAux > 84 and VAux <= 103) else 
			 p1&dat3&p2 when (VAux > 136 and VAux <= 286) else 
			 (others=>'0');
	process (clk_50MHz)
	begin-- '0';
		if vidaux = '1' then
			if(VAux > 286 and VAux < 439) and (HAux > 46 and HAux < 239) then
				
					r <= '0';
					g <= img(conv_integer(HAux)); 
					b <= '0';
			elsif(VAux > 286 and VAux < 439) and (HAux > 46 and HAux < 593) then
				r <= '0';
					g <= img(conv_integer(HAux)); 
					b <= '0';
			elsif(VAux >= 137 and VAux <= 286) and (HAux >= 240 and HAux <=389) then
				r <= '0';
					g <= img(conv_integer(HAux)); 
					b <= '0';
			elsif(VAux > 42 and VAux < 63) and (HAux > 46 and HAux < 87) then
					if state_m = "000" then
						r <= img(conv_integer(HAux));
						g <= img(conv_integer(HAux));
						b <= img(conv_integer(HAux));
					else
						r <= '0';
						g <= '0';
						b <= '0';
					end if;
			elsif(VAux > 62 and VAux < 83) and (HAux > 46 and HAux < 87) then
					if state_m = "001" or state_m = "010" or state_m = "011"  then
						r <= img(conv_integer(HAux));
						g <= img(conv_integer(HAux));
						b <= img(conv_integer(HAux));
					else
						r <= '0';
						g <= '0';
						b <= '0';
					end if;
			elsif(VAux > 82 and VAux < 103) and (HAux > 46 and HAux < 87) then
					if state_m = "100" then
						r <= img(conv_integer(HAux));
						g <= img(conv_integer(HAux));
						b <= img(conv_integer(HAux));
					else
						r <= '0';
						g <= '0';
						b <= '0';
					end if;
			elsif(VAux > 20 and VAux < 41) and (HAux > 46 and HAux < 67) then
				if state = "00" then
					r <= img(conv_integer(HAux));
					g <= '0'; 
					b <= not img(conv_integer(HAux)) ;
				elsif state = "01" then
					r <= '0';
					g <= img(conv_integer(HAux)); 
					b <= not img(conv_integer(HAux)); 
				elsif state = "10" then
					r <= img(conv_integer(HAux));
					g <= img(conv_integer(HAux)); 
					b <= not img(conv_integer(HAux)); 
				elsif state = "11" then
					r <= img(conv_integer(HAux));
					g <= '0'; 
					b <= not img(conv_integer(HAux));
				else 
				r <= '0';
				g <= '0';
				b <= '1';
				end if;
			else
				r <= '0';
				g <= '0';
				b <= '1';
			end if;
		else 
			r <= '0';
			g <= '0';
			b <= '0';
		end if;
	end process;
	H <= HSyncAux;
	V <= VSyncAux;

end Behavioral;

