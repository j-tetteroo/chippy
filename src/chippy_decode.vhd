library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity chippy_decode is
	port (clk : in std_logic,
	reset : in std_logic,
	instr : in std_logic_vector(15 downto 0),	 -- 2 byte instruction MSB first
	reg_read : out std_logic,
	reg_write : out std_logic,
	reg_addr : out std_logic_vector(4 downto 0),
	mem_read : out std_logic,
	mem_write : out std_logic);
end chippy_decode;

architecture behavioural of chippy_decode is

	signal r, rin : decode_reg_type;

begin
	
	combinatorial : process(reset, instr, r)
		variable v : decode_reg_type;
	begin
		v := r;
		if (instr = x"00E0") then
			-- CLS clear display
		elsif (instr = x"00EE") then
			-- RET return from subroutine
		elsif (instr(15 downto 12) = x"1") then
			-- JP addr Jump to location nnn
		elsif (instr(15 downto 12) = x"2") then
			-- CALL addr Call subroutine at nnn
		elsif (instr(15 downto 12) = x"3") then
			-- SE Vx, byte Skip next instr if reg Vx = kk
		elsif (instr(15 downto 12) = x"4") then
			-- SNE Vx, byte Skip next instr if reg Vx != kk
		elsif (instr(15 downto 12) = x"5") AND (instr(3 downto 0) = x"0") then
			-- SE Vx, Vy Skip next instr if Vx = Vy
		elsif (instr(15 downto 12) = x"6") then
			-- LD Vx, byte Set Vx = kk
		elsif (instr(15 downto 12) = x"7") then
			-- ADD Vx, byte Set Vx = Vx + kk
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"0") then
			-- LD Vx, Vy Set Vx = Vy
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"1") then
			-- OR Vx, Vy Set Vx = Vx OR Vy
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"2") then
			-- AND Vx, Vy Set Vx = Vx AND Vy
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"3") then
			-- XOR Vx, Vy Set Vx = Vx XOR Vy
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"4") then
			-- ADD Vx, Vy Set Vx = Vx + Vy, set VF = carry
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"5") then
			-- SUB Vx, Vy Set Vx = Vx - Vy, set VF = NOT borrow
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"6") then
			-- SHR Vx {, Vy} Set Vx = Vx SHR 1 (shift LSB into VF)
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"7") then
			-- SUBN Vx, Vy Set Vx = Vy - Vx, set VF = NOT borrow
		elsif (instr(15 downto 12) = x"8") AND (instr(3 downto 0) = x"E") then
			-- SHL Vx {, Vy} Set Vx = Vx SHL 1 (shift MSB into VF)
		elsif (instr(15 downto 12) = x"9") AND (instr(3 downto 0) = x"0") then
			-- SNE Vx, Vy Skip next instr if Vx != Vy
		elsif (instr(15 downto 12) = x"A") then
			-- LD I, addr Set reg I = nnn
		elsif (instr(15 downto 12) = x"B") then
			-- JP V0, addr Jump to location nnn + V0
		elsif (instr(15 downto 12) = x"C") then
			-- RND Vx, byte Set Vx = random byte AND kk
		elsif (instr(15 downto 12) = x"D") then
			-- DRW Vx, Vy, nibble Display n-byte sprite at mem I at (Vx, Vy), VF = collision
		elsif (instr(15 downto 12) = x"E") and (instr(7 downto 0) = x"9E") then
			-- SKP Vx, Skip next instruction if key = Vx is pressed
		elsif (instr(15 downto 12) = x"E") and (instr(7 downto 0) = x"A1") then 
			-- SKNP Vx, Skip next instruction if key = Vx is not pressed		
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"07") then 
			-- LD Vx, DT, Vx = delay timer value
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"0A") then
			-- LD Vx, K, Wait for key press, store value in Vx
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"15") then
			-- LD DT, Vx, Set delay timer = Vx
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"18") then
			-- LD ST, Vx, Set sound timer = Vx
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"1E") then
			-- ADD I, Vx, Set I = I + Vx
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"29") then			
			-- LD F, Vx, Set I = location of sprite for digit Vx
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"33") then
			-- LD B, Vx, Set BCD representation of Vx in mem I, I+1 and I+2
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"55") then			
			-- LD [I], Vx, Store registers V0 through Vx in memory starting at I
		elsif (instr(15 downto 12) = x"F") and (instr(7 downto 0) = x"65") then
			-- LD Vx, [I], Read registers V0 through Vx from memory starting at I
		end if;
	end process;
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process;
	
end architecture;
			
			
			
			
				
			
			
			
		
			
			
			
			
			
			
				
				
				
			