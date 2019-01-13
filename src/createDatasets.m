function [] = createDatasets()
%createDatasets this function creates and saves to disk the 4 datasets
%needed for the short project: trainingEyes, trainingNotEyes,
%testingEyes, testingNotEyes
%   this function reads and writes to ..\data
clc;
clear;

notEyes = zeros([32,128,1521*19]);
eyeStrips = zeros([32,128,1521]);
eyeCoords = zeros(1,4,1521);

%llegir les posicions
eyeLocs = dir(fullfile('data\originalDataset', '*.eye'));
peopleImages = dir(fullfile('data\originalDataset', 'BioID*.pgm'));

for idx = 1:numel(eyeLocs)
    fi = eyeLocs(idx);
    eyeCoordsFile = fopen(strcat(fullfile('data\originalDataset', fi.name)));
    textscan(eyeCoordsFile,'%s %s %s %s',1);
    eyeCoords(:,:,idx)= double(cell2mat(textscan(eyeCoordsFile,'%d %d %d %d',1)));
    fclose('all'); 
end 

%eyeCoords = matrix containing positions of both eyes

%abans de fer mes calculs, netejar les variables inutils?
clearvars eyeLocs
%now, from all the images of people, extract only the part with eyes

for i = 1:1521
    Im = imread(fullfile(peopleImages(i).folder, peopleImages(i).name));
    [F C] = size(Im);
    center1 = eyeCoords(1,1:2,i); %LX LY
    center2 = eyeCoords(1,3:4,i); %RX RY
    dist = uint32(abs(center2(1)-center1(1))*0.3);
    disty = dist/2;
    
    left = max(1,min(center1(1),center2(1))-dist);
    right = min(C,max(center1(1),center2(1))+dist);
    top = max(1, min(center1(2),center2(2)) - disty);
    bot = min(F, max(center1(2),center2(2)) + disty);
    eyeStrips(:,:,i) = imresize(Im(top:bot,left:right),[32,128]);
end
%eyeStrips es una array de rectangles que contenen els ulls de cada imatge

n = 1521;  %nombre d'imatges d'on agafar samples de no ulls
for i = 1:n
    Im = imread(fullfile(peopleImages(i).folder, peopleImages(i).name));
    [F C] = size(Im);
    for j = 1:19
        y = randi(F-32);    %y and x are the upper left coords of the window
        x = randi(C-128);
        %ens hem d'assegurar que no agafem del tro� amb ulls
        while  (x < eyeCoords(1,1,i) && eyeCoords(1,1,i) < (x+64) || ...
                (x+64) < eyeCoords(1,3,i) && eyeCoords(1,3,i) < (x+128)) && ...
               (y < eyeCoords(1,2,i) && eyeCoords(1,2,i) < (y+32) || ...
                y < eyeCoords(1,4,i) && eyeCoords(1,4,i) < (y+32))
            y = randi(F-32);    %y and x are the upper left coords of the window
            x = randi(C-128);
        end
        %afegir l'imatge a noteyes
        notEyes(:,:,(i-1)*19+j) = Im(y:y+31,x:x+127);
    end
end
%afegir imatges que nom�s tinguin un ull a notEyes?


%crear els sets d'imatges de training i de testing
nEyes = uint32(size(eyeStrips,3))-1;
nNotEyes = uint32(size(notEyes,3))-1;
trainingEyes = eyeStrips(:,:,1:nEyes*0.9);
trainingNotEyes = notEyes(:,:,1:nNotEyes*0.9); 
testingEyes = eyeStrips(:,:,nEyes*0.9+1:end);
testingNotEyes = notEyes(:,:,nNotEyes*0.9+1:end); 

%save to file
save('data\TrainData.mat', 'trainingEyes','trainingNotEyes');
save('data\TestData.mat', 'testingEyes','testingNotEyes');

expectedLabels = xlsread("data\Miram.xlsx", 1, "E5:E1525");
trainigGLab = expectedLabels(1:length(trainingEyes));
testingGLab = expectedLabels(length(trainingEyes)+1:end);

save('data\GazeLabelsData.mat', 'trainigGLab','testingGLab')

end

