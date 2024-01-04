library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity velocity_decoder is
	generic (
		pixels_y : integer := 256;
		pixels_x : integer := 512;
		vel_mag: integer := 1; -- Velocity Magnitude
		object_width : unsigned(9 downto 0):= 10d"4");
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
end;

architecture synth of velocity_decoder is

--type START is (TRUE, FALSE);
   --signal select_to_start : START := FALSE;
signal flag : std_logic := '0';

begin
	process(game_clk) begin
		if rising_edge(game_clk) then
			if (flag = '0') then
				if (player = '1') then
					object_x <= 6d"6";
					object_y <= 5d"16";
				else
					object_x <= 6d"57";
					object_y <= 5d"16";
				end if;
				if (p1_select = '0') then
					flag <= '1';
				end if;
			else
				
				prev_y <= object_y;
				prev_x <= object_x;
				if (encoded_velocity(1) = '0') then
					if (encoded_velocity(0) = '0') then
						object_y <= object_y - to_unsigned(vel_mag, object_y'length);
					else
						object_y <= object_y + to_unsigned(vel_mag, object_y'length);
					end if;
					object_x <= object_x;
				else
					if (encoded_velocity(0) = '0') then
						object_x <= object_x - to_unsigned(vel_mag, object_x'length);
					else
						object_x <= object_x + to_unsigned(vel_mag, object_x'length);
					end if;
					object_y <= object_y;
				end if;
			end if;
		end if;
	end process;
end;
