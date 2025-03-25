----------------------------------------------------------------------------
--  FPGA Lab 701 - AXI Stream Receiver Interface
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Stream Receiver for I2S Transmitter
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
                                                            
----------------------------------------------------------------------------
-- Entity definition
entity axis_receiver_interface is
	generic (
		INPUT_DATA_WIDTH	: integer	:= 32;
		OUTPUT_DATA_WIDTH   : integer   := 24
	);
	port (
		lrclk_i	       : in std_logic;
		s00_axis_aclk  : in std_logic;
		s00_axis_aresetn : in std_logic; 
		s00_axis_tdata : in std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
		s00_axis_tlast    : in std_logic; -- Don't care
		s00_axis_tstrb : in std_logic_vector((INPUT_DATA_WIDTH/8)-1 downto 0);  -- Don't care
		s00_axis_tvalid : in std_logic;

		left_audio_data_o : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
		right_audio_data_o : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
		s00_axis_tready   : out std_logic
	);
end axis_receiver_interface;
----------------------------------------------------------------------------
architecture Behavioral of axis_receiver_interface is
----------------------------------------------------------------------------------
-- Define constants
----------------------------------------------------------------------------------

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    

----------------------------------------------------------------------------
-- Process to handle AXI handshake
ready_respond : process(s00_axis_aclk)
begin
    -- Only operate on the rising edge of the clock
    if rising_edge(s00_axis_aclk) then
       
        -- Always down to take in data if we can (valid data, no reset)
        if (s00_axis_tvalid = '1') and (s00_axis_aresetn = '1') then
            s00_axis_tready <= '1'; 
            if (lrclk_i = '0') then -- LEFT channel
                left_audio_data_o <= s00_axis_tdata(30 downto 7); -- Note that we don't care about the padding bits
                right_audio_data_o <= (others => '0');
            elsif (lrclk_i = '1') then -- RIGHT channel
                left_audio_data_o <= (others => '0');
                right_audio_data_o <= s00_axis_tdata(30 downto 7); -- Note that we don't care about the padding bits
            end if;
        else
            -- Nothing to transmit, so we go to zero on all relevant outputs
            s00_axis_tready <= '0';
            left_audio_data_o <= (others => '0');
            right_audio_data_o <= (others => '0');
        end if;      
          
    end if;
end process ready_respond;

----------------------------------------------------------------------------   
end Behavioral;