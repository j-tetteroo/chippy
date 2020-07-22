library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chippy_global.all;

entity chippy_uartloader is
	generic (
		BAUDCNT : integer := 1251;
		BAUDCNT_DIV2 : integer := 625;
		MEM_OFFSET : unsigned(11 downto 0) := x"200"	-- Input data written to this offset in main memory
	);
	port (
		clk : in std_logic;
		reset : in std_logic; 
		
		rx_in : in std_logic;
		tx_out : out std_logic;	
		enable : in std_logic; 
		
		mem_addr : out std_logic_vector(11 downto 0);
		mem_we : out std_logic;
		mem_data_out : out std_logic_vector(7 downto 0);
		
		transfer_complete : out std_logic
	);
end chippy_uartloader;

architecture behavioural of chippy_uartloader is 

	type t_uart_state is (IDLE, START_RX, RX, RX_DONE, START_TX, TX, TX_DONE, XFER_COMPLETE);
	
	type uart_state_type is record 
		state : t_uart_state;	 	   
		
		rx_buffer : std_logic_vector(7 downto 0);  
		tx_buffer : std_logic_vector(7 downto 0);	

		write_enable : std_logic;
		byte_counter : unsigned(11 downto 0);
		
		parity : std_logic;
		tx_out : std_logic;			  
		
		bit_count : unsigned(3 downto 0);
		clk_count : unsigned(11 downto 0);
	end record;


	signal r, rin : uart_state_type := (
		state => IDLE,
		rx_buffer => x"00",
		tx_buffer => x"00",
		write_enable => '0',
		byte_counter => x"000",
		parity => '0',
		tx_out => '0',
		bit_count => x"0",
		clk_count => x"000"
	);

begin
	
	combinatorial : process(reset, r, rx_in, enable)
		variable v : uart_state_type; 
	begin
		v := r;				 
		v.tx_out := '1';
		v.write_enable := '0';
		
		case r.state is
			when IDLE => 
				v.clk_count := to_unsigned(0, v.clk_count'length);	
				if (rx_in = '1') then
					v.state := IDLE;
				else
					v.state := START_RX;
					v.clk_count := to_unsigned(BAUDCNT_DIV2, v.clk_count'length);
				end if;
			when START_RX =>
				-- Synchronize with middle of start bit 
				if r.clk_count = 0 then
					if rx_in = '0' then
						v.state := RX;		-- Start receiving
					else
						v.state := IDLE;	-- False alarm	  
					end if;
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);	-- Set timer for next state
					v.bit_count := to_unsigned(0, v.bit_count'length);			-- Reset bit count
				else
					v.clk_count := r.clk_count - 1;								-- Decrement timer
				end if;
			when RX => 
				if r.clk_count = 0 then
					if r.bit_count = 9 then		-- 8 bits + parity received
						v.state := RX_DONE;
						v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					else
						-- Append bit and reset counter
						if r.bit_count = 8 then
							v.parity := rx_in;
						else 
							v.rx_buffer := rx_in & r.rx_buffer(7 downto 1);
						end if;
						v.bit_count := r.bit_count + 1;	-- Increment bit count
						v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);	-- Reset timer
					end if;
				else
					v.clk_count := r.clk_count - 1;	-- Timer
				end if;
			when RX_DONE =>
				-- Check parity
			   	if v.parity /= (v.rx_buffer(0) XOR v.rx_buffer(1) XOR v.rx_buffer(2) XOR v.rx_buffer(3) XOR v.rx_buffer(4) XOR v.rx_buffer(5) XOR v.rx_buffer(6) XOR v.rx_buffer(7)) then
					v.tx_buffer := x"CC";	-- Send invalid parity response	
				else
					v.tx_buffer := x"55";	-- Send valid parity response 
					v.write_enable := '1';	-- Write to memory
				end if;
				-- Wait for stop bit
			   	if r.clk_count = 0 then
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);	-- Set timer for next stage
					v.state := START_TX;
				else
					v.clk_count := r.clk_count - 1;
				end if;
			when START_TX =>
				-- Send start bit
				v.tx_out := '0';
				if r.clk_count = 0 then	
					v.bit_count := to_unsigned(0, v.bit_count'length);			-- Reset bit count for TX
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);  	-- Set timer for next stage
					v.state := TX;
				else 
					v.clk_count := r.clk_count - 1;	-- Decrement timer
				end if;
			when TX =>
				-- Send bits   
				-- TODO: clean up this code, there is a glitch in the 7-8 bit transition
				if r.clk_count = 0 then
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					if r.bit_count = 8 then	
						v.state := TX_DONE;
					else
						v.bit_count := r.bit_count + 1;
					end if;		
				else
					v.clk_count := r.clk_count - 1;	-- Decrement timer
				end if;
				if r.bit_count /= 8 then
					v.tx_out := r.tx_buffer(to_integer(r.bit_count(2 downto 0)));	-- Set output bit
				else
					v.tx_out := '0';	-- Set parity (always 0)
				end if;
			when TX_DONE =>
				-- Send stop bit
				if r.byte_counter = x"DFF" then
					v.state := XFER_COMPLETE;		-- Transfer complete, terminate
				elsif r.clk_count = 0 then	 
					v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
					v.byte_counter := r.byte_counter + 1;
					v.state := IDLE;
				else
					v.clk_count := r.clk_count - 1;
				end if;
			when XFER_COMPLETE =>	 
				-- Received 0xDFF bytes
				v.state := XFER_COMPLETE;
			when others =>
				v.state := IDLE;
		end case;
		
		if (reset = '1') then
			v.state := IDLE; 	 
			v.clk_count := to_unsigned(BAUDCNT, v.clk_count'length);
			v.rx_buffer := x"00"; 
			v.tx_buffer := x"00";
			v.byte_counter := x"000";
		end if;
		
		rin <= v;
		tx_out <= r.tx_out;
		
		transfer_complete <= '1' WHEN (r.state = XFER_COMPLETE) ELSE '0'; 
			
		mem_addr <= std_logic_vector(MEM_OFFSET + r.byte_counter);
		mem_data_out <= r.rx_buffer;
		mem_we <= r.write_enable;

	end process;
	
	synchronous : process(clk)
	begin
		if clk'event and clk = '1' then
			r <= rin;
		end if;
	end process;
	
end architecture;