library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chippy_global.all;

entity chippy_cpu is
	port (clk : in std_logic;
	reset : in std_logic;

	alu_op : out std_logic_vector(3 downto 0);
	alu_A_in : out unsigned(7 downto 0);
	alu_B_in : out unsigned(7 downto 0);
	alu_out : in unsigned(15 downto 0);
	alu_carry : in std_logic;
	
	mem_addr : out std_logic_vector(12 downto 0);
	mem_data_in : in std_logic_vector(7 downto 0);
	mem_data_out : out std_logic_vector(7 downto 0));
end chippy_cpu;

architecture behavioural of chippy_cpu is

	signal r, rin : cpu_state_type;


begin
	
	combinatorial : process(reset, r)
		variable v : cpu_state_type; 
		variable tmp : unsigned(8 downto 0);
	begin
		v := r;	
		case r.state is
			when FETCH =>
				-- Fetch next instruction from memory (16-bit word)
				case to_integer(r.cycle_counter) is
					when 0 =>
						v.cycle_counter := to_unsigned(3, v.cycle_counter'length);
					when 1 =>
						v.cur_ins(7 downto 0) := mem_data_in;
						v.state := EXECUTE;
						v.cycle_counter := v.cycle_counter - 1;
					when 2 =>
						v.cur_ins(15 downto 8) := mem_data_in;
						mem_addr <= std_logic_vector(r.PC(12 downto 0) + 1);
						v.cycle_counter := r.cycle_counter - 1;
					when 3 =>
						mem_addr <= std_logic_vector(r.PC(12 downto 0));
						v.cycle_counter := r.cycle_counter - 1;
					when others =>
				end case;
			when EXECUTE =>
				-- Execute current instruction
				if (r.cur_ins = x"00E0") then
					-- CLS clear display
					-- Set counter = 64*32
					-- Clear bits of framebuffer
				elsif (r.cur_ins = x"00EE") then
					-- RET return from subroutine 
					v.PC := r.stack(to_integer(r.SP));
					v.SP := r.SP - 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"1") then
					-- JP addr Jump to location nnn	 
					v.PC :=  resize(unsigned(r.cur_ins(11 downto 0)), v.PC'length);
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"2") then
					-- CALL addr Call subroutine at nnn	  
					v.SP := r.SP + 1;
					v.stack(to_integer(v.SP)) := r.PC;
					v.PC :=  resize(unsigned(r.cur_ins(11 downto 0)), v.PC'length);
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"3") then
					-- SE Vx, byte Skip next instr if reg Vx = kk
					if (std_logic_vector(r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))) = r.cur_ins(7 downto 0)) then
						v.PC := r.PC + 2;
					else
						v.PC := r.PC + 1;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"4") then
					-- SNE Vx, byte Skip next instr if reg Vx != kk
					if (std_logic_vector(r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))) /= r.cur_ins(7 downto 0)) then
						v.PC := r.PC + 2;
					else
						v.PC := r.PC + 1;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"5") AND (r.cur_ins(3 downto 0) = x"0") then
					-- SE Vx, Vy Skip next instr if Vx = Vy
					if ( r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) = r.V(to_integer(unsigned(r.cur_ins(7 downto 4)))) ) then
						v.PC := r.PC + 2;
					else
						v.PC := r.PC + 1;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"6") then
					-- LD Vx, byte Set Vx = kk
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := unsigned(r.cur_ins(7 downto 0));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"7") then
					-- ADD Vx, byte Set Vx = Vx + kk
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) + unsigned(r.cur_ins(7 downto 0));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"0") then
					-- LD Vx, Vy Set Vx = Vy
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.V(to_integer(unsigned(r.cur_ins(7 downto 4))));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"1") then
					-- OR Vx, Vy Set Vx = Vx OR Vy
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) OR r.V(to_integer(unsigned(r.cur_ins(7 downto 4))));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"2") then
					-- AND Vx, Vy Set Vx = Vx AND Vy
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) AND r.V(to_integer(unsigned(r.cur_ins(7 downto 4))));
					v.PC := r.PC + 1;
					v.state := FETCH; 
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"3") then
					-- XOR Vx, Vy Set Vx = Vx XOR Vy
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) XOR r.V(to_integer(unsigned(r.cur_ins(7 downto 4))));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"4") then
					-- ADD Vx, Vy Set Vx = Vx + Vy, set VF = carry
					tmp := ('0' & r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))) + ('0' & r.V(to_integer(unsigned(r.cur_ins(7 downto 4)))));
					v.V(15) := unsigned("0000000" & tmp(8)); -- Set carry in VF
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := tmp(7 downto 0);
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"5") then
					-- SUB Vx, Vy Set Vx = Vx - Vy, set VF = NOT borrow
					if r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) > r.V(to_integer(unsigned(r.cur_ins(7 downto 4)))) then
						v.V(15) := to_unsigned(1, v.V(15)'length);
					else
						v.V(15) := to_unsigned(0, v.V(15)'length);
					end if;
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) - r.V(to_integer(unsigned(r.cur_ins(7 downto 4))));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"6") then
					-- SHR Vx {, Vy} Set Vx = Vx SHR 1 (shift LSB into VF)
					v.V(15) := unsigned("0000000" & r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))(0)); -- Set carry in VF
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := unsigned("0" & r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))(7 downto 1));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"7") then
					-- SUBN Vx, Vy Set Vx = Vy - Vx, set VF = NOT borrow
					if r.V(to_integer(unsigned(r.cur_ins(7 downto 4)))) > r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) then
						v.V(15) := to_unsigned(1, v.V(15)'length);
					else
						v.V(15) := to_unsigned(0, v.V(15)'length);
					end if;
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.V(to_integer(unsigned(r.cur_ins(7 downto 4)))) - r.V(to_integer(unsigned(r.cur_ins(11 downto 8))));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"E") then
					-- SHL Vx {, Vy} Set Vx = Vx SHL 1 (shift MSB into VF)
					v.V(15) := unsigned("0000000" & r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))(7)); -- Set carry in VF
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := unsigned(r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))(6 downto 0) & "0");
					v.PC := r.PC + 1;
					v.state := FETCH;					
				elsif (r.cur_ins(15 downto 12) = x"9") AND (r.cur_ins(3 downto 0) = x"0") then
					-- SNE Vx, Vy Skip next instr if Vx != Vy
					if ( r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) /= r.V(to_integer(unsigned(r.cur_ins(7 downto 4)))) ) then
						v.PC := r.PC + 2;
					else
						v.PC := r.PC + 1;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"A") then
					-- LD I, addr Set reg I = nnn
					v.I := unsigned("0000" & r.cur_ins(11 downto 0));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"B") then
					-- JP V0, addr Jump to location nnn + V0
					v.PC := r.V(0) + resize(unsigned(r.cur_ins(11 downto 0)), v.PC'length);
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"C") then
					-- RND Vx, byte Set Vx = random byte AND kk
				elsif (r.cur_ins(15 downto 12) = x"D") then
					-- DRW Vx, Vy, nibble Display n-byte sprite at mem I at (Vx, Vy), VF = collision
				elsif (r.cur_ins(15 downto 12) = x"E") and (r.cur_ins(7 downto 0) = x"9E") then
					-- SKP Vx, Skip next instruction if key = Vx is pressed
				elsif (r.cur_ins(15 downto 12) = x"E") and (r.cur_ins(7 downto 0) = x"A1") then 
					-- SKNP Vx, Skip next instruction if key = Vx is not pressed		
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"07") then 
					-- LD Vx, DT, Vx = delay timer value
					v.V(to_integer(unsigned(r.cur_ins(11 downto 8)))) := r.delay;
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"0A") then
					-- LD Vx, K, Wait for key press, store value in Vx
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"15") then
					-- LD DT, Vx, Set delay timer = Vx
					v.delay := r.V(to_integer(unsigned(r.cur_ins(11 downto 8))));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"18") then
					-- LD ST, Vx, Set sound timer = Vx
					v.sound := r.V(to_integer(unsigned(r.cur_ins(11 downto 8))));
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"1E") then
					-- ADD I, Vx, Set I = I + Vx
					v.I := r.I + resize(r.V(to_integer(unsigned(r.cur_ins(11 downto 8)))), v.I'length);
					v.PC := r.PC + 1;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"29") then			
					-- LD F, Vx, Set I = location of sprite for digit Vx
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"33") then
					-- LD B, Vx, Set BCD representation of Vx in mem I, I+1 and I+2
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"55") then			
					-- LD [I], Vx, Store registers V0 through Vx in memory starting at I
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"65") then
					-- LD Vx, [I], Read registers V0 through Vx from memory starting at I
				end if;
				when others =>
		end case;
	end process;
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process;
	
end architecture;
			
			
			
			
				
			
			
			
		
			
			
			
			
			
			
				
				
				
			