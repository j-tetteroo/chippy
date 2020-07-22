library ieee;	
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_test is	
	generic (
		BAUDCNT : integer := 1251;
		BAUDCNT_DIV2 : integer := 625
	);
	port (clk : in std_logic; 	-- 12 MHz
	reset : in std_logic;
	rx_in : in std_logic;
	tx_out : out std_logic;
	led_out : out std_logic );
end uart_test;


architecture behavioural of uart_test is  
	type t_uart_state is (IDLE, STARTRX, RX, RXDONE, STARTTX, TX, TXDONE);
	
	type uart_reg_type is record 
		state : t_uart_state;
		rx_buffer : std_logic_vector(7 downto 0);
		tx_out : std_logic;
		bit_count : unsigned(3 downto 0);
		clk_count : unsigned(11 downto 0);
	end record;

	signal r, r_in : uart_reg_type;
	
begin
	
	combinatorial : process(reset, r)
		variable v : uart_reg_type;
	begin
		v := r;
		v.tx_out := '1';
		
		case r.state is
			when IDLE => 
				v.clk_count := to_unsigned(0, v.clk_count'length);	
				if rx_in = '1' then
					v.state := IDLE;
				else
					v.state := STARTRX;
					v.clk_count := to_unsigned(BAUDCNT_DIV2, v.clk_count'length);
				end if;
			when STARTRX =>
				-- Synchronize with middle of start bit 
				if r.clk_count = 0 then
					if rx_in = '0' then
						v.state := RX;		-- Start receiving
					else
						v.state := IDLE;	-- False alarm	  
					end if;
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					v.bit_count := to_unsigned(0, v.bit_count'length);
				else
					v.clk_count := r.clk_count - 1;
				end if;
			when RX => 
				if r.clk_count = 0 then
					if r.bit_count = 8 then
						v.state := RXDONE;
						v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					else
						-- Append bit and reset counter
						v.bit_count := r.bit_count + 1;
						v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
						v.rx_buffer := rx_in & r.rx_buffer(7 downto 1);
					end if;
				else
					v.clk_count := r.clk_count - 1;
				end if;
			when RXDONE =>
				-- Wait for stop bit
			   	if r.clk_count = 0 then
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					v.state := STARTTX;
				else
					v.clk_count := r.clk_count - 1;
				end if;
			when STARTTX =>
				-- Send start bit
				v.tx_out := '0';
				if r.clk_count = 0 then	
					v.bit_count := "0000";
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);  
					--v.rx_buffer := x"41";	-- OVERRIDE
					v.state := TX;
				else 
					v.clk_count := r.clk_count - 1;
				end if;
			when TX =>
			-- Send bits
				if r.clk_count = 0 then
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					if r.bit_count = 7 then	
						v.state := TXDONE;
					else
						v.bit_count := r.bit_count + 1;
					end if;		
				else
					v.tx_out := r.rx_buffer(to_integer(r.bit_count(2 downto 0)));
					v.clk_count := r.clk_count - 1;	
				end if;
			when TXDONE =>
				-- Stop bit
				if r.clk_count = 0 then	 
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					v.state := IDLE;
				else
					v.clk_count := r.clk_count - 1;
				end if;
			when others =>
				v.state := IDLE;
		end case;
		
		if (reset = '1') then
			v.state := IDLE; 	 
			v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
			v.rx_buffer := x"41";
		end if;
		
		r_in <= v;
		tx_out <= r.tx_out;
		
		if v.state = RX then
			led_out <= '1';
		else
			led_out <= '0';
		end if;
		
	end process;
	
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= r_in;	
		end if;				  
	end process;		

end behavioural;