library ieee;
library work;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;
use work.vga_test;

entity vga_test_tb is
end vga_test_tb;

architecture test of vga_test_tb is

	constant DELTA : time := 83 ns;	-- 12 Mhz

    signal sim_finished : boolean := false;

    signal clk : std_logic;
    signal reset : std_logic;			
	
	signal h_sync : std_logic;
	signal v_sync : std_logic;
	signal r : std_logic;
	signal g : std_logic;
	signal b : std_logic;
	signal lock : std_logic; 
	signal clk25 : std_logic;


begin
	-- Declare component under test
	vga : entity vga_test
		port map(clk12 => clk,
				reset => reset,
				h_sync => h_sync,
				v_sync => v_sync,
				r => r,
				g => g,
				b => b,
				lock_pll => lock,
				clk25_out => clk25);
	
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
		wait for 1 us;
		reset <= '0';
	end procedure sync_reset;

	
	begin
		
		report "#### START TESTS ####";
		
		sync_reset;
		
		wait until lock = '1';
		
		wait for 40 ns;
		assert h_sync = '1' report "Failed h_sync high initial" severity error;
		assert r = '1' report "Failed R high" severity error; -- Horizontal scanline 
		
		for i in 0 to 641 loop
			wait until rising_edge(clk25);
		end loop;
		assert r = '0' report "Failed R low" severity error; 	-- Horizontal front porch
		
		for i in 0 to 16 loop
			wait until rising_edge(clk25);
		end loop;	
		assert h_sync = '0' report "Failed h_sync low" severity error; -- Horizontal sync
		
		for i in 0 to 96 loop
			wait until rising_edge(clk25);
		end loop;
		assert h_sync = '1' report "Failed h_sync high" severity error; -- Horizontal back porch	
		
		for i in 0 to 48 loop
			wait until rising_edge(clk25);
		end loop;
		assert r = '1' report "Failed R high" severity error; -- Next scanline
		
		-- One scanline completed		   
		
		for i in 0 to (800*479) loop			-- skip all scanlines
			wait until rising_edge(clk25);	
		end loop;
		
		assert v_sync = '1' report "Failed v_sync high 1" severity error;	-- Vertical front porch
		
		for i in 0 to (800*10) loop
			wait until rising_edge(clk25);
		end loop;
		
		assert v_sync = '0' report "Failed v_sync low" severity error; -- Vertical sync
		
		for i in 0 to (800*2) loop
			wait until rising_edge(clk25);
		end loop;
		
		assert v_sync = '1' report "Failed v_sync high 2" severity error; -- Vertical back porch 	
		
		for i in 0 to (800*33) loop
			wait until rising_edge(clk25);
		end loop;	
		
		-- One frame completed	
		
		for i in 0 to (800*525) loop
			wait until rising_edge(clk25);
		end loop;
		
		report "#### TESTS COMPLETED ####";

        sim_finished <= true;
        wait;				  
	end process tb1;
end test;