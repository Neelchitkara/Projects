% blindsAlarm
%
%Author: Neel Chitkara
%Date: 12/03/2024
%
% Function   : blindsAlarm
%
% Purpose    : to automate a system in which a servo motor opens and closes
% a set of blinds depending on the sunlight levels being tracked on a window from a
% lightsensor on an arduino kit. If the sunlight levels are approaching a limit threshold, 
% an led and buzzer will activate as an alarm letting you know when its time to wake up or go to sleep
%
% Parameters : 
% Arduino - beginner grove kit for arduino intialization
%lightSensor - light sensor on the arduino kit 'A6' pin
%s - servo motor connected to arduino board 'D2' pin
%led - pin connected on arduino kit 'D4'
%buzzer - buzzer on the arduino kit connected to 'D5'
%nearingStateThreshold - double, a range the voltage/light level needs to be to the limit to be considered nearing the sunlight levels
%openLimit - double, is the limit for changing states, the limit seen when its going from sunlight to darkness
%previousState - a string representing the state that it was, and the string that is compared to the current state to seen if theres a change
%timeHolder - array of values holding the time that elapsed
%lightVoltageHolder - array holding the voltage levels for the light which updates so we can plot it
%stateChangeVoltageHolder - array holding voltage levels in which the state changed, holders are all initialized to 0 so they can be updated
%stateChangeTime -  another array holding the time in which the voltage levels changed state
%
% Return     : 
% nothing returns, it continuously loops because the while loop keeps going while its true, which is always until its terminated
% 
% Examples of Usage:
% run blindsAlarm
%    updates all alarms and leds and servo motors when following the
%    criteria for all requirements
%    terminate when wanting to end

% Window Blind Controller using Grove Light Sensor and Servo Motor
clear, clc;

% Set up serial communication with Arduino
a = arduino('/dev/cu.usbserial-0001', 'Nano3', 'Libraries', 'Servo');

% Set up sensors and actuators
lightSensor = 'A6';
s = servo(a,'D2');
LED = 'D4';
Buzzer = 'D5';

% Define light intensity thresholds for opening and closing blinds
nearingStateThreshold = 0.3; %range the light level needs to be near to activate other components%
openLimit= 1.1632; % volts
previousState = " "; %intialize as empty%

%Set Variables for Plotting% 
timeHolder = 0; %initialize to 0
lightvoltageHolder = 0; %initialize to 0
stateChangeVoltageHolder = 0; %initialize to 0
stateChangeTime= 0; % intiialize to 0

writePosition(s, 1); %initialize as open so the further actions can proceed depending on the situation%




%Set up Graph/Plotting%
figure; %open figure plot%
grid on; %set a grid%
title('Automatic Window Blinds and Alarm Controller'); %set title%
xlabel('Time Elapsed (S)'); %set common x label for all y axes%
ylim([0 5]); %set common y limit%


yyaxis left; %use the left y axis specifically%
ylabel('Light Level (V)'); %label left y axis%
lightPlot = plot(timeHolder, lightvoltageHolder, '-m', 'MarkerSize', 15); % set a variable that is a plot for the time and light voltage levels, this is a variable so it can be updated later on%
    
yyaxis right; %now use right y axis specifically%
ylabel('Change of Light Level State') %label right y axis%
stateChangePlot = plot(stateChangeTime, stateChangeVoltageHolder, 'ro', 'MarkerSize', 15); % set another variable that is plotting changes in stage, this is a variable for the same reason%

legend( {'Light Level (V)' , 'Changes of State'}, 'Location', 'northeast','Orientation','vertical');% set a legend, this is placed in the top right corner, and horizontally didnt fit the graph right%

hold on; %keep updating anything added%



startingTime = datetime("now"); %set the initial time running the program%

