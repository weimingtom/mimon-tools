EESchema Schematic File Version 2  date 11.7.2010 21:27:36
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:special
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:divadlo-cache
EELAYER 24  0
EELAYER END
$Descr A4 11700 8267
Sheet 1 1
Title ""
Date "11 jul 2010"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Connection ~ 9550 4625
Wire Wire Line
	10300 4625 10300 4450
Wire Wire Line
	8050 4625 10300 4625
Connection ~ 8050 4625
Wire Wire Line
	8800 4625 8800 4450
Connection ~ 9500 4525
Wire Wire Line
	10300 4350 10225 4350
Wire Wire Line
	10225 4350 10225 4525
Wire Wire Line
	10225 4525 8000 4525
Wire Wire Line
	8800 4350 8750 4350
Wire Wire Line
	8750 4350 8750 4525
Connection ~ 8000 4525
Connection ~ 9550 4050
Wire Wire Line
	10300 4150 10300 4050
Wire Wire Line
	10300 4050 7850 4050
Connection ~ 7850 4150
Wire Wire Line
	8800 4050 8800 4150
Wire Wire Line
	7850 4050 7850 5625
Connection ~ 8675 5425
Wire Wire Line
	8050 4250 7925 4250
Wire Wire Line
	7925 4250 7925 5425
Wire Wire Line
	7925 5425 10175 5425
Connection ~ 9975 5425
Wire Wire Line
	9550 4250 9375 4250
Wire Wire Line
	9375 4250 9375 5425
Wire Wire Line
	4975 6850 5125 6850
Wire Wire Line
	5125 6850 5125 7125
Wire Wire Line
	5125 7125 10325 7125
Wire Wire Line
	10325 7125 10325 6500
Connection ~ 9975 6500
Wire Wire Line
	10325 6500 9975 6500
Connection ~ 7675 6325
Wire Wire Line
	7175 6325 7675 6325
Wire Wire Line
	7175 4775 7675 4775
Wire Wire Line
	7675 4775 7675 6850
Wire Wire Line
	7675 6850 9475 6850
Wire Wire Line
	6375 5975 6375 6050
Wire Wire Line
	6375 6050 6050 6050
Wire Wire Line
	6050 6250 6225 6250
Wire Wire Line
	6225 6250 6225 5425
Wire Wire Line
	6225 5425 6375 5425
Wire Wire Line
	6050 5950 6150 5950
Wire Wire Line
	6150 5950 6150 6525
Wire Wire Line
	6150 6525 6375 6525
Wire Wire Line
	7175 5775 7675 5775
Connection ~ 7675 5775
Wire Wire Line
	7175 5225 7175 2850
Wire Wire Line
	7175 2850 5000 2850
Connection ~ 5100 2850
Connection ~ 7175 4775
Wire Wire Line
	9975 5425 9975 6850
Wire Wire Line
	10175 5425 10175 4250
Wire Wire Line
	10175 4250 10300 4250
Wire Wire Line
	8675 5425 8675 4250
Wire Wire Line
	8675 4250 8800 4250
Connection ~ 9375 5425
Wire Wire Line
	7850 5625 7175 5625
Wire Wire Line
	7850 4150 8050 4150
Wire Wire Line
	9550 4050 9550 4150
Connection ~ 8800 4050
Wire Wire Line
	7175 6175 8000 6175
Wire Wire Line
	8000 6175 8000 4350
Wire Wire Line
	8000 4350 8050 4350
Wire Wire Line
	9500 4525 9500 4350
Wire Wire Line
	9500 4350 9550 4350
Connection ~ 8750 4525
Wire Wire Line
	7175 6725 8050 6725
Wire Wire Line
	8050 6725 8050 4450
Wire Wire Line
	9550 4625 9550 4450
Connection ~ 8800 4625
$Comp
L CONN_4 LED4
U 1 1 4C3A1A07
P 10650 4300
F 0 "LED4" V 10600 4300 50  0000 C CNN
F 1 "CONN_4" V 10700 4300 50  0000 C CNN
	1    10650 4300
	1    0    0    -1  
