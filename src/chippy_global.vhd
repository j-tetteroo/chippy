library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package chippy_global is  
	
	type t_regfile is array (15 downto 0) of unsigned(7 downto 0);
	type t_stack is array (15 downto 0) of unsigned(15 downto 0);
	type t_cpu_state is (FETCH, EXECUTE);	
	type t_fbuf_state is (FWAIT, INIT, READ, READ_1, CALCULATE, WRITE, WRITE_1);  
	
	-- Framebuffer state
	type fbuf_state_type is record
		state : t_fbuf_state;
		
		addr : std_logic_vector(4 downto 0);
		linebuf : std_logic_vector(71 downto 0); 
		
		we : std_logic;	 		
		data : std_logic_vector(63 downto 0); 
		
		vf : std_logic;
		
	end record;
	
	-- CPU state
	type cpu_state_type is record
		
		state : t_cpu_state; 
		
		cur_ins : std_logic_vector(15 downto 0);	 -- current instruction 2 byte instruction MSB first 
		
		V : t_regfile;		   
		stack : t_stack;
		
		I : unsigned(15 downto 0);
		
		delay : unsigned(7 downto 0);
		sound : unsigned(7 downto 0);
		
		PC : unsigned(15 downto 0);
		SP : unsigned(7 downto 0);
		
		cycle_counter : unsigned(11 downto 0);
		
		mem_we : std_logic;
		mem_addr : std_logic_vector(11 downto 0);
		mem_data_in : std_logic_vector(7 downto 0);
		mem_data_out : std_logic_vector(7 downto 0);
		
		alu_op : std_logic_vector(3 downto 0);
		alu_A_in : unsigned(7 downto 0);
		alu_B_in : unsigned(7 downto 0);
		alu_out : unsigned(15 downto 0);
		alu_carry : std_logic; 
		
		
	end record;

	-- ALU operations: ADD=0001, OR=0010, AND=0011, XOR=0100, SUB=0101, SHR=0110, SUBN=0111, SHL=1000, RND=1001
	constant ALU_ADD : std_logic_vector(3 downto 0):= "0001";
	constant ALU_OR : std_logic_vector(3 downto 0):= "0010";
	constant ALU_AND : std_logic_vector(3 downto 0):= "0011";
	constant ALU_XOR : std_logic_vector(3 downto 0):= "0100";
	constant ALU_SUB : std_logic_vector(3 downto 0):= "0101";
	constant ALU_SHR : std_logic_vector(3 downto 0):= "0110";
	constant ALU_SUBN : std_logic_vector(3 downto 0):= "0111";
	constant ALU_SHL : std_logic_vector(3 downto 0):= "1000";
	constant ALU_RND : std_logic_vector(3 downto 0):= "1001";
	
	
end package;