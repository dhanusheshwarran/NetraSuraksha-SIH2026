function processedImg = preprocessFundus(rawImg, targetSize)
if nargin < 2, targetSize = [224, 224]; end
if ischar(rawImg) || isstring(rawImg)
    img = imread(rawImg);
else
    img = rawImg;
end

% Resize image
imgResized = imresize(img, targetSize);

% Ben Graham illumination subtraction
blurred = imgaussfilt(imgResized, 10);
processedImg = imlincomb(4, imgResized, -4, blurred, 128);
end