----------------------------------------------------------------------------
--  FPGA Lab 202 - SPI Controller
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Testbench for SPI controller component
--      Uses assert statements to automatically check for correct functionality
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity tb_spi_controller is
end tb_spi_controller;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture testbench of tb_spi_controller is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant CLOCK_PERIOD : time := 8ns;  -- system clock period

constant DEBUG_MODE : std_logic := '1';

-- Update these constants to meet your design specifications
constant CLK_DIV_TC_IMPL : integer := 1250;     -- This will produce a 100 kHz clock signal -- use for implementation
constant CLK_DIV_TC_SIM : integer := 3;         -- Use faster clock for simulation

-- Add constants for defining your components and signal data widths
constant SPI_DATA_WIDTH : integer := 16;
constant DA2_DATA_WIDTH : integer := 12;
constant DATA_WIDTH : integer := SPI_DATA_WIDTH; 
constant RAMP_MAX_VALUE : integer := 2**DA2_DATA_WIDTH-1;
constant TEST_PATTERN : std_logic_vector(DA2_DATA_WIDTH-1 downto 0) := x"542";

-- Set the CLK_DIV_TC constant dynamically from the DEBUG_MODE input
constant CLK_DIV_TC : integer := CLK_DIV_TC_IMPL when DEBUG_MODE = '0' else CLK_DIV_TC_SIM;

----------------------------------------------------------------------------
-- Signals 
signal clk, spi_clk : std_logic := '0';
signal enable : std_logic := '1';
signal data_in : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal data_out, data_out_a_signal, data_out_b_signal : std_logic := '0';
signal spi_sync : std_logic := '1';		
signal spi_channnel_switch : std_logic := '0';

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Add your spi_controller component declaration here 
component da2_controller is
    Generic ( DATA_WIDTH : integer := SPI_DATA_WIDTH);
    Port (  clk_i      :   in STD_LOGIC;
            data_i          :   in std_logic_vector(DATA_WIDTH-1 downto 0);
            enable_i        :   in std_logic;
            select_ab_i     :   in std_logic;
            
            da2_sync_o      :   out std_logic;
            da2_dina_o      :   out std_logic;
            da2_dinb_o      :   out std_logic;
            da2_sclk_o      :   out std_logic);
end component;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    
-- Instantiate/port map your spi_controller component as the DUT
dut : da2_controller 
    port map (
        clk_i => clk,
        data_i => data_in,
        enable_i => enable,
        select_ab_i => spi_channnel_switch,
        da2_sync_o => spi_sync,
        da2_dina_o => data_out_a_signal,
        da2_dinb_o => data_out_b_signal,
        da2_sclk_o => spi_clk);

----------------------------------------------------------------------------   
-- Processes
----------------------------------------------------------------------------   
-- Generate clock        
clock_gen_process : process
begin
	clk <= '0';				-- start low
	wait for CLOCK_PERIOD/2;		-- wait for half a clock period
	loop							-- toggle, and loop
	  clk <= not(clk);
	  wait for CLOCK_PERIOD/2;
	end loop;
end process clock_gen_process;


-- Process to keep data_out consistent
-- This is mostly for testing below - it allows us to simply ask about the accuracy of the data without respect to channel
-- Other testing (e.g., Test 4) is performed to ensure that the correct channels are used
data_out_alive_process : process(spi_channnel_switch, data_out_a_signal, data_out_b_signal) 
begin

    -- If 0, channel A
    if (spi_channnel_switch = '0') then
        data_out <= data_out_a_signal;
    
    -- If 1, channel B
    else
        data_out <= data_out_b_signal;
    end if;
    
end process data_out_alive_process;

----------------------------------------------------------------------------
-- Stimulus process
----------------------------------------------------------------------------
stim_proc : process
begin

----------------------------------------------------------------------------
-- Initialize
enable <= '0';
data_in <= (others => '0');
wait for CLOCK_PERIOD*10;
wait until rising_edge(clk);

-- Start driving data in
data_in <= x"7654";
wait for CLOCK_PERIOD;

----------------------------------------------------------------------------
-- Test 1: Enable the SPI controller
----------------------------------------------------------------------------
wait until rising_edge(clk);
enable <= '1';
wait for CLOCK_PERIOD;

-- Test 1 Autocheck: check if data output is serialized correctly
-- This assumes the spi_sync signal is hooked up to the output signal on your controller
-- Update according to your design
wait until spi_sync = '0';
for i in DATA_WIDTH-1 downto 0 loop
    wait until rising_edge(clk);
    assert data_out = data_in(i) report "Test 1 FAILED: mismatch at bit " & integer'image(i) severity warning;
end loop;
wait until rising_edge(clk);

----------------------------------------------------------------------------
-- Test the opposite to output the message. The sync signal should be HIGH
assert spi_sync = '0' report "Test 1 PASSED" severity note;

----------------------------------------------------------------------------
-- Test 2: Change the input data
----------------------------------------------------------------------------
data_in <= x"F221";

-- Test 2 Autocheck: check if data output is serialized correctly
wait until spi_sync = '1';      -- wait for previous data packet to finish sending
wait until spi_sync = '0';      -- wait until shift reg is loaded with new data
for i in DATA_WIDTH-1 downto 0 loop
    wait until rising_edge(clk);
    assert data_out = data_in(i) report "Test 2 FAILED: mismatch at bit " & integer'image(i) severity warning;
end loop;
wait until rising_edge(clk);

----------------------------------------------------------------------------
-- Test the opposite to output the message. The sync signal should be HIGH
report "Cut here";
assert spi_sync = '0' report "Test 2 PASSED" severity note;
wait for CLOCK_PERIOD;

----------------------------------------------------------------------------
-- Test 3: Disable the SPI controller
----------------------------------------------------------------------------
enable <= '0';
wait for CLOCK_PERIOD;
wait until rising_edge(clk);
for i in DATA_WIDTH-1 downto 0 loop
    wait until rising_edge(clk);
    assert data_out = '0' report "Test 3 FAILED: SPI controller still outputting data" severity warning;
end loop;

assert spi_sync = '0' report "Test 3 PASSED" severity note;
wait for CLOCK_PERIOD;

----------------------------------------------------------------------------
-- Test 4: Change the DAC channel and re-enable the SPI controller
----------------------------------------------------------------------------
wait for CLOCK_PERIOD;
spi_channnel_switch <= '1';
data_in <= x"A123";
wait until rising_edge(clk);
enable <= '1';
wait until rising_edge(clk);
wait until spi_sync = '1';      -- wait for previous data packet to finish sending
wait until spi_sync = '0';      -- wait until shift reg is loaded with new data
for i in DATA_WIDTH-1 downto 0 loop
    wait until rising_edge(clk);
    -- IMPORTANT: Note tht this is concerned with the B signal, now that we specifically care about channel switching.
    assert data_out_b_signal = data_in(i) report "Test 4 FAILED: Channel switch failed" severity warning;
end loop;
wait until rising_edge(clk);

assert spi_sync = '0' report "Test 4 PASSED" severity note;
wait for CLOCK_PERIOD*5;

----------------------------------------------------------------------------
-- End of simulation
----------------------------------------------------------------------------
std.env.stop;   -- Stop the simulation

end process stim_proc;

end testbench;
