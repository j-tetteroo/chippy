library ieee;
library work;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;
use work.chippy_randgen;

entity chippy_randgen_tb is
end chippy_randgen_tb;

architecture test of chippy_randgen_tb is

	constant DELTA : time := 100 ns;
	constant MAX_DELAY : natural := 100;


    signal sim_finished : boolean := false;

    signal clk : std_logic;
    signal reset : std_logic;
	
	signal state_out : unsigned(7 downto 0);
	signal result : unsigned(7 downto 0);
	
	file input_buf : text;

begin
	-- Declare component under test
	randgen : entity chippy_randgen
		port map(clk => clk,
			reset => reset,
			rand_out => state_out);
	
clock : process
    begin
        if not sim_finished then
            clk <= '1';
            wait for DELTA / 2;
            clk <= '0';
            wait for DELTA / 2;
        else
            wait;
        end if;
    end process clock;
	
	
tb1: process

	procedure sync_reset is
	begin
		wait until rising_edge(clk);
		wait for DELTA / 4;
		reset <= '1';
		wait until rising_edge(clk);
		wait for DELTA / 4;
		reset <= '0';
	end procedure sync_reset;
	
	variable col : line; -- line from input buffer
	variable result_bit : bit_vector(7 downto 0); -- state of lfsr

	
	begin
		file_open(input_buf, "test/lfsr.txt", read_mode);
		
		report "#### START TESTS ####";
		
		sync_reset;
		
		while not endfile(input_buf) loop
			readline(input_buf, col);
			read(col, result_bit);

			result <= unsigned(to_stdlogicvector(result_bit));
			wait for 1 ns;
			assert result = state_out report "Failed comparison" severity error;
			
			wait until rising_edge(clk);  
		end loop;
		
		report "#### TESTS COMPLETED ####";
		file_close(input_buf);
        sim_finished <= true;
        wait;				  
	end process tb1;
end test;
		