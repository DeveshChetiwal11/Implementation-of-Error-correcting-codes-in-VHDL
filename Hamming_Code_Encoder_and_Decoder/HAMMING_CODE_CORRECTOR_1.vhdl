library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HAMMING_CODE__CORRECTOR_1 is
  generic (
     n : positive := 4; -- number of data bits
     k : positive := 3  -- number of parity bits
  );
  port (
     A : in std_logic_vector(n+k-1 downto 0);   -- received data with parity bits
     B : out std_logic_vector(n-1 downto 0);  -- corrected data
     error : out std_logic  -- error flag
  );
end entity;

architecture behavioral of HAMMING_CODE_CORRECTOR_1 is
signal B2 : std_logic_vector(n+k-1 downto 0);

begin

	process(A)
	variable C : std_logic_vector(k-1 downto 0); -- variable to store binary representation of bit position
	variable D : std_logic_vector(k-1 downto 0); -- variable to store the sum of C values
	variable B1 : std_logic_vector(n+k-1 downto 0);
	variable error_pos : integer := 0;				 -- variable to store the position of the error bit
	variable all_zero : std_logic;
	begin
  
    -- initiating all vectors to zero
	 all_zero := '0';
	 D := (others => '0'); 
    C := (others => '0');
	 
    -- iterate through all the bits in the input signal
    for j in 0 to n+k-1 loop
	   if A(j) = '1' then
         C := std_logic_vector(to_unsigned(j+1, k)); -- convert the bit position to binary and store in C
		   D := D xor C; -- add the C value to the D variable
		end if;
	 end loop;
	 
	 -- checking if there is no error i.e. no error condition binary sum is all zeroes
	 for l in 0 to k-1 loop
	   all_zero := D(l) or all_zero;
	 end loop;
	 
	 -- check if the binary sum is zero, indicating no error
	 if all_zero = '0' then
	   error <= '0';
		B1 := A;
	 else
	   error_pos := to_integer(unsigned(D)); -- convert the D value to an integer to get the error bit position
	   for i in 0 to n+k-1 loop
			if ( i+1 = error_pos ) then
				B1(i) := NOT ( A(i) ); 
			else 
				B1(i) := A(i);
			end if;
		end loop;
		error <= '1';
	 end if;
	 
	 B2 <= B1;
	 
	 -- set the error flag based on whether an error was detected and corrected
	 if A = B1 then
	   error <= '0';
	 end if;

	end process;
	
	-- The process below has been used for converting the n+k bits corrected signal to a n bits
	-- output signal which was the original message which was encdoed and trransferred
	
	process(B2)
	variable x : integer := 0;
	variable B3 : std_logic_vector(n-1 downto 0 );
	begin
	
	x := 0;
	B3 := (others => '0'); 
	
	for i in 0 to n+k-1 loop
		if ( i = 2**x - 1 ) then
			x := x + 1;
		else
			B3(i-x) := B2(i);
		end if;
	end loop;
	
	B <= B3;
	
	end process;
end Behavioral;
