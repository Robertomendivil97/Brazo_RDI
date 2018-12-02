library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

--Esta entidad genera un PWM a partir del duty cycle que se le especifica de entrada
--*El funcionamiento de este componente es a base de los pulsos del reloj de la Spartan

--El duty cycle que recibe de entrada está¡ en pulsos de la Spartan (1/50MHz)
--y se sigue la siguiente regla para hacer conversiones:
--
--      duty(us)       period(us)
--    ------------ = --------------
--    duty(pulses)   period(pulses)
--
--  duty(pulses) = duty(us)*period(pulses)/period(us)
--  duty(pulses) = duty(us)/0.02(us)

--Experimentalmente se han comprobado que:
--     0° se generan con un duty de  548 us
--   180° se generan con un duty de 2400 us

entity PWM_Gen is
   port( duty      : in integer range 0 to 1000000; -- duty cycle del PWM (Spartan pulses) = duty(us)/0.02(us) STD_LOGIC_VECTOR(19 downto 0);
         clk_50MHz : in STD_LOGIC;                  -- reloj de 50MHz
         pwm       : out STD_LOGIC );               -- señal con PWM generado
end PWM_Gen;

architecture behavioral of PWM_Gen is

   --Spartan clock period      0.02 (microseconds)   = 1/50MHz
   --  Desired PWM period    20,000 (microoseconds)  = Arduino's period
   --  Desired PWM period 1,000,000 (Spartan pulses) = Desired(us)/Spartan(us)

   constant PWMperiod : integer range 0 to 1000000 := 1000000; --(Spartan pulses)
   signal cont : integer range 0 to 1000000 := 0; --(Spartan pulses)
	
	--constant PWMperiod : STD_LOGIC_VECTOR(19 downto 0) := "11110100001001000000"; --(Spartan pulses)
   --signal cont        : STD_LOGIC_VECTOR(19 downto 0) := "00000000000000000000"; --(Spartan pulses) 

begin

   --Se cuentan los pulsos de la Spartan que han transcurrido durante el ciclo PWM
   process (clk_50MHz)
   begin

      if rising_edge(clk_50MHz) then
         if cont = PWMperiod - 1 then
            cont <= 0;
         else
            cont <= cont + 1;
         end if;
      end if;
      
   end process;
   
   --La señal del PWM está en 1 mientras los pulsos transcurridos sean menor a los pulsos del duty cycle
   PWM <= '1' when (cont < duty) else '0';
            
end behavioral;


