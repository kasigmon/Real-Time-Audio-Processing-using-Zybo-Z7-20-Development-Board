----------------------------------------------------------------------------
--  FPGA Lab 901 - Filter Wrapper
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Implements one of four audio filters with AXI
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity filter_wrapper is
	generic (
		INPUT_DATA_WIDTH	: integer	:= 32;
		FILTER_DATA_WIDTH : integer := 24
	);
    Port (  s00_axis_aclk : in STD_LOGIC;
            m00_axis_aclk : in STD_LOGIC; -- Same as above
            filter_select_i : in STD_LOGIC_VECTOR(2 downto 0);
            lrclk_i : in STD_LOGIC;
            s00_axis_tdata : in STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0);
            m00_axis_tready : in STD_LOGIC;
            s00_axis_tvalid : in STD_LOGIC;
            
            m00_axis_tdata : out STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0);
            m00_axis_tvalid : out STD_LOGIC;
            s00_axis_tready : out STD_LOGIC
    );            
end filter_wrapper;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of filter_wrapper is

----------------------------------------------------------------------------
-- Define Components
----------------------------------------------------------------------------
-- FIRST Filter (BPF)
COMPONENT fir_compiler_0
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
  );
END COMPONENT;

-- SECOND Filter (BSF)
COMPONENT fir_compiler_1
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
  );
END COMPONENT;

-- THIRD Filter (HPF)
COMPONENT fir_compiler_2
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
  );
END COMPONENT;

-- FOURTH Filter (LPF)
COMPONENT fir_compiler_3
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
  );
END COMPONENT;

-- AXI Stream Receiver
component axis_receiver_interface is
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
end component;

-- AXI Stream Transmitter
component axis_transmitter_interface is
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
end component;

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- Input and output signals for each filter
-- This, while a bit lengthy, allows us to completely cut off filters using the below process, avoiding any unexpected performance by a non-selected filter
signal data_output_signal_filtera_l, data_output_signal_filterb_l, data_output_signal_filterc_l, data_output_signal_filterd_l : STD_LOGIC_VECTOR(FILTER_DATA_WIDTH-1 downto 0) := (others => '0');
signal data_output_signal_filtera_r, data_output_signal_filterb_r, data_output_signal_filterc_r, data_output_signal_filterd_r : STD_LOGIC_VECTOR(FILTER_DATA_WIDTH-1 downto 0) := (others => '0');
signal m_tvalid_filtera_l, m_tvalid_filterb_l,  m_tvalid_filterc_l,  m_tvalid_filterd_l : STD_LOGIC := '0';
signal m_tready_filtera_l, m_tready_filterb_l,  m_tready_filterc_l,  m_tready_filterd_l : STD_LOGIC := '0';
signal s_tvalid_filtera_l, s_tvalid_filterb_l,  s_tvalid_filterc_l,  s_tvalid_filterd_l : STD_LOGIC := '0';
signal s_tready_filtera_l, s_tready_filterb_l,  s_tready_filterc_l,  s_tready_filterd_l : STD_LOGIC := '0';
signal m_tvalid_filtera_r, m_tvalid_filterb_r,  m_tvalid_filterc_r,  m_tvalid_filterd_r : STD_LOGIC := '0';
signal m_tready_filtera_r, m_tready_filterb_r,  m_tready_filterc_r,  m_tready_filterd_r : STD_LOGIC := '0';
signal s_tvalid_filtera_r, s_tvalid_filterb_r,  s_tvalid_filterc_r,  s_tvalid_filterd_r : STD_LOGIC := '0';
signal s_tready_filtera_r, s_tready_filterb_r,  s_tready_filterc_r,  s_tready_filterd_r : STD_LOGIC := '0';

-- We don't care about the AXI signals TSTRB or TLAST, so we set them by default
signal axis_tstrb : STD_LOGIC_VECTOR(3 downto 0) := (others => '1');
signal tlast_signal : STD_LOGIC := '0';

-- Left/Right Data Signals
-- These are signals that either hold (1) received data from the AXI receiver or (2) data to be transmitted via the AXI transmitter
signal left_audio_data_o_signal_received, left_audio_data_o_signal_tooutput, right_audio_data_o_signal_received, right_audio_data_o_signal_tooutput : std_logic_vector(FILTER_DATA_WIDTH-1 downto 0) := (others => '0');

----------------------------------------------------------------------------
begin


