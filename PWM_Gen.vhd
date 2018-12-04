--------------------------------------------------------------------------------
-- GENERADOR DE SENALES PWM PARA CONTROL DE SERVOMOTORES:
--
-- Nota: Este componente trabaja con un reloj de frecuencia especifica para los
-- servos que se estan utilizando en el proyecto (consultar la
-- documentacion)
-- 
-- Formulas (consultar documentacion para explicacion)
--    period = PulseCycle_Motor(us) * Range_Motor(degrees) / ( Duty_Range(us) * 1(degrees) )
--    dutyDisplacement = min_Motor_Range(us) * Range_Motor(degrees) / ( Duty_Range(us) * 1(degrees) )
--
--    frecuencia del reloj = 1000000(Hz) * Range_Motor(degrees) * 1(us) / ( Duty_Range(us) * 1(degrees) )
--    contLimit del reloj = 25(MHz) / frequencia_del_reloj(Hz)
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PWM_Gen is
   port ( pos        : in integer range 0 to 180; -- posicion del servo (degrees)
          clk_166kHz : in std_logic;				  -- reloj de 166kHz (no usar otro reloj)
          pwm        : out std_logic );			  -- senal con PWM generado
end PWM_Gen;

architecture behavioral of PWM_Gen is

   constant period : integer := 3333;              -- (clk_166kHz pulses)
   signal periodCount : integer range 0 to period; -- (clk_166kHz pulses)

   constant dutyDisplacement : integer := 150;   -- (clk_166kHz pulses) 
   signal dutyReal : integer range 0 to period; -- (clk_166kHz pulses)
	
begin

   --Definicion de dutyReal (consultar documentacion)
   dutyReal <= pos + dutyDisplacement;

   process (clk_166kHz)
   begin
      if rising_edge(clk_166kHz) then
         if periodCount = period - 1 then
            periodCount <= 0;
         else
            periodCount <= periodCount + 1;
         end if;
      end if;
   end process;
   
   --La senal del PWM esta en '1' mientras durante la duracion del duty cycle
   PWM <= '1' when (periodCount < dutyReal) else '0';
            
end behavioral;


