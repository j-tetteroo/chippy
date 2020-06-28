library ieee;
library work;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;
use work.uart_test;

entity uart_test_tb is
end uart_test_tb;

architecture test of uart_test_tb is

	constant DELTA : time := 83 ns;	-- 12 Mhz 
	constant BAUD : time := 103750 ns;

    signal sim_finished : boolean := false;

    signal clk : std_logic;
    signal reset : std_logic;			
	
	signal tx : std_logic;
	signal rx : std_logic;

begin
	-- Declare component under test
	uart : entity uart_test
		port map(clk => clk,
				reset => reset,
				rx_in => tx,
				tx_out => rx);

	
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
		tx <= '1';	-- IDLE	
		sync_reset;	  
		
		wait until rising_edge(clk);
		tx <= '0';	-- start bit
		wait for BAUD;
		tx <= '1';	-- bit 0
		wait for BAUD;
		tx <= '0';	-- bit 1
		wait for BAUD;
		tx <= '1';	-- bit 2
		wait for BAUD;
		tx <= '0';	-- bit 3
		wait for BAUD;
		tx <= '1';	-- bit 4
		wait for BAUD;
		tx <= '0';	-- bit 5
		wait for BAUD;
		tx <= '1';	-- bit 6
		wait for BAUD;
		tx <= '0';	-- bit 7
		wait for BAUD;		
		tx <= '1';	-- stop bit	
		wait until rx = '0';
		wait for BAUD / 2; -- synchronize
		assert rx = '0' report "Failed to synchronize RX" severity error; -- Middle of start bit
		wait for BAUD;
		assert rx = '1' report "Failed bit 0" severity error;	-- bit 0
		wait for BAUD;
		assert rx = '0' report "Failed bit 1" severity error;	-- bit 1
		wait for BAUD;					  
		assert rx = '1' report "Failed bit 2" severity error;	-- bit 2
		wait for BAUD;
		assert rx = '0' report "Failed bit 3" severity error;	-- bit 3
		wait for BAUD;
		assert rx = '1' report "Failed bit 4" severity error;	-- bit 4
		wait for BAUD;		
		assert rx = '0' report "Failed bit 5" severity error;	-- bit 5
		wait for BAUD;
		assert rx = '1' report "Failed bit 6" severity error;	-- bit 6
		wait for BAUD;
		assert rx = '0' report "Failed bit 7" severity error;	-- bit 7
		wait for BAUD;
		assert rx = '1' report "Failed stop bit 0" severity error;	-- stop bit
		wait for BAUD;
		assert rx = '1' report "Failed stop bit 1" severity error;	-- Still idle
		
		report "#### TESTS COMPLETED ####";

        sim_finished <= true;
        wait;				  
	end process tb1;
end test;