library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity animate is
	generic (
		pixels_y : integer := 480;
		pixels_x : integer := 640;
		gen_v : integer := 1;
		object_width : integer := 16);
	port (
		north : in std_logic;
		south : in std_logic;
		east : in std_logic;
		west : in std_logic;
		-- Critical Timing Logic
		pll_clk : in std_logic;
		valid : in std_logic;
		frame_clk : in std_logic;
		-- Positional Variables
		object_x : out unsigned(9 downto 0) := 10d"0";
		object_y : out unsigned(9 downto 0) := 10d"0"
	);
end;

architecture synth of animate is

	signal ihateyou : unsigned(19 downto 0) := 20d"0";
	signal test_x : integer range 0 to 480 := 0;
	signal twentynineBC : unsigned(28 downto 0) := 29d"0"; -- Counter?
	signal leftright : std_logic := '0'; -- 1 is left, 0 is right

begin
	process(pll_clk) begin
		if rising_edge(pll_clk) and rising_edge(frame_clk) then			
			if (east = '0' and west = '0') then
				object_y <= 10d"240";
				object_x <= object_x;
			elsif (east = '1' and west = '0') then
				leftright <= '1';
				twentynineBC <= twentynineBC + 29d"1";
				object_x <= twentynineBC(28 downto 19);
			elsif (east = '0' and west = '1') then
				leftright <= '0';
				twentynineBC <= twentynineBC - 29d"1";
				object_x <= twentynineBC(28 downto 19);				
			else 
				if leftright = '1' then -- Preserve Velocity Flag
					twentynineBC <= twentynineBC + 29d"1";
				else
					twentynineBC <= twentynineBC - 29d"1";
				end if;
				object_x <= twentynineBC(28 downto 19);
				--object_y <= 10d"240";
				--object_x <= object_x;
			end if;
		end if;
	end process;
end;