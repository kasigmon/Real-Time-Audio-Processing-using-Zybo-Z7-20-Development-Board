----------------------------------------------------------------------------
--  FPGA Lab 701 - Clock Generator Testbench
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Testbench for clock generator
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity tb_clock_generator is
end tb_clock_generator;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture testbench of tb_clock_generator is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- For simulated clock
constant CLOCK_PERIOD : time := 8ns;  -- system clock period
signal clk : std_logic := '0';
signal test : integer := 0;

-- Values to measure
signal ac_adc_lrclk_o, ac_bclk_o, ac_dac_lrclk_o, ac_mclk_o, mclk_o, unbuffered_clk_reg : stD_logic := '0';
----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Declare components used in the testbench simulation
component clock_generation is
    Port (  sysclk_i : in STD_LOGIC; -- Should be 12.288 MHz
	
            ac_adc_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_bclk_o : out STD_LOGIC; -- Should be MCLK/4
            ac_dac_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_mclk_o : out STD_LOGIC; 
            mclk_o : out STD_LOGIC; -- Should be 12.288 MHz, but with ODDR
			unbuffered_clk_reg : out STD_LOGIC);  -- Should be LRCLOCK without ODDR
end component;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    
-- Shift register instance (and/or datapath/controller)
dut : clock_generation 
    port map (
        sysclk_i => clk,
        
        ac_adc_lrclk_o => ac_adc_lrclk_o,
        ac_bclk_o => ac_bclk_o,
        ac_dac_lrclk_o => ac_dac_lrclk_o,
        ac_mclk_o => ac_mclk_o,
        mclk_o => mclk_o,
        unbuffered_clk_reg => unbuffered_clk_reg);

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


----------------------------------------------------------------------------
-- Stimulus process
----------------------------------------------------------------------------
stim_proc : process
begin

wait for CLOCK_PERIOD*50;

test <= 1;

wait for CLOCK_PERIOD*50;

test <= 2;

wait for CLOCK_PERIOD*25000;

----------------------------------------------------------------------------
-- End of simulation
----------------------------------------------------------------------------
std.env.stop;   -- Stop the simulation

end process stim_proc;

end testbench;