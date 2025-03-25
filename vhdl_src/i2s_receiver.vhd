----------------------------------------------------------------------------
--  FPGA Lab 701 - I2S Receiver
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Receives bits in complaince with I2S
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity i2s_receiver is
	Generic ( INPUT_DATA_WIDTH : integer := 24;
	          OUTPUT_DATA_WIDTH : integer := 32);
    Port (  mclk_i 	: in STD_LOGIC; -- Should be 12.288 MHz
            bclk_i 	: in STD_LOGIC; -- Should be 12.288/4 MHz
			pblrc_i : in STD_LOGIC; -- Should be 12.288/256 MHz.
            data_i : in STD_LOGIC; -- Data input, received in serial
            
			right_audio_data_o	: out STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0); -- RIGHT data to be output
			left_audio_data_o	: out STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0) -- LEFT data to be output
         );  
end i2s_receiver;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of i2s_receiver is

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- States for State Machine
type state_type is (LeftChannel, RightChannel);	
signal curr_state : state_type := LeftChannel;

-- Data Input
signal data_received : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0) := (others => '0');

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
        -- If our shift counter is lower than the input data width, and ignoring the first "X" (don't care), move the data into data_received
        if (shift_counter < INPUT_DATA_WIDTH+1) and (shift_counter > 0) then
            data_received(INPUT_DATA_WIDTH - shift_counter) <= data_i; -- Note that we're going "backwards" here as we receive data
        end if;
        
        -- Counting through bits, increment as it makes sense
        if (phrase_counter = OUTPUT_DATA_WIDTH-1) then -- Time to reset phrase
            phrase_counter <= 0;
            shift_counter <= 0;
            --data_received <= (others => '0');
        else -- We're not done with the phrase
            if (shift_counter < INPUT_DATA_WIDTH+1) then -- Increment shift counter, accounting for one bit of "0" added to front
                shift_counter <= shift_counter + 1;
            end if;
            phrase_counter <= phrase_counter + 1; -- Increment phrase counter
        end if;
        
    end if;
end process shift_data;

output_data : process(phrase_counter)
begin
    if (phrase_counter = 0) then
        if (curr_state = LeftChannel) then
            left_audio_data_o <= data_received;
        elsif (curr_state = RightChannel) then
            right_audio_data_o <= data_received;
        end if;
    end if;
end process output_data;

---- Output the values when we have them and we're on the correct channel   
--left_audio_data_o <= data_received when ((curr_state = LeftChannel) and (shift_counter >= INPUT_DATA_WIDTH+1)) else (others => '0');
--right_audio_data_o <= data_received when ((curr_state = RightChannel) and (shift_counter >= INPUT_DATA_WIDTH+1)) else (others => '0');

end Behavioral;