% Monitor light levels and control servo motor
while true %unlimited loop until terminated%
    lightLevel = readVoltage(a, lightSensor); %read sensor pin%
    timeCovered = seconds(datetime("now") - startingTime);  %https://www.youtube.com/watch?v=y68eoAbeUQs%Real time intervals%
    timeHolder(end + 1) = timeCovered; %add another value to end of the time matrix%
    lightvoltageHolder(end + 1) = lightLevel;   %add another value to end of light matrix%
    
   
    %Call function that checks the state change it is currently, aswell as where and at what voltage the state is changing%
   [stateChangeOccurred, currentState, stateChangeTime, stateChangeVoltageHolder] = checkStateChange(lightLevel, openLimit, previousState, timeCovered, stateChangeTime, stateChangeVoltageHolder);
    
    % Control servo motor based on light levels
   if stateChangeOccurred %if the function goes through, move on to checking if the state is above or below the limit, then using the servo motor%
        if strcmpi(currentState, "open") %if these two match%
            writePosition(s, 1); % Open the blinds because theres now sunlight %
            disp(['Blinds Opening! Time To Wake Up! Light Level Is: ', num2str(lightLevel), ' Volts']); %this will display the message only when theres a change of state%
        else %if they dont match%
            writePosition(s, 0); % Close the blinds because theres now no sunlight%
            disp(['Blinds Closing! Time To Sleep! Light Level Is: ', num2str(lightLevel), ' Volts']); %when the opposite change in state happens display its time to close the blinds%
        end
        previousState = currentState; % Update the last state so it can repeat the proccess%
   end
    
   %setting if statement for checking when the light level is approaching sunset or sunrise , which will cause a led and buzzer to sound until lt exits either end of the light threshold%
    if abs(lightLevel - openLimit) <= nearingStateThreshold %if the overall distance on either end of the threshold is in this range then%
        writeDigitalPin(a , LED , 1) %it will activate a led light warning nearing%
        writeDigitalPin(a , Buzzer , 1) %also will activate a buzzer alarm indicating a change in sunlight state%
        disp(['Almost Changing Time Periods! Time To Lock In! Light Level Is: ' num2str(lightLevel), ' Volts']); %displaying if this is true%
    else
        writeDigitalPin(a , LED , 0) %it will turn off led after leaving threshold range%
        writeDigitalPin(a, Buzzer , 0) %will turn off buzzer alarm after leaving threshold range%
    end

    %update plot after collecting all data% %also will be linked in
    %references%
    set(lightPlot,'XData' , timeHolder, 'YData' , lightvoltageHolder); %set function updating the intial plotting variables i created in the beginning with empty variables, now theyre updated so im updating x data, and%
    set(stateChangePlot , 'XData' , stateChangeTime , 'YData' , stateChangeVoltageHolder); %updating the y data (both axes of y)% %this was done using a 'set' becausse this is the only proper way of updating this inside of this while loop, i used stack overflow to help myself out%
    
    drawnow; %draw/update line
    
    % Pause until re entering the beginning of the loop again%
    pause(0.5);
end


%% function that checks for the state of the sensor at live time, aswell as comparing the current state with the previous state, which will check for changes in state, and what volts this occurs at%
% Function   : [stateChangeOccurred, currentState, stateChangeTime, stateChangeVoltageHolder] = checkStateChange(lightLevel, openLimit, previousState, timeCovered, stateChangeTime, stateChangeVoltageHolder)
%
% Purpose:  Checks the current light level and determines a state, then uses the state to determine if there has been any change in state (sunlight to no sunlight, or no sunlight to sunlight), then it tracks the time and voltage at the moment when the state changes.
%
% Parameters : 
% lightLevel  = a double found from reading the light sensor on the grove beginner kit for arduino
% openLimit = a double which is a middle ground between the voltage reading of sufficient sunlight, acts as a threshold to determine when states are classified as themselves, and when they are
% previousState = a string that represents if the state has changed from the past state to the new current state
% timeCovered = a double that represents the elapsed time from the current time to the updated current time every time the unlimited while loop iterates over itself
% stateChangeTime = a array that is filled with all times in which the state was deemed changed from the previous state to the current state if it were to switch
% stateChangeVoltageHolder = an array that is filled with all of the voltages in which the state was deemed changed from the previous state to the current state
%
% Return    :
% stateChangeOccured = a returning logical value (1(true) , 0(false)) letting you know if a state change has occured at any point
% currentState = a string letting you know an updated current state of either being needing to be opened or closed 
% stateChangeTime = a array of times that is updated every iteration letting you know the times in which the states changed from previous state to current state (provided they're different%
% stateChangeVoltageHolder = this is another array of updated voltages in
% which the state was deemed changed from the previous state to the current state (again considering theyre different)
%
% Examples of Usage:
%  [stateChangeOccurred, currentState, stateChangeTime, stateChangeVoltageHolder] = checkStateChange(lightLevel, openLimit, previousState, timeCovered, stateChangeTime, stateChangeVoltageHolder)
% stateChangeOccured = 1
%currentState = "Open"
%stateChangeTime = [ f(1) ] ---> (the time at when it was true(1))
%stateChangeVoltageHolder = [ voltage(1)]

function [stateChangeOccurred, currentState, stateChangeTime, stateChangeVoltageHolder] = checkStateChange(lightLevel, openLimit, previousState, timeCovered, stateChangeTime, stateChangeVoltageHolder)    
    % Determine the current state based on the light level
      if lightLevel >openLimit 
           currentState = "Open"; %state now is to open the blinds%
      elseif lightLevel<openLimit
           currentState = "Close"; %but if its less, close the blinds%
      end

    % Check if the state has changed
    if ~strcmpi(currentState, previousState) %if there is a change in state(light to no light) then proceed
        stateChangeOccurred = true; % State has changed
        % Update the time and light level arrays for plotting
       stateChangeTime = [stateChangeTime timeCovered]; %this creates an array we can later update the plot with containing the time the state changed alongside the elapsed time% 
       stateChangeVoltageHolder = [stateChangeVoltageHolder lightLevel]; %this creates an array we can later update the plot with containing the light voltage at the state changing point%
    else
        stateChangeOccurred = false; % State has not changed
    end
end