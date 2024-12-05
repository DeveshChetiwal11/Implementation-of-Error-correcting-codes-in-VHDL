library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ldpc_encoder_1 is
    generic (
        N : integer := 20;  -- Codeword length
        K : integer := 5;   -- Message length (N-K is parity check equations)
        WC : integer := 3;  -- Column weight
        WR : integer := 4   -- Row weight
    );
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        msg_in : in  std_logic_vector(K-1 downto 0);
        codeword_out : out std_logic_vector(N-1 downto 0)
    );
end ldpc_encoder_1;

architecture Behavioral of ldpc_encoder_1 is
    -- Matrix types
    type h_matrix is array (0 to N-K-1, 0 to N-1) of std_logic;
    type g_matrix is array (0 to K-1, 0 to N-1) of std_logic;
    type msg_matrix is array (0 to K-1) of std_logic;
    type code_matrix is array (0 to N-1) of std_logic;
    type bit_participation_matrix is array (0 to N-1, 0 to N-K-1) of std_logic;
    
    -- Signals
    signal H : h_matrix := (others => (others => '0'));
    signal G_internal : g_matrix := (others => (others => '0'));
    signal bit_participates : bit_participation_matrix := (others => (others => '0'));
    signal msg_internal : msg_matrix;
    signal code_result : code_matrix;
	 signal DCA : std_logic_vector(N-1 downto 0);
    
    type state_type is (IDLE, INIT_MATRIX, GENERATE_G, ENCODE, FINISH);
    signal state : state_type := IDLE;
    
    -- Matrix multiplication function
    function matrix_multiply(msg : msg_matrix; gen : g_matrix) return code_matrix is
        variable result : code_matrix;
        variable temp : std_logic;
    begin
        -- Initialize result
        for i in 0 to N-1 loop
            result(i) := '0';
        end loop;
        
        -- Perform matrix multiplication
        for i in 0 to N-1 loop  -- For each column in G matrix (output bit)
            temp := '0';
            for j in 0 to K-1 loop  -- For each row in G matrix
                temp := temp xor (msg(j) and gen(j, i));
            end loop;
            result(i) := temp;
        end loop;
        
        return result;
    end function;
    
    -- H matrix initialization procedure (unchanged)
    procedure initialize_h_matrix(
        signal h_mat : out h_matrix;
        signal participates : out bit_participation_matrix
    ) is
        variable row_idx : integer;
        variable col_idx : integer;
        variable block_idx : integer;
        variable block_size : integer;
    begin
        -- Clear matrices
        for i in 0 to N-K-1 loop
            for j in 0 to N-1 loop
                h_mat(i, j) <= '0';
            end loop;
        end loop;
        
        for i in 0 to N-1 loop
            for j in 0 to N-K-1 loop
                participates(i, j) <= '0';
            end loop;
        end loop;
        
        block_size := N / WR;
        
        -- Generate systematic part
        for i in 0 to (N-K)/WC - 1 loop
            for j in 0 to WR-1 loop
                row_idx := i;
                col_idx := i * WR + j;
                if row_idx < N-K and col_idx < N then
                    h_mat(row_idx, col_idx) <= '1';
                    participates(col_idx, row_idx) <= '1';
                end if;
            end loop;
        end loop;
        
        -- Generate remaining blocks with cyclic shifts
        for b_idx in 1 to WC-1 loop
            for i in 0 to (N-K)/WC - 1 loop
                for j in 0 to WR-1 loop
                    row_idx := b_idx * ((N-K)/WC) + i;
                    col_idx := (i * WR + j + b_idx * block_size) mod N;
                    if row_idx < N-K and col_idx < N then
                        h_mat(row_idx, col_idx) <= '1';
                        participates(col_idx, row_idx) <= '1';
                    end if;
                end loop;
            end loop;
        end loop;
    end procedure;

    -- G matrix generation function (unchanged)
    function generate_g_matrix(h_in: h_matrix) return g_matrix is
        variable g_out : g_matrix;
        variable temp : std_logic;
        variable h_transpose : h_matrix;
    begin
        -- Transpose the H matrix
        for i in 0 to N-K-1 loop
            for j in 0 to N-1 loop
                h_transpose(i, j) := h_in(i, j);
            end loop;
        end loop;

        -- Generate the G matrix
        for i in 0 to K-1 loop
            for j in 0 to N-1 loop
                if j < K then
                    -- Generate the systematic part of G
                    if i = j then
                        g_out(i, j) := '1';
                    else
                        g_out(i, j) := '0';
                    end if;
                else
                    -- Generate the parity part of G
                    temp := '0';
                    for k in 0 to N-K-1 loop
                        temp := temp xor (h_transpose(k, j) and h_in(i, k));
                    end loop;
                    g_out(i, j) := temp;
                end if;
            end loop;
        end loop;
        
        return g_out;
    end function;

begin
    -- Main state machine process
    process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
            else
                case state is 
                    when IDLE =>
                        state <= INIT_MATRIX;
                    when INIT_MATRIX =>
                        state <= GENERATE_G;
                    when GENERATE_G =>
                        state <= ENCODE;
                    when ENCODE =>
                        state <= FINISH;
                    when FINISH =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- Matrix initialization and generation process
    process(clk)
    begin
        if rising_edge(clk) then
            if state = INIT_MATRIX then
                initialize_h_matrix(H, bit_participates);
                G_internal <= generate_g_matrix(H);
            end if;
        end if;
    end process;

    -- Message input process
    process(msg_in)
    begin
        for i in 0 to K-1 loop
            msg_internal(i) <= msg_in(i);
        end loop;
    end process;

    -- Encoding process using corrected matrix multiplication
    process(clk)
    begin
        if rising_edge(clk) then
            if state = ENCODE then
                code_result <= matrix_multiply(msg_internal, G_internal);
            end if;
        end if;
    end process;

    -- Output assignment process
    process(code_result)
    begin
        for i in 0 to N-1 loop
            DCA(i) <= code_result(i);
        end loop;
    end process;
	 
	    process(DCA)
		 begin
			  for i in 0 to 4 loop
					codeword_out(N-1- i) <= DCA(4-i);
			  end loop;
			  
			  for i in 5 to N-1 loop
					codeword_out(N-1- i) <= DCA(i);
			  end loop;
		 end process;


end Behavioral;