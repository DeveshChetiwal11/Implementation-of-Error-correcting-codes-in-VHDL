library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity HCE_UM_1 is
	generic( 
			n : integer := 4; -- no. of data bits
			k : integer := 3); -- no. of parity bits (excluding the extra parity bit)
   port (
		A : in  std_logic_vector (n-1 downto 0);
      B : out std_logic_vector (n+k downto 0));
end entity;

architecture Behavioral of HCE_UM_1 is 

type TwoDimensionalArray is array (natural range <>) of std_logic_vector(k-1 downto 0);
type TwoDimensionalArray1 is array (natural range <>) of std_logic_vector(n-1 downto 0);
signal C : TwoDimensionalArray(0 to n-1);
signal B1 : std_logic_vector(k-1 downto 0);

-- The function below performs the matrix multiplication operation, used to multiply matrices A and B of size pxq 
-- and qxr, in this case we have used it to multiply a A1 matrix of 1xn size and C matrix of nx(k+1) size which we 
-- used in getting a vector B1 of k+1 length

function MAT_MUL(	p : integer := 1;
						q : integer := 3;
						r : integer := 8;
						A : TwoDimensionalArray1;
						B : TwoDimensionalArray) return std_logic_vector is
	
	type TwoDimensionalArray2 is array (natural range <>) of std_logic_vector(r-1 downto 0);
	variable temp : TwoDimensionalArray2(0 to p-1);
	variable sum : TwoDimensionalArray2(0 to p-1);
	variable C1 : TwoDimensionalArray2(0 to p-1);
	variable C : std_logic_vector(p*r-1 downto 0);

begin
	
	for i in 0 to p-1 loop
		for j in 0 to r-1 loop
			temp := (others => (others => '0'));
	
			for k in 0 to q-1 loop
				temp(i)(j) := temp(i)(j) XOR (A(i)(k) AND B(k)(j));
			end loop;
	
			sum(i)(j) := temp(i)(j);
		end loop;
	end loop;
		
	C1 := sum;
	
-- Convert the 2-dimensional matrix C1 to 1-dimensional output array or vector C
	for i in 0 to p-1 loop
		for j in 0 to r-1 loop
			C((i * r) + j) := C1(i)(j);
		end loop;
	end loop;
	
	return C;
	
end function MAT_MUL;

begin

-- Below process is used to create a parity matrix of nxk size and on closely observing the matrix we found a 
-- pattern in it. Say for example a (7, 4) code we will need a parity matrix of 4x3 size. The matrix looks like
-- [ { 0 1 1 } { 1 0 1 } { 1 1 0 } { 1 1 1 } ]. We can see that the first row is binary representation of 3 and
-- the 2nd, 3rd and 4th are of 5, 6 and 7, respectively. So, we have to make a matrix in such a way that all the
-- binary representaion of numbers till n + k are there except those of 0 and  the numbers whose powers are in 2.

	process (A) 
	variable x : integer;
	begin
	
	x := 0;
	
	for i in 1 to n+k loop
		
		if ( ( i = 2**x )) then
			x := x + 1;
		else
			C( ( i - 1 ) - x ) <= std_logic_vector( to_unsigned(i, k));
		end if;
		
	end loop;
	
	end process;
	
	process(A, C)
	variable A1 : TwoDimensionalArray1(0 to 0);
	begin
	
	-- Convert the 1-dimensional input array or input vector A to 2-dimensional matrix A1
	for j in 0 to n-1 loop
		A1(0)(j) := A(j);
	end loop;
	
	B1 <= MAT_MUL(p => 1, q => n, r => k, A => A1, B => C); -- Generating parity bits by multiplying 
																			  -- data bits with parity matrix with the
																			  -- help of MAT_MUL function
	
	end process;

-- The process below is used to create a output vector B in which the positions in power of 2 are parity bits and
-- rest are data bits. m and z are to be set zero hence they are inititated to zero for every input
	
	process(A, B1)
	variable m : integer;
	variable z : integer;
	variable B2 : std_logic_vector(n+k downto 0);
	begin
	
	m := 0;
	z := 0;
	B2 := (others => '0');
	
	for i in 0 to n+k-1 loop
		if ( i = 2**m - 1 ) then
			B2(i) := B1(i - z);
			m := m + 1;
		else
			B2(i) := A(i - m);
			z := z + 1;
		end if;
	end loop;
	
	-- The given below loop creates an extra parity bit which keeps in check the even parity of whole output vector
	
	for j in 0 to n+k-1 loop
		B2(n+k) := B2(n+k) XOR B2(j); 
	end loop;
	
	B <= B2;
	end process;

end architecture;
