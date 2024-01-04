library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_vga is
	port(
		-- FPGA Internal Clock
		ref_clk_in : in std_logic;
		-- VGA Outputs
		hsync_out : out std_logic;
		vsync_out : out std_logic;
		rgb_out : out std_logic_vector(5 downto 0) := "000000";
		pll_out : out std_logic;
		-- NES Controller Player 1
		data_in_one : in std_logic;
		data_in_two : in std_logic;
		continCLK_out : out std_logic;
		latch_out : out std_logic
		);
end;

architecture synth of top_vga is
	--pll component
	component vga_pll is
    port(
        ref_clk_i: in std_logic;
        rst_n_i: in std_logic;
        outcore_o: out std_logic;
        outglobal_o: out std_logic
    );
	end component;
	
	--vga component 
	component vga is
    port(
		clk : in std_logic;
        hsync : out std_logic;
		vsync : out std_logic;
		valid : out std_logic;
		frame_clk : out std_logic;
		game_clk : out std_logic;
		row : out unsigned(9 downto 0);
		col : out unsigned(9 downto 0)
    );
	end component;
	
	--pattern generator component
	component pattern_gen is
    port(
		object_x_P1 : in unsigned(5 downto 0);
		object_y_P1 : in unsigned(4 downto 0);
		object_x_P2 : in unsigned(5 downto 0);
		object_y_P2 : in unsigned(4 downto 0);
		prev_x_P1: in unsigned(5 downto 0);
		prev_y_P1 : in unsigned(4 downto 0);
		prev_x_P2 : in unsigned(5 downto 0);
		prev_y_P2 : in unsigned(4 downto 0);
		valid : in std_logic;
		row : in unsigned(9 downto 0);
		col : in unsigned(9 downto 0);
		pll_clk : in std_logic;
		frame_clk : in std_logic;
		input_one : in unsigned(7 downto 0);
		input_two : in unsigned(7 downto 0);
		r_address : out std_logic_vector(10 downto 0);
		data_from_mem : in std_logic_vector(1 downto 0);
		w_address : out std_logic_vector(10 downto 0);
		data_to_mem : out std_logic_vector(1 downto 0);
		write_enable : out std_logic;
		write_a : out std_logic;
		read_b : out std_logic;
		rgb : out std_logic_vector(5 downto 0)
    );
	end component;
	
	-- velocity decoder component
	component velocity_decoder is
	port (
		player : in std_logic;
		p1_select : in std_logic;
		encoded_velocity : in std_logic_vector(1 downto 0);
		game_clk : in std_logic;
		object_x : out unsigned(5 downto 0);
		object_y : out unsigned(4 downto 0);
		prev_x : out unsigned(5 downto 0);
		prev_y : out unsigned(4 downto 0)
	);
	end component;
	
	-- bike_velocity component
	component bike_velocity is
	port (
		player : in std_logic;
		p1_select : in std_logic;
		north : in std_logic;
		south : in std_logic;
		east : in std_logic;
		west : in std_logic;
		clk : in std_logic;
		encoded_velocity : out std_logic_vector(1 downto 0)
	);
	end component;
	
	-- trail_memory component
	component trail_memory is
	port (
		clk : in std_logic;
		r_addr : in std_logic_vector(10 downto 0);
		r_data : out std_logic_vector(1 downto 0);
		w_addr : in std_logic_vector(10 downto 0);
		w_data : in std_logic_vector(1 downto 0);
		a_enable : in std_logic;
		b_enable : in std_logic;
		w_enable : in std_logic
	);
	end component;
	
	-- NES Controller Component
	component NES is
	port(
		latch : out std_logic;
		continCLK : out std_logic;
		digital_one : out unsigned(7 downto 0);
		digital_two : out unsigned(7 downto 0);
		data_one : in std_logic;
		data_two : in std_logic
	);
	end component;
	
	-- signals to connect modules together
	signal frame_clk_sig : std_logic;
	signal game_clk_sig : std_logic;
	signal clk_sig : std_logic;
	signal val_sig : std_logic;
	signal row_sig : unsigned(9 downto 0);
	signal col_sig : unsigned(9 downto 0);
	signal object_x_sig_P1 : unsigned(5 downto 0);
	signal object_y_sig_P1 : unsigned(4 downto 0);
	signal object_x_sig_P2 : unsigned(5 downto 0);
	signal object_y_sig_P2 : unsigned(4 downto 0);
	signal prev_x_sig_P1 : unsigned(5 downto 0);
	signal prev_y_sig_P1 : unsigned(4 downto 0);
	signal prev_x_sig_P2 : unsigned(5 downto 0);
	signal prev_y_sig_P2 : unsigned(4 downto 0);
	
	-- NES Controller signal
	signal controller_sig_one : unsigned(7 downto 0);
	signal controller_sig_two : unsigned(7 downto 0);

	-- velocity_decoder signal
	signal encoded_velocity_sig1 : std_logic_vector(1 downto 0) := "11";
	signal encoded_velocity_sig2 : std_logic_vector(1 downto 0) := "10";
	signal player1_sig : std_logic := '0';
	signal player2_sig : std_logic := '1';

	-- memory signals
	signal r_addr_sig :  std_logic_vector(10 downto 0);
	signal r_data_sig : std_logic_vector(1 downto 0);
	signal w_addr_sig : std_logic_vector(10 downto 0);
	signal w_data_sig : std_logic_vector(1 downto 0);
	signal w_enable_sig : std_logic;
	signal a_enable_sig : std_logic;
	signal b_enable_sig : std_logic;

	--begin architecture
	begin
	pll : vga_pll port map(
	-- inputs
		ref_clk_i => ref_clk_in,
		rst_n_i => '1',
	-- outputs
		outcore_o => pll_out,
		outglobal_o => clk_sig);
	
	vga_comms : vga port map(
	-- inputs
		clk => clk_sig,
	-- outputs
		hsync => hsync_out,
		vsync => vsync_out,
		valid => val_sig,
		frame_clk => frame_clk_sig,
		game_clk => game_clk_sig,
		row => row_sig,
		col => col_sig);
	
	color : pattern_gen	port map(
	-- inputs
		object_x_P1 => object_x_sig_P1,
		object_y_P1 => object_y_sig_P1,
		object_x_P2 => object_x_sig_P2,
		object_y_P2 => object_y_sig_P2,
		
		prev_x_P1 => prev_x_sig_P1,
		prev_y_P1 => prev_y_sig_P1,
		prev_x_P2 => prev_x_sig_P2,
		prev_y_P2 => prev_y_sig_P2,
		
		valid => val_sig,
		row => row_sig,
		col => col_sig,
		pll_clk => clk_sig,
		
		input_one => controller_sig_one,
		input_two => controller_sig_two,
	-- outputs
		r_address => r_addr_sig,
		data_from_mem => r_data_sig,
		w_address => w_addr_sig,
		data_to_mem => w_data_sig,
		write_enable => w_enable_sig,
		write_a => a_enable_sig,
		read_b => b_enable_sig,
		frame_clk => frame_clk_sig,
		rgb => rgb_out
	);
	
	--Movement for PLAYER 1
	direction_P1 : bike_velocity port map(
	-- inputs
		player => player1_sig,
		p1_select => controller_sig_one(5),
		north => controller_sig_one(3),
		south => controller_sig_one(2),
		east => controller_sig_one(0),
		west => controller_sig_one(1),
		clk => clk_sig,
	-- outputs
		encoded_velocity => encoded_velocity_sig1
	);
	
	velocity_P1 : velocity_decoder port map(
	-- inputs
		player => player1_sig,
		encoded_velocity => encoded_velocity_sig1,
		game_clk => game_clk_sig,
		p1_select => controller_sig_one(5),
	-- outputs
		object_x => object_x_sig_P1,
		object_y => object_y_sig_P1,
		prev_x => prev_x_sig_P1,
		prev_y => prev_y_sig_P1
	);
	
	--Movement for PLAYER 2
	direction_P2 : bike_velocity port map(
	-- inputs
		player => player2_sig,
		p1_select => controller_sig_one(5),
		north => controller_sig_two(3),
		south => controller_sig_two(2),
		east => controller_sig_two(0),
		west => controller_sig_two(1),
		clk => clk_sig,
	-- outputs
		encoded_velocity => encoded_velocity_sig2
	);
	
	velocity_P2 : velocity_decoder port map(
	-- inputs
		player => player2_sig,
		encoded_velocity => encoded_velocity_sig2,
		game_clk => game_clk_sig,
		p1_select => controller_sig_one(5),
	-- outputs
		object_x => object_x_sig_P2,
		object_y => object_y_sig_P2,
		prev_x => prev_x_sig_P2,
		prev_y => prev_y_sig_P2
	);
	
	RAM : trail_memory port map(
	-- inputs
		clk => clk_sig,
		r_addr => r_addr_sig,
		w_addr => w_addr_sig,
		w_data => w_data_sig,
		a_enable => a_enable_sig,
		b_enable => b_enable_sig,
		w_enable => w_enable_sig,
	-- outputs
		r_data => r_data_sig
	);
	
	--NES PART
	NES_inst : NES port map (
	-- inputs
		data_one => data_in_one,
		data_two => data_in_two,
	-- outputs
		latch => latch_out,
		continCLK => continCLK_out,
		digital_one => controller_sig_one,
		digital_two => controller_sig_two
	);
	
end;