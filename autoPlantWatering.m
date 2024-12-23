%  autoPlantWatering
%
%Author : Neel Chitkara
%Date: 12/03/2024
%
%
% name of code (function) : autoPlantWatering
%
% Purpose    : creates a system that will check the state of the soils
% moisture level, then uses the soils state to output a select amount of
% water to hydrate the plant/soil. and plots all of the
% data/voltages/moisture levels, in real time.
%
% Parameters : 
%a - arduino initialization
%water_Alot - double of the amount of water to release if the plants moisture level is too low and needs to be watered alot
%water_Alittle - a double of the amount of water to release if the plants moisture level is slightly too low and needs to be watered a little amount
% ^^ these water amounts are approximated for my size of plant
%checkSensor - the amount of time the sensors moisture level will be
%checked for differences (this value worked well for my video and for my graph, in bigger situations it will be at a longer period)
%timeHolder - a array in which the values of the time will be held
%voltageHolder - a array in which the values of the voltages will be held when updated
%timeCovered - is the elapsed time being updated consistently every 15 seconds from starting the code 
%voltage- voltage level calculated from arduino
%
% Calibration data:
%  
% Time to for water to begin flowing:    1.5 sec
%
% Time to empty 1 litre of water:     22.14 sec
%
% Examples of Usage:
%
%   run autoPlantWatering
%  checks soil state
% pumps water depending on how the soil state is
% plots voltage levels/moisture levels
% loops
% terminate to end

%Clear existing Vars%
clear all;
a = arduino("/dev/cu.usbserial-0001","Nano3");
%Create Variables to begin With%
water_Alot = 0.07; %0.1 Litres%
water_Alittle = 0.02; %0.02 Litres%
checkSensor = 15; %Currently set 15 second intervals%
%Graphing%

%Labelling and initializing%
figure;
hold on;
grid on;
title('Live Soil Moisture Tracking :)');
xlabel('Time (s)');
ylabel('Soils Live Moisture Level (V)');
startTime = datetime('now');
ylim([1.5 4])
timeHolder = [ ];
voltageHolder = [ ];

%Constant Loop%
while true %while true just means itll never stop running%
    
    timeCovered = seconds(datetime('now') - startTime);  %https://www.youtube.com/watch?v=y68eoAbeUQs%Real time intervals%
    voltage = readVoltage(a,'A1');
    timeHolder(end + 1) = timeCovered; %add another value to end of matrix%
    voltageHolder(end + 1) = voltage;   %add another value to end of matrix%
    plot(timeHolder, voltageHolder, '-m','MarkerSize',50);
    drawnow;
   %End Graphing%
    state = currentSoilState( a );
    if strcmpi(state,"dry_Air") %use string compare(I)because currentsoilstate(a) is outputting a string and it needs to be compared while not being case sensitive either (therefore strcmpi)%
        fprintf('PLEASE PLACE SENSOR INTO PLANT!...\n')
    elseif strcmpi(state,"dry_Soil")
        fprintf('SOIL IS EXTREMELY DRY: WATERING ALOT...\n')
        pumpWater(a,water_Alot)
    elseif strcmpi(state,"littlewet_Soil")
        fprintf('PLANT NEEDS SLIGHT WATERING: WATERING NOW...\n')
        pumpWater(a , water_Alittle)
    elseif strcmpi(state,"wet_Soil")
        fprintf('PLANT IS HAPPILY WATERED: NOT WATERING:) ...\n')
    else
        fprintf('WAY TOO MUCH WATER: DO NOT ADD ANY WATER EXTERNALLY...\n')
    end
    pause(5.0);
end

%%
% function value = currentSoilState( a )
%
% Function   : currentSoilState ( a )
%
% Purpose    : analyze the soil moisture sensor and categorize voltages to
% different soil states. will then give you the state that the soil is in
% as a displayed string
%
% Parameters : 
%voltage - double, is the analyzed voltage value from the soil moisture when read
%from the arduino 
%state - an updated string value that represents the current state the soil is in
%
%
%
%
%
% 
% Return     :
% state = string of the state the soil moisture sensor is in
%
% Calibration data:
% Not immersed in water:    3.5435 v
% Immersed in dry soil:     3.3138 v
% Immersed in water-saturated soil:    2.9179 (2.7566) v
% Immersed in water:    1.6618 / 2.5362 v
%
% Examples of Usage:
%
%    >> state = currentSoilState( a )
% state =
%
%     "dry soil"
%

function state = currentSoilState( a )
    voltage = readVoltage(a, 'A1'); %check voltage of the sensor wherever its located%
    if voltage >= 3.4%If voltage is 3.5435 or greater%
        state = "dry_Air"; %the state of the sensor is in the air%
    elseif voltage >= 3.2134 %if voltage is below the dry_air, and greater than or equal to 3.3138%
        state = "dry_Soil"; %then the state of the sensor is in dry soil%
    elseif voltage >=2.9179 % below dry soil and greaterthan = to 2.6393%
        state = "littleWet_Soil"; %then its in wet soil%
    elseif voltage >= 2.5         %2.7366
        state = "wet_Soil";
    elseif voltage < 2.5
        state= "Water"; %else if its less than wet soil then its in water%
    end
end

%%
% function pumpWater( a , litres )
%
% Function   : pumpWater( a , litres )
%
% Purpose    : pumping a designated amount of water depending on the amount
% of litres needed depending on the plant size using the arduino kits water
% pump and relay connecting wires
%
% Parameters : 
%pumpStart -  a double showing the pre calculated value of how long it takes to get the water fully out of the pump
%oneLitre_Time - a double of the start time plus the amount of pre calulated time to pump a litre of water
%pumpTime - a double of the one litre time multiplied by the amount of
%litres you want to pump, which will overall calculate the amount of time it will take to pump a designated amount of water

% Calibration data:
%  
% Time to for water to begin flowing:    1.5 sec
%
% Time to empty 1 litre of water:     22.14 sec
%
% Examples of Usage:
%
%    >> pumpWater(a, litres)
% pump turns on (writeDigitalPin(a,'D2',1)
%until pump time is over
% pump turns off

function pumpWater(a, litres)
pumpStart = 1.5; %amount of time it takes to start pumping%
oneLitre_Time = (22.14 + pumpStart); %total time to pump one litre ( including the start time)%
pumpTime = (oneLitre_Time * litres); %Multiplying by litres here does makes sense and is resoanable because when dispensing the water using the pump, the pump is expelling liquid at approx a constant rate, therefore meaning you can multiply the time for one litre by any amount of litres to find total time% 
writeDigitalPin(a , 'D2' , 1) %turn on the pump%
pause(pumpTime) %keep the pump running for (pumpTime) amount of time%
writeDigitalPin(a , 'D2' , 0) %turn off the pump%
end 