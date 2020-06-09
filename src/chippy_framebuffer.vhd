library IEEE;
use IEEE.std_logic_1164.all;	   
use IEEE.NUMERIC_STD.ALL;

use work.chippy_global.all;

entity chippy_framebuffer is
	port (
		clk : in std_logic;	
		reset : in std_logic;
		row : in unsigned(4 downto 0);
		column : in unsigned(5 downto 0); 	  
		sprite : in std_logic_vector(7 downto 0); 
		we_in : in std_logic;	 
		
		rdata_in : in std_logic_vector(63 downto 0);		-- Input from internal framebuffer
		we_out : out std_logic;	 
		addr_out : out std_logic_vector(4 downto 0);		
		wdata_out : out std_logic_vector(63 downto 0);		-- Output to internal framebuffer and external framebuffer
		VF_flag : out std_logic;					
		stall : out std_logic
	);
end chippy_framebuffer;

architecture behavioural of chippy_framebuffer is	

	signal r, rin : fbuf_state_type;	

begin


	combinatorial : process (reset, r)
		variable v : fbuf_state_type;
		variable offset : integer;	 
		variable result : std_logic_vector(7 downto 0);
		
	begin 
		v := r;			
		v.vf := '0';
		v.we := '0';
		
		case r.state is
			when FWAIT =>
				stall <= '0';
				if we_in = '1' then
					v.state := INIT;
				else
					v.state := FWAIT;
				end if;
			when INIT =>
				stall <= '1';
				v.addr := std_logic_vector(row);	
				v.state := READ;
			when READ => 
				stall <= '1';
				v.linebuf := rdata_in(63 downto 0) & rdata_in(63 downto 56);
				v.state := CALCULATE;
			when CALCULATE =>						
				stall <= '1';
				offset := 71 - to_integer(column);
				v.linebuf(offset downto offset-7) := r.linebuf(offset downto offset-7) XOR sprite;
				if (r.linebuf AND NOT(v.linebuf)) /= x"000000000000000000" then	-- Check if we overwrite a bit 
					v.vf := '1';
				else
					v.vf := '0';
				end if;
				v.state := WRITE;
			when WRITE =>
				v.vf := r.vf;
				v.we := '1';
				stall <= '1';
				addr_out <= std_logic_vector(row);	
				if column > 55 then
					v.data := r.linebuf(7 downto 0 ) & r.linebuf(63 downto 8);	-- Wraparound
				else	
					v.data := r.linebuf(71 downto 8);
				end if;
				v.state := FWAIT;				  
			when others =>
				stall <= '0';
				v.state := FWAIT;
		end case; 
		
		if (reset = '1') then
			v.state := FWAIT;
			v.linebuf := (others => '0');
			we_out <= '0';
			addr_out <= "00000";
			wdata_out <= (others => '0');
			VF_flag <= '0';				
			stall <= '0';
		end if;
		
		rin <= v;	
		we_out <= r.we;
		addr_out <= r.addr;
		wdata_out <= r.data;
		VF_flag <= r.vf WHEN (r.state = FWAIT) ELSE '0';
		
	end process;  
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process;
		

end behavioural;