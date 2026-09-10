% --- NETRASURAKSHA PORTAL 1: FULL PATIENT INTAKE & TRIAGE ---
clc; clear; close all;

% ==========================================
% PAGE 1: LOCATION SETUP
% ==========================================
locFig = uifigure('Name', 'NetraSuraksha: Location Setup', 'Position', [400, 200, 400, 400], 'Color', [0.1 0.1 0.1]);
uilabel(locFig, 'Text', 'NETRASURAKSHA: LOCATION', 'Position', [85, 330, 300, 30], 'FontSize', 18, 'FontWeight', 'bold', 'FontColor', 'w');
uilabel(locFig, 'Text', 'State:', 'Position', [50, 260, 100, 22], 'FontColor', 'w');
stateDrop = uidropdown(locFig, 'Items', {'Tamil Nadu'}, 'Position', [50, 235, 300, 22]);
uilabel(locFig, 'Text', 'District:', 'Position', [50, 190, 100, 22], 'FontColor', 'w');
distDrop = uidropdown(locFig, 'Items', {'Coimbatore', 'Madurai', 'Trichy', 'Salem', 'Chennai'}, 'Position', [50, 165, 300, 22]);
uilabel(locFig, 'Text', 'Block / Taluk:', 'Position', [50, 120, 150, 22], 'FontColor', 'w');
blockDrop = uidropdown(locFig, 'Items', {'Pollachi', 'Mettupalayam', 'Sulur', 'Kinathukadavu'}, 'Position', [50, 95, 300, 22]);
uibutton(locFig, 'Text', 'NEXT ➔', 'Position', [50, 30, 300, 40], 'BackgroundColor', [0 0.4 0.8], 'FontColor', 'w', 'ButtonPushedFcn', @(btn,event) uiresume(locFig));
uiwait(locFig);
if ~isvalid(locFig), return; end

patientState = stateDrop.Value; patientDistrict = distDrop.Value; patientBlock = blockDrop.Value;
close(locFig);

% ==========================================
% PAGE 2: PATIENT VITALS
% ==========================================
patFig = uifigure('Name', 'NetraSuraksha: Patient Vitals', 'Position', [400, 150, 400, 550], 'Color', [0.1 0.1 0.1]);
uilabel(patFig, 'Text', 'PATIENT REGISTRATION', 'Position', [100, 480, 300, 30], 'FontSize', 18, 'FontWeight', 'bold', 'FontColor', 'w');
uilabel(patFig, 'Text', 'Full Name:', 'Position', [50, 430, 100, 22], 'FontColor', 'w');
nameEdit = uieditfield(patFig, 'text', 'Position', [50, 405, 300, 22]);
uilabel(patFig, 'Text', 'Age:', 'Position', [50, 365, 50, 22], 'FontColor', 'w');
ageEdit = uieditfield(patFig, 'numeric', 'Position', [50, 340, 100, 22]);
uilabel(patFig, 'Text', 'Gender:', 'Position', [200, 365, 50, 22], 'FontColor', 'w');
genderDrop = uidropdown(patFig, 'Items', {'Male', 'Female', 'Other'}, 'Position', [200, 340, 150, 22]);
uilabel(patFig, 'Text', 'Blood Sugar Level (RBS):', 'Position', [50, 295, 200, 22], 'FontColor', 'w');
sugarEdit = uieditfield(patFig, 'numeric', 'Position', [50, 270, 300, 22]);
uilabel(patFig, 'Text', 'Other Known Disabilities:', 'Position', [50, 225, 200, 22], 'FontColor', 'w');
disabilityEdit = uieditfield(patFig, 'text', 'Position', [50, 200, 300, 22], 'Value', 'None');
uilabel(patFig, 'Text', 'Phone Number (For Alerts):', 'Position', [50, 155, 200, 22], 'FontColor', 'w');
phoneEdit = uieditfield(patFig, 'text', 'Position', [50, 130, 300, 22]);
uibutton(patFig, 'Text', 'CAPTURE FUNDUS IMAGE 📷', 'Position', [50, 40, 300, 50], 'BackgroundColor', [0 0.6 0], 'FontColor', 'w', 'ButtonPushedFcn', @(btn,event) uiresume(patFig));
uiwait(patFig);
if ~isvalid(patFig), return; end

