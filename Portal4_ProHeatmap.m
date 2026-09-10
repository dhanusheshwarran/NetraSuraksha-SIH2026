% --- NETRASURAKSHA PORTAL 4: PRO GEOSPATIAL HEATMAP & ANALYTICS ---
clc; clear; close all;

disp('Launching Portal 4 Pro Heatmap Radar...');
registryFile = 'live_registry.csv';

% Base coordinates for Tamil Nadu districts
geoMap = dictionary(["Coimbatore", "Madurai", "Trichy", "Salem", "Chennai"], ...
                    {[11.0168, 76.9558], [9.9252, 78.1198], [10.7905, 78.7047], [11.6643, 78.1460], [13.0827, 80.2707]});
districts = keys(geoMap);

% 1. Read live patient data
if isfile(registryFile)
    rawData = readtable(registryFile, 'TextType', 'string');
else
    disp('No live data found. Map will initialize at zero baseline.');
    rawData = table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
        'VariableNames', {'Timestamp', 'State', 'District', 'Block', 'Verdict'});
end

% 2. Crunch analytics per district
TotalScanned = zeros(length(districts), 1);
ReferableCount = zeros(length(districts), 1);
SafeCount = zeros(length(districts), 1);
Lats = zeros(length(districts), 1); 
Lons = zeros(length(districts), 1);

for i = 1:length(districts)
    d = districts(i);
    TotalScanned(i) = sum(rawData.District == d);
    ReferableCount(i) = sum(rawData.District == d & rawData.Verdict == "Referable");
    SafeCount(i) = TotalScanned(i) - ReferableCount(i);
    
    coordsCell = geoMap(d); coords = coordsCell{1}; 
    Lats(i) = coords(1); Lons(i) = coords(2);
end

% 3. Render High-End Dark UI Window
fig = uifigure('Name', 'Portal 4: NPCBVI National Heatmap Radar', 'Position', [100, 100, 1100, 750], 'Color', [0.05 0.05 0.05]);

uilabel(fig, 'Text', 'NPCBVI National Health Radar: Live Epidemiological Density', ...
    'Position', [20, 700, 700, 30], 'FontSize', 18, 'FontWeight', 'bold', 'FontColor', 'w');

% Create professional geographic axes with dark terrain styling
gx = geoaxes(fig, 'Position', [0.04 0.04 0.92 0.88]);
geobasemap(gx, 'darkwater');
gx.MapCenter = [11.12, 78.65]; % Centered precisely on Tamil Nadu
gx.ZoomLevel = 7;

hold(gx, 'on');

% 4. Render Smooth Heat Density Effect
% FIX: We mathematically duplicate the coordinates based on screening volume to create genuine heat map intensity.
% Multiplied by 50 to ensure even 1 patient creates a visible, glowing hotspot.
expandedLats = repelem(Lats, (TotalScanned + 1) * 50);
expandedLons = repelem(Lons, (TotalScanned + 1) * 50);

% Plot the smooth density layer underneath
hDensity = geodensityplot(gx, expandedLats, expandedLons, 'FaceAlpha', 0.6);
colormap(gx, 'hot'); % Applies glowing fire colors to the map

% 5. Plot precise interactive target markers over the heat zones
markerColors = repmat([0 0.8 0], length(districts), 1); 
markerColors(ReferableCount > 0, :) = repmat([1 0.2 0.2], sum(ReferableCount > 0), 1); 
markerSizes = 80 + (TotalScanned * 40);

sc = geoscatter(gx, Lats, Lons, markerSizes, markerColors, 'filled', ...
    'MarkerEdgeColor', 'w', 'LineWidth', 2);

% 6. Custom Dynamic Data Tipping (Zoom in and tap for analytics breakdown)
customTips = strings(length(districts), 1);
for i = 1:length(districts)
    customTips(i) = sprintf(' DISTRICT: %s \n -------------------------- \n 📊 Total Scanned: %d \n 🔴 Referable (Critical): %d \n 🟢 Non-Referable (Safe): %d ', ...
        districts(i), TotalScanned(i), ReferableCount(i), SafeCount(i));
end

sc.DataTipTemplate.DataTipRows(1) = dataTipTextRow('', customTips);
sc.DataTipTemplate.DataTipRows(2) = []; 
sc.DataTipTemplate.DataTipRows(3) = []; 
sc.DataTipTemplate.Interpreter = 'none';

disp('✅ Pro Heatmap loaded. Use the zoom controls and tap location pins to inspect regional patient statistics.');