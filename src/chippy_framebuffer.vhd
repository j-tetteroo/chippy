library IEEE;
use IEEE.std_logic_1164.all;	   
use IEEE.NUMERIC_STD.ALL;

use work.chippy_global.all;

entity chippy_framebuffer is
	port (
		clk : in std_logic;	
		reset : in std_logic;
		row : in unsigned(4 downto 0);
		column : in unsigned(4 downto 0); 	  
		sprite : in std_logic_vector(7 downto 0); 
		we_in : in std_logic;
		
		we_out : out std_logic;	 
		waddr_out : out std_logic_vector(4 downto 0);
		wdata_out : out std_logic_vector(63 downto 0);
		VF_flag : out std_logic;					
		stall : out std_logic
	);
end chippy_framebuffer;

architecture behavioural of chippy_framebuffer is	

	signal r, rin : fbuf_state_type;	   
	signal we_int : std_logic;	
	signal rdata_int : std_logic_vector(63 downto 0);
	signal wdata_int : std_logic_vector(63 downto 0);
	signal addr_int	: std_logic_vector(4 downto 0);

begin

	internal_buffer : entity chippy_memory
	generic map (
		addr_width => 5,
		data_width => 64)
	port map(clk => clk,
		addr => addr_int,
		write_en => we_int,
		din => wdata_int,
		dout => rdata_int);	

	combinatorial : process (reset, r)
		variable v : fbuf_state_type;
		variable offset : integer;	 
		variable result : std_logic_vector(7 downto 0);
		
	begin 
		v := r;	
		case r.state is
			when FWAIT =>
				we_int <= '0';
				stall <= '0';
				if we_in = '1' then
					v.state := INIT;
				else
					v.state := FWAIT;
				end if;
			when INIT =>
				we_int <= '0';
				stall <= '1';
				v.addr := std_logic_vector(row);	
				v.state := READ;
			when READ =>
				we_int <= '0';	 
				stall <= '1';
				v.linebuf := rdata_int(63 downto 0) & rdata_int(63 downto 56);
				v.state := CALCULATE;
			when CALCULATE =>						
				we_int <= '0';	 
				stall <= '1';
				offset := 63 - to_integer(column);
				v.linebuf(offset downto offset-7) := r.linebuf(offset downto offset-7) XOR sprite;
				if unsigned(v.linebuf AND NOT r.linebuf) /= 0 then
					VF_flag <= '1';
				else
					VF_flag <= '0';
				end if;
				v.state := WRITE;
			when WRITE =>
				we_int <= '1';	 
				stall <= '1';
				addr_int <= std_logic_vector(row);	
				if column > 55 then
					wdata_int <= r.linebuf(7 downto 0) & r.linebuf(63 downto 8);	-- Wraparound
				else	
					wdata_int <= r.linebuf(71 downto 8);
				end if;
				v.state := FWAIT;				  
			when others =>
				we_int <= '0';
				stall <= '0';
		end case;
		
		rin <= v;	
		we_out <= we_int;	
		waddr_out <= addr_int;
		
	end process;  
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process;
		

end behavioural;