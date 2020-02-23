library ieee;	
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chippy_global.all;

-- ALU operations: ADD=0001, OR=0010, AND=0011, XOR=0100, SUB=0101, SHR=0110, SUBN=0111, SHL=1000, RND=1001

entity chippy_alu is
	port (clk : in std_logic;
	reset : in std_logic;
	op : in std_logic_vector(3 downto 0);	 -- ALU opcode
	A_in : in unsigned(7 downto 0);
	B_in : in unsigned(7 downto 0);
	ALU_out : out unsigned(15 downto 0); -- ALU out (8 bits for all instructions except ADD I, Vx)
	carry_out : out std_logic);	-- Used to set VF register, also used by shift instructions
end chippy_alu;	  

architecture behavioural of chippy_alu is  

	type alu_reg_type is record
		ALU_output : unsigned(15 downto 0);
		ALU_carry : std_logic;
	end record;

	signal r, rin : alu_reg_type;
	
	signal RNG_out : unsigned(7 downto 0);

begin
	
	-- RNG component
	randgen : entity chippy_randgen
		port map(clk => clk,
			reset => reset,
			rand_out => RNG_out);
	
	combinatorial : process(op, RNG_out, A_in, B_in, r, reset)
		variable v : alu_reg_type;
		variable tmp : unsigned(8 downto 0);
		
	begin
		v := r;	
		v.ALU_carry := '0';
		case(op) is
			when ALU_ADD =>
				tmp := ('0' & A_in) + ('0' & B_in);
				v.ALU_carry := tmp(8);
				v.ALU_output := "00000000" & tmp(7 downto 0);
			when ALU_OR =>
				v.ALU_output := "00000000" & (A_in OR B_in);
			when ALU_AND =>
				v.ALU_output := "00000000" & (A_in AND B_in);
			when ALU_XOR =>									 
				v.ALU_output := "00000000" & (A_in XOR B_in);
			when ALU_SUB =>									 
				if A_in > B_in then
					v.ALU_carry := '1';
				else
					v.ALU_carry := '0';
				end if;
				v.ALU_output := "00000000" & (A_in - B_in);
			when ALU_SHR =>		
				v.ALU_carry := A_in(0);
				v.ALU_output := "000000000" & A_in(7 downto 1);
			when ALU_SUBN =>
				if B_in > A_in then
					v.ALU_carry := '1';
				else
					v.ALU_carry := '0';
				end if;
				v.ALU_output := "00000000" & (B_in - A_in);	
			when ALU_SHL =>
				v.ALU_carry := A_in(7);
				v.ALU_output := "00000000" & A_in(6 downto 0) & '0';
			when ALU_RND =>
				v.ALU_carry := '0';
				v.ALU_output := "00000000" & (RNG_out AND A_in);	-- Random value is ANDed with kk stored in A_in
			when others => 
				v.ALU_carry := '0';
				v.ALU_output := "0000000000000000";
			
		end case;
		
		if (reset = '1') then
			v.ALU_output := "0000000000000000";
			v.ALU_carry := '0';
		end if;	 
		
		rin <= v;
	end process;
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process; 
	ALU_out <= r.ALU_output; 
	carry_out <= r.ALU_carry;
end architecture;