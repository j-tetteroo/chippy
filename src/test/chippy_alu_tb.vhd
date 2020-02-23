library ieee;
library work;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 	   
use IEEE.std_logic_textio.all;

use std.textio.all;
use work.chippy_alu;

entity chippy_alu_tb is
end chippy_alu_tb;

architecture test of chippy_alu_tb is

	constant DELTA : time := 100 ns;
	constant MAX_DELAY : natural := 100;


    signal sim_finished : boolean := false;

    signal clk : std_logic;
    signal reset : std_logic;
	
	signal opcode : std_logic_vector(3 downto 0);
	signal alu_A_in : unsigned(7 downto 0);
	signal alu_B_in : unsigned(7 downto 0);
	signal alu_out : unsigned(15 downto 0);	
	signal carry_out : std_logic;			   
	
	signal RNG_out_verify : unsigned(7 downto 0);
	
	file input_buf : text;

begin 
	
	-- Random number generator to compare to alu RNG
	randgen : entity chippy_randgen
		port map(clk => clk,
			reset => reset,
			rand_out => RNG_out_verify);					
			
	-- Declare component under test
	alu : entity chippy_alu
		port map (clk => clk,
			reset => reset,
			op => opcode,
			A_in => alu_A_in,
			B_in => alu_B_in,
			ALU_out => alu_out,
			carry_out => carry_out);
	
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
	variable v_opcode : bit_vector(3 downto 0);
	variable v_alu_A_in : bit_vector(7 downto 0);
	variable v_alu_B_in : bit_vector(7 downto 0);
	variable v_alu_out : bit_vector(15 downto 0);	
	variable v_carry_out : bit;
	variable v_SPACE : character;  -- for spaces between data in file
	variable result : unsigned(15 downto 0); 
	variable res_carry : std_logic;


begin
	file_open(input_buf, "test/alu.txt", read_mode);
	
	report "#### START TESTS ####";
	
	sync_reset;
	
	while not endfile(input_buf) loop
		readline(input_buf, col);	-- Read the decription line but don't do anything with it. 
		writeline(OUTPUT, col);
		readline(input_buf, col);
		--writeline(OUTPUT, col);
		
		read(col, v_opcode); 
		read(col, v_SPACE);
		read(col, v_alu_A_in);
		read(col, v_SPACE);
		read(col, v_alu_B_in);
		read(col, v_SPACE);
		read(col, v_alu_out);
		read(col, v_SPACE);
		read(col, v_carry_out);	
		
	   	wait until rising_edge(clk);  
		   
		opcode <= to_stdlogicvector(v_opcode);
		alu_A_in <= unsigned(to_stdlogicvector(v_alu_A_in));
		alu_B_in <= unsigned(to_stdlogicvector(v_alu_B_in));
		result := unsigned(to_stdlogicvector(v_alu_out));
		res_carry := to_stdulogic(v_carry_out);
		
		wait until rising_edge(clk);  
		wait for 1 ns;
		assert result = alu_out report "Failed result comparison " & integer'image(to_integer(result)) severity error;
		assert res_carry = carry_out report "Failed carry comparison" severity error;
		
 
	end loop;
	
	for i in 1 to 10 loop
		--wait until rising_edge(clk);
		opcode <= "1001";
		alu_A_in <= "11111111";				 
		result := "00000000" & RNG_out_verify;
		wait until rising_edge(clk); 
		wait for 1 ns;
		report integer'image(to_integer(result)) & " " & integer'image(to_integer(alu_out));
		assert result = alu_out report "Failed RNG 1" severity error;
	end loop;
	
	for i in 1 to 10 loop
		--wait until rising_edge(clk);
		opcode <= "1001";
		alu_A_in <= "11110000";				 
		result := "00000000" & (RNG_out_verify AND "11110000");
		wait until rising_edge(clk); 
		wait for 1 ns;
		report integer'image(to_integer(result)) & " " & integer'image(to_integer(alu_out));
		assert result = alu_out report "Failed RNG 2" severity error;
	end loop;
	
	report "#### TESTS COMPLETED ####";
	file_close(input_buf);
    sim_finished <= true;
    wait;				  
end process tb1;

end test;