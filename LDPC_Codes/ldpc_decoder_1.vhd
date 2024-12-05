library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ldpc_decoder_1 is
    generic (
        N : integer := 20;  -- Codeword length
        K : integer := 5;   -- Message length
        WC : integer := 3;  -- Column weight
        WR : integer := 4   -- Row weight
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        codeword_in : in std_logic_vector(N-1 downto 0);
        start_decode : in std_logic;
        message_out : out std_logic_vector(K-1 downto 0);
        valid_out : out std_logic;
        error_detected : out std_logic;
        error_corrected : out std_logic;
        uncorrectable_error : out std_logic
    );
end ldpc_decoder_1;

architecture Behavioral of ldpc_decoder_1 is
    -- Type definitions for matrices and arrays
    type h_matrix is array (0 to N-K-1, 0 to N-1) of std_logic;
    type syndrome_array is array (0 to N-K-1) of std_logic;
    type bit_reliability is array (0 to N-1) of integer range -WC to WC;
    type error_count_array is array (0 to N-1) of integer range 0 to WC;
    type message_positions is array (0 to K-1) of integer range 0 to N-1;
    
    -- State machine states
    type decoder_state is (
        IDLE,
        INIT_MATRIX,
        LOAD_CODEWORD,
        CALC_SYNDROME,
        UPDATE_RELIABILITY,
        FLIP_BITS,
        CHECK_CONVERGENCE,
        OUTPUT_RESULT
    );
    
    -- Control signals
    signal state : decoder_state := IDLE;
    signal iteration_count : integer range 0 to 50 := 0;
    signal matrix_initialized : std_logic := '0';
    signal error_count : integer range 0 to N := 0;
    
    -- Data storage signals
    signal H : h_matrix := (others => (others => '0'));
    signal current_codeword : std_logic_vector(N-1 downto 0);
    signal next_codeword : std_logic_vector(N-1 downto 0);
    signal decoded_codeword : std_logic_vector(N-1 downto 0);
    signal syndromes : syndrome_array := (others => '0');
    signal bit_scores : bit_reliability := (others => 0);
    signal error_counts : error_count_array := (others => 0);
    signal message_pos : message_positions;
    
    -- Constants
    constant MAX_ITERATIONS : integer := 20;
    constant ERROR_THRESHOLD : integer := WC/2;
    constant MAX_ERRORS : integer := (N-K)/2;  -- Maximum correctable errors
    
    -- Function to calculate syndrome for a given check equation
    function calculate_syndrome(
        word : std_logic_vector;
        row : integer;
        h_mat : h_matrix
    ) return std_logic is
        variable result : std_logic := '0';
    begin
        for i in 0 to N-1 loop
            if h_mat(row, i) = '1' then
                result := result xor word(i);
            end if;
        end loop;
        return result;
    end function;
    
    -- Function to check if all syndromes are zero
    function check_all_syndromes_zero(
        syn : syndrome_array
    ) return boolean is
    begin
        for i in syn'range loop
            if syn(i) = '1' then
                return false;
            end if;
        end loop;
        return true;
    end function;

    -- Function to identify systematic positions
    function get_systematic_positions(h_mat : h_matrix) return message_positions is
        variable pos : message_positions;
        variable count : integer := 0;
    begin
        for col in N-K to N-1 loop  -- Check systematic part (last K columns)
            pos(count) := col;
            count := count + 1;
        end loop;
        return pos;
    end function;

