%function runClaw(location,destinaion)
%    runClaw2(location,destination);
%end

clear all; clc; close all;
location = [[55,420];[168,391];[268,370]];
destination = [[70,161];[198,192];[266,269]];
%claw = startClaw();
%claw.setAllJointsPosition([0,90,90,93,300]);
%joints = moveTo(100,200,50)
%[x,y] = translateToOrigin(180,290);
runClaw2(location,destination);

function runClaw2(location,destination)
    claw = startClaw();
    for i = 1 : 3
     [lx,ly] = translateToOrigin(location(i,1),location(i,2))
     joint_angles = moveTo(lx,ly,60);
     moveArm(claw,joint_angles);
     pause(2);
     grab(claw,[lx,ly]);
     pause(2);
     [dx,dy] = translateToOrigin(destination(i,1),destination(i,2));
     angles2 = moveTo(dx,dy,100);
     moveArm(claw,angles2);
     pause(2);
     release(claw,[dx,dy]);
     pause(2);
    end
    claw.stop();
end

function claw =  startClaw()
    claw = TheClaw();
    for id = claw.BASE:claw.WRIST
    claw.setJointTorqueEnable(id, 1); % Enable torque on motor
    claw.setJointControlMode(id, claw.POS_TIME); % Set mode to time to position
    claw.setJointTimeToPosition(id, 3); % Set joint time to position to 2 seconds
    end
end

function angle = positiveAngle(claw,oangle,cangle)
    angle = cangle - oangle;
end

function moveArm(claw,angles)
ANGLES = claw.getAllJointsPosition();
claw.setJointPosition(claw.BASE,round(angles(1),2));
claw.setJointPosition(claw.SHOULDER,round(angles(2),2));
claw.setJointPosition(claw.ELBOW,round(angles(3),2));
claw.setJointPosition(claw.WRIST,round(angles(4),2));
pause(3);
end

function grab(claw,location)
   %Open Claw
   claw.setJointPosition(claw.CLAW,350);
   pause(2);
   %Move down to object
   angles = moveTo(location(1),location(2),20);
   moveArm(claw,angles);
   pause(3);
   %Close Claw around object
   claw.setJointPosition(claw.CLAW,210);
   pause(2);
   %Raise up above object
   angles2 = moveTo(location(1),location(2),60);
   moveArm(claw,angles2);
end

function release(claw,location)
    %Move down
    angles = moveTo(location(1),location(2),20);
    moveArm(claw,angles);
    pause(3);
    %Open Claw
    claw.setJointPosition(claw.CLAW,250);
    pause(2);
    %Move up
    angles2 = moveTo(location(1),location(2),60);
    moveArm(claw,angles2);
    pause(2);
    %Close claw
    claw.setJointPosition(claw.CLAW,110);
    pause(2);
end

function [x,y] = translateToOrigin(inX,inY)
    origin = [100,290];
    x =  -1 * (origin(1) - inX);
    y =  (origin(2) - inY);
end

function joint_angles = moveTo(inX,inY,inZ)
c = 40.0;
h = 53.0;
r = 30.309;
L2 = 170.384;
L3 = 136.307;
L4 = 86.0;


a = inZ + L4 + c - h;
b = sqrt(inX ^ 2 +inY ^ 2) - r;
d = sqrt(a ^ 2 + b ^2);

beta = atan2d(a,b);
A = (-(L3^2) + d^2 + L2^2)/(2*L2*d);
alpha = atan2d(sqrt(1-A^2),A);
D = (-(d ^2) + L2 ^ 2 + L3 ^ 2) / (2 * L2 * L3);
q2 = atan2d(sqrt(1 -D^2),D);
%q1
q1 = alpha + beta;
%q0
q0 = atan2d(inY,inX);
%q2
q3 = 270 - q1 - q2;
%q3 = 90-q1-q2;

joint_angles = [q0,q1,q2,q3];

end