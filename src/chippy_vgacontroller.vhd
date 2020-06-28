library ieee;	
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pll;

-- Run the framebuffer memory at 25 mhz

entity chippy_vgacontroller is
	port (clk12 : in std_logic;	-- 12 mhz
	reset : in std_logic;
	
	rdata_in : in std_logic_vector(63 downto 0); -- Framebuffer input scanline
	raddr : out std_logic_vector(4 downto 0); -- Framebuffer address		  
	
	h_sync : out std_logic;
	v_sync : out std_logic;
	r : out std_logic;
	g : out std_logic;
	b : out std_logic;
	lock_pll : out std_logic;
	clk25_out : out std_logic);		
	
end chippy_vgacontroller; 

architecture behavioural of chippy_vgacontroller is  

	signal clk25 : std_logic; 
	signal lock : std_logic;	-- PLL lock signal
	signal h_counter : integer range 0 to 800;
	signal v_counter : integer range 0 to 525;
	type mem_type is array (2047 downto 0) of std_logic;
	signal mem : mem_type;
	
	type vga_reg_type is record
		h_counter : integer range 0 to 800;
		v_counter : integer range 0 to 525;
		r : std_logic;
		g : std_logic;
		b : std_logic;
		h_sync : std_logic;
		v_sync : std_logic;
	end record;

	signal reg, reg_in : vga_reg_type;
	signal inv_reset : std_logic;		-- PLL reset is active low

begin	
	
	-- PLL instance 25 MHz
	vga_pll_inst: entity vga_pll
	port map(
		REFERENCECLK => clk12,
          PLLOUTCORE => clk25,
          PLLOUTGLOBAL => open,
          RESET => inv_reset,
		  LOCK => lock);
		  
	combinatorial : process(reset, reg, lock)
		variable v : vga_reg_type;
		variable v_offset : integer;
		variable h_offset : integer;
	begin
		v := reg;
		v.r := '0';
		v.g := '0';
		v.b := '0';
		v.h_sync := '1';
		v.v_sync := '1';
		
		if (v.h_counter < 640) then
			v.h_counter := v.h_counter + 1;
		elsif (v.h_counter >= 656) and (v.h_counter < 752) then
			v.h_sync := '0';
			v.h_counter := v.h_counter + 1;
		elsif (v.h_counter >= 799) then
			v.v_counter := v.v_counter + 1;
			v.h_counter := 0;
		else
			v.h_counter := v.h_counter + 1;
		end if;		
		
		-- Fetch scanline from framebuffer memory
		if (v.v_counter >= 79) and (v.v_counter < 400) then
			raddr <= std_logic_vector(to_unsigned((v.v_counter-79) / 10, raddr'length));
		end if;	
		
		-- Draw input scanline
		if (v.v_counter > 79) and (v.v_counter <= 400) and (v.h_counter < 640) then
			if rdata_in(v.h_counter / 10) = '1' then
				v.r := '1';
				v.g := '1';
				v.b := '1';	
			else
				v.r := '0';
				v.g := '0';
				v.b := '0';	
			end if;
		end if;		
		
		
		if (v.v_counter < 480) and (v.h_counter < 640) then
			-- Visible area	
			
--			if (v.v_counter > 80) and (v.v_counter < 400) then
--				v_offset := v.v_counter / 10;
--				h_offset := ((v.h_counter / 10) + (v_offset mod 2)) mod 2;
--				
--				if h_offset = 1 then
--					v.r := '1';
--					v.g := '1';
--					v.b := '1';
--				else
--					v.r := '0';
--					v.g := '0';
--					v.b := '0';
--				end if;
--			end if;
			
		elsif (v.v_counter >= 490) and (v.v_counter < 492) then
			v.v_sync := '0';
		elsif (v.v_counter >= 525) then
			v.v_counter := 0;
		end if;
		
		if ((reset = '1') OR (lock = '0')) then
			v.h_counter := 0;
			v.v_counter := 0;
			v.r := '0';
			v.g := '0';
			v.b := '0';
			v.h_sync := '1';
			v.v_sync := '1';  
		end if;
		
		
		reg_in <= v;
	end process;

		
	synchronous : process(clk25)
	begin
		if clk25'event and clk25 = '1' then
			reg <= reg_in;	
		end if;
	end process;
	
	inv_reset <= NOT reset;
	
	r <= reg.r;
	g <= reg.g;
	b <= reg.b;
	h_sync <= reg.h_sync;
	v_sync <= reg.v_sync;	 
	
	lock_pll <= lock;
	clk25_out <= clk25;
	
end behavioural;