----------------------------------------------------------------------------
-- COMPONENT WIRING
--------------------------------------------------------------------------
-- AXI Stream Receiver
axis_receiver : axis_receiver_interface
    port map(
		lrclk_i	        => lrclk_i,
		
		s00_axis_aclk  => s00_axis_aclk,
		s00_axis_aresetn => '1',
		s00_axis_tdata => s00_axis_tdata, -- Input data
		s00_axis_tvalid => s00_axis_tvalid, -- INPUT as part of receipt of data, straight out of element
		s00_axis_tready   => s00_axis_tready, -- OUTPUT as part of receipt of data, straight out of element
		s00_axis_tstrb => axis_tstrb,-- Don't care
		s00_axis_tlast    => tlast_signal, -- Don't care
		
		left_audio_data_o => left_audio_data_o_signal_received,
		right_audio_data_o => right_audio_data_o_signal_received
    );

-- AXI Stream Transmitter
axis_transmitter : axis_transmitter_interface
    port map(
		left_audio_data_i => left_audio_data_o_signal_tooutput, -- Left channel data
		right_audio_data_i => right_audio_data_o_signal_tooutput, -- Right channel data
		lrclk_i => lrclk_i, -- L/R clock
		m00_axis_aclk => m00_axis_aclk, -- Clock
		m00_axis_aresetn => '1', -- No reset

		m00_axis_tdata => m00_axis_tdata, -- Output data
		m00_axis_tlast => tlast_signal, -- Don't care
		m00_axis_tstrb => axis_tstrb, -- Don't care
		m00_axis_tvalid => m00_axis_tvalid, -- OUTPUT ready to send data, straight out of element
		m00_axis_tready => m00_axis_tready -- INPUT for indicating ready to receive data, straight out of element
    );

-- FIRST Filter (BPF) LEFT CHANNEL
filter_1_bpf_l : fir_compiler_0
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filtera_l, -- Input to receive valid signal
    s_axis_data_tready => s_tready_filtera_l, -- Output indicating ready
    s_axis_data_tdata => left_audio_data_o_signal_received, -- Push 24-bit data to left channel
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filtera_l, -- Output indicating ready to send
    m_axis_data_tready => m_tready_filtera_l, -- Input indicating source ready
    m_axis_data_tdata => data_output_signal_filtera_l -- Data to send
  );

-- FIRST Filter (BPF) RIGHT CHANNEL
filter_1_bpf_r : fir_compiler_0
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filtera_r,
    s_axis_data_tready => s_tready_filtera_r,
    s_axis_data_tdata => right_audio_data_o_signal_received,
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filtera_r,
    m_axis_data_tready => m_tready_filtera_r,
    m_axis_data_tdata => data_output_signal_filtera_r
  );

-- SECOND Filter (BSF) LEFT CHANNEL
filter_2_bsf_l : fir_compiler_1
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filterb_l, -- Input to receive valid signal
    s_axis_data_tready => s_tready_filterb_l, -- Output indicating ready
    s_axis_data_tdata => left_audio_data_o_signal_received, -- Push 24-bit data to left channel
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filterb_l, -- Output indicating ready to send
    m_axis_data_tready => m_tready_filterb_l, -- Input indicating source ready
    m_axis_data_tdata => data_output_signal_filterb_l -- Data to send
  );

-- SECOND Filter (BSF) RIGHT CHANNEL
filter_2_bsf_r : fir_compiler_1
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filterb_r,
    s_axis_data_tready => s_tready_filterb_r,
    s_axis_data_tdata => right_audio_data_o_signal_received,
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filterb_r,
    m_axis_data_tready => m_tready_filterb_r,
    m_axis_data_tdata => data_output_signal_filterb_r
  );

-- THIRD Filter (HPF) LEFT CHANNEL
filter_3_hpf_l : fir_compiler_2
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filterc_l, -- Input to receive valid signal
    s_axis_data_tready => s_tready_filterc_l, -- Output indicating ready
    s_axis_data_tdata => left_audio_data_o_signal_received, -- Push 24-bit data to left channel
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filterc_l, -- Output indicating ready to send
    m_axis_data_tready => m_tready_filterc_l, -- Input indicating source ready
    m_axis_data_tdata => data_output_signal_filterc_l -- Data to send
  );

-- THIRD Filter (HPF) RIGHT CHANNEL
filter_3_hpf_r : fir_compiler_2
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filterc_r,
    s_axis_data_tready => s_tready_filterc_r,
    s_axis_data_tdata => right_audio_data_o_signal_received,
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filterc_r,
    m_axis_data_tready => m_tready_filterc_r,
    m_axis_data_tdata => data_output_signal_filterc_r
  );

