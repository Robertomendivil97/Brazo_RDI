library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity Brazo is
	port ( clk_50MHz : IN STD_LOGIC;
			 servoSelect : IN STD_LOGIC_VECTOR(5 downto 1); --Switches que determinan qu� motor est� activado
          btn_inc, btn_dec : IN STD_LOGIC; --Botones para incrementar o disminuir la rotaci�n de los motores seleccionados
          btn_save, btn_play, btn_reset : IN STD_LOGIC; --Botones para guardar estado, reproducir rutina y borrar rutina
			 servos: OUT STD_LOGIC_VECTOR(5 downto 1) );
end Brazo;

architecture Behavioral of Brazo is

   --Componente para generar señales PWM para cada motor
	component PWM_Gen is
		port( duty      : in STD_LOGIC_VECTOR(19 downto 0); -- duty cycle del PWM (Spartan pulses) = duty(us)/0.02(us)
			  clk_50MHz : in STD_LOGIC;                     -- reloj de 50MHz
			  pwm       : out STD_LOGIC );                  -- señal con PWM generado
	 end component;

	--Divisores para generar relojes auxiliares
	component divisor_5Hz is
		port( clk_50MHz : in  STD_LOGIC;
   			clk_5Hz   : out STD_LOGIC );
	end component;
	
	--Señales para guardar la posici�n actual de cada uno de los servos
	signal dutyS1 : STD_LOGIC_VECTOR(6 downto 0) := "0000000";
	signal dutyS2 : STD_LOGIC_VECTOR(6 downto 0) := "0000000";
	signal dutyS3 : STD_LOGIC_VECTOR(6 downto 0) := "0000000";
	signal dutyS4 : STD_LOGIC_VECTOR(6 downto 0) := "0000000";
	signal dutyS5 : STD_LOGIC_VECTOR(6 downto 0) := "0000000";
	
	--Señales para validar que los servos no excedan su capacidad
	signal min, max : STD_LOGIC;

	--Señales de relojes auxiliares
   signal clk_5Hz : STD_LOGIC;
   
begin

	--Mapeo de cada uno de los servos del brazo
	Servo1 : PWM_Gen port map (dutyS1, clk_50MHz, servos(1));
	Servo2 : PWM_Gen port map (dutyS2, clk_50MHz, servos(2));
	Servo3 : PWM_Gen port map (dutyS3, clk_50MHz, servos(3));
	Servo4 : PWM_Gen port map (dutyS4, clk_50MHz, servos(4));
	Servo5 : PWM_Gen port map (dutyS5, clk_50MHz, servos(5));
	
	--Max = '1' cuando alguno de los motores seleccionados ha llegado al m�ximo
	max <= '1' when ( (dutyS1 > 126) and (servoSelect(1) = '1') ) or
						 ( (dutyS2 > 126) and (servoSelect(2) = '1') ) or
						 ( (dutyS3 > 126) and (servoSelect(3) = '1') ) or
						 ( (dutyS4 > 126) and (servoSelect(4) = '1') ) or
						 ( (dutyS5 > 126) and (servoSelect(5) = '1') )
				 else '0';
	--Min = '1' cuando alguno de los motores seleccionados ha llegado al m�nimo	  
	min <= '1' when ( (dutyS1 < 1) and (servoSelect(1) = '1') ) or
						 ( (dutyS2 < 1) and (servoSelect(2) = '1') ) or
						 ( (dutyS3 < 1) and (servoSelect(3) = '1') ) or
						 ( (dutyS4 < 1) and (servoSelect(4) = '1') ) or
						 ( (dutyS5 < 1) and (servoSelect(5) = '1') )
				  else '0';
				  
	--Generar relojes auxiliares
	clk5Hz: divisor_5Hz port map (clk_50MHz, clk_5Hz);
	
	process(clk_5Hz) begin
		if rising_edge(clk_5Hz) then
			--Cuando se presiona el btn_inc y ninguno de los motores ha llegado al m�ximo, incrementar
			if (btn_inc = '1') and (max = '0') then
				if servoSelect(1) = '1' then
					dutyS1 <= dutyS1 + 1;
				end if;
				if servoSelect(2) = '1' then
					dutyS2 <= dutyS2 + 1;
				end if;
				if servoSelect(3) = '1' then
					dutyS3 <= dutyS3 + 1;
				end if;
				if servoSelect(4) = '1' then
					dutyS4 <= dutyS4 + 1;
				end if;
				if servoSelect(5) = '1' then
					dutyS5 <= dutyS5 + 1;
				end if;
			--Cuando se presiona el btn_dec y ninguno de los motores ha llegado al m�nimo, decrementar
			elsif (btn_dec = '1') and (min = '0') then
				if servoSelect(1) = '1' then
					dutyS1 <= dutyS1 - 1;
				end if;
				if servoSelect(2) = '1' then
					dutyS2 <= dutyS2 - 1;
				end if;
				if servoSelect(3) = '1' then
					dutyS3 <= dutyS3 - 1;
				end if;
				if servoSelect(4) = '1' then
					dutyS4 <= dutyS4 - 1;
				end if;
				if servoSelect(5) = '1' then
					dutyS5 <= dutyS5 - 1;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

