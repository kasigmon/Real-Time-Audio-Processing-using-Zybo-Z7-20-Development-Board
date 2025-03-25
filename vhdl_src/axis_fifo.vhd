----------------------------------------------------------------------------
--  FPGA Lab 601 - FIFO
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: First In, First Out
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fifo is
Generic (
    FIFO_DEPTH : integer := 1024;
    DATA_WIDTH : integer := 32);
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
end axis_fifo;
----------------------------------------------------------------------------
architecture Behavioral of axis_fifo is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- This is our table of values
type stored_data_item is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal fifo_registry : stored_data_item := (others => (others => '0'));

-- Signals for full, empty
signal full_signal, empty_signal : std_logic := '0';

-- These are our indexes, all instantialize at 0
signal write_index, read_index : integer range 0 to FIFO_DEPTH-1 := 0;

-- These are our values for output
signal data_to_read : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

-- This is our word count
signal fifo_count : integer range 0 to FIFO_DEPTH-1 := 0;
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------

empty_o <= empty_signal;
full_o <= full_signal;

-- Everything in a single process to avoid multiple writes
fifo_process : process (clk_i)
begin
    if rising_edge(clk_i) then
    
        -- RESETTING
        if (reset_i = '1') then
            write_index <= 0;
            full_signal <= '0';
            fifo_count <= 0;
        else
            
            -- WRITING
            if (wr_en_i = '1' and full_signal = '0') then
                
                -- Write to the registry
                fifo_registry(write_index) <= wr_data_i;
                write_index <= (write_index + 1) mod FIFO_DEPTH;
                
                -- Increment the FIFO counter of words if writing
                if (fifo_count < FIFO_DEPTH) then
                    fifo_count <= fifo_count + 1;
                end if;
                
            end if;
            
            -- READING
            if (rd_en_i = '1' and empty_signal = '0') then
            
                -- Read from the registry
                rd_data_o <= fifo_registry(read_index);
                read_index <= (read_index + 1) mod FIFO_DEPTH;
                
                -- Decrement the FIFO Counter of words if reading
                if (fifo_count > 0) then
                    fifo_count <= fifo_count - 1;
                end if; 
            end if;
        
            -- Handling for if we're full
            if (fifo_count = FIFO_DEPTH) then
                full_signal  <= '1';
            else
                full_signal  <= '0';
            end if;
            
            -- Handling for if we're empty AND receiving no words
            if (fifo_count = 0) and (wr_en_i = '0') then
                empty_signal <= '1';
            else
                empty_signal <= '0';            
            end if;
            
        end if;
    end if;
end process fifo_process;

---- Read data from appropriate index 
--rd_data_o <= data_to_read;

---- Basic signals - full, empty, valid
--empty_signal <= '1' when (fifo_count = 0) and (wr_en_i = '0') and (reset_i = '0') else '0';
--full_signal <= '1' when (fifo_count = FIFO_DEPTH-1) else '0';
--rd_valid_o <= '1' when (fifo_count > 0) and (reset_i = '0') else '0';

--empty_o <= empty_signal;
--full_o <= full_signal;

---- Process for monitoring the FIFO count
--fifo_read : process(clk_i)
--begin
--    -- Only operate on the rising edge of the clock
--    if rising_edge(clk_i) then
--        -- If we reset, all goes to zero
--        if (reset_i = '1') then
--            fifo_count <= 0;
--            write_index <= 0;
--            read_index <= 0;
--        else 
            
--            -- Only write if prompted
--            if (wr_en_i = '1') then
--                -- Refuse to write if full
--                if (full_signal = '0') then
--                    -- Write to registry
--                    fifo_registry(write_index) <= wr_data_i;
            
--                    -- Write index logic, including rollover handling
--                    if (write_index = FIFO_DEPTH-1) then
--                        write_index <= 0;
--                    else
--                        write_index <= write_index + 1;
--                    end if;
--                end if;
--            end if;
            
--            -- Only take in new data if enabled to do so
--            if (rd_en_i = '1') and (empty_signal = '0') then
                
--                -- Read index logic, including rollover handling
--                if (read_index = FIFO_DEPTH-1) then
--                    read_index <= 0;
--                else
--                    read_index <= read_index + 1;
--                end if;
                
--                data_to_read <= fifo_registry(read_index);
                
--            end if;
            
--            -- Manage our word count
--            -- This is where we're writing but not reading
--            if (fifo_count < FIFO_DEPTH-1) and (rd_en_i = '0') and (wr_en_i = '1') then
--                fifo_count <= fifo_count + 1;
--            -- Reading, but not writing
--            elsif (fifo_count > 0) and (rd_en_i = '1') and (wr_en_i = '0') then
--                fifo_count <= fifo_count - 1;   
--            end if;
--        end if;
--    end if;
--end process fifo_read;

----------------------------------------------------------------------------
----------------------------------------------------------------------------   
end Behavioral;