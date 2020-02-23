library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package chippy_global is 
	

	
	type regfile_type is record
		
		V0 : std_logic_vector(7 downto 0);
		V1 : std_logic_vector(7 downto 0);
		V2 : std_logic_vector(7 downto 0);
		V3 : std_logic_vector(7 downto 0);
		V4 : std_logic_vector(7 downto 0);
		V5 : std_logic_vector(7 downto 0);
		V6 : std_logic_vector(7 downto 0);
		V7 : std_logic_vector(7 downto 0);
		V8 : std_logic_vector(7 downto 0);
		V9 : std_logic_vector(7 downto 0);
		VA : std_logic_vector(7 downto 0);
		VB : std_logic_vector(7 downto 0);
		VC : std_logic_vector(7 downto 0);
		VD : std_logic_vector(7 downto 0);
		VE : std_logic_vector(7 downto 0);
		VF : std_logic_vector(7 downto 0);
		
		I : std_logic_vector(15 downto 0);
		
		delay : std_logic_vector(7 downto 0);
		sound : std_logic_vector(7 downto 0);
		
		PC : std_logic_vector(15 downto 0);
		SP : std_logic_vector(7 downto 0);
		
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