library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_Level is
  Port (CLK,RST : in std_logic;
        SCL,SDA : inout std_logic; 
        CS : out STD_LOGIC;
        SDIN : out STD_LOGIC;
        SCLK : out STD_LOGIC;
        DC : out STD_LOGIC;
        RES : out STD_LOGIC;
        VBAT : out STD_LOGIC;
        VDD : out STD_LOGIC);
end Top_Level;

architecture Top_Level of Top_Level is

    component pmod_real_time_clock 
    GENERIC(
        sys_clk_freq : INTEGER); 
    PORT(
        clk           : IN    STD_LOGIC;                     --system clock
        reset_n       : IN    STD_LOGIC;                     --asynchronous active-low reset
        scl           : INOUT STD_LOGIC;                     --I2C serial clock
        sda           : INOUT STD_LOGIC;                     --I2C serial data
        i2c_ack_err   : OUT   STD_LOGIC;                     --I2C slave acknowledge error flag
        set_clk_ena   : IN    STD_LOGIC;                     --set clock enable
        set_seconds   : IN    STD_LOGIC_VECTOR(6 DOWNTO 0);  --seconds to set clock to
        set_minutes   : IN    STD_LOGIC_VECTOR(6 DOWNTO 0);  --minutes to set clock to
        set_hours     : IN    STD_LOGIC_VECTOR(4 DOWNTO 0);  --hours to set clock to
        set_am_pm     : IN    STD_LOGIC;                     --am/pm to set clock to, am = '0', pm = '1'
        set_weekday   : IN    STD_LOGIC_VECTOR(2 DOWNTO 0);  --weekday to set clock to
        set_day       : IN    STD_LOGIC_VECTOR(5 DOWNTO 0);  --day of month to set clock to
        set_month     : IN    STD_LOGIC_VECTOR(4 DOWNTO 0);  --month to set clock to
        set_year      : IN    STD_LOGIC_VECTOR(7 DOWNTO 0);  --year to set clock to
        set_leapyear  : IN    STD_LOGIC;                     --specify if setting is a leapyear ('1') or not ('0')
        seconds       : OUT   STD_LOGIC_VECTOR(6 DOWNTO 0);  --clock output time: seconds
        minutes       : OUT   STD_LOGIC_VECTOR(6 DOWNTO 0);  --clock output time: minutes
        hours         : OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);  --clock output time: hours
        am_pm         : OUT   STD_LOGIC;                     --clock output time: am/pm (am = '0', pm = '1')
        weekday       : OUT   STD_LOGIC_VECTOR(2 DOWNTO 0);  --clock output time: weekday
        day           : OUT   STD_LOGIC_VECTOR(5 DOWNTO 0);  --clock output time: day of month
        month         : OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);  --clock output time: month
        year          : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0)); --clock output time: year
    END component;
    
    component time2vectors 
    Port (clk,rst : in std_logic; 
            seconds : in std_logic_vector(6 downto 0); 
            minutes : in std_logic_vector(6 downto 0); 
            hours   : in std_logic_vector(4 downto 0); 
            con_sec_dig1 : out std_logic_vector(7 downto 0); 
            con_sec_dig2 : out std_logic_vector(7 downto 0); 
            con_min_dig1 : out std_logic_vector(7 downto 0); 
            con_min_dig2 : out std_logic_vector(7 downto 0); 
            con_hou_dig1 : out std_logic_vector(7 downto 0);    
            con_hou_dig2 : out std_logic_vector(7 downto 0));
    end component;
    
    component PmodOLEDCtrl 
    Port ( 
            CLK     : in  STD_LOGIC;
            RST     : in  STD_LOGIC;
            sec_dig_1 : in std_logic_vector(7 downto 0); 
            sec_dig_2 : in std_logic_vector(7 downto 0); 
            min_dig_1 : in std_logic_vector(7 downto 0); 
            min_dig_2 : in std_logic_vector(7 downto 0); 
            hou_dig_1 : in std_logic_vector(7 downto 0); 
            hou_dig_2 : in std_logic_vector(7 downto 0); 
            CS      : out STD_LOGIC;
            SDIN    : out STD_LOGIC;
            SCLK    : out STD_LOGIC;
            DC        : out STD_LOGIC;
            RES    : out STD_LOGIC;
            VBAT    : out STD_LOGIC;
            VDD    : out STD_LOGIC);
    end component;
    
    signal sec : std_logic_vector(6 downto 0); 
    signal min : std_logic_vector(6 downto 0); 
    signal hou : std_logic_vector(4 downto 0); 
    signal sec_1 : std_logic_vector(7 downto 0);
    signal sec_2 : std_logic_vector(7 downto 0); 
    signal min_1 : std_logic_vector(7 downto 0); 
    signal min_2 : std_logic_vector(7 downto 0); 
    signal hou_1 : std_logic_vector(7 downto 0);
    signal hou_2 : std_logic_vector(7 downto 0);     

begin

   RTCC : pmod_real_time_clock
   Generic map(sys_clk_freq => 125_000_000)
   port map(clk => CLK, 
            reset_n => '1',
            scl => SCL, 
            sda => SDA, 
            i2c_ack_err => open,
            set_clk_ena => '0',
            set_seconds => (others => '0'),
            set_minutes => (others => '0'),
            set_hours => (others => '0'),
            set_am_pm => '0',
            set_weekday => (others => '0'),
            set_day => (others => '0'),
            set_month => (others => '0'),
            set_year => (others => '0'),
            set_leapyear => '0',
            seconds => sec,
            minutes => min,
            hours => hou, 
            am_pm => open,
            weekday => open,
            day => open,
            month => open,
            year => open); 
                       
   Convert : time2vectors
   port map(clk => CLK,
            rst => RST,
            seconds => sec,
            minutes => min,
            hours => hou, 
            con_sec_dig1 => sec_1,
            con_sec_dig2 => sec_2,
            con_min_dig1 => min_1,
            con_min_dig2 => min_2,
            con_hou_dig1 => hou_1,
            con_hou_dig2 => hou_2); 
            
  OLED : PmodOLEDCtrl
  port map( CLK => CLK,
            RST => RST, 
            sec_dig_1 => sec_1,
            sec_dig_2 => sec_2,
            min_dig_1 => min_1,
            min_dig_2 => min_2,
            hou_dig_1 => hou_1,
            hou_dig_2 => hou_2, 
            CS => CS,
            SDIN => SDIN,
            SCLK => SCLK,
            DC => DC, 
            RES => RES,
            VBAT => VBAT, 
            VDD => VDD);           
            
   
           

end Top_Level;