pName = string(nameEdit.Value); pAge = num2str(ageEdit.Value); pGender = string(genderDrop.Value);
pSugar = num2str(sugarEdit.Value); pDisability = string(disabilityEdit.Value); pPhone = string(phoneEdit.Value);
close(patFig);
if pName == "", pName = "Unknown Patient"; end
if pPhone == "", pPhone = "No Number"; end

% ==========================================
% PAGE 3: IQG & AI INFERENCE
% ==========================================
[file, path] = uigetfile({'*.png;*.jpg', 'Images'}, 'Capture Patient Retina');
if isequal(file, 0), return; end
img = imread(fullfile(path, file));

imwrite(img, 'current_patient_scan.jpg');

% 1. Isolate the actual retina (ignore the massive black borders)
grayEye = rgb2gray(img);
eyeMask = grayEye > 15; 

% 2. Apply a micro-blur just to kill digital web noise, preserving vessels
cleanGray = imgaussfilt(grayEye, 0.5);

% 3. Calculate Laplacian variance ONLY on the illuminated retinal pixels
laplacianImg = imfilter(double(cleanGray), fspecial('laplacian', 0.2), 'replicate');
blurMetric = var(laplacianImg(eyeMask));

% Healthy retinas will now score well above 30. Blurry ones drop below.
if blurMetric < 30.0
    figure('Name', 'Portal 1: IQG Alert', 'Position', [200, 200, 400, 400]);
    imshow(img); title(sprintf('❌ REJECTED: BLURRY (\\sigma^2 = %.1f)', blurMetric), 'Color', 'red', 'FontSize', 14); 
    return;
end

try
    load('netrasuraksha_matlab_binary_95plus.mat', 'trainedNet');
    [pred, ~] = classify(trainedNet, imresize(img, [224, 224])); verdict = string(pred);
catch
    verdict = "Referable"; % Demo Failsafe
end

try
    load('netrasuraksha_matlab_binary_95plus.mat', 'trainedNet');
    [pred, ~] = classify(trainedNet, imresize(img, [224, 224])); verdict = string(pred);
catch
    verdict = "Referable"; % Demo Failsafe
end

% ==========================================
% PAGE 4: HEALTH WORKER RESULT DASHBOARD
% ==========================================
resFig = uifigure('Name', 'Portal 1: AI Triage Result', 'Position', [450, 250, 400, 250], 'Color', [0.1 0.1 0.1]);
uilabel(resFig, 'Text', sprintf('Patient: %s', pName), 'Position', [20, 180, 360, 30], 'FontColor', 'w', 'FontSize', 14, 'HorizontalAlignment', 'center');

if verdict == "Referable"
    uilabel(resFig, 'Text', '🚨 REFERABLE', 'Position', [20, 120, 360, 40], 'FontColor', [1 0.2 0.2], 'FontSize', 22, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    uilabel(resFig, 'Text', 'Action: Data syncing to Specialist (Portal 3).', 'Position', [20, 80, 360, 20], 'FontColor', 'w', 'HorizontalAlignment', 'center');
else
    uilabel(resFig, 'Text', '✅ NON-REFERABLE', 'Position', [20, 120, 360, 40], 'FontColor', [0 0.8 0], 'FontSize', 22, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    uilabel(resFig, 'Text', 'Action: Patient is safe. Routine checkup in 12 months.', 'Position', [20, 80, 360, 20], 'FontColor', 'w', 'HorizontalAlignment', 'center');
end

uibutton(resFig, 'Text', 'SYNC DATA & CLOSE', 'Position', [100, 20, 200, 40], 'BackgroundColor', [0 0.4 0.8], 'FontColor', 'w', 'ButtonPushedFcn', @(btn,event) uiresume(resFig));
uiwait(resFig);
if isvalid(resFig), close(resFig); end

% ==========================================
% DATABASE SYNC
% ==========================================
registryFile = 'live_registry.csv';
timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
if ~isfile(registryFile)
    fid = fopen(registryFile, 'w');
    fprintf(fid, 'Timestamp,State,District,Block,Name,Age,Gender,BloodSugar,Disability,Phone,Verdict\n');
    fclose(fid);
end
fid = fopen(registryFile, 'a');
fprintf(fid, '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n', timestamp, patientState, patientDistrict, patientBlock, pName, pAge, pGender, pSugar, pDisability, pPhone, verdict);
fclose(fid);