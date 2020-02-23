library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity chippy_regfile is
	port (clk : in std_logic,
	reset : in std_logic,
	
	reg_input_data : in std_logic_vector(7 downto 0),
	reg_read : in std_logic,
	reg_write : in std_logic,
	reg_addr : in std_logic_vector(3 downto 0),
	reg_output_data : out std_logic_vector(7 downto 0)
	
	);
end chippy_regfile;

architecture behavioural of chippy_regfile is


	signal r, rin;

begin
	
	combinatorial : process(reg_input_data, reg_read, reg_write, reg_addr, r)
		variable v : regfile_type;
		
	begin
		v := r;
		
	end process;
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process; 
	
end architecture;