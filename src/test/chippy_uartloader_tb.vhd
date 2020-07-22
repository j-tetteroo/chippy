library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chippy_global.all;			   

use work.chippy_uartloader;

entity chippy_uartloader_tb is
end chippy_uartloader_tb;

architecture test of chippy_uartloader_tb is

	constant DELTA : time := 83 ns;	-- 12 Mhz 
	constant BAUD : time := 103750 ns;


    signal sim_finished : boolean := false;

    signal clk : std_logic;
    signal reset : std_logic;
		
	signal rx_in : std_logic;
	signal tx_out : std_logic;	
	signal enable : std_logic; 
		
	signal mem_addr : std_logic_vector(11 downto 0);
	signal mem_we : std_logic;
	signal mem_data_out : std_logic_vector(7 downto 0);
		
	signal transfer_complete : std_logic;

begin
	
	-- Component under test	
	uartloader : entity chippy_uartloader
		port map (clk => clk,
			reset => reset,	 
			rx_in => tx_out,
			tx_out => rx_in,
			enable => enable,
			mem_addr => mem_addr,
			mem_we => mem_we,
			mem_data_out => mem_data_out,
			transfer_complete => transfer_complete);


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

  	procedure uart_write_byte(
	  data_in : in std_logic_vector(7 downto 0);
	  signal tx_out : out std_logic) is
	begin
		tx_out <= '0';	-- Send start bit
		wait for BAUD;
		
		-- Send byte
		for i in 0 to 7 loop
			tx_out <= data_in(i);
			wait for BAUD;
		end loop;
		
		-- Send parity bit
		tx_out <= data_in(0) XOR data_in(1) XOR data_in(2) XOR data_in(3) XOR data_in(4) XOR data_in(5) XOR data_in(6) XOR data_in(7);
		wait for BAUD;
		
		-- Send stop bit
		tx_out <= '1';
		wait for BAUD;	  
	end procedure uart_write_byte;	  
	
	procedure uart_read_byte(
		compare_byte : in std_logic_vector(7 downto 0);
		signal rx_in : in std_logic) is	  
		variable parity : std_logic;
		variable data_out : std_logic_vector(7 downto 0);
	begin	
		wait until rx_in = '0';
		wait for BAUD / 2; -- synchronize with middle of signal	 
		
		-- Check if start bit valid
		assert rx_in = '0' report "Failed to synchronize RX" severity error;
		wait for BAUD;
		
		-- Receive byte
		for i in 0 to 7 loop
			data_out(i) := rx_in;  
			wait for BAUD;
		end loop;
		
		assert compare_byte = data_out report "Failed to read correct byte RX" severity error;
		
		-- Receive parity bit
		parity := rx_in;
		assert parity = (data_out(0) XOR data_out(1) XOR data_out(2) XOR data_out(3) XOR data_out(4) XOR data_out(5) XOR data_out(6) XOR data_out(7)) report "Failed parity RX" severity error;
		wait for BAUD;
		
		-- Receive stop bit	
		assert rx_in = '1' report "Failed stop bit RX" severity error;
		wait for BAUD;
	
	end procedure uart_read_byte;
		
		
	
begin
	report "#### START TESTS ####";
	
	sync_reset;
	
	-- TODO: Check memory output
	
	-- TODO: Test entire 0xDFF rom load
	--wait until rising_edge(clk); 
	
	for i in 0 to 3583 loop
		report "Byte " & integer'image(i) severity note;
		assert transfer_complete = '0' report "Failed transfer completion" severity error;
		uart_write_byte("10101010", tx_out);
		uart_read_byte(x"55", rx_in);
	end loop;
	
	assert transfer_complete = '1' report "Failed transfer completion" severity error;
	 
--  	uart_write_byte("10101010", tx_out);
--
--	-- Parity bit is correct, so we should receive 0x55 back   
--	
--	
--	
--	--
--	uart_write_byte("11110000", tx_out);
--	uart_read_byte(x"55", rx_in);
--	
--	uart_write_byte("11001100", tx_out);
--	uart_read_byte(x"55", rx_in);
--

	
	report "#### TESTS COMPLETED ####";
    sim_finished <= true;
    wait;		
	
	
end process tb1;	
	
end test;