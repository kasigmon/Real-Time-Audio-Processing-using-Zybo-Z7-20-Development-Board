----------------------------------------------------------------------------
--  FPGA Lab 701 - I2S Transmitter
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Transmits bits in complaince with I2S
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity i2s_transmitter is
	Generic ( INPUT_DATA_WIDTH : integer := 24;
	          OUTPUT_DATA_WIDTH : integer := 32);
    Port (  mclk_i 	: in STD_LOGIC; -- Should be 12.288 MHz
            bclk_i 	: in STD_LOGIC; -- Should be 12.288/4 MHz
			pblrc_i : in STD_LOGIC; -- Should be 12.288/256 MHz.
			right_audio_data_i	: in STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0); -- RIGHT data to be transmitted
			left_audio_data_i	: in STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0); -- LEFT data to be transmitted
	
            data_o : out STD_LOGIC -- Data output
         );  
end i2s_transmitter;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of i2s_transmitter is

----------------------------------------------------------------------------
-- Define Components
----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- States for State Machine
type state_type is (LeftChannel, RightChannel, Idle);	
signal curr_state : state_type := Idle;

-- Data Input
signal data_for_stream : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0) := (others => '0');

signal shift_counter : integer := 0;
signal phrase_counter : integer := 0;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------

---------------------------------------------------------------------------
-- CONTROLLER ELEMENT
-- Determine Channel
channel_state : process(pblrc_i)
begin
    if (pblrc_i = '0') then
        curr_state <= LeftChannel; -- LEFT channel
    elsif (pblrc_i = '1') then
        curr_state <= RightChannel; -- RIGHT channel
    end if;
end process channel_state;

-- DATAPATH ELEMENT
-- Acts like a shift register, pumps out what it gets
shift_data : process(bclk_i)
begin
    if falling_edge(bclk_i) then
        -- If we're idle, all values are zero.
        if (curr_state = Idle) then
            data_for_stream <= (others => '0');
        
        -- If we're not idle (outputting left/right channel), then:
        else
            -- For our very first value ("X" - Don't care), we always output a 0.
            if (shift_counter  = 0) then 
                if (curr_state = LeftChannel) then
                    data_for_stream <= left_audio_data_i; -- Left channel data set
                elsif (curr_state = RightChannel) then
                    data_for_stream <= right_audio_data_i; -- Right channel data set
                else
                    data_for_stream <= (others => '0'); -- No data set, all to zero
                end if;    
                
            -- Once we're above value 0, we begin to shift whatever is stored in the data_for_stream signal
            elsif (shift_counter > 0) then
                if (shift_counter < INPUT_DATA_WIDTH) then -- Note that this accounts for the one bit of "0" added on to the front
                    data_for_stream <= data_for_stream(INPUT_DATA_WIDTH-2 downto 0) & data_for_stream(INPUT_DATA_WIDTH-1); -- Shift
                else
                    data_for_stream <= (others => '0'); -- No more data to shift, go to zero   
                end if;
            end if;
        end if;
        
        -- Counting through bits, increment as it makes sense
        if (phrase_counter = OUTPUT_DATA_WIDTH-1) then -- Time to reset phrase
            phrase_counter <= 0;
            shift_counter <= 0;
        else -- We're not done with the phrase
            if (shift_counter < INPUT_DATA_WIDTH) then -- Increment shift counter, accounting for one bit of "0" added to front
                shift_counter <= shift_counter + 1;
            end if;
            phrase_counter <= phrase_counter + 1; -- Increment phrase counter
        end if;
        
    end if;
end process shift_data;

-- Output the last bit            
data_o <= data_for_stream(INPUT_DATA_WIDTH-1);

end Behavioral;