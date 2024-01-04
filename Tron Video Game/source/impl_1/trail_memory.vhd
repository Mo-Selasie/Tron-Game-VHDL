library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity trail_memory is
	port(
		clk : in std_logic;
		r_addr : in std_logic_vector(10 downto 0);
		r_data : out std_logic_vector(1 downto 0);
		w_addr : in std_logic_vector(10 downto 0);
		w_data : in std_logic_vector(1 downto 0);
		a_enable : in std_logic;
		b_enable : in std_logic;
		w_enable : in std_logic
	);
end;

architecture synth of trail_memory is

type ramtype is array(2**11-1 downto 0) of
  std_logic_vector(1 downto 0);
  
function initialize return ramtype is
variable initialized : ramtype;
begin
	for i in ramtype'range loop
		if (to_unsigned(i,11)(5 downto 0) = 6d"63") then
			initialized(i) := "01";
		elsif (to_unsigned(i,11)(5 downto 0) = 6d"0") then
			initialized(i) := "01";
		elsif (to_unsigned(i,11)(10 downto 6) = 5d"0") then
			initialized(i) := "01";
		elsif (to_unsigned(i,11)(10 downto 6) = 5d"31") then
			initialized(i) := "01";
		else
			initialized(i) := "00";
		end if;
	end loop;
	return initialized;
end function;
  
signal mem : ramtype := initialize;
begin
	process(clk) begin
		if rising_edge(clk) then
			if a_enable = '1' then
				if w_enable = '1' then
					mem(to_integer(unsigned(w_addr))) <= w_data;
				end if;
			end if;
		end if;
	end process;

	process(clk) begin
		if rising_edge(clk) then
			if b_enable = '1' then
				r_data <= mem(to_integer(unsigned(r_addr)));
			end if;
		end if;
	end process;
end;