$EndComp
$Comp
L CONN_4 LED3
U 1 1 4C3A1A02
P 9900 4300
F 0 "LED3" V 9850 4300 50  0000 C CNN
F 1 "CONN_4" V 9950 4300 50  0000 C CNN
	1    9900 4300
	1    0    0    -1  
$EndComp
$Comp
L CONN_4 LED2
U 1 1 4C3A19FE
P 9150 4300
F 0 "LED2" V 9100 4300 50  0000 C CNN
F 1 "CONN_4" V 9200 4300 50  0000 C CNN
	1    9150 4300
	1    0    0    -1  
$EndComp
$Comp
L CONN_4 LED1
U 1 1 4C3A19F1
P 8400 4300
F 0 "LED1" V 8350 4300 50  0000 C CNN
F 1 "CONN_4" V 8450 4300 50  0000 C CNN
	1    8400 4300
	1    0    0    -1  
$EndComp
$Comp
L BC237 Q?
U 1 1 4C3A16FD
P 7075 6525
F 0 "Q?" H 7275 6425 50  0000 C CNN
F 1 "BC237" H 7325 6675 50  0000 C CNN
F 2 "TO92-EBC" H 7265 6525 30  0001 C CNN
	1    7075 6525
	1    0    0    -1  
$EndComp
$Comp
L BC237 Q?
U 1 1 4C3A16F8
P 7075 5975
F 0 "Q?" H 7275 5875 50  0000 C CNN
F 1 "BC237" H 7325 6125 50  0000 C CNN
F 2 "TO92-EBC" H 7265 5975 30  0001 C CNN
	1    7075 5975
	1    0    0    -1  
$EndComp
$Comp
L BC237 Q?
U 1 1 4C3A16F4
P 7075 5425
F 0 "Q?" H 7275 5325 50  0000 C CNN
F 1 "BC237" H 7325 5575 50  0000 C CNN
F 2 "TO92-EBC" H 7265 5425 30  0001 C CNN
	1    7075 5425
	1    0    0    -1  
$EndComp
$Comp
L POT POT-B
U 1 1 4C3A16C9
P 6625 6525
F 0 "POT-B" H 6625 6425 50  0000 C CNN
F 1 "POT" H 6625 6525 50  0000 C CNN
	1    6625 6525
	1    0    0    -1  
$EndComp
$Comp
L POT POT-G
U 1 1 4C3A16C5
P 6625 5975
F 0 "POT-G" H 6625 5875 50  0000 C CNN
F 1 "POT" H 6625 5975 50  0000 C CNN
	1    6625 5975
	1    0    0    -1  
$EndComp
$Comp
L POT POT-R
U 1 1 4C3A16B7
P 6625 5425
F 0 "POT-R" H 6625 5325 50  0000 C CNN
F 1 "POT" H 6625 5425 50  0000 C CNN
	1    6625 5425
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR01
U 1 1 4C3A1479
P 9975 6850
F 0 "#PWR01" H 9975 6850 30  0001 C CNN
F 1 "GND" H 9975 6780 30  0001 C CNN
	1    9975 6850
	1    0    0    -1  
$EndComp
$Comp
L +BATT #PWR02
U 1 1 4C3A1474
P 9475 6850
F 0 "#PWR02" H 9475 6800 20  0001 C CNN
F 1 "+BATT" H 9475 6950 30  0000 C CNN
	1    9475 6850
	1    0    0    -1  
$EndComp
$Comp
L ATMEGA32-P IC1
U 1 1 4C3A1401
P 5050 4850
F 0 "IC1" H 4250 6680 50  0000 L BNN
F 1 "ATMEGA32-P" H 5250 2950 50  0000 L BNN
F 2 "DIL40" H 5525 2875 50  0001 C CNN
	1    5050 4850
	1    0    0    -1  
$EndComp
$EndSCHEMATC
