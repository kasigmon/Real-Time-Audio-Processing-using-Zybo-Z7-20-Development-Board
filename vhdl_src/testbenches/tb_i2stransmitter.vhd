----------------------------------------------------------------------------
--  FPGA Lab 701 - I2S Transmitter/Receiver Testbench
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Testbench for I2S Transmitter AND I2S Receiver
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity tb_i2stransmitter is
end tb_i2stransmitter;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture testbench of tb_i2stransmitter is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- For simulated clock
constant CLOCK_PERIOD : time := 8ns;  -- system clock period
signal clk : std_logic := '0';
signal test : integer := 0;

-- Dummy signals
constant INPUT_DATA_WIDTH : integer := 24;
signal left_dummy_value : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0) := x"32141c";
signal right_dummy_value : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0) := x"abc1c1";
signal i2s_data_output : std_logic := '0';

-- Values to measure
signal ac_adc_lrclk_o, ac_bclk_o, ac_dac_lrclk_o, ac_mclk_o, mclk_o, unbuffered_clk_reg : std_logic := '0';

-- Values to evalute from receiver
signal left_audio_data_signal, right_audio_data_signal : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0) := (others => '0');
----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Clock generator
component clock_generation is
    Port (  sysclk_i : in STD_LOGIC; -- Should be 12.288 MHz
	
            ac_adc_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_bclk_o : out STD_LOGIC; -- Should be MCLK/4
            ac_dac_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_mclk_o : out STD_LOGIC; 
            mclk_o : out STD_LOGIC; -- Should be 12.288 MHz, but with ODDR
			unbuffered_clk_reg : out STD_LOGIC);  -- Should be LRCLOCK without ODDR
end component;

-- I2S Transmitter
component i2s_transmitter is
	Generic ( INPUT_DATA_WIDTH : integer := 24;
	          OUTPUT_DATA_WIDTH : integer := 32);
    Port (  mclk_i 	: in STD_LOGIC; -- Should be 12.288 MHz
            bclk_i 	: in STD_LOGIC; -- Should be 12.288/4 MHz
			pblrc_i : in STD_LOGIC; -- Should be 12.288/256 MHz.
			right_audio_data_i	: in STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0); -- RIGHT data to be transmitted
			left_audio_data_i	: in STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0); -- LEFT data to be transmitted
	
            data_o : out STD_LOGIC -- Data output
         );  
end component;

-- I2S Receiver
component i2s_receiver is
	Generic ( INPUT_DATA_WIDTH : integer := 24;
	          OUTPUT_DATA_WIDTH : integer := 32);
    Port (  mclk_i 	: in STD_LOGIC; -- Should be 12.288 MHz
            bclk_i 	: in STD_LOGIC; -- Should be 12.288/4 MHz
			pblrc_i : in STD_LOGIC; -- Should be 12.288/256 MHz.
            data_i : in STD_LOGIC; -- Data input, received in serial
            
			right_audio_data_o	: out STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0); -- RIGHT data to be output
			left_audio_data_o	: out STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0) -- LEFT data to be output
         );  
end component;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    
-- Clock Generator
clockgen : clock_generation 
    port map (
        sysclk_i => clk,
        
        ac_adc_lrclk_o => ac_adc_lrclk_o,
        ac_bclk_o => ac_bclk_o,
        ac_dac_lrclk_o => ac_dac_lrclk_o,
        ac_mclk_o => ac_mclk_o,
        mclk_o => mclk_o,
        unbuffered_clk_reg => unbuffered_clk_reg);

-- I2S Transmitter
i2stransmitter_dut : i2s_transmitter
    port map (
        mclk_i => mclk_o,
        bclk_i => ac_bclk_o,
        pblrc_i => ac_adc_lrclk_o,
        right_audio_data_i => right_dummy_value,
        left_audio_data_i => left_dummy_value,
        
        data_o => i2s_data_output   
    );

-- I2S Receiver
i2sreceiver_dut : i2s_receiver
    port map (
        mclk_i => mclk_o,
        bclk_i => ac_bclk_o,
        pblrc_i => ac_adc_lrclk_o,
        data_i => i2s_data_output,
        
        right_audio_data_o => right_audio_data_signal,
        left_audio_data_o => left_audio_data_signal
    );

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