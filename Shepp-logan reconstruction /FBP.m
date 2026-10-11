clc;
clear all; close all;
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
I1 = iradon(R1,10);
I2 = iradon(R2,5);
I3 = iradon(R3,2);
imshow(I1)
title('FBP Iradon')
figure, imshow(I2)
figure, imshow(I3)
title('Filtered Backprojection')

figure, 
imagesc(theta3,xp,R3); colormap(hot); colorbar
xlabel('\theta'); ylabel('x\prime');


%___adding noise_______________________________________________

J1 = imnoise(I3,'salt & pepper',0.01);
imshow(J1)
title('low noise')
theta1 = 0:10:170; 
theta3 = 0:2:178; 
[R3,xp] = radon(J1,theta3);
I3 = iradon(R3,2);
figure, imshow(I3)
title('FBP of low noise')

J2 = imnoise(I3,'salt & pepper',0.025);
imshow(J2)
title('medium noise')
theta1 = 0:10:170; 
theta3 = 0:2:178; 
[R3,xp] = radon(J2,theta3);
I3 = iradon(R3,2);
figure, imshow(I3)
title('FBP of medium noise')

J3 = imnoise(I3,'salt & pepper',0.05);
imshow(J3)
title('high noise')
theta1 = 0:10:170; 
theta3 = 0:2:178; 
[R3,xp] = radon(J3,theta3);
I3 = iradon(R3,2);
figure, imshow(I3)
title('FBP of high noise')
