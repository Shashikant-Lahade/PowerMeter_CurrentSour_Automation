clear all;
close all;

tic; % Start timer to see how long program takes to execute

% Source Meter Configuration
startCurrent = 0; % mA
endCurrent = 25; % mA
stepCurrent = 0.1; % mA

wv = '680';
no_reading = (endCurrent - startCurrent) / stepCurrent + 1;

currentData = startCurrent:stepCurrent:endCurrent;
voltageData = zeros(size(currentData));

% Connect to Keithley source meter
keithley = visa('NI', 'USB::0x05E6::0x2450::04391527::INSTR');
fopen(keithley);

% Power Meter Configuration
num_points = length(currentData);
num_readings = 1; % Number of readings per point
PauseTime = 0.1; % Pause between steps during measurements

% Connect to ThorLabs power meter
meter = visa('NI', 'USB::0x1313::0x8078::P0016567::INSTR');
fopen(meter);
fprintf(meter, ['SENSe:CORRection:WAVelength ', wv]);
wavelength = query(meter, 'SENSe:CORRection:WAVelength?');

% Initialize array to store readings
power_readings = zeros(num_points, num_readings);

% Synchronize data collection
for i = 1:num_points
    % Set current on Keithley source meter
    fprintf(keithley, ['SOUR:CURR ', num2str(currentData(i)/1000)]); % Convert to A
    
    % Read voltage from Keithley
    fprintf(keithley, 'MEAS:VOLT?');
    voltageData(i) = str2double(fscanf(keithley));
    
    % Read power from ThorLabs power meter
    for k = 1:num_readings
        fprintf(meter, 'MEASure:POWer');
        pause(PauseTime);
   
        power_string = query(meter, 'READ?');       % Reads the power from the power meter
        power_readings(i, k) = str2double(power_string);
    end
end

% Close connections
fclose(keithley);
delete(keithley);
fclose(meter);
delete(meter);

% Plot data
figure;
subplot(2, 1, 1);
plot(currentData, voltageData, 'b.-');
xlabel('Current (mA)');
ylabel('Voltage (V)');
title('Keithley Source Meter Data');

subplot(2, 1, 2);
plot(currentData, power_readings, 'r.-');
xlabel('Current (mA)');
ylabel('Power (W)');
title('ThorLabs Power Meter Data');

toc; % End timer

% % Save data to file
filename = [wv 'nm_VCSEL_Char'];
save([filename '.mat'], 'currentData', 'voltageData', 'power_readings');
csvwrite([filename '.csv'], [currentData', voltageData', power_readings]);
savefig([filename '.fig']);
saveas(gcf, [filename '.png']); % Save figure as .png

