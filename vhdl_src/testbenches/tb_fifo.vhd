----------------------------------------------------------------------------
--  FPGA Lab 601 - AXI Stream FIFO
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kendall Farnham
--  Modified: Ben Dobbins
----------------------------------------------------------------------------
--	Description: Testbench for a FIFO 
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity tb_fifo is
end tb_fifo;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture testbench of tb_fifo is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- Constants
constant CLOCK_PERIOD   : time      := 10ns;      -- 100 MHz clock
constant DATA_WIDTH     : integer   := 8;         -- FIFO data width
constant FIFO_DEPTH     : integer   := 10;        -- FIFO depth

----------------------------------------------------------------------------
-- FIFO pointers and signals  
signal fifo_rd_en, fifo_wr_en       : std_logic;
signal full, empty, rd_data_valid   : std_logic;
signal reset, clk                   : std_logic;
signal data_in, data_out            : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

----------------------------------------------------------------------------
-- Simulation Only Signals
signal test_id      : integer := 0;
signal input_reset  : std_logic := '0';

----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------  
component axis_fifo is
    Generic (
        FIFO_DEPTH : integer := FIFO_DEPTH;
        DATA_WIDTH : integer := DATA_WIDTH);
    Port ( 
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        -- Write channel
        wr_en_i     : in std_logic;
        wr_data_i   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Read channel
        rd_en_i     : in std_logic;
        rd_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_valid_o  : out std_logic;
        
        -- Status flags
        empty_o         : out std_logic;
        full_o          : out std_logic);   
end component axis_fifo;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------   
-- FIFO instance
axi_stream_fifo : axis_fifo
    port map ( 
        clk_i => clk,
        reset_i => reset,
        wr_en_i => fifo_wr_en,
        wr_data_i => data_in,
        rd_en_i => fifo_rd_en,
        rd_data_o => data_out,
        rd_valid_o => rd_data_valid,
        empty_o => empty,
        full_o => full);

----------------------------------------------------------------------------   
-- Clock Generation Processes
----------------------------------------------------------------------------  
clock_gen_process : process
begin
	clk <= '0';				    -- start low
	wait for CLOCK_PERIOD/2;
	loop						-- toggle, wait half a clock period, and loop
	  clk <= not(clk);
	  wait for CLOCK_PERIOD/2;
	end loop;
end process clock_gen_process;

----------------------------------------------------------------------------   
-- Generate ADC data
----------------------------------------------------------------------------   
generate_fifo_data : process
begin
    -- Initialize
    data_in <= (others => '0');
    wait until rising_edge(clk);
    loop
        if (input_reset = '1') then
            data_in <= (others => '0');
        elsif (fifo_wr_en = '1') then
            data_in <= std_logic_vector(unsigned(data_in)+1);
        end if;
        wait for CLOCK_PERIOD;
    end loop;
end process generate_fifo_data;


----------------------------------------------------------------------------   
-- Stim process
----------------------------------------------------------------------------  
stim_proc : process
begin
    
    test_id <= 0;
    -- Initialize
    fifo_rd_en <= '0';
    fifo_wr_en <= '0'; 
    
    -- Asynchronous reset
    input_reset     <= '1';
    reset           <= '1'; -- resets FIFO addresses
    wait for 55 ns;
    input_reset     <= '0';
    reset           <= '0';
    
    ----------------------------------------------------------------------------   
    -- Test 1: Try to read the empty FIFO
    ----------------------- ---------------------------------------------------- 
    test_id <= 1;
    -- The expected result is that data_valid is held LOW during this duration.
    
    --ASSERT READ ENABLE:
    wait until rising_edge(clk);
    fifo_wr_en <= '0'; 
    fifo_rd_en <= '1';
    wait for 5*CLOCK_PERIOD;
    
    --DEASSERT READ ENABLE:
    fifo_wr_en <= '0'; 
    fifo_rd_en <= '0';
    wait for 5*CLOCK_PERIOD;
    
    ----------------------------------------------------------------------------   
    -- Test 2: Write FIFO -- check if FULL flag works as expected
    ----------------------------------------------------------------------------  
    test_id <= 2;
    -- The expected result is that once the buffer fills up and the FULL flag
    -- is asserted, new values will stop being written into the FIFO.
    
    wait until rising_edge(clk);
    fifo_wr_en <= '1'; 
    wait for CLOCK_PERIOD*20;
    fifo_wr_en <= '0';

    ----------------------------------------------------------------------------   
    -- Test 3: Read FIFO -- check if EMPTY flag works as expected
    ---------------------------------------------------------------------------- 
    test_id <= 3;
    -- The expected result is that once the EMPTY flag is reasserted, 
    -- data_valid drops LOW again.
    
    wait until rising_edge(clk);
    fifo_rd_en <= '1'; 
    wait for CLOCK_PERIOD*20;
    fifo_rd_en <= '0';
    
    ----------------------------------------------------------------------------   
    -- Test 4: Simultaneous read/write
    ----------------------------------------------------------------------------  
    test_id <= 4;
    -- The expected result is that both read and write can occur simultaneously.
    
    -- Asynchronous reset
    input_reset     <= '1';
    reset           <= '1'; -- resets FIFO addresses
    wait for 55 ns;
    input_reset     <= '0';
    reset           <= '0';
    
    
    wait until rising_edge(clk);
    fifo_wr_en <= '1'; 
    wait for CLOCK_PERIOD;
    fifo_rd_en <= '1'; 
    wait for CLOCK_PERIOD*20;
    fifo_rd_en <= '0'; 
    fifo_wr_en <= '0';
    
    wait for CLOCK_PERIOD*20;
    
    ----------------------------------------------------------------------------   
    -- Test 5: Only fill the buffer part of the way, read out, then fill more
    ----------------------------------------------------------------------------  
    test_id <= 5;
    --The expected result is that the addresses increment independently of each other
    --Fulfilling the idea that we can write in and read out at different rates.

    input_reset     <= '1';
    reset           <= '1'; -- resets FIFO addresses
    wait for 55 ns;
    input_reset     <= '0';
    reset           <= '0';
    
    
    wait until rising_edge(clk);
    fifo_wr_en <= '1'; 
    fifo_rd_en <= '0';
    wait for 5*CLOCK_PERIOD;
    
    fifo_wr_en <= '0'; 
    fifo_rd_en <= '1';
    wait for 3*CLOCK_PERIOD;
    
    fifo_wr_en <= '1'; 
    fifo_rd_en <= '0';
    wait for 4*CLOCK_PERIOD;
    
    fifo_wr_en <= '0'; 
    fifo_rd_en <= '0';
    wait for CLOCK_PERIOD*20;
    
    std.env.stop;

end process;
----------------------------------------------------------------------------

end testbench;