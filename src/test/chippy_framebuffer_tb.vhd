library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chippy_global.all;			   

use work.chippy_framebuffer;

entity chippy_framebuffer_tb is
end chippy_framebuffer_tb;

architecture test of chippy_framebuffer_tb is

	constant DELTA : time := 100 ns;
	constant MAX_DELAY : natural := 100;


    signal sim_finished : boolean := false;

    signal clk : std_logic;
    signal reset : std_logic;			
	
	signal row : unsigned(4 downto 0);
	signal column : unsigned(5 downto 0);
	signal sprite : std_logic_vector(7 downto 0);
	signal we : std_logic;	
	signal in_data : std_logic_vector(63 downto 0);
	
	signal out_we : std_logic;
	signal out_waddr : std_logic_vector(4 downto 0);
	signal out_wdata : std_logic_vector(63 downto 0);
	signal out_VF_flag : std_logic;
	signal out_stall : std_logic;


begin		   

	
	-- Component under test	
	fbuf : entity chippy_framebuffer
		port map (clk => clk,
				reset => reset,
				row => row,
				column => column,
				sprite => sprite,
				we_in => we,
				we_out => out_we,
				rdata_in => in_data,
				addr_out => out_waddr,
				wdata_out => out_wdata,
				VF_flag => out_VF_flag,
				stall => out_stall);



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
	
--		row : in unsigned(4 downto 0);
--		column : in unsigned(4 downto 0); 	  
--		sprite : in std_logic_vector(7 downto 0); 
--		we_in : in std_logic;	   

   	in_data <= (others => '1');
	row <= "00100";
	column <= "001000";
	sprite <= "10101010";
	we <= '1';			 
	wait until rising_edge(clk);
	wait for 1 ns;
	assert out_stall = '1' report "Failed Stall 0" severity error;
	we <= '0';
	wait until rising_edge(clk);
	wait for 1 ns;
	assert out_stall = '1' report "Failed Stall 1" severity error;
	wait until rising_edge(clk);
	wait for 1 ns;
	assert out_stall = '1' report "Failed Stall 2" severity error;
	wait until rising_edge(clk); 
	wait for 1 ns;
	assert out_stall = '1' report "Failed Stall 3" severity error;
	we <= '1';	   
	assert out_we = '0' report "Failed WE 0" severity error;
	wait until rising_edge(clk); 
	wait for 1 ns;
	assert out_wdata = x"FF55FFFFFFFFFFFF" report "Failed Mem 0" severity error;
	assert out_stall = '0' report "Failed Stall 4" severity error; 
	assert out_VF_flag = '1' report "Failed VF 0" severity error;
	assert out_waddr = "00100" report "Failed addr 0" severity error;
	assert out_we = '1' report "Failed WE 0" severity error;
	
	in_data <= (others => '0');
	row <= "11011";
	column <= "111100";
	sprite <= "11111111"; 
	wait until rising_edge(clk);
	wait for 1 ns;
	assert out_stall = '1' report "Failed Stall 5" severity error;
	we <= '0';
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	wait until rising_edge(clk); 
	assert out_we = '0' report "Failed WE 1" severity error;
	wait until rising_edge(clk);
	we <= '1';
	wait for 1 ns;
	assert out_wdata = x"F00000000000000F" report "Failed Mem 1" severity error;
	assert out_stall = '0' report "Failed Stall 6" severity error;
	assert out_VF_flag = '0' report "Failed VF 1" severity error;
	assert out_waddr = "11011" report "Failed addr 1" severity error;
	assert out_we = '1' report "Failed WE 1" severity error;
	
	in_data <= "1111111100000000000000000000000000000000000000000000000000000000";
	row <= "01001";
	column <= "111100";
	sprite <= "11111111";
	wait until rising_edge(clk); 
	wait for 1 ns;
	assert out_stall = '1' report "Failed Stall 7" severity error;
	we <= '0';
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	assert out_we = '0' report "Failed WE 2" severity error;
	wait until rising_edge(clk);
	we <= '1';
	wait for 1 ns;
	assert out_wdata = x"0F0000000000000F" report "Failed Mem 1" severity error;
	assert out_stall = '0' report "Failed Stall 8" severity error;
	assert out_VF_flag = '1' report "Failed VF 2" severity error;
	assert out_waddr = "01001" report "Failed addr 2" severity error;
	assert out_we = '1' report "Failed WE 2" severity error;

	in_data <= "0000000010101010000000000000000000000000000000000000000000000000";
	row <= "00000";
	column <= "001000";
	sprite <= "01010101";
	wait until rising_edge(clk);
	wait for 1 ns;
	assert out_stall = '1' report "Failed Stall 9" severity error;
	we <= '0';
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	wait until rising_edge(clk); 
	wait until rising_edge(clk);
	assert out_we = '0' report "Failed WE 3" severity error;
	wait until rising_edge(clk);
	assert out_wdata = x"00FF000000000000" report "Failed Mem 2" severity error;
	assert out_stall = '0' report "Failed Stall 10" severity error; 
	assert out_VF_flag = '0' report "Failed VF 3" severity error; 
	assert out_waddr = "00000" report "Failed addr 3" severity error; 
	assert out_we = '1' report "Failed WE 3" severity error;

	report "#### TESTS COMPLETED ####";
	sim_finished <= true;
	wait;		
	
	
end process tb1;	

end test;