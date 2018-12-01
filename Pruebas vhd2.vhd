library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Brazo is
	port ( clk_50MHz : IN STD_LOGIC;
			 --servoSelect : IN STD_LOGIC_VECTOR(5 downto 1); --Switches que determinan quï¿½ motor estï¿½ activado
          btn_inc, btn_dec : IN STD_LOGIC; --Botones para incrementar o disminuir la rotaciï¿½n de los motores seleccionados
          btn_save, btn_play, btn_reset : IN STD_LOGIC; --Botones para guardar estado, reproducir rutina y borrar rutina
			 LEDs : OUT STD_LOGIC_VECTOR(7 downto 0);
			 servos: OUT STD_LOGIC_VECTOR(5 downto 1) );
end Brazo;

architecture Behavioral of Brazo is

   --Velocidad de reproducciÃ³n de rutinas (tiempo de espera entre cada posiciÃ³n)
   constant delay : integer := 20; --(clk10Hz pulses) = delay(s)*10
   signal contDelay : integer := 0; --(clk10Hz pulses)

   --Componente de memoria para almacenar posiciones de motores para rutinas
   component memoria16x25 is
      port ( clk_50Hz : IN STD_LOGIC;
             write : IN STD_LOGIC; --SeÃ±al para escribir en la direcciÃ³n de memoria apuntada por MAR
             MAR : IN integer range 0 to 2**4 - 1; --Registro para almacenar la direcciÃ³n de memoria de la que se leerÃ¡ o en la que se escribirÃ¡
             MDRin : IN STD_LOGIC_VECTOR(100 downto 1); --Registro que muestra la direcciÃ³n de memoria apuntada
				 MDRout : OUT STD_LOGIC_VECTOR(100 downto 1) ); --Registro que muestra la direcciÃ³n de memoria apuntada
   end component;

   --Apuntadores a memoria y control
   constant memSize : integer := 2**4;
   signal MAR : integer range 0 to memSize - 1;
	signal MDRin : STD_LOGIC_VECTOR(100 downto 1);
	signal MDRout : STD_LOGIC_VECTOR(100 downto 1);
	signal writeMem : STD_LOGIC := '0';
   signal endPtr, currPtr : integer range 0 to memSize - 1 := 0;
   signal memoryFull : STD_LOGIC := '0';

   --Estados para la mÃ¡quina de estados
   type state_type is (idle, write1, write2, play, fetch1, fetch2);
   signal state : state_type;

   --Componente para generar seÃ±ales PWM para cada motor
	component PWM_Gen is
		port( duty      : in STD_LOGIC_VECTOR(19 downto 0); -- duty cycle del PWM (Spartan pulses) = duty(us)/0.02(us)
			   clk_50MHz : in STD_LOGIC;                     -- reloj de 50MHz
			   pwm       : out STD_LOGIC );                  -- seÃ±al con PWM generado
	 end component;

	--Divisores para generar relojes auxiliares
	component divisor_10Hz is
		port( clk_50MHz : in  STD_LOGIC;
   			clk_10Hz   : out STD_LOGIC );
   end component;
   
   --Componente OneShot para ignorar el ruido de los botones
   component OneShot is
      port( E  : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            S : OUT STD_LOGIC );
   end component;

   --Botones pasados por OneShot
   signal OS_save, OS_play, OS_reset : STD_LOGIC;
   
   --LÃ­mite de duty para cada uno de los servos (para revisar que no los superen)
   constant maxS1 : STD_LOGIC_VECTOR(19 downto 0) := "00011111010000000000"; --128000 Spartan pulses o 2360 us
   constant maxS2 : STD_LOGIC_VECTOR(19 downto 0) := "00011111010000000000"; --128000 Spartan pulses o 2360 us
   constant maxS3 : STD_LOGIC_VECTOR(19 downto 0) := "00011111010000000000"; --128000 Spartan pulses o 2360 us
   constant maxS4 : STD_LOGIC_VECTOR(19 downto 0) := "00011111010000000000"; --128000 Spartan pulses o 2360 us
   constant maxS5 : STD_LOGIC_VECTOR(19 downto 0) := "00011111010000000000"; --128000 Spartan pulses o 2360 us

   constant minS1 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000"; --27400 Spartan pulses o 548 us
   constant minS2 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000"; --27400 Spartan pulses o 548 us
   constant minS3 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000"; --27400 Spartan pulses o 548 us
   constant minS4 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000"; --27400 Spartan pulses o 548 us
   constant minS5 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000"; --27400 Spartan pulses o 548 us
   
	--SeÃ±ales para guardar la posiciï¿½n actual de cada uno de los servos (en pulsos de la Spartan)
	signal dutyS1 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000";
	signal dutyS2 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000";
	signal dutyS3 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000";
	signal dutyS4 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000";
	signal dutyS5 : STD_LOGIC_VECTOR(19 downto 0) := "00000110101100001000";

	--SeÃ±ales de relojes auxiliares
   signal clk_10Hz : STD_LOGIC;
   
