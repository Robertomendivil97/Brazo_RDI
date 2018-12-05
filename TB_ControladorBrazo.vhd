LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY TB_ControladorBrazo IS
END TB_ControladorBrazo;
 
ARCHITECTURE behavior OF TB_ControladorBrazo IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ControladorBrazo
    PORT(
         clk_50MHz : IN  std_logic;
         btn_inc : IN  std_logic;
         btn_dec : IN  std_logic;
         btn_mtr : IN  std_logic;
         btn_modo : IN  std_logic;
         state_arm : OUT  std_logic_vector(1 downto 0);
         state_claw : OUT  std_logic_vector(1 downto 0);
         state_modo : OUT  std_logic_vector(1 downto 0);
         state_rotate : OUT  std_logic_vector(2 downto 0);
         pwmS1 : OUT  std_logic;
         pwmS2A : OUT  std_logic;
         pwmS2B : OUT  std_logic;
         pwmS3 : OUT  std_logic;
         pwmS4 : OUT  std_logic;
         pwmS5 : OUT  std_logic;
         pwmS6 : OUT  std_logic;
         LEDs : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_50MHz : std_logic := '0';
   signal btn_inc : std_logic := '0';
   signal btn_dec : std_logic := '0';
   signal btn_mtr : std_logic := '0';
   signal btn_modo : std_logic := '0';

 	--Outputs
   signal state_arm : std_logic_vector(1 downto 0);
   signal state_claw : std_logic_vector(1 downto 0);
   signal state_modo : std_logic_vector(1 downto 0);
   signal state_rotate : std_logic_vector(2 downto 0);
   signal pwmS1 : std_logic;
   signal pwmS2A : std_logic;
   signal pwmS2B : std_logic;
   signal pwmS3 : std_logic;
   signal pwmS4 : std_logic;
   signal pwmS5 : std_logic;
   signal pwmS6 : std_logic;
   signal LEDs : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_50MHz_period : time := 20 ps;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ControladorBrazo PORT MAP (
          clk_50MHz => clk_50MHz,
          btn_inc => btn_inc,
          btn_dec => btn_dec,
          btn_mtr => btn_mtr,
          btn_modo => btn_modo,
          state_arm => state_arm,
          state_claw => state_claw,
          state_modo => state_modo,
          state_rotate => state_rotate,
          pwmS1 => pwmS1,
          pwmS2A => pwmS2A,
          pwmS2B => pwmS2B,
          pwmS3 => pwmS3,
          pwmS4 => pwmS4,
          pwmS5 => pwmS5,
          pwmS6 => pwmS6,
          LEDs => LEDs
        );

   -- Clock process definitions
   clk_50MHz_process :process
   begin
		clk_50MHz <= '0';
		wait for clk_50MHz_period/2;
		clk_50MHz <= '1';
		wait for clk_50MHz_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		btn_inc  <= '0';
		btn_dec  <= '0';
		btn_mtr  <= '0';
		btn_modo <= '0';
      wait for 100 ns;

		-- hold the increase position button for 0.1 second
		btn_inc <= '1';
		wait for 100 ms;
		btn_inc <= '0';
		
		--press the button to change selected motor twice
		wait for 100 ms;
		btn_mtr <= '1';
		wait for 100 ms;
		btn_mtr <= '0';
		wait for 100 ms;
		btn_mtr <= '1';
		wait for 100 ms;
		btn_mtr <= '0';
		
		-- hold the decrease position button for 0.1 second
		wait for 100 ms;
		btn_dec <= '1';
		wait for 100 ms;
		btn_dec <= '0';
		
		--press the button to change mode once
		wait for 100 ms;
		btn_modo <= '1';
		wait for 100 ms;
		btn_modo <= '0';
		
		-- watch the routine for 10 seconds
		wait for 4000 ms;
		
		--press the button to change mode once
		wait for 100 ms;
		btn_modo <= '1';
		wait for 100 ms;
		btn_modo <= '0';
		
      wait;
   end process;

END;