begin
    -- Main state machine process
    process(clk, reset)
        variable any_bit_flipped : boolean;
        variable all_syndromes_zero : boolean;
        variable total_errors : integer;
    begin
        if reset = '1' then
            state <= IDLE;
            valid_out <= '0';
            error_detected <= '0';
            error_corrected <= '0';
            uncorrectable_error <= '0';
            iteration_count <= 0;
            matrix_initialized <= '0';
            current_codeword <= (others => '0');
            next_codeword <= (others => '0');
            decoded_codeword <= (others => '0');
            bit_scores <= (others => 0);
            error_counts <= (others => 0);
            error_count <= 0;
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start_decode = '1' then
                        if matrix_initialized = '0' then
                            state <= INIT_MATRIX;
                        else
                            state <= LOAD_CODEWORD;
                        end if;
                        valid_out <= '0';
                        error_detected <= '0';
                        error_corrected <= '0';
                        uncorrectable_error <= '0';
                        iteration_count <= 0;
                        error_count <= 0;
                    end if;

                when INIT_MATRIX =>
                    -- Initialize systematic H matrix
                    -- First, set the systematic part (identity matrix in the last K columns)
                    for i in 0 to N-K-1 loop
                        for j in 0 to N-1 loop
                            H(i,j) <= '0';  -- Clear all entries first
                        end loop;
                    end loop;

                    -- Set the parity check connections
                    for i in 0 to N-K-1 loop
                        -- Set WR-1 random connections in the parity part
                        for j in 0 to WR-2 loop
                            H(i, (i + j) mod (N-K)) <= '1';
                        end loop;
                        -- Set one connection to systematic part
                        H(i, N-K + (i mod K)) <= '1';
                    end loop;
                    
                    -- Initialize message positions
                    message_pos <= get_systematic_positions(H);
                    matrix_initialized <= '1';
                    state <= LOAD_CODEWORD;

                when LOAD_CODEWORD =>
                    current_codeword <= codeword_in;
                    next_codeword <= codeword_in;
                    decoded_codeword <= codeword_in;
                    bit_scores <= (others => 0);
                    error_counts <= (others => 0);
                    state <= CALC_SYNDROME;

                when CALC_SYNDROME =>
                    total_errors := 0;
                    -- Calculate syndromes and count errors
                    for i in 0 to N-K-1 loop
                        syndromes(i) <= calculate_syndrome(current_codeword, i, H);
                        if calculate_syndrome(current_codeword, i, H) = '1' then
                            total_errors := total_errors + 1;
                        end if;
                    end loop;
                    
                    error_count <= total_errors;
                    
                    if total_errors = 0 then
                        state <= OUTPUT_RESULT;
                    elsif total_errors > MAX_ERRORS then
                        uncorrectable_error <= '1';
                        state <= OUTPUT_RESULT;
                    else
                        error_detected <= '1';
                        state <= UPDATE_RELIABILITY;
                    end if;

                when UPDATE_RELIABILITY =>
                    -- Update bit reliability scores based on failed checks
                    for i in 0 to N-1 loop
                        error_counts(i) <= 0;
                        for j in 0 to N-K-1 loop
                            if H(j, i) = '1' and syndromes(j) = '1' then
                                error_counts(i) <= error_counts(i) + 1;
                            end if;
                        end loop;
                    end loop;
                    
                    state <= FLIP_BITS;

                when FLIP_BITS =>
                    any_bit_flipped := false;
                    next_codeword <= current_codeword;
                    
                    -- Flip bits that participate in too many failed checks
                    for i in 0 to N-1 loop
                        if error_counts(i) > ERROR_THRESHOLD then
                            next_codeword(i) <= not current_codeword(i);
                            any_bit_flipped := true;
                        end if;
                    end loop;
                    
                    if any_bit_flipped then
                        if iteration_count < MAX_ITERATIONS then
                            current_codeword <= next_codeword;
                            iteration_count <= iteration_count + 1;
                            state <= CALC_SYNDROME;
                        else
                            uncorrectable_error <= '1';
                            state <= OUTPUT_RESULT;
                        end if;
                    else
                        state <= CHECK_CONVERGENCE;
                    end if;

                when CHECK_CONVERGENCE =>
                    all_syndromes_zero := check_all_syndromes_zero(syndromes);
                    
                    if all_syndromes_zero then
                        error_corrected <= '1';
                        decoded_codeword <= current_codeword;
                    else
                        uncorrectable_error <= '1';
                    end if;
                    
                    state <= OUTPUT_RESULT;

                when OUTPUT_RESULT =>
                    -- Extract message from systematic positions
                    for i in 0 to K-1 loop
                        message_out(i) <= decoded_codeword(message_pos(i));
                    end loop;
                    
                    valid_out <= '1';
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;