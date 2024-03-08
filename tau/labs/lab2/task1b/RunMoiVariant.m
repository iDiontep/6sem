clc;
clear all;
close all;

tic;                                    % запуск секундомера

XMAX = 3;                               % размер сетки рисования
STEP = 0.2;                             % шаг сетки
TMAX = 3;                              % время моделирования
MAINSYSNAME = "Laboratory";         % название модели
SUBSYSNAME = "moiVariant";               % название подмодели


simInitSet(TMAX, MAINSYSNAME, SUBSYSNAME);                  % инициализация параметров системы
plotLocus(XMAX, STEP, MAINSYSNAME, SUBSYSNAME);             % построение фазовых портретов

toc;                                    % остановка секундомера
