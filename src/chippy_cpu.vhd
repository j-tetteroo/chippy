library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chippy_global.all;

use work.chippy_randgen;
use work.chippy_bcd_lut;

entity chippy_cpu is
	port (clk : in std_logic;
	reset : in std_logic;
	
	mem_addr : out std_logic_vector(11 downto 0);
	mem_we : out std_logic;
	mem_data_in : in std_logic_vector(7 downto 0);
	mem_data_out : out std_logic_vector(7 downto 0);
	
	keypad_in : in std_logic_vector(3 downto 0); 
	keypad_pressed : in std_logic);
end chippy_cpu;

architecture behavioural of chippy_cpu is

	signal r, rin : cpu_state_type;
	signal bcd_addr : std_logic_vector(7 downto 0) := (others => '0');
	signal bcd_val : std_logic_vector(11 downto 0) := (others => '0');
   	signal rnd_in : unsigned(7 downto 0) := (others => '0');

begin
	-- Random number generator
	randgen : entity chippy_randgen
		port map(clk => clk,
			reset => reset,
			rand_out => rnd_in);
	
	-- BCD lookup table
	bcd_lut : entity chippy_bcd_lut
		port map(addr => bcd_addr,
		data => bcd_val);	
		
	-- TODO: Check all memory write instructions to see if they set WE = 1		   
	-- TODO: fix the update of mem_addr on rising edge
	
	combinatorial : process(reset, r)
		variable v : cpu_state_type; 
		variable tmp : unsigned(8 downto 0);
		variable idx_x : integer;
		variable idx_y : integer;
	begin
		v := r;
		
		idx_x := to_integer(unsigned(r.cur_ins(11 downto 8)));	-- Vx
		idx_y := to_integer(unsigned(r.cur_ins(7 downto 4))); 	-- Vy
		
		case r.state is
			when FETCH =>
				-- Fetch next instruction from memory (16-bit word)
				case to_integer(r.cycle_counter) is
					when 0 => 
						-- Set cycle counter and load mem addr
						v.mem_addr := std_logic_vector(r.PC(11 downto 0));
						v.cycle_counter := to_unsigned(1, v.cycle_counter'length);
					when 1 =>
						-- Wait for first word, set next mem addr
						v.mem_addr := std_logic_vector(r.PC(11 downto 0) + 1);
						v.cycle_counter := to_unsigned(2, v.cycle_counter'length);
					when 2 =>	
						-- Load first word
						v.cur_ins(15 downto 8) := mem_data_in;
						v.cycle_counter := to_unsigned(3, v.cycle_counter'length);
					when 3 => 					 
						-- Load second word, done
						v.cur_ins(7 downto 0) := mem_data_in;
						v.state := EXECUTE;
						v.cycle_counter := to_unsigned(0, v.cycle_counter'length);
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
					v.SP := r.SP - 1;
					v.PC := r.stack(to_integer(v.SP));
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"1") then
					-- JP addr Jump to location nnn	 
					v.PC :=  resize(unsigned(r.cur_ins(11 downto 0)), v.PC'length);
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"2") then
					-- CALL addr Call subroutine at nnn	  
					v.SP := r.SP + 1;
					v.stack(to_integer(r.SP)) := r.PC;
					v.PC :=  resize(unsigned(r.cur_ins(11 downto 0)), v.PC'length);
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"3") then
					-- SE Vx, byte Skip next instr if reg Vx = kk
					if (std_logic_vector(r.V(idx_x)) = r.cur_ins(7 downto 0)) then
						v.PC := r.PC + 4;
					else
						v.PC := r.PC + 2;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"4") then
					-- SNE Vx, byte Skip next instr if reg Vx != kk
					if (std_logic_vector(r.V(idx_x)) /= r.cur_ins(7 downto 0)) then
						v.PC := r.PC + 4;
					else
						v.PC := r.PC + 2;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"5") AND (r.cur_ins(3 downto 0) = x"0") then
					-- SE Vx, Vy Skip next instr if Vx = Vy
					if ( r.V(idx_x) = r.V(idx_y) ) then
						v.PC := r.PC + 4;
					else
						v.PC := r.PC + 2;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"6") then
					-- LD Vx, byte Set Vx = kk
					v.V(idx_x) := unsigned(r.cur_ins(7 downto 0));
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"7") then
					-- ADD Vx, byte Set Vx = Vx + kk
					v.V(idx_x) := r.V(idx_x) + unsigned(r.cur_ins(7 downto 0));
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"0") then
					-- LD Vx, Vy Set Vx = Vy
					v.V(idx_x) := r.V(idx_y);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"1") then
					-- OR Vx, Vy Set Vx = Vx OR Vy
					v.V(idx_x) := r.V(idx_x) OR r.V(idx_y);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"2") then
					-- AND Vx, Vy Set Vx = Vx AND Vy
					v.V(idx_x) := r.V(idx_x) AND r.V(idx_y);
					v.PC := r.PC + 2;
					v.state := FETCH; 
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"3") then
					-- XOR Vx, Vy Set Vx = Vx XOR Vy
					v.V(idx_x) := r.V(idx_x) XOR r.V(idx_y);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"4") then
					-- ADD Vx, Vy Set Vx = Vx + Vy, set VF = carry
					tmp := ('0' & r.V(idx_x)) + ('0' & r.V(idx_y));
					v.V(15) := unsigned("0000000" & tmp(8)); -- Set carry in VF
					v.V(idx_x) := tmp(7 downto 0);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"5") then
					-- SUB Vx, Vy Set Vx = Vx - Vy, set VF = NOT borrow
					if r.V(idx_x) > r.V(idx_y) then
						v.V(15) := to_unsigned(1, v.V(15)'length);
					else
						v.V(15) := to_unsigned(0, v.V(15)'length);
					end if;
					v.V(idx_x) := r.V(idx_x) - r.V(idx_y);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"6") then
					-- SHR Vx {, Vy} Set Vx = Vx SHR 1 (shift LSB into VF)
					v.V(15) := unsigned("0000000" & r.V(idx_x)(0)); -- Set carry in VF
					v.V(idx_x) := unsigned("0" & r.V(idx_x)(7 downto 1));
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"7") then
					-- SUBN Vx, Vy Set Vx = Vy - Vx, set VF = NOT borrow
					if r.V(idx_y) > r.V(idx_x) then
						v.V(15) := to_unsigned(1, v.V(15)'length);
					else
						v.V(15) := to_unsigned(0, v.V(15)'length);
					end if;
					v.V(idx_x) := r.V(idx_y) - r.V(idx_x);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"8") AND (r.cur_ins(3 downto 0) = x"E") then
					-- SHL Vx {, Vy} Set Vx = Vx SHL 1 (shift MSB into VF)
					v.V(15) := unsigned("0000000" & r.V(to_integer(unsigned(r.cur_ins(11 downto 8))))(7)); -- Set carry in VF
					v.V(idx_x) := unsigned(r.V(idx_x)(6 downto 0) & "0");
					v.PC := r.PC + 2;
					v.state := FETCH;					
				elsif (r.cur_ins(15 downto 12) = x"9") AND (r.cur_ins(3 downto 0) = x"0") then
					-- SNE Vx, Vy Skip next instr if Vx != Vy
					if ( r.V(idx_x) /= r.V(idx_y) ) then
						v.PC := r.PC + 4;
					else
						v.PC := r.PC + 2;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"A") then
					-- LD I, addr Set reg I = nnn
					v.I := unsigned("0000" & r.cur_ins(11 downto 0));
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"B") then
					-- JP V0, addr Jump to location nnn + V0
					v.PC := r.V(0) + resize(unsigned(r.cur_ins(11 downto 0)), v.PC'length);
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"C") then
					-- RND Vx, byte Set Vx = random byte AND kk	 
					v.V(idx_x) := rnd_in AND unsigned(r.cur_ins(7 downto 0));
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"D") then
					-- DRW Vx, Vy, nibble Display n-byte sprite at mem I at (Vx, Vy), VF = collision
				elsif (r.cur_ins(15 downto 12) = x"E") and (r.cur_ins(7 downto 0) = x"9E") then
					-- SKP Vx, Skip next instruction if key = Vx is pressed
					if ((unsigned(keypad_in) = r.V(idx_x)) and (keypad_pressed = '1')) then
						v.PC := r.PC + 4;
					else
						v.PC := r.PC + 2;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"E") and (r.cur_ins(7 downto 0) = x"A1") then 
					-- SKNP Vx, Skip next instruction if key = Vx is not pressed
					if ((unsigned(keypad_in) /= r.V(idx_x)) or (keypad_pressed = '0')) then
						v.PC := r.PC + 4;
					else
						v.PC := r.PC + 2;
					end if;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"07") then 
					-- LD Vx, DT, Vx = delay timer value
					v.V(idx_x) := r.delay;
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"0A") then
					-- LD Vx, K, Wait for key press, store value in Vx	 
					if (keypad_pressed = '1') then
						v.V(idx_x) := resize(unsigned(keypad_in), v.V(idx_x)'length);
						v.state := FETCH;
						v.PC := r.PC + 2;
					else   
						v.state := EXECUTE;
					end if;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"15") then
					-- LD DT, Vx, Set delay timer = Vx
					v.delay := r.V(idx_x);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"18") then
					-- LD ST, Vx, Set sound timer = Vx
					v.sound := r.V(idx_x);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"1E") then
					-- ADD I, Vx, Set I = I + Vx
					v.I := r.I + resize(r.V(idx_x), v.I'length);
					v.PC := r.PC + 2;
					v.state := FETCH;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"29") then			
					-- LD F, Vx, Set I = location of sprite for digit Vx
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"33") then
					-- LD B, Vx, Set BCD representation of Vx in mem I, I+1 and I+2
					if (r.cycle_counter = 0) then
						v.cycle_counter := to_unsigned(4, v.cycle_counter'length);
						bcd_addr <= std_logic_vector(r.V(idx_x));	-- Set BCD address to LUT, read in next cycle
					elsif (r.cycle_counter = 1) then
						v.mem_we := '0';
						v.PC := r.PC + 2;
						v.cycle_counter := r.cycle_counter - 1;
						v.state := FETCH;
					elsif (r.cycle_counter = 2) then
						v.mem_addr := std_logic_vector(r.I(11 downto 0) + 2);
						v.mem_data_out := ("0000" & bcd_val(3 downto 0));
						v.mem_we := '1';
						v.cycle_counter := r.cycle_counter - 1;	
					elsif (r.cycle_counter = 3) then
						v.mem_addr := std_logic_vector(r.I(11 downto 0) + 1);
						v.mem_data_out := ("0000" & bcd_val(7 downto 4));
						v.mem_we := '1';
						v.cycle_counter := r.cycle_counter - 1;	
					elsif (r.cycle_counter = 4) then 
						v.mem_addr := std_logic_vector(r.I(11 downto 0));
						v.mem_data_out := ("0000" & bcd_val(11 downto 8));
						v.mem_we := '1';
						v.cycle_counter := r.cycle_counter - 1;	
					end if;	
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"55") then			
					-- LD [I], Vx, Store registers V0 through Vx in memory starting at I   
					-- TODO: check if you dont load them in reverse order?
					-- TODO: make sure you set write enable
					if (r.cycle_counter = 0) then
						v.cycle_counter := to_unsigned(idx_x + 1, v.cycle_counter'length); 
						v.mem_addr := std_logic_vector(v.I(11 downto 0));
						v.mem_data_out := std_logic_vector(r.V(0));
						v.mem_we := '1';
					elsif (r.cycle_counter = 1) then  
						v.mem_we := '0';
						v.cycle_counter := r.cycle_counter - 1;
						v.PC := r.PC + 2;
						v.state := FETCH;
					else
						v.mem_addr := std_logic_vector(v.I(11 downto 0) + idx_x - r.cycle_counter + 2);
						v.mem_data_out := std_logic_vector(r.V(to_integer(idx_x - r.cycle_counter + 2)));
						v.mem_we := '1';
						v.cycle_counter := r.cycle_counter - 1;		
					end if;
				elsif (r.cur_ins(15 downto 12) = x"F") and (r.cur_ins(7 downto 0) = x"65") then
					-- LD Vx, [I], Read registers V0 through Vx from memory starting at I	 
					if (r.cycle_counter = 0) then
						v.cycle_counter := to_unsigned(1, v.cycle_counter'length);
						v.mem_addr := std_logic_vector(v.I(11 downto 0));	   
					elsif (r.cycle_counter = 1) then  
						v.cycle_counter := r.cycle_counter + 1;
						v.mem_addr := std_logic_vector(v.I(11 downto 0) + 1); 
					elsif (r.cycle_counter = idx_x + 3) then	
						v.cycle_counter := to_unsigned(0, v.cycle_counter'length);
						v.PC := r.PC + 2;
						v.state := FETCH; 
					else  
						v.mem_addr := std_logic_vector(v.I(11 downto 0) + r.cycle_counter); 
						v.V(to_integer(r.cycle_counter - 2)) := unsigned(mem_data_in);
						v.cycle_counter := r.cycle_counter + 1;		
					end if;					
					-- Memory sequence for reg V0
					-- Cycle 0: Set address from instruction word
					-- Cycle 1: Address has become visible to memory unit
					-- Cycle 2: Data has become visible to CPU
					-- Cycle 3: Data has been loaded in register V0
				end if;
				when others =>
		end case;
		
		if (reset = '1') then
			v.cur_ins := x"0000";
			v.I := "0000000000000000";
			v.PC := x"0000";
			v.SP := x"00";
			v.delay := x"00";
			v.sound := x"00";
			v.state := FETCH;  
			v.cycle_counter := to_unsigned(0, v.cycle_counter'length);	
			for i in v.V'range loop
  				v.V(i) := x"00";
			end loop; 
			-- TODO: Fully initialize state
		end if;	 	   
		
		rin <= v;	 
		mem_addr <= r.mem_addr;
		mem_we <= r.mem_we;
		mem_data_out <= r.mem_data_out;
	end process;
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process;
	
end architecture;
			
			
			
			
				
			
			
			
		
			
			
			
			
			
			
				
				
				
			