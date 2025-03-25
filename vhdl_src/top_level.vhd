----------------------------------------------------------------------------
--  FPGA Lab 701 - I2S Top Level
----------------------------------------------------------------------------
-- 	MECE ENGG 463
--	Author: Kirk Sigmon
----------------------------------------------------------------------------
--	Description: Top-level file - I2S Receiver and clock generator to transmitter
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
                                                            
----------------------------------------------------------------------------
-- Entity definition
entity top_level is
    Port ( 
        sysclk_i      : in  std_logic;                        -- 125 MHz system clock
        
        -- User controls
        ac_mute_en_i : in STD_LOGIC;
        
        -- Audo Codec I2S Controls
        ac_bclk_o : out STD_LOGIC;
        ac_mclk_o : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC; -- Active low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i : in STD_LOGIC;
        ac_adc_lrclk_o : out STD_LOGIC;
        
        -- AXI Stuff
        s00_axis_aclk : in STD_LOGIC;
        s00_axis_aresetn : in STD_LOGIC;
        s00_axis_tdata : in std_logic_vector(31 downto 0);       
        s00_axis_tlast : in STD_LOGIC;
        s00_axis_tstrb : in std_logic_vector (3 downto 0);
        s00_axis_tvalid : in STD_LOGIC;
        
        s00_axis_tready : out STD_LOGIC;
        
        m00_axis_aclk : in STD_LOGIC;
        m00_axis_aresetn : in STD_LOGIC;
        m00_axis_tready : in STD_LOGIC;
        
        m00_axis_tdata : out std_logic_vector(31 downto 0);
        m00_axis_tlast : out STD_LOGIC;
        m00_axis_tstrb : out std_logic_vector(3 downto 0);
        m00_axis_tvalid : out STD_LOGIC;
        
        unbuffered_lrclk : out STD_LOGIC
        );
end top_level;
----------------------------------------------------------------------------
architecture Behavioral of top_level is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant INPUT_DATA_WIDTH_CONST : integer := 24;	-- 24-bit signals
constant OUTPUT_DATA_WIDTH_CONST : integer := 32;	-- 32-bit phrases


-- Various clock values
signal ac_adc_lrclk_o_signal, ac_dac_lrclk_o_signal, ac_mclk_o_signal, mclk_o_signal, unbuffered_clk_reg_signal, buffered_bclk, unbuffered_bclk : std_logic := '0';

-- Left/Right Data Signals
signal left_audio_data_o_signal, left_audio_data_o_signal_fromreceiver, right_audio_data_o_signal, right_audio_data_o_signal_fromreceiver : std_logic_vector(INPUT_DATA_WIDTH_CONST-1 downto 0) := (others => '0');

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Clock generator
component clock_generation is
    Port (  sysclk_i : in STD_LOGIC; -- Should be 12.288 MHz
	
            ac_adc_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_bclk_o : out STD_LOGIC; -- Should be MCLK/4
            bclk_o : out STD_LOGIC; -- Unbuffered BCLK
            ac_dac_lrclk_o : out STD_LOGIC; -- Should be BCLK/64 or MCLK/256
            ac_mclk_o : out STD_LOGIC; 
            mclk_o : out STD_LOGIC; -- Should be 12.288 MHz, but with ODDR
			unbuffered_clk_reg : out STD_LOGIC);  -- Should be LRCLOCK without ODDR
end component;

-- I2S Transmitter
component i2s_transmitter is
	Generic ( INPUT_DATA_WIDTH : integer := INPUT_DATA_WIDTH_CONST;
	          OUTPUT_DATA_WIDTH : integer := OUTPUT_DATA_WIDTH_CONST);
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
	Generic ( INPUT_DATA_WIDTH : integer := INPUT_DATA_WIDTH_CONST;
	          OUTPUT_DATA_WIDTH : integer := OUTPUT_DATA_WIDTH_CONST);
    Port (  mclk_i 	: in STD_LOGIC; -- Should be 12.288 MHz
            bclk_i 	: in STD_LOGIC; -- Should be 12.288/4 MHz
			pblrc_i : in STD_LOGIC; -- Should be 12.288/256 MHz.
            data_i : in STD_LOGIC; -- Data input, received in serial
            
			right_audio_data_o	: out STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0); -- RIGHT data to be output
			left_audio_data_o	: out STD_LOGIC_VECTOR(INPUT_DATA_WIDTH-1 downto 0) -- LEFT data to be output
         );  
