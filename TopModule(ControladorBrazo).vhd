--------------------------------------------------------------------------------
-- CONTROLADOR DEL BRAZO (TOP MODULE):
--
-- Nota: Desde aqui se generaran los relojes auxiliares que se necesitaran en
-- todos los subniveles (para evitar retrasos por latches o FF accidentales)
-- 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControladorBrazo is
	port ( clk_50MHz : in std_logic;										    -- senal del reloj interno de la Spartan
			 btn_inc, btn_dec, btn_mtr, btn_modo : in std_logic;	    -- botones para incrementar y decrementar posicion del servo seleccionado
			 state_arm, state_claw,										  	    -- \
			 state_modo : out std_logic_vector(1 downto 0) := "00";   --  senales para controlar el dispositivo esclavo
			 state_rotate : out std_logic_vector(2 downto 0) :="000"; -- /
			 pwmS1, pwmS2A, pwmS2B,	pwmS3,								    -- senales de PWM para controlar cada uno
			 pwmS4, pwmS5, pwmS6 : out std_logic;						    --  de los servos
			 LEDs : out std_logic_vector(7 downto 0) := "00000000");	 -- leds de la Spartan (permiten visualizar estados)
end ControladorBrazo;

architecture Behavioral of ControladorBrazo is

	--Estados para la maquina de estados
   type state_type is (manual, rutina1, release_btnModo, release_btnMtr);
	signal state : state_type;
	signal nextModo : state_type;
	
	--Registro para guardar el numero de motor seleccionado
	signal selectedMotor : integer range 1 to 6 := 1;
	signal nextMotor : integer range 1 to 6 := 1;

   --Velocidad de reproduccion de rutinas (tiempo de espera entre cada posicion)
   constant delay : integer := 4; 						  -- (clk_20Hz pulses) <= delay(s)*20
   signal contDelay : integer range 0 to delay := 0; -- (clk_20Hz pulses)

   --Componente para generar senales PWM para cada motor
	component PWM_Gen is
		port ( pos        : in integer range 0 to 180; -- posicion del servo (degrees)
         	 clk_166kHz : in std_logic;				  -- reloj de 166kHz (no usar otro reloj)
         	 pwm        : out std_logic );			  -- senal con PWM generado
	 end component;

	--Divisores para generar relojes auxiliares
	component divisor_20Hz is
		port ( clk_50MHz	: in  std_logic;
   			 clk_20Hz	: out std_logic );
	end component;
	component divisor_166kHz is
		port ( clk_50MHz	: in  std_logic;
				 clk_166kHz : out std_logic );
	end component;
	signal clk_20Hz, clk_166kHz : std_logic;
   
   --Limite fisico maximo y minimo para posiciones (en grados) de los servos
	constant minS1 : integer :=   0; -- Base Gira
	constant minS2 : integer :=  17; -- Base Levanta
	constant minS3 : integer :=  26; -- Codo Levanta
	constant minS4 : integer :=   4; -- Garra Levanta
	constant minS5 : integer :=   0; -- Garra Gira
	constant minS6 : integer :=  56; -- Garra Abre
   
	constant maxS1 : integer := 200; -- Base Gira
   constant maxS2 : integer := 162; -- Base Levanta
	constant maxS3 : integer := 113; -- Codo Levanta
	constant maxS4 : integer := 173; -- Garra Levanta
	constant maxS5 : integer := 200; -- Garra Gira
	constant maxS6 : integer := 180; -- Garra Abre
	
	--Senales para guardar la posicion actual (en grados) dee los servos
	signal posS1 : integer range 0 to 200 := 100; -- Base Gira
   signal posS2 : integer range 0 to 200 := 100; -- Base Levanta
	signal posS3 : integer range 0 to 200 := 100; -- Codo Levanta
	signal posS4 : integer range 0 to 200 := 100; -- Garra Levanta
	signal posS5 : integer range 0 to 200 := 100; -- Garra Gira
	signal posS6 : integer range 0 to 200 := 100; -- Garra Abre

	--Senales auxiliares para incrementar/decrementar posiciones
	signal incS1, incS2, incS3, incS4, incS5, incS6 : integer range 0 to 200;
	signal decS1, decS2, decS3, decS4, decS5, decS6 : integer range 0 to 200;

	--Senales auxiliares para obtener la siguiente posicion del brazo en una rutina
	signal nextS1, nextS2, nextS3, nextS4, nextS5, nextS6 : integer range 0 to 200;
	signal getNextState : std_logic := '0';

	--Componentes para mandar llamar rutinas automáticas
	component Rutina_1 is
		port ( nextState : in std_logic;
				 reset : in std_logic;
				 currS1, currS2, currS3, currS4,
				 currS5, currS6 : in integer range 0 to 200;
				 nextS1, nextS2, nextS3, nextS4,
				 nextS5, nextS6 : out integer range 0 to 200 );
	end component;

