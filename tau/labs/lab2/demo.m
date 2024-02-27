clc;
close all;
clear all;

tic;

XMAX = 5; 
STEP = 0.5;
TMAX = 10;
BETA = 0.3;

[x1, x2] = meshgrid(-XMAX: STEP: XMAX);

dx = @(t,x) pendulumGrat(t,x, BETA)
