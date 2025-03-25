----------------------------------------------------------------------------
--  FPGA Lab 701 - Audio Codec Passthrough
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Authors: Ben Dobbins and Kendall Farnham
----------------------------------------------------------------------------
--	Description: Testbench for top-level audio codec passthrough
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity tb_top_level is
end tb_top_level;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture testbench of tb_top_level is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- Timing constants
constant CLOCK_PERIOD : time := 8ns;            -- 125 MHz system clock period
constant MCLK_PERIOD : time := 81.38 ns;        -- 12.288 MHz MCLK
constant SAMPLING_FREQ  : real := 48000.00;     -- 48 kHz sampling rate
constant T_SAMPLE : real := 1.0/SAMPLING_FREQ;

-- Input waveform
constant AUDIO_DATA_WIDTH : integer := 24;
constant SINE_FREQ : real := 1000.0;
constant SINE_AMPL  : real := real(2**(AUDIO_DATA_WIDTH-1)-1);

----------------------------------------------------------------------------
-- Signals to hook up to DUT
signal clk : std_logic := '0';
signal mute_en_sw : std_logic;
signal mute_n, bclk, mclk, data_in, data_out, lrclk : std_logic;

----------------------------------------------------------------------------
-- Testbench signals
signal bit_count : integer;
signal sine_data, sine_data_tx : std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');
----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
component top_level is
    Port (
		sysclk_i : in  std_logic;	
		
		-- User controls
		ac_mute_en_i : in STD_LOGIC;
		
		-- Audio Codec I2S controls
        ac_bclk_o : out STD_LOGIC;
        ac_mclk_o : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC;	-- Active Low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i : in STD_LOGIC;
        ac_adc_lrclk_o : out STD_LOGIC);
        
end component;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    
-- DA2 SPI controller
dut : top_level 
    port map (
        sysclk_i => clk,
        ac_mute_en_i => mute_en_sw,
        ac_bclk_o => bclk,
        ac_mclk_o => mclk,
        ac_mute_n_o => mute_n,
        ac_dac_data_o => data_out,
        ac_dac_lrclk_o => open,
        ac_adc_data_i => data_in,
        ac_adc_lrclk_o => lrclk);

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
-- Disable mute
mute_en_sw <= '0';

----------------------------------------------------------------------------
-- Generate input data (stimulus)
----------------------------------------------------------------------------
generate_audio_data: process
    variable t : real := 0.0;
begin		
----------------------------------------------------------------------------
-- Loop forever	
loop	
----------------------------------------------------------------------------
-- Progress one sample through the sine wave:
sine_data <= std_logic_vector(to_signed(integer(SINE_AMPL*sin(math_2_pi*SINE_FREQ*t) ), AUDIO_DATA_WIDTH));

----------------------------------------------------------------------------
-- Take sample
wait until lrclk = '1';
sine_data_tx <= std_logic_vector(unsigned(not(sine_data(AUDIO_DATA_WIDTH-1)) & sine_data(AUDIO_DATA_WIDTH-2 downto 0)));

----------------------------------------------------------------------------
-- Transmit sample to right audio channel
----------------------------------------------------------------------------
bit_count <= AUDIO_DATA_WIDTH-1;            -- Initialize bit counter, send MSB first
for i in 0 to AUDIO_DATA_WIDTH-1 loop
    wait until bclk = '0';
    data_in <= sine_data_tx(bit_count-i);     -- Set input data
end loop;

wait until bclk = '0';
data_in <= '0';
bit_count <= AUDIO_DATA_WIDTH-1;            -- Reset bit counter to MSB

----------------------------------------------------------------------------
--Transmit sample to left audio channel
----------------------------------------------------------------------------
wait until lrclk = '0';
for i in 0 to AUDIO_DATA_WIDTH-1 loop
    wait until bclk = '0';
    data_in <= sine_data_tx(bit_count-i);     -- Set input data
end loop;
data_in <= '0';

----------------------------------------------------------------------------						
--Increment by one sample
t := t + T_SAMPLE;
end loop;
    
end process generate_audio_data;



end testbench;