begin

	--Mapeo de divisores para generar señales relojes auxiliares
	Divisor_clk20Hz: divisor_20Hz port map (clk_50MHz, clk_20Hz);
	Divisor_clk166kHz: divisor_166kHz port map (clk_50MHz, clk_166kHz);

	--Mapeo de generadores de senales PWM para cada motor
	PWMGen_S1 : PWM_Gen port map (posS1, clk_166kHz, pwmS1);
	PWMGen_S2A: PWM_Gen port map (posS2, clk_166kHz, pwmS2A);
	PWMGen_S2B: PWM_Gen port map (posS2, clk_166kHz, pwmS2B);
	PWMGen_S3 : PWM_Gen port map (posS3, clk_166kHz, pwmS3);
	PWMGen_S4 : PWM_Gen port map (posS4, clk_166kHz, pwmS4);
	PWMGen_S5 : PWM_Gen port map (posS5, clk_166kHz, pwmS5);
	PWMGen_S6 : PWM_Gen port map (posS6, clk_166kHz, pwmS6);

	--Mapeo de las rutinas
	R1: Rutina_1 port  map ( getNextState, '0',
									posS1, posS2, posS3, posS4, posS5, posS6,
									nextS1, nextS2, nextS3, nextS4, nextS5, nextS6 );

	--Definicion de senales auxiliares de incremento y decremento de posiciones
	incS1 <= posS1 + 1 when (selectedMotor = 1) and (posS1 < maxS1) else posS1;
	incS2 <= posS2 + 1 when (selectedMotor = 2) and (posS2 < maxS2) else posS2;
	incS3 <= posS3 + 1 when (selectedMotor = 3) and (posS3 < maxS3) else posS3;
	incS4 <= posS4 + 1 when (selectedMotor = 4) and (posS4 < maxS4) else posS4;
	incS5 <= posS5 + 1 when (selectedMotor = 5) and (posS5 < maxS5) else posS5;
	incS6 <= posS6 + 1 when (selectedMotor = 6) and (posS6 < maxS6) else posS6;

	decS1 <= posS1 - 1 when (selectedMotor = 1) and (posS1 > minS1) else posS1;
	decS2 <= posS2 - 1 when (selectedMotor = 2) and (posS2 > minS2) else posS2;
	decS3 <= posS3 - 1 when (selectedMotor = 3) and (posS3 > minS3) else posS3;
	decS4 <= posS4 - 1 when (selectedMotor = 4) and (posS4 > minS4) else posS4;
	decS5 <= posS5 - 1 when (selectedMotor = 5) and (posS5 > minS5) else posS5;
	decS6 <= posS6 - 1 when (selectedMotor = 6) and (posS6 > minS6) else posS6;

	--Definicion de siguiente motor
	nextMotor <= 1 when selectedMotor = 6 else selectedMotor + 1;

	--Maquina de estados
	process(clk_20Hz)
	begin
		if rising_edge(clk_20Hz) then
			case state is

				when manual =>
					if btn_inc = '1' then
						posS1 <= incS1; posS2 <= incS2; posS3 <= incS3;
						posS4 <= incS4; posS5 <= incS5; posS6 <= incS6;
					elsif btn_dec = '1' then
						posS1 <= decS1; posS2 <= decS2; posS3 <= decS3;
						posS4 <= decS4; posS5 <= decS5; posS6 <= decS6;
					elsif btn_mtr = '1' then
						state <= release_btnMtr;
					elsif btn_modo = '1' then
						nextModo <= rutina1;
						state <= release_btnModo;
					end if;

				when rutina1 =>
					if btn_modo = '0' then
						nextModo <= manual;
						state <= release_btnMtr;
					elsif	contDelay = delay then
						getNextState <= '1';
						posS1 <= nextS1; posS2 <= nextS2; posS3 <= nextS3;
						posS4 <= nextS4; posS5 <= nextS5; posS6 <= nextS6;
						contDelay <= 0;
					else
						getNextState <= '0';
						contDelay <= contDelay + 1;
					end if;
				
				when release_btnModo =>
					if btn_modo = '0' then
						state <= nextModo;
					end if;

				when release_btnMtr =>
					if btn_mtr = '0' then
						selectedMotor <= nextMotor;
						state <= manual;
					end if;

			end case;
		end if;
	end process;

	--Definicion de las salidas de control para dispositivo esclavo
	state_arm <= "10" when posS3 < 73 else
					 "01" when posS3 < 103 else
					 "00";

	state_claw <= "10" when posS5 < 21 else
					  "01" when posS5 < 99 else
					  "00";

	state_modo <= "11" when state = rutina1 else
					  "10";

	state_rotate <= "000" when posS1 < 37 else
						 "001" when posS1 < 72 else
						 "010" when posS1 < 105 else
						 "011" when posS1 < 126 else
						 "100";
	
end Behavioral;