-- FOURTH Filter (LPF) LEFT CHANNEL
filter_4_lpf_l : fir_compiler_3
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filterd_l, -- Input to receive valid signal
    s_axis_data_tready => s_tready_filterd_l, -- Output indicating ready
    s_axis_data_tdata => left_audio_data_o_signal_received, -- Push 24-bit data to left channel
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filterd_l, -- Output indicating ready to send
    m_axis_data_tready => m_tready_filterd_l, -- Input indicating source ready
    m_axis_data_tdata => data_output_signal_filterd_l -- Data to send
  );

-- FOURTH Filter (LPF) RIGHT CHANNEL
filter_4_lpf_r : fir_compiler_3
  PORT MAP (
    -- Clock
    aclk => s00_axis_aclk,
    
    -- RECEIPT Components
    s_axis_data_tvalid => s_tvalid_filterd_r,
    s_axis_data_tready => s_tready_filterd_r,
    s_axis_data_tdata => right_audio_data_o_signal_received,
    
    -- TRANSMITTING Components
    m_axis_data_tvalid => m_tvalid_filterd_r,
    m_axis_data_tready => m_tready_filterd_r,
    m_axis_data_tdata => data_output_signal_filterd_r
  );
--------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------
-- Filter selection logic
filter_select : process(filter_select_i)
begin
    -- The selection of a filter is wholly based on the filter_select_i signal, which is itself driven by three upper board switches
    -- FIRST Filter (BPF)
    if (filter_select_i = "011") then
    
        -- Assert valid data to be received
        s_tvalid_filtera_l <= '1';
        s_tvalid_filtera_r <= '1';
        
        -- Initiate ready to receive output
        m_tready_filtera_l <= '1';
        m_tready_filtera_r <= '1';
        
        -- Condition data receipt upon confirmation of TREADY for AXI
        if (s_tready_filtera_l = '1') then
            left_audio_data_o_signal_tooutput <= data_output_signal_filtera_l;
        end if;
        
        if (s_tready_filtera_r = '1') then
            right_audio_data_o_signal_tooutput <= data_output_signal_filtera_r;
        end if;

    -- SECOND Filter (BSF)
    elsif (filter_select_i = "100") then
    
        -- Assert valid data to be received
        s_tvalid_filterb_l <= '1';
        s_tvalid_filterb_r <= '1';
        
        -- Initiate ready to receive output
        m_tready_filterb_l <= '1';
        m_tready_filterb_r <= '1';
        
        -- Condition data receipt upon confirmation of TREADY for AXI
        if (s_tready_filterb_l = '1') then
            left_audio_data_o_signal_tooutput <= data_output_signal_filterb_l;
        end if;
        
        if (s_tready_filterb_r = '1') then
            right_audio_data_o_signal_tooutput <= data_output_signal_filterb_r;
        end if;
    
    -- THIRD Filter (HPF)
    elsif (filter_select_i = "010") then
    
        -- Assert valid data to be received
        s_tvalid_filterc_l <= '1';
        s_tvalid_filterc_r <= '1';
        
        -- Initiate ready to receive output
        m_tready_filterc_l <= '1';
        m_tready_filterc_r <= '1';
        
        -- Condition data receipt upon confirmation of TREADY for AXI
        if (s_tready_filterc_l = '1') then
            left_audio_data_o_signal_tooutput <= data_output_signal_filterc_l;
        end if;
        
        if (s_tready_filterb_r = '1') then
            right_audio_data_o_signal_tooutput <= data_output_signal_filterc_r;
        end if;
        
    -- FOURTH Filter (LPF)
    elsif (filter_select_i = "001") then
    
        -- Assert valid data to be received
        s_tvalid_filterd_l <= '1';
        s_tvalid_filterd_r <= '1';
        
        -- Initiate ready to receive output
        m_tready_filterd_l <= '1';
        m_tready_filterd_r <= '1';
        
        -- Condition data receipt upon confirmation of TREADY for AXI
        if (s_tready_filterd_l = '1') then
            left_audio_data_o_signal_tooutput <= data_output_signal_filterd_l;
        end if;
        
        if (s_tready_filterb_r = '1') then
            right_audio_data_o_signal_tooutput <= data_output_signal_filterd_r;
        end if;
        
     -- Default Operation - no filter, just pass through the audio
     else
        left_audio_data_o_signal_tooutput <= left_audio_data_o_signal_received;
        right_audio_data_o_signal_tooutput <= right_audio_data_o_signal_received;    
    end if;
end process filter_select;

--------------------------------------------------------------------------

end Behavioral;