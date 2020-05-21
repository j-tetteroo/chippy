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
	signal column : unsigned(4 downto 0);
	signal sprite : std_logic_vector(7 downto 0);
	signal we : std_logic;
	
	signal out_we : std_logic;
	signal out_waddr : std_logic_vector(4 downto 0);
	signal out_wdata : std_logic_vector(63 downto 0);
	signal out_VF_flag : std_logic;
	signal out_stall : std_logic;


begin		   

	
	-- Component under test	
	cpu : entity chippy_framebuffer
		port map (clk => clk,
				reset => reset,
				row => row,
				column => column,
				sprite => sprite,
				we_in => we,
				we_out => out_we,
				waddr_out => out_waddr,
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

	alias cpu_r_state is << signal cpu.r : cpu_state_type>>; 
	alias cpu_rin_state is << signal cpu.rin : cpu_state_type>>;
	
begin
	report "#### START TESTS ####";
	
	sync_reset;
	
	report "#### TESTS COMPLETED ####";
    sim_finished <= true;
    wait;		
	
	
end process tb1;	

end test;