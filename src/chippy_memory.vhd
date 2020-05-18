library IEEE;
use IEEE.std_logic_1164.all;	   
--use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;  


entity chippy_memory is
generic (
	addr_width : natural := 12;	-- 4096 bytes, byte addressable
	data_width : natural := 8);
port (
	addr : in std_logic_vector (addr_width - 1 downto 0);
	write_en : in std_logic;
	clk : in std_logic;
	din : in std_logic_vector (data_width - 1 downto 0);
	dout : out std_logic_vector (data_width - 1 downto 0));
end chippy_memory;

-- This should infer a BRAM by the synthesizer
architecture behavioural of chippy_memory is
	type mem_type is array ((2** addr_width) - 1 downto 0) of std_logic_vector(data_width - 1 downto 0);
	signal mem : mem_type;	
	signal raddr : std_logic_vector(addr_width - 1 downto 0);
begin
	process (clk)
	begin
		if (clk'event and clk = '1') then
			if (write_en = '1') then
				mem(conv_integer(addr)) <= din;
			end if;
			raddr <= addr;
			-- Read address register controlled by clock.
		end if;
	end process;
	dout <= mem(conv_integer(raddr));
end behavioural;