end component;

-- AXI Stream Receiver
component axis_receiver_interface is
	generic (
		INPUT_DATA_WIDTH	: integer	:= OUTPUT_DATA_WIDTH_CONST;
		OUTPUT_DATA_WIDTH   : integer   := INPUT_DATA_WIDTH_CONST
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
		INPUT_DATA_WIDTH	: integer	:= INPUT_DATA_WIDTH_CONST;
		OUTPUT_DATA_WIDTH	: integer	:= OUTPUT_DATA_WIDTH_CONST
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
begin
----------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------- 
-- Clock wizard
i2s_clock_gen : clock_generation
    port map (
        sysclk_i => sysclk_i,
        
        ac_adc_lrclk_o => ac_adc_lrclk_o_signal,
        ac_bclk_o => buffered_bclk,
        bclk_o => unbuffered_bclk,
        ac_dac_lrclk_o => ac_dac_lrclk_o_signal,
        ac_mclk_o => ac_mclk_o_signal,
        mclk_o => mclk_o_signal,
        unbuffered_clk_reg => unbuffered_clk_reg_signal
    );

-- I2S Transmitter
audio_transmitter : i2s_transmitter
    port map (
        mclk_i => mclk_o_signal,
        bclk_i => unbuffered_bclk,
        pblrc_i => unbuffered_clk_reg_signal,
        right_audio_data_i => right_audio_data_o_signal,
        left_audio_data_i => left_audio_data_o_signal,
        
        data_o => ac_dac_data_o   
    );

-- I2S Receiver
audio_receiver : i2s_receiver
    port map (
        mclk_i => mclk_o_signal,
        bclk_i => unbuffered_bclk,
        pblrc_i => unbuffered_clk_reg_signal,
        data_i => ac_adc_data_i,
        
        right_audio_data_o => right_audio_data_o_signal_fromreceiver,
        left_audio_data_o => left_audio_data_o_signal_fromreceiver
    );

-- AXI Stream Receiver
axis_receiver : axis_receiver_interface
    port map(
		lrclk_i	        => unbuffered_clk_reg_signal,
		s00_axis_aclk  => s00_axis_aclk,
		s00_axis_aresetn => s00_axis_aresetn,
		s00_axis_tdata => s00_axis_tdata,
		s00_axis_tlast    => s00_axis_tlast,
		s00_axis_tstrb => s00_axis_tstrb,
		s00_axis_tvalid => s00_axis_tvalid,

		left_audio_data_o => left_audio_data_o_signal,
		right_audio_data_o => right_audio_data_o_signal,
		s00_axis_tready   => s00_axis_tready
    );

-- AXI Stream Transmitter
axis_transmitter : axis_transmitter_interface
    port map(
		left_audio_data_i => left_audio_data_o_signal_fromreceiver,
		right_audio_data_i => right_audio_data_o_signal_fromreceiver,
		lrclk_i => unbuffered_clk_reg_signal,
		m00_axis_aclk => m00_axis_aclk,
		m00_axis_aresetn => m00_axis_aresetn,
		m00_axis_tready => m00_axis_tready,

		m00_axis_tdata => m00_axis_tdata,
		m00_axis_tlast => m00_axis_tlast,
		m00_axis_tstrb => m00_axis_tstrb,
		m00_axis_tvalid => m00_axis_tvalid
    );

-- Assignment of output values from clocks
ac_adc_lrclk_o <= ac_adc_lrclk_o_signal;
ac_dac_lrclk_o <= ac_dac_lrclk_o_signal;
ac_bclk_o <= buffered_bclk;
ac_mclk_o <= ac_mclk_o_signal;
unbuffered_lrclk <= unbuffered_clk_reg_signal;

----------------------------------------------------------------------------
-- Processes
----------------------------------------------------------------------------
-- This implements a simple reset signal on the rising edge of mclk
reset_signal : process(mclk_o_signal)
begin
    if rising_edge(mclk_o_signal) then
        ac_mute_n_o <= not ac_mute_en_i;
    end if;
end process reset_signal;

----------------------------------------------------------------------------   
end Behavioral;