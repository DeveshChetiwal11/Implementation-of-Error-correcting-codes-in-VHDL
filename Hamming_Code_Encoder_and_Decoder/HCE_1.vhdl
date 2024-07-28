library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.ECC.all;

entity HCE1 is
	generic( 
			n : integer := 11;
			k : integer := 4);
   port (
		A : in  std_logic_vector (n-1 downto 0);
      B : buffer std_logic_vector (n+k-1 downto 0);
		S : out std_logic_vector (n+k downto 0));
end entity;

architecture Behavioral of HCE1 is 

type TwoDimensionalArray1 is array (0 to n-1, 0 to n+k-1)of std_logic;
signal G : TwoDimensionalArray1;
type TwoDimensionalArray2 is array (0 to n-1, 0 to n-1)of std_logic;
signal A1 : TwoDimensionalArray2;
type TwoDimensionalArray is array (natural range <>) of std_logic_vector(k-1 downto 0);
signal C : TwoDimensionalArray(0 to n-1);
signal M : std_logic_vector(n*(n+k)-1 downto 0);
signal T : std_logic;

begin

	process (A)
   begin
    -- Convert the 1-dimensional input array or input vector A to 2-dimensional matrix A1
		for i in 0 to n-1 loop
			for j in 0 to n-1 loop
				if (i = j) then
					A1(i, j) <= '1';
				else
					A1(i, j) <= '0';
				end if;
			end loop;
		end loop;
	end process;

	process(A)
	variable a : integer := n + k;
	variable z : integer := 0;
	variable count : integer := 0;
	variable D : std_logic_vector(k-1 downto 0);
	begin
	
	for i in 0 to n+k-1 loop

-- Created a vector D which is binary representation of the integer 'a' which is decreasing and check if it has 
-- only one '1' in it ( since, binary representation of a number which is in poer of 2 has only one '1' in it) 
-- then ignore it and go ahead 
			
			D := std_logic_vector( to_unsigned(a, k));
			
			for i in 0 to k-1 loop
					if (D(i) = '1') then
						count := count + 1;
					end if;
			end loop;
			
			if ( count = 1 OR count = 0) then
				a := a - 1;
				count := 0;
				z := z + 1;
			else 
				C(i-z) <= D;
				a := a - 1;
				count := 0;
			end if;


	end loop;
	
	end process;
	
	process (A1, C)
   variable b : integer := 0;
	variable d : integer := 0;
	variable count : integer := 0;
	variable R : std_logic_vector(k-1 downto 0);
   begin
		for i in 0 to n-1 loop
				d := 0;
				b := 0;
			for j in 0 to n+k-1 loop
			
-- Created a vector R which is binary representation of the index 'j' which is decreasing and check if it has 
-- only one '1' in it ( since, binary representation of a number which is in poer of 2 has only one '1' in it) 
-- then ignore it and go ahead 
			
				R := std_logic_vector( to_unsigned(j, k));
				for i in 0 to k-1 loop
						if (R(i) = '0') then
							count := count + 1;
						end if;
				end loop;
			
					if ( count = 1 OR count = 0) then
						G(i,j) <= C(i)((k-1)-(j-b)); -- Here, (k-1)-(j-b) is done because mirror image of original 
																-- matrix was getting inserted into generator matrix, G if
																-- j-b was directly used
						d := d + 1;
						count := 0;
					else 
						G(i,j) <= A1(i, j-d);
						b := b + 1;
						count := 0;
					end if;
			
			end loop;
		end loop;
	end process;
	
	process (G)
	variable temp : std_logic_vector(n*(n+k)-1 downto 0);
	variable temp1 : std_logic_vector(n*(n+k)-1 downto 0);

   begin
   -- Convert the 2-dimensional matrix G to 1-dimensional output array or vector temp
		for i in 0 to n-1 loop
			for j in 0 to n+k-1 loop
				temp((i * (n+k)) + j) := G(i, j);
			end loop;
		end loop;
		
		for i in 0 to n*(n+k)-1 loop
			temp1(n*(n+k)-1-i) := temp(i);
		end loop;
		M <= temp1;
		
	end process;

	U0 : MAT_MUL port map(A, M, B);
	
	process(B,T)
	variable D : std_logic;
	begin
		D := '0';
		for i in 0 to n+k-1 loop
		D := B(i) xor D;
--			if B(i) = '1' then
--        count := count + 1;
--			end if;
		end loop;
		T <= D;
--
--		if count mod 2 = 0 then
--			D <= '0'; -- even parity
--		else
--			D <= '1'; -- odd parity
--		end if;
	end process;
	
	--B(n+k) <= D;
	S(n+k-1 downto 0) <= B;
	S(n+k) <= T;

end architecture;

