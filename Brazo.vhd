library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity Brazo is
	port ( clk_50MHz : IN STD_LOGIC;
			 --servoSelect : IN STD_LOGIC_VECTOR(5 downto 1); --Switches que determinan qué motor esté activado
          btn_inc, btn_dec : IN STD_LOGIC; --Botones para incrementar o disminuir la rotacién de los motores seleccionados
          btn_save, btn_play, btn_reset : IN STD_LOGIC; --Botones para guardar estado, reproducir rutina y borrar rutina
			 LEDs : OUT STD_LOGIC_VECTOR(7 downto 0);
			 servos: OUT STD_LOGIC_VECTOR(6 downto 1) );
end Brazo;

architecture Behavioral of Brazo is

   --Velocidad de reproducción de rutinas (tiempo de espera entre cada posición)
   constant delay : integer := 10; --(clk10Hz pulses) = delay(s)*10
   signal contDelay : integer range 0 to delay := 0; --(clk10Hz pulses)

   --Componente de memoria para almacenar posiciones de motores para rutinas
   component memoria16x100 is
      port ( clk_10Hz : IN STD_LOGIC;
             memWrite : IN STD_LOGIC; --Señal para escribir en la dirección de memoria apuntada por MAR
             MAR : IN integer range 0 to 2**4 - 1; --Registro para almacenar la dirección de memoria de la que se leerá¡ o en la que se escribirá¡
             MDRin : IN STD_LOGIC_VECTOR(100 downto 1); --Registro que muestra la dirección de memoria apuntada
				 MDRout : OUT STD_LOGIC_VECTOR(100 downto 1) ); --Registro que muestra la dirección de memoria apuntada
   end component;

   --Apuntadores a memoria y control
   constant memSize : integer := 2**4;
   signal MAR : integer range 0 to memSize - 1;
	signal MDRin : STD_LOGIC_VECTOR(100 downto 1);
	signal MDRout : STD_LOGIC_VECTOR(100 downto 1);
	signal writeMem : STD_LOGIC := '0';
   signal endPtr, currPtr : integer range 0 to memSize - 1 := 0;
   signal memoryFull : STD_LOGIC := '0';

   --Estados para la má¡quina de estados
   type state_type is (idle, write1, write2, play, fetch1, fetch2);
   signal state : state_type;

   --Componente para generar seá±ales PWM para cada motor
	component PWM_Gen is
		port( duty      : in integer range 0 to 1000000; -- duty cycle del PWM (Spartan pulses) = duty(us)/0.02(us)
         clk_50MHz : in STD_LOGIC;                  -- reloj de 50MHz
         pwm       : out STD_LOGIC );               -- señal con PWM generado
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
   
   --Lí­mite de duty para cada uno de los servos (para revisar que no los superen)
   constant maxS1 : integer range 0 to 1000000 := 120000; -- Base Gira     : (Spartan pulses) | 2400 us | 180°
   constant maxS2 : integer range 0 to 1000000 := 110740; -- Base Levanta  : (Spartan pulses) | 2215 us | 162°
	--constant minS3 (es el mismo que el S2)
	constant maxS4 : integer range 0 to 1000000 :=  85532; -- Codo Levanta  : (Spartan pulses) | 1711 us | 113°
	constant maxS5 : integer range 0 to 1000000 := 116399; -- Garra Levanta : (Spartan pulses) | 2328 us | 173°
	constant maxS6 : integer range 0 to 1000000 :=  89648; -- Garra Abre    : (Spartan pulses) | 1793 us | 121°
	
	constant minS1 : integer range 0 to 1000000 :=  27400; -- Base Gira     : (Spartan pulses) |  548 us |   0°
	constant minS2 : integer range 0 to 1000000 :=  36146; -- Base Levanta  : (Spartan pulses) |  723 us |  17°
	--constant minS3 (es el mismo que el S2)
	constant minS4 : integer range 0 to 1000000 :=  40776; -- Codo Levanta  : (Spartan pulses) |  816 us |  26°
	constant minS5 : integer range 0 to 1000000 :=  29458; -- Garra Levanta : (Spartan pulses) |  589 us |   4°
	constant minS6 : integer range 0 to 1000000 :=  56209; -- Garra Abre    : (Spartan pulses) | 1124 us |  56°
   
	--Señales para guardar la posicién actual de cada uno de los servos (en pulsos de la Spartan)
	signal dutyS1  : integer range 0 to 1000000 :=  73700; -- Base Gira     : (Spartan pulses) | 1474 us |  90°
	signal dutyS2  : integer range 0 to 1000000 :=  73700; -- Base Levanta  : (Spartan pulses) | 1474 us |  90°
	--signal dutyS3 (es el mismo que el S2)
	signal dutyS4  : integer range 0 to 1000000 :=  73700; -- Codo Levanta  : (Spartan pulses) | 1474 us |  90°
	signal dutyS5  : integer range 0 to 1000000 :=  73700; -- Garra Levanta : (Spartan pulses) | 1474 us |  90°
	signal dutyS6  : integer range 0 to 1000000 :=  73700; -- Garra Abre    : (Spartan pulses) | 1474 us |  90°

	--Seá±ales de relojes auxiliares
   signal clk_10Hz : STD_LOGIC;
	
	signal debug1, debug2 : STD_LOGIC := '1';
   
