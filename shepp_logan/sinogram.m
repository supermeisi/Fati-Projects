clc;
clear;
P = phantom(256);
imshow(P)
title('original image')
theta1 = 0:10:170; 
[R1,xp] = radon(P,theta1);
theta2 = 0:5:175;
[R2,xp] = radon(P,theta2);
theta3 = 0:2:178; 
[R3,xp] = radon(P,theta3);

figure, imagesc(theta3,xp,R3); colormap(hot); colorbar
xlabel('\theta'); ylabel('x\prime')

figure, 
imagesc(theta3,xp,R3); colormap(hot); colorbar
xlabel('\theta'); ylabel('x\prime');
