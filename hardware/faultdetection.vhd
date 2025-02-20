LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY faultdetector IS
	GENERIC (len : INTEGER := 8;   -- bit width of similarity count
			logWindowSize : INTEGER := 3;   -- log2(windowSize)
			windowSize : INTEGER := 10);    -- the number of 
	PORT (
		clk, rst, RAM_WR  	: IN STD_LOGIC;
		metric        	: IN  STD_LOGIC_VECTOR (len - 1 DOWNTO 0);    
		faultflag      	: OUT  STD_LOGIC
	);
END ENTITY faultdetector;

ARCHITECTURE behavioral OF faultdetector IS

signal pointer_to_sum, pointer_to_minues : unsigned (logWindowSize-1 downto 0);    --
-- signal memout : STD_LOGIC_VECTOR (len - 1 DOWNTO 0);
signal RAM_DATA_OUT, toMineus : STD_LOGIC_VECTOR (len DOWNTO 0);  --
signal newdata : SIGNED( len DOWNTO 0);     --
signal newdatatoadder : SIGNED(logWindowSize + len - 1 DOWNTO 0);  ---
constant zeroconstant : SIGNED(logWindowSize - 2 DOWNTO 0) := (others=>'0'); 
constant oneconstant : SIGNED(logWindowSize - 2 DOWNTO 0) := (others=>'1'); 
constant zeroconstantfort : UNSIGNED(len - 1 DOWNTO 0) := (others=>'0'); 
constant oneconstantfort : UNSIGNED(logWindowSize - 1 DOWNTO 0) := (others=>'1'); 
signal paddingconstant : SIGNED(logWindowSize - 2 DOWNTO 0); 
signal threshold : UNSIGNED(logWindowSize + len - 1 DOWNTO 0);   ------need to be modified based on the problem
signal din, dout : STD_LOGIC_VECTOR (logWindowSize + len - 1 DOWNTO 0);
type RAM_ARRAY is array (0 to WindowSize-1) of STD_LOGIC_VECTOR (len - 1 DOWNTO 0); -- Adjusted array size
signal ram : RAM_ARRAY := (others => (others => '0'));

COMPONENT popCount IS
	GENERIC (lenPop : INTEGER := 8);   -- bit width of popCounters
	PORT (
		clk , rst 	: IN STD_LOGIC;
		en		 	: IN STD_LOGIC;
		dout        : OUT  STD_LOGIC_VECTOR (lenPop-1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT reg IS
	GENERIC (lenPop : INTEGER := 8);   -- bit width of popCounters
	PORT (
		clk 		: IN STD_LOGIC;
		regUpdate, regrst 	: IN STD_LOGIC;
		din         : IN  STD_LOGIC_VECTOR (lenPop - 1 DOWNTO 0);
		dout        : OUT  STD_LOGIC_VECTOR (lenPop - 1 DOWNTO 0)
	);
END COMPONENT;

BEGIN


process(clk)
begin
    if rising_edge(clk) then
        if (RAM_WR = '1') then
            ram(to_integer(pointer_to_sum)) <= metric;
        end if;
    end if;
end process;

-- toAdder <= signed(zeroconstant & memout);

PROCESS(clk)
BEGIN 
	IF rising_edge(clk) THEN
		IF(rst = '1') THEN
            pointer_to_sum <= (OTHERS => '0');
		ELSIF (RAM_WR = '1') THEN 
            pointer_to_sum <= pointer_to_sum + 1;
		END IF;
	END IF;
END PROCESS;

pointer_to_minues <=  pointer_to_sum + 1;
RAM_DATA_OUT <= '0' & ram(to_integer(pointer_to_minues));
toMineus <= '0' & metric;
threshold <= oneconstantfort & zeroconstantfort;
newdata <= signed(toMineus) - signed(RAM_DATA_OUT);  -- Matching types for subtraction
newdatatoadder <= paddingconstant  & newdata;
din <= std_logic_vector(signed(dout) + newdatatoadder);
paddingconstant <= zeroconstant when newdata(len) = '0' else oneconstant;
resultreg : reg
GENERIC MAP(lenPop => len+ logWindowSize )  -- Correct the generic mapping for len
PORT MAP (
    clk => clk,
    regUpdate => RAM_WR,  -- Ensure proper signal mapping
    regrst => rst,
    din => din,
    dout => dout
);

-- faultflag <= '1' when dout < threshold else '0';
faultflag <= '1' when unsigned(dout) < (threshold) else '0';


END ARCHITECTURE behavioral;




--LIBRARY IEEE;
--USE IEEE.STD_LOGIC_1164.ALL;
--USE IEEE.NUMERIC_STD.ALL;

--ENTITY tbfaultdetector IS
	
--END ENTITY tbfaultdetector;
--ARCHITECTURE tb OF tbfaultdetector IS

--component faultdetector IS
--GENERIC (len : INTEGER := 8;   -- bit width of similarity count
--        logWindowSize : INTEGER := 3;   -- log2(windowSize)
--        windowSize : INTEGER := 10);    -- the number of 
--PORT (
--    clk, rst, RAM_WR  	: IN STD_LOGIC;
--    metric   STD_LOGIC_VECTOR (len - 1 DOWNTO 0);    
--    faultflag STD_LOGIC
--);
--END component

--signal  clk, 	: STD_LOGIC :='0' ;
--signal  metri STD_LOGIC_VECTOR (7 DOWNTO 0);    
--signal  fault  STD_LOGIC;
--begin 

--CUT : faultdetector 
--GENERIC map( 8, 3, 8)
--PORT map(
--    clk, rst, RAM_WR , metric  ,faultflag  
--);
--clk <= not(clk) after 1 ns;
--rst <= '1', '0' after 10 ns;

--process begin
--    wait for 20 ns;
--    RAM_WR <=  '1';
--    wait for 2 ns;
--    RAM_WR <='0';
--end process;

--metric <= "10101010", "11101010" after 15 ns, "10100010" after 35 ns, "10101010" after 55 ns, "10111010" after 75 ns, "11101110" after 95 ns, "10101011" after 105 ns, "00000101" after 125 ns;  

--END ARCHITECTURE;