begin

	--Usar LEDs para determinar estado
	LEDs(5 downto 0) <= "000100" when state = idle else
							  "000010" when state = write1 else
							  "000001" when state = write2 else
							  "001000" when state = play else
							  "010000" when state = fetch1 else
							  "100000" when state = fetch2 else
							  "000101";
	LEDs(6) <= debug2;
	LEDs(7) <= debug1;

	--Mapeo de cada uno de los servos del brazo
	Servo1: PWM_Gen port map (dutyS1, clk_50MHz, servos(1));
	Servo2: PWM_Gen port map (dutyS2, clk_50MHz, servos(2));
	Servo3: PWM_Gen port map (dutyS2, clk_50MHz, servos(3));
	Servo4: PWM_Gen port map (dutyS4, clk_50MHz, servos(4));
	Servo5: PWM_Gen port map (dutyS5, clk_50MHz, servos(5));
   Servo6: PWM_Gen port map (dutyS6, clk_50MHz, servos(6));

   --Limpiar seá±ales de botones a traves de OneShots
   OSsave:  OneShot port map (btn_save , clk_10Hz, OS_save );
   OSplay:  OneShot port map (btn_play , clk_10Hz, OS_play );
   OSreset: OneShot port map (btn_reset, clk_10Hz, OS_reset);
   
	--Generar relojes auxiliares
	clk10Hz: divisor_10Hz port map (clk_50MHz, clk_10Hz);
   
   --Mapeo de memoria
   Memory: memoria16x100 port map (clk_10Hz, writeMem, MAR, MDRin, MDRout);

	process(clk_10Hz) begin
		if rising_edge(clk_10Hz) then
         case state is

            when idle =>
               if btn_inc = '1' then
                  dutyS1 <= 73700;
						dutyS2 <= 73700;
						dutyS4 <= 73700;
						dutyS5 <= 73700;
						dutyS6 <= 73700;
						debug1 <= not debug1;--not debug1;
						state <= idle;
               elsif btn_dec = '1' then
                  dutyS1 <= 56209;
						dutyS2 <= 56209;
						dutyS4 <= 56209;
						dutyS5 <= 56209;
						dutyS6 <= 56209;
						debug2 <= not debug2;
						state <= idle;
               elsif OS_reset = '1' then
                  endPtr <= 0;
                  memoryFull <= '0';
						state <= idle;
               elsif OS_save = '1' and memoryFull = '0' then
                  MAR <= endPtr;
                  MDRin <= CONV_STD_LOGIC_VECTOR(dutyS1, 20) &
									CONV_STD_LOGIC_VECTOR(dutyS2, 20) &
									CONV_STD_LOGIC_VECTOR(dutyS4, 20) &
									CONV_STD_LOGIC_VECTOR(dutyS5, 20) &
									CONV_STD_LOGIC_VECTOR(dutyS6, 20) ;
						state <= write1;
               elsif OS_play = '1' and endPtr > 0 then --((endPtr > 0) or (memoryFull = '1')) then
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
               dutyS1 <= CONV_INTEGER(UNSIGNED(MDRout( 20 downto 01)));
               dutyS2 <= CONV_INTEGER(UNSIGNED(MDRout( 40 downto 21)));
               dutyS4 <= CONV_INTEGER(UNSIGNED(MDRout( 60 downto 41)));
               dutyS5 <= CONV_INTEGER(UNSIGNED(MDRout( 80 downto 61)));
               dutyS6 <= CONV_INTEGER(UNSIGNED(MDRout(100 downto 81)));
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
		else
			null;
		end if;
	end process;

end Behavioral;

