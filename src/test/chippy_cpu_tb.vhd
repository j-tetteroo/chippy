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

	alias cpu_r_state is << signal cpu.r : cpu_state_type>>; 
	alias cpu_rin_state is << signal cpu.rin : cpu_state_type>>;
	
begin
	report "#### START TESTS ####";
	
	sync_reset;
	
	-- TODO: full stack test	
	-- TODO: arithmetic test		
	-- TODO: test those reg-mem instructions with real memory	
	
	-- Fetch 0	 
	
	wait until rising_edge(clk); -- Fetch 1
	-- I = 5, v3 = 8, v2 = 2, v1 = 15, v0 = 134 (0x86)
	cpu_rin_state.I <= force to_unsigned(5, cpu_rin_state.I'length);   
	cpu_rin_state.V(3) <= force to_unsigned(8, cpu_rin_state.V(3)'length);
	cpu_rin_state.V(2) <= force to_unsigned(2, cpu_rin_state.V(2)'length);
	cpu_rin_state.V(1) <= force to_unsigned(21, cpu_rin_state.V(1)'length);
	cpu_rin_state.V(0) <= force to_unsigned(134, cpu_rin_state.V(0)'length);
	
	-- Store registers V0 through Vx in memory starting at location I (5). 0xF355 
	
	wait until rising_edge(clk); -- Fetch 2
	cpu_rin_state.I <= release;
	cpu_rin_state.V(3) <= release;
	cpu_rin_state.V(2) <= release;
	cpu_rin_state.V(1) <= release;
	cpu_rin_state.V(0) <= release;
	mem_data_in <= x"F3";

	wait until rising_edge(clk); -- Fetch 3
	mem_data_in <= x"55";
	wait until rising_edge(clk); -- Execute 0
	wait until rising_edge(clk); -- Execute 4
	wait for 1 ns;
	assert mem_addr = x"005" report "Failed Mem Addr 0" severity error;
	assert mem_data_out = x"86" report "Failed Mem Out 0" severity error;
	wait until rising_edge(clk); -- Execute 3
	wait for 1 ns;
	assert mem_addr = x"006" report "Failed Mem Addr 1" severity error;
	assert mem_data_out = x"15" report "Failed Mem Out 1" severity error;
	wait until rising_edge(clk); -- Execute 2
	wait for 1 ns;
	assert mem_addr = x"007" report "Failed Mem Addr 2" severity error;
	assert mem_data_out = x"02" report "Failed Mem Out 2" severity error;
	wait until rising_edge(clk); -- Execute 1
	wait for 1 ns;
	assert mem_addr = x"008" report "Failed Mem Addr 3" severity error;
	assert mem_data_out = x"08" report "Failed Mem Out 3" severity error;			
	
	-- Test JP addr Jump to location nnn  
	wait until rising_edge(clk);
	-- Fetch 0
	wait until rising_edge(clk);
	-- Fetch 1
	wait until rising_edge(clk);
	-- Fetch 2
	mem_data_in <= x"19";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"87";
	wait until rising_edge(clk);
	-- Execute 0 
	wait until rising_edge(clk);
	-- Fetch 0					
	wait for 1 ns;
	assert cpu_r_state.PC = x"987" report "Failed JP 2" severity error;	
	
	-- Already setting up data for next test
	wait until rising_edge(clk);
	-- Fetch 1					
	wait for 1 ns;
	assert mem_addr = x"987" report "Failed JP 1" severity error;		 	
	
   	-- Test CALL addr Call subroutine at nnn 
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"24";
	wait until rising_edge(clk); 	
	-- Fetch 3
	mem_data_in <= x"56";
	wait until rising_edge(clk); 	
	-- Execute 0
	wait until rising_edge(clk); 	
	wait for 1 ns;				 
	-- Fetch 0
	assert cpu_r_state.PC = x"456" report "Failed CALL 1" severity error;
	assert cpu_r_state.SP = 1 report "Failed CALL 2" severity error;   
	assert cpu_r_state.stack(0) = x"0987" report "Failed CALL 3" severity error;
	
	-- Test RET return from subroutine
	-- Stack(0) = x"0987"
	-- SP = 1
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"00";
	wait until rising_edge(clk); 	
	-- Fetch 3
	mem_data_in <= x"EE";
	wait until rising_edge(clk); 	
	-- Execute	
	wait until rising_edge(clk);
	wait for 1 ns;	
	-- Fetch 0
	assert cpu_r_state.PC = x"987" report "Failed RET 1" severity error;  
	assert cpu_r_state.SP = 0 report "Failed RET 2" severity error;
	
	-- Test SE Vx, byte Skip next instr if reg Vx = kk (inc PC 4 bytes)
	-- V1 = 0x15, PC = 987
	wait until rising_edge(clk);	
	-- Fetch 1	
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"31";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"15";		
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.PC = x"98B" report "Failed SE 1" severity error;
	
	-- V1 = 0x15, PC = 98B, inc PC 2 bytes
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"31";	
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"07";			-- Compare with wrong value
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0  
	assert cpu_r_state.PC = x"98D" report "Failed SE 2" severity error;
	
	-- Test SNE Vx, byte Skip next instr if reg Vx != kk (inc PC 4 bytes)
	-- V1 = 0x15, PC = 98D
	wait until rising_edge(clk);	
	-- Fetch 1	
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"41";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"15";
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;				 
	-- Fetch 0
	assert cpu_r_state.PC = x"98F" report "Failed SNE 2" severity error; 
	
	-- V1 = 15, PC = 98B  (inc 2 bytes)
	wait until rising_edge(clk);	
	-- Fetch 1	
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"41";
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"07";			-- Compare with wrong value
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.PC = x"993" report "Failed SNE 4" severity error;
	
	-- Test SE Vx, Vy Skip next instr if Vx = Vy
	-- Load v4 = 0x15 
	cpu_rin_state.V(4) <= force to_unsigned(21, cpu_rin_state.V(4)'length);
	
	-- V1 = 0x15, V4 = 0x15, PC = 0x993
	wait until rising_edge(clk);
	-- Fetch 1
	cpu_rin_state.V(4) <= release;	
	wait until rising_edge(clk);
	-- Fetch 2
	mem_data_in <= x"51";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"40";
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.PC = x"997" report "Failed SE Vx=Vy 1" severity error;
	
	-- V1 = 0x15, V3 = 0x08, PC = 0x997
	wait until rising_edge(clk);
	-- Fetch 1
	wait until rising_edge(clk);
	-- Fetch 2
	mem_data_in <= x"51";	
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"30";			-- Compare with wrong value, so no skip
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.PC = x"999" report "Failed SE Vx=Vy 2" severity error; 

	-- Test LD Vx, byte Set Vx = kk
	wait until rising_edge(clk);
	-- Fetch 1
	wait until rising_edge(clk);
	-- Fetch 2
	mem_data_in <= x"6A";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"BB";
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);	
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.V(10) = x"BB" report "Failed LD Vx=kk" severity error; 
	
	-- Test LD Vx, Vy Set Vx = Vy
	wait until rising_edge(clk);
	-- Fetch 1
	wait until rising_edge(clk);
	-- Fetch 2
	mem_data_in <= x"8C";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"A0";
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;				
	-- Fetch 0
	assert cpu_r_state.V(12) = x"BB" report "Failed LD Vx = Vy" severity error;
	
	-- Test SNE Vx, Vy Skip next instr if Vx != Vy
	-- V1 = 0x15, V4 = 0x15, PC = 0x99D	
	wait until rising_edge(clk);	
	-- Fetch 1		
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"91";	
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"40";
	wait until rising_edge(clk);
	-- Execute 
	wait until rising_edge(clk);
	-- Fetch 0
	wait for 1 ns;
	assert cpu_r_state.PC = x"99F" report "Failed SNE Vx!=Vy 1" severity error;	-- Equal so dont skip
	
	-- V1 = 0x15, V3 = 0x08, PC = 0x99F
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"91";
	wait until rising_edge(clk);	
	mem_data_in <= x"30";
	wait until rising_edge(clk);	
	-- Execute 
	wait until rising_edge(clk);
	-- Fetch 0
	wait for 1 ns;
	assert cpu_r_state.PC = x"9A3" report "Failed SNE Vx!=Vy 2" severity error; -- Unequal so skip
	
	-- Test LD I, addr Set reg I = nnn
	wait until rising_edge(clk);	
	-- Fetch 1			
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"A1";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"23";
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);
	-- Fetch 0
	wait for 1 ns; 	  
	assert cpu_r_state.I = x"123" report "Failed LD I = nnn" severity error;
	
	-- Test JP V0, addr Jump to location nnn + V0
	-- V0 = 0x86
	wait until rising_edge(clk);	
	-- Fetch 1				
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"B2";
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"9B";
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk); 
	wait for 1 ns;				 
	-- Fetch 0
	assert cpu_r_state.PC = x"321" report "Failed JP V0+nnn 1" severity error;
	
	-- Test SKP Vx, Skip next instruction if key = Vx is pressed  
	-- V3 = 8, PC = 0x321
	wait until rising_edge(clk);	
	-- Fetch 1
	keypad_in <= x"8";
	keypad_pressed <= '1';	
	wait until rising_edge(clk);	
	-- Fetch 2			
	mem_data_in <= x"E3";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"9E";
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;				
	-- Fetch 0
	assert cpu_r_state.PC = x"325" report "Failed SKP 1" severity error;

	wait until rising_edge(clk);	
	-- Fetch 1
	keypad_in <= x"8";
	keypad_pressed <= '0';			-- No key pressed
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"E3";	
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"9E";			
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;				
	-- Fetch 0
	assert cpu_r_state.PC = x"327" report "Failed SKP 2" severity error;
		
	wait until rising_edge(clk);	
	-- Fetch 1
	keypad_in <= x"9";	 			-- Different key pressed, don't skip
	keypad_pressed <= '1';		
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"E3";
	wait until rising_edge(clk);	
	mem_data_in <= x"9E";			
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;				
	-- Fetch 0
	assert cpu_r_state.PC = x"329" report "Failed SKP 3" severity error;
	
	-- Test SKNP Vx, Skip next instruction if key = Vx is NOT pressed
	wait until rising_edge(clk);	
	-- Fetch 1
	keypad_in <= x"2";	 			-- Key = V2 so don't skip
	keypad_pressed <= '1';	
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"E2";	
	wait until rising_edge(clk);		
	-- Fetch 3
	mem_data_in <= x"A1";			
	wait until rising_edge(clk);
	-- Execute
	wait until rising_edge(clk);	
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.PC = x"32B" report "Failed SKNP 1" severity error;
	
	wait until rising_edge(clk);	
	-- Fetch 1
	keypad_in <= x"3";	 			-- Different key pressed, so skip
	keypad_pressed <= '1';	
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"E2";	
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"A1";			
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;				
	-- Fetch 0
	assert cpu_r_state.PC = x"32F" report "Failed SKNP 2" severity error;
	
	wait until rising_edge(clk);	
	-- Fetch 1
	keypad_in <= x"2";	 			-- Key = V2
	keypad_pressed <= '0';			-- No key press, so skip
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"E2";	
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"A1";			
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;	
	-- Fetch 0
	assert cpu_r_state.PC = x"333" report "Failed SKNP 3" severity error;
	
	-- Test LD DT, Vx, Set delay timer = Vx (0x15)
	assert cpu_r_state.delay /= x"15" report "Failed LD DT,Vx 1" severity error;
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"F4";
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"15";
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.delay = x"15" report "Failed LD DT,Vx 2" severity error;
	
	-- Test LD Vx, DT, Vx = delay timer value  
	assert cpu_r_state.V(5) /= x"15" report "Failed LD Vx,DT 1" severity error;
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"F5";
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"07";
	wait until rising_edge(clk);	
	-- Execute
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0
	assert cpu_r_state.V(5) = x"15" report "Failed LD Vx,DT 2" severity error; 
	
	-- Test LD ST, Vx, Set sound timer = Vx
	assert cpu_r_state.sound /= x"86" report "Failed LD ST,Vx" severity error;
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"F0";
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"18";
	wait until rising_edge(clk);	
	-- Executed
	wait until rising_edge(clk);
	wait for 1 ns;				
	-- Fetch 0
	assert cpu_r_state.sound = x"86" report "Failed LD ST,Vx" severity error;  
	
	-- Test LD B, Vx, Set BCD representation of Vx in mem I, I+1 and I+2
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"F0";
	wait until rising_edge(clk);	
	-- Fetch 3
	mem_data_in <= x"33";
	wait until rising_edge(clk);	
	-- Execute 0
	wait until rising_edge(clk);	
	-- Execute 4
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Execute 3
	assert mem_we = '1' report "Failed LD B, Vx 1 WE" severity error;
	assert mem_addr = std_logic_vector(cpu_r_state.I(11 downto 0)) report "Failed LD B, Vx 1 ADDR" severity error;
	assert mem_data_out = x"01" report "Failed LD B, Vx 1" severity error;	
	
	wait until rising_edge(clk);	
	wait for 1 ns;
	-- Execute 2
	assert mem_we = '1' report "Failed LD B, Vx 2 WE" severity error;
	assert mem_addr = std_logic_vector(cpu_r_state.I(11 downto 0) + 1) report "Failed LD B, Vx 2 ADDR" severity error;
	assert mem_data_out = x"03" report "Fail ed LD B, Vx 2" severity error;	 
	
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Execute 1
	assert mem_we = '1' report "Failed LD B, Vx 3 WE" severity error;
	assert mem_addr = std_logic_vector(cpu_r_state.I(11 downto 0) + 2) report "Failed LD B, Vx 3 ADDR" severity error;
	assert mem_data_out = x"04" report "Failed LD B, Vx 3" severity error;
	
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Fetch 0
	assert mem_we = '0' report "Failed LD B, Vx 4" severity error;
	
	-- Test LD Vx, [I], Read registers V0 through Vx from memory starting at I	
	-- v0 = 0x86, v1 = 0x15, v2 = 0x02, v3 = 0x08, v4 = 0x15, v5 = 0x15, I = 0x123
	-- Store v0 = 12, v1 = 23, v2 = 34, v3 = 45, v4 = 56	
	wait until rising_edge(clk);	
	-- Fetch 1
	wait until rising_edge(clk);	
	-- Fetch 2
	mem_data_in <= x"F4";
	wait until rising_edge(clk);
	-- Fetch 3
	mem_data_in <= x"65";		
	wait until rising_edge(clk);
	wait for 1 ns;
	-- Execute 0
	-- Set up memory and cycle counter	
	assert cpu_r_state.cycle_counter = 0 report "Failed LD Vx, [I] 1" severity error; 
	
	wait until rising_edge(clk);	
	wait for 1 ns;
	-- Execute 1		 
	assert mem_addr = x"123" report "Failed LD Vx, [I] 2" severity error; 
	assert mem_we = '0' report "Failed LD Vx, [I] 3" severity error; 
	
	wait until rising_edge(clk); 	
	-- Execute 2						 
	mem_data_in <= x"12";
	wait for 1 ns;
	assert mem_addr = x"124" report "Failed LD Vx, [I] 4" severity error;
	
	wait until rising_edge(clk); 	
	-- Execute 3						
	mem_data_in <= x"23";
	wait for 1 ns;	 
	assert mem_addr = x"125" report "Failed LD Vx, [I] 5" severity error;	 
	assert cpu_r_state.V(0) = x"12" report "Failed LD Vx, [I] 6" severity error;
	
	wait until rising_edge(clk);  	-- Execute 2
	mem_data_in <= x"34";
	wait for 1 ns;
	assert mem_addr = x"126" report "Failed LD Vx, [I] 7" severity error;
	assert cpu_r_state.V(1) = x"23" report "Failed LD Vx, [I] 8" severity error;
	
	wait until rising_edge(clk);	-- Execute 1						 
	mem_data_in <= x"45";
	wait for 1 ns; 
	assert mem_addr = x"127" report "Failed LD Vx, [I] 9" severity error;
	assert cpu_r_state.V(2) = x"34" report "Failed LD Vx, [I] 10" severity error;
	
	wait until rising_edge(clk);
	mem_data_in <= x"56";
	wait for 1 ns; 
	assert mem_addr = x"128" report "Failed LD Vx, [I] 11" severity error;
	assert cpu_r_state.V(3) = x"45" report "Failed LD Vx, [I] 12" severity error;  

	wait until rising_edge(clk); 
	wait for 1 ns;
	--assert mem_addr = x"128" report "Failed LD Vx, [I] 8" severity error;
	assert cpu_r_state.V(4) = x"56" report "Failed LD Vx, [I] 13" severity error;
	
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	--assert cpu_r_state.V(4) = x"45" report "Failed LD Vx, [I] 10" severity error;
	--assert cpu_r_state.V(5) = x"15" report "Failed LD Vx, [I] 14" severity error;	 

	report "#### TESTS COMPLETED ####";
    sim_finished <= true;
    wait;		
	
	
end process tb1;	
	
end test;