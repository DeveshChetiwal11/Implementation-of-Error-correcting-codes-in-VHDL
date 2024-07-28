library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity HCC1 is
	generic(
	n : integer := 4; --Data bits
	k : integer := 3); --Parity bits
	port (
		A : in  std_logic_vector (n+k downto 0);
      B : out std_logic_vector (n-1 downto 0);
		error : out std_logic);
end entity;

architecture Behavioral of HCC1 is

type TwoDimensionalArray is array (natural range <>) of std_logic_vector(0 downto 0);
type TwoDimensionalArray1 is array (natural range <>) of std_logic_vector(n+k downto 0);
signal H : TwoDimensionalArray1(0 to k);
signal S : std_logic_vector(k downto 0);
signal B1 : std_logic_vector(n+k downto 0);

-- The function below performs the matrix multiplication operation, used to multiply matrices A and B of size pxq 
-- and qxr, in this case we have used it to multiply a H matrix of (k+1)x(n+k+1) size and A1 matrix of (n+k+1)x1 
-- size which we used in getting a vector S1 of k length

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
	
	--The below is process is for creating a check matrix, H
	process(A)
	begin
	
	for i in 0 to k loop
		for j in 0 to n+k loop
			if (i = k) then
				H(i)(j) <= '1';
			elsif ((j+1)/ 2**(k-1-i)) mod 2 = 1 then
				H(i)(n+k-j) <= '1';
			else 
				H(i)(n+k-j) <= '0';
			end if;
		end loop;
	end loop;
	
	end process;
	
	process(A, H)
	variable A1 : TwoDimensionalArray(0 to n+k);
	variable S1 : std_logic_vector(k downto 0);
	begin
	
	-- Convert the 1-dimensional input array or input vector A to 2-dimensional matrix A1
	for j in 0 to n+k loop
		A1(j)(0) := A((n+k)-j);
	end loop;
	
	S1 := MAT_MUL(p => k+1, q => n+k+1, r => 1, A => H, B => A1);	-- Generating a vector by multiplying 
																						-- check matirx with input with the
																						-- help of MAT_MUL function. It is the 
																						-- reverse of syndrome vector
	for j in 0 to k loop
		S(j) <= S1(k - j); -- Generating a syndrome vector by reversing the vector S1
	end loop;
	
	end process;
	
	process(A, S, B1)
	variable error1 : integer := 0;
	variable error2 : std_logic;
	variable err_pos : integer := 0;
	variable S1 : std_logic_vector(k-1 downto 0);
	begin
	
	S1 := S(k downto 1);
	
	error1 := to_integer(unsigned(S1));
	error2 := S(0);
	
	if ((error2 = '0') AND (error1 /= 0))then   -- Two bit error condition
		
		error <= '1';
		
		for i in 0 to n+k loop
			B1(i) <= '0';
		end loop;
		
	elsif ((error2 = '1') AND (error1 /= 0)) then   -- One bit error in any position other than the extra bit 
																 -- position
		
		error <= '0';
		
		err_pos := error1;
		
		for i in 0 to n+k loop
			if (i+1 = err_pos) then
				B1(i) <= NOT(A(i));
			else 
				B1(i) <= A(i);
			end if;
		end loop;
	
	elsif ((error2 = '1') AND (error1 = 0)) then  -- One bit error in the extra parity bit position i.e. in the 
															  -- (n+k)th position
		error <= '0';
		
		B1(n+k) <= NOT(A(n+k));
		
		for i in 0 to n+k-1 loop 
			B1(i) <= A(i);
		end loop;
		
	else   --Zero error
		error <= '0';
		
		for i in 0 to n+k loop 
			B1(i) <= A(i);
		end loop;
		
	end if;
	
	end process;
	
	-- The process below has been used for converting the n+k bits corrected signal to a n bits
	-- output signal which was the original message which was encdoed and trransferred
	
	process(B1)
	variable x : integer;
	variable B2 : std_logic_vector(n-1 downto 0 );
	begin
	
	x := 0;
	B2 := (others => '0'); 
	
	for i in 0 to n+k loop
		if ( i = 2**x - 1 ) then
			x := x + 1;
		else
			B2(i-x) := B1(i);
		end if;
	end loop;
	
	B <= B2;
	end process;

end architecture;