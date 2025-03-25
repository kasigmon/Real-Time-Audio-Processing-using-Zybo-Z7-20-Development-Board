----------------------------------------------------------------------------
--  FPGA Lab 701 - AXI Stream Transmitter Interface
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Transmitter for I2S Receiver
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
                                                            
----------------------------------------------------------------------------
-- Entity definition
entity axis_transmitter_interface is
	generic (
		INPUT_DATA_WIDTH	: integer	:= 24;
		OUTPUT_DATA_WIDTH	: integer	:= 32
	);
	port (
		left_audio_data_i : in std_logic_vector(INPUT_DATA_WIDTH-1 downto 0); 
		right_audio_data_i : in std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
		lrclk_i : in std_logic;
		m00_axis_aclk : in std_logic;
		m00_axis_aresetn : in std_logic;
		m00_axis_tready : in std_logic;

		m00_axis_tdata	: out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
		m00_axis_tlast : out std_logic;
		m00_axis_tstrb : out std_logic_vector((OUTPUT_DATA_WIDTH/8)-1 downto 0);
		m00_axis_tvalid : out std_logic
	);
end axis_transmitter_interface;
----------------------------------------------------------------------------
architecture Behavioral of axis_transmitter_interface is
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
-- Process to respond to s00 via handshakes
ready_respond : process(m00_axis_aclk) -- AXI CLOCK
begin
    -- Only operate on the rising edge of the clock
    if rising_edge(m00_axis_aclk) then
       
        -- Always down to take in data if we can
        if (m00_axis_tready = '1') and (m00_axis_aresetn = '1') then
            m00_axis_tvalid <= '1'; 
            if (lrclk_i = '0') then -- LEFT channel
                m00_axis_tdata <= "0" & left_audio_data_i & "0000000"; -- Adding padding
            elsif (lrclk_i = '1') then -- RIGHT channel
                m00_axis_tdata <= "0" & right_audio_data_i & "0000000"; -- Adding padding
            end if;
        else
            m00_axis_tvalid <= '0';
            m00_axis_tdata <= (others => '0');
        end if;      
          
    end if;
end process ready_respond;

m00_axis_tstrb <= "0111"; -- Setting to standard value, this is largely ignored

----------------------------------------------------------------------------   
end Behavioral;