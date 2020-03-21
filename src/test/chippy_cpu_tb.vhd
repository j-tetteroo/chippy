library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chippy_global.all;			   

use work.chippy_cpu;

entity chippy_cpu_tb is
end chippy_cpu_tb;

architecture test of chippy_cpu_tb is

	constant DELTA : time := 100 ns;
	constant MAX_DELAY : natural := 100;


    signal sim_finished : boolean := false;

    signal clk : std_logic;
    signal reset : std_logic;
	
	signal keypad_in : std_logic_vector(3 downto 0);
	signal keypad_pressed : std_logic;
	
	signal mem_addr : std_logic_vector(11 downto 0);
	signal mem_we : std_logic;
	signal mem_data_in : std_logic_vector(7 downto 0);
	signal mem_data_out : std_logic_vector(7 downto 0);

begin
	
	-- Component under test	
	cpu : entity chippy_cpu
		port map (clk => clk,
			reset => reset,	 
			keypad_in => keypad_in,
			keypad_pressed => keypad_pressed,
			mem_addr => mem_addr,
			mem_we => mem_we,
			mem_data_in => mem_data_in,
			mem_data_out => mem_data_out);


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
	
begin
	report "#### START TESTS ####";
	
	sync_reset;
	
	-- Load I = 5
	wait until rising_edge(clk);
	mem_data_in <= x"A0";
	wait until rising_edge(clk);
	mem_data_in <= x"05";
	wait until rising_edge(clk);
	wait until rising_edge(clk); -- execute
	
	-- Load v3 = 8 	0x6308
	wait until rising_edge(clk);
	mem_data_in <= x"63";
	wait until rising_edge(clk);
	mem_data_in <= x"08";
	wait until rising_edge(clk);
	wait until rising_edge(clk); -- execute
	
	-- Load v2 = 2 	0x6202
	wait until rising_edge(clk);
	mem_data_in <= x"62";
	wait until rising_edge(clk);
	mem_data_in <= x"02";
	wait until rising_edge(clk);
	wait until rising_edge(clk); -- execute
	
	-- Load v1 = 15 0x6115
	wait until rising_edge(clk);
	mem_data_in <= x"61";
	wait until rising_edge(clk);
	mem_data_in <= x"15";
	wait until rising_edge(clk);
	wait until rising_edge(clk); -- execute
	
	-- Load v0 = 134 0x6086
	wait until rising_edge(clk);
	mem_data_in <= x"60";
	wait until rising_edge(clk);
	mem_data_in <= x"86";
	wait until rising_edge(clk);
	wait until rising_edge(clk); -- execute
	
	-- Store registers V0 through Vx in memory starting at location I. 0xF355 
	wait until rising_edge(clk);
	mem_data_in <= x"F3";
	wait until rising_edge(clk);
	mem_data_in <= x"55";
	wait until rising_edge(clk); -- execute	
	wait for 1 ns;
	assert mem_addr = x"005" report "Failed Mem Addr 0" severity error;
	assert mem_data_out = x"08" report "Failed Mem Out 0" severity error;
	wait until rising_edge(clk);
	wait for 1 ns;
	assert mem_addr = x"006" report "Failed Mem Addr 1" severity error;
	assert mem_data_out = x"02" report "Failed Mem Out 1" severity error;
	wait until rising_edge(clk);
	wait for 1 ns;
	assert mem_addr = x"007" report "Failed Mem Addr 2" severity error;
	assert mem_data_out = x"15" report "Failed Mem Out 2" severity error;
	wait until rising_edge(clk);
	wait for 1 ns;
	assert mem_addr = x"008" report "Failed Mem Addr 3" severity error;
	assert mem_data_out = x"86" report "Failed Mem Out 3" severity error;
	wait until rising_edge(clk);
	
	-- Test JP addr Jump to location nnn  
	wait until rising_edge(clk);
	mem_data_in <= x"19";
	wait until rising_edge(clk);
	mem_data_in <= x"87";
	wait until rising_edge(clk);
	wait until rising_edge(clk); 
	wait for 1 ns;
	assert mem_addr = x"987" report "Failed JP" severity error;
	
	-- Test CALL addr Call subroutine at nnn
	wait until rising_edge(clk);	-- Fetch 0
	mem_data_in <= x"24";
	wait until rising_edge(clk);	-- Fetch 2
	mem_data_in <= x"56";
	wait until rising_edge(clk); 	-- Fetch 1
	wait until rising_edge(clk); 	-- Execute
	wait for 1 ns;
	assert mem_addr = x"456" report "Failed CALL" severity error;  
	
	-- Test RET return from subroutine
	wait until rising_edge(clk);	-- Fetch 0
	mem_data_in <= x"00";
	wait until rising_edge(clk);	-- Fetch 2
	mem_data_in <= x"EE";
	wait until rising_edge(clk); 	-- Fetch 1
	wait until rising_edge(clk); 	-- Execute
	wait for 1 ns;
	assert mem_addr = x"987" report "Failed RET" severity error;   
	
	-- Test SE Vx, byte Skip next instr if reg Vx = kk 
	-- V1 = 15, PC = 987
	wait until rising_edge(clk);	-- Fetch 0
	mem_data_in <= x"31";	
	wait until rising_edge(clk);	-- Fetch 2
	mem_data_in <= x"15";
	wait until rising_edge(clk);	-- Fetch 1
	wait until rising_edge(clk);	-- Execute
	wait for 1 ns;
	assert mem_addr = x"989" report "Failed SE 1" severity error;
	
	-- V1 = 15, PC = 989
	wait until rising_edge(clk);	-- Fetch 0
	mem_data_in <= x"31";	
	wait until rising_edge(clk);	-- Fetch 2
	mem_data_in <= x"07";			-- Compare with wrong value
	wait until rising_edge(clk);	-- Fetch 1
	wait until rising_edge(clk);	-- Execute
	wait for 1 ns;
	assert mem_addr = x"98A" report "Failed SE 2" severity error; 
	
	
	
	report "#### TESTS COMPLETED ####";
    sim_finished <= true;
    wait;		
	
	
end process tb1;	
	
end test;