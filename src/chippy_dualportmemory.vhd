library IEEE;
use IEEE.std_logic_1164.all;	   
--use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;  

entity chippy_dualportmemory is
	generic (
		addr_width : natural := 5;		-- 64x32	
		data_width : natural := 64);
	port (
		write_en : in std_logic;
		waddr : in std_logic_vector (addr_width - 1 downto 0);
		wclk : in std_logic;
		raddr : in std_logic_vector (addr_width - 1 downto 0);
		rclk : in std_logic;
		din : in std_logic_vector (data_width - 1 downto 0);
		dout : out std_logic_vector (data_width - 1 downto 0));
end chippy_dualportmemory;

-- Pseudo-dual port BRAM
architecture behavioural of chippy_dualportmemory is
	type mem_type is array ((2** addr_width) - 1 downto 0) of std_logic_vector(data_width - 1 downto 0);
	signal mem : mem_type;
	--attribute syn_ramstyle: string;
	--attribute syn_ramstyle of mem: signal is "no_rw_check";
begin
	process (wclk) -- Write memory.
	begin
		if (wclk'event and wclk = '1') then
			if (write_en = '1') then
				mem(conv_integer(waddr)) <= din;
				-- Using write address bus.
			end if;
		end if;
	end process;
	
	process (rclk) -- Read memory.
	begin
		if (rclk'event and rclk = '1') then
			dout <= mem(conv_integer(raddr));
			-- Using read address bus.
		end if;
	end process;
end behavioural;