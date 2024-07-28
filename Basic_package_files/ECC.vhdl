library ieee;
use ieee.std_logic_1164.all;

package ECC is
	component NOT_1 is
    port(I0 : in std_logic;          
         O0 : out std_logic); 
	end component;
	
	COMPONENT XOR_2 is
    port (I0,I1 :in std_logic;
          O0: out std_logic);
	end COMPONENT;


	component AND_2 is
	port(I0, I1 : in std_logic;
		     O0 : out std_logic );
	end component;

	component OR_2 is
	port(I0, I1 : in std_logic;
		     O0 : out std_logic );
			  
	end component;
	
	COMPONENT MUX_2X1 is
	port(I0, I1, S0 : in std_logic; -- Inputs
			O0 : out std_logic); -- Output
	end COMPONENT;
	
	COMPONENT Hamming_code_encoder is 
	port( I : in std_logic_vector(3 downto 0);
		   O : out std_logic_vector(6 downto 0));
	end COMPONENT;
	
	COMPONENT SIPO is
	generic( 
			n : integer := 7);
	port(
			CLK, RESET : in std_logic;
			A : in std_logic; -- Here, A is the data input that we will be serially inserting
			B : buffer std_logic_vector(n-1 downto 0) ); -- Here, B is the output that we will be getting as an vector
																 -- which is parallel
	end COMPONENT;


	component MAT_ADD is
		generic( 
				m : integer := 4;
				n : integer := 4);
		port (
			A : in  std_logic_vector (m*n-1 downto 0);
			B : in  std_logic_vector (m*n-1 downto 0);
			C : out std_logic_vector (m*n-1 downto 0);
			Carry : out std_logic);
	end component;

	component MAT_MUL is
		generic( 
				  m : integer := 1;
				  n : integer := 4;
				  k : integer := 7);
		port (
			A : in  std_logic_vector (m*n-1 downto 0);
			B : in  std_logic_vector (n*k-1 downto 0);
			C : out std_logic_vector (m*k-1 downto 0));
	end component;
	
	
end ECC;