begin

	--Usar LEDs para determinar estado
	LEDs(6 downto 0) <= "0000100" when state = idle else
							  "0000010" when state = write1 else
							  "0000001" when state = write2 else
							  "0001000" when state = play else
							  "0010000" when state = fetch1 else
							  "0100000" when state = fetch2 else
							  "0000000";
	LEDs(7) <= memoryFull;

	--Mapeo de cada uno de los servos del brazo
	Servo1: PWM_Gen port map (dutyS1, clk_50MHz, servos(1));
	Servo2: PWM_Gen port map (dutyS2, clk_50MHz, servos(2));
	Servo3: PWM_Gen port map (dutyS3, clk_50MHz, servos(3));
	Servo4: PWM_Gen port map (dutyS4, clk_50MHz, servos(4));
   Servo5: PWM_Gen port map (dutyS5, clk_50MHz, servos(5));

   --Limpiar seÃ±ales de botones a traves de OneShots
   OSsave:  OneShot port map (btn_save , clk_10Hz, OS_save );
   OSplay:  OneShot port map (btn_play , clk_10Hz, OS_play );
   OSreset: OneShot port map (btn_reset, clk_10Hz, OS_reset);
   
	--Generar relojes auxiliares
	clk10Hz: divisor_10Hz port map (clk_50MHz, clk_10Hz);
   
   --Mapeo de memoria
   Memory: memoria16x25 port map (clk_10Hz, writeMem, MAR, MDRin, MDRout);

	process(clk_10Hz) begin
		if rising_edge(clk_10Hz) then
         case state is

            when idle =>
               if btn_inc = '1' then
                  dutyS1 <= "00000110101100001000";--dutyS1 + "00000000001000101110"; -- +558
                  dutyS2 <= "00000110101100001000";--dutyS2 + "00000000001000101110"; -- +558
                  dutyS3 <= "00000110101100001000";--dutyS3 + "00000000001000101110"; -- +558
                  dutyS4 <= "00000110101100001000";--dutyS4 + "00000000001000101110"; -- +558
                  dutyS5 <= "00000110101100001000";--dutyS5 + "00000000001000101110"; -- +558
						--state <= idle;
               elsif btn_dec = '1' then
                  dutyS1 <= "00011111010000000000";--dutyS1 - "00000000001000101110"; -- -558
                  dutyS2 <= "00011111010000000000";--dutyS2 - "00000000001000101110"; -- -558
                  dutyS3 <= "00011111010000000000";--dutyS3 - "00000000001000101110"; -- -558
                  dutyS4 <= "00011111010000000000";--dutyS4 - "00000000001000101110"; -- -558
                  dutyS5 <= "00011111010000000000";--dutyS5 - "00000000001000101110"; -- -558
						--state <= idle;
               elsif OS_reset = '1' then
                  endPtr <= 0;
                  memoryFull <= '0';
						--state <= idle;
               elsif OS_save = '1' and memoryFull = '0' then
                  MAR <= endPtr;
                  MDRin <= dutyS1 & dutyS2 & dutyS3 & dutyS4 & dutyS5;
                  state <= write1;
               elsif (OS_play = '1') and ((endPtr > 0) or ((memoryFull = '0') and (endPtr = 0))) then
                  currPtr <= 0;
                  contDelay <= delay;
                  state <= play;
					else
						null;
               end if;

            when write1 =>
               writeMem <= '1';
               state <= write2;

            when write2 =>
               if endPtr = (memSize - 1) then
                  writeMem <= '0';
                  endPtr <= 0;
                  memoryFull <= '1';
                  state <= idle;
               else
                  writeMem <= '0';
                  endPtr <= endPtr + 1;
                  state <= idle;
               end if;

            when play =>
               if OS_play = '1' then
                  state <= idle;
               elsif contDelay > 0 then
                  contDelay <= contDelay - 1;
               else
                  MAR <= currPtr;
                  state <= fetch1;
               end if;

            when fetch1 =>
               dutyS1 <= MDRout( 20 downto 01);
               dutyS2 <= MDRout( 40 downto 21);
               dutyS3 <= MDRout( 60 downto 41);
               dutyS4 <= MDRout( 80 downto 61);
               dutyS5 <= MDRout(100 downto 81);
               state <= fetch2;

            when fetch2 =>
               if memoryFull = '0' and currPtr = (endPtr - 1) then
                  currPtr <= 0;
                  contDelay <= delay;
                  state <= play;
               elsif memoryFull = '1' and currPtr = (memSize - 1) then
                  currPtr <= 0;
                  contDelay <= delay;
                  state <= play;
               else
                  currPtr <= currPtr + 1;
                  contDelay <= delay;
                  state <= play;
               end if;

            when others =>
               null;

         end case;
		end if;
	end process;

end Behavioral;

