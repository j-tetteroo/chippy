library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Pseudo random number generator

entity chippy_randgen is
	port (clk : in std_logic;
	reset : in std_logic;
	rand_out : out unsigned(7 downto 0));
end chippy_randgen;		


architecture behavioural of chippy_randgen is  

	signal state, state_new : unsigned(7 downto 0);   
	signal feedback : std_logic;

begin 
	combinatorial : process(state)
		variable feedback : std_logic;
		variable v_state : unsigned(7 downto 0);
	begin						  
		feedback := state(7) XOR state(5) XOR state(4) XOR state(3); -- Taps: x^8 + x^6 + x^5 + x^4 + 1
		v_state := state(6 downto 0) & feedback;
		state_new <= v_state;
	end process;
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then	 
			if reset = '1' then
				state <= "00100001";
			else
				state <= state_new;
			end if;
		end if;
	end process; 
	rand_out <= state;
	
end architecture;