## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project
## This file is the constraint file needed for Lab6 

set_property PACKAGE_PIN L16 [get_ports CLK]                            
    set_property IOSTANDARD LVCMOS33 [get_ports CLK]
    create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK]
 
set_property PACKAGE_PIN N15 [get_ports RST]                        
    set_property IOSTANDARD LVCMOS33 [get_ports RST]
set_property PACKAGE_PIN T14 [get_ports {CS}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {CS}]
#Bank = 15, Pin name = IO_L5N_T0_AD9N_15,                    Sch name = JA2
set_property PACKAGE_PIN T15 [get_ports {SDIN}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {SDIN}]

#Bank = 15, Pin name = IO_L16P_T2_A28_15,                    Sch name = JA4
set_property PACKAGE_PIN R14 [get_ports {SCLK}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {SCLK}]
#Bank = 15, Pin name = IO_0_15,                                Sch name = JA7
set_property PACKAGE_PIN U14 [get_ports {DC}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {DC}]
#Bank = 15, Pin name = IO_L20N_T3_A19_15,                    Sch name = JA8
set_property PACKAGE_PIN U15 [get_ports {RES}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {RES}]
#Bank = 15, Pin name = IO_L21N_T3_A17_15,                    Sch name = JA9
set_property PACKAGE_PIN V17 [get_ports {VBAT}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {VBAT}]
#Bank = 15, Pin name = IO_L21P_T3_DQS_15,                    Sch name = JA10
set_property PACKAGE_PIN V18 [get_ports {VDD}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {VDD}]


	
set_property PACKAGE_PIN T11 [get_ports {SCL}]                    
        set_property IOSTANDARD LVCMOS33 [get_ports {SCL}]

set_property PACKAGE_PIN T10 [get_ports {SDA}]                    
            set_property IOSTANDARD LVCMOS33 [get_ports {SDA}]
