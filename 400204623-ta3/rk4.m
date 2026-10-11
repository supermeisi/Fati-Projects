% Runge-Kutta method to solve up to a third order ODE which is an IVP(Initial Value Problem)
%    a1(t)y''' + a2(t)y'' + a3(t)y' + a4(t)y = f(t)
%    t = the independent vatiable; t = [t0 tn]
%    y = the dependent variable y(t)
%    Initial conditions:y(t0)   = v0,y'(t0)  = v1,y''(t0) = v2
 function rk4gui03()
 clc
 % Create the GUI menu
 figure('Position',[33 319 839 624], ...
       'Name','rk4','Color','w','NumberTitle','off'); 
 
 handles = createGUIenvironment();
 
% Execute button
uicontrol('Style', 'pushbutton', 'String','RUN', ...
          'ForegroundColor','k', ...
          'BackgroundColor',[0.8 0.8 0], ...
          'FontSize',11,'FontWeight','bold', ...
          'Units','normalized','Position', [0.675 0.75 0.1 0.05], ...
          'Callback',{@solveIVP,handles});
% view report
uicontrol('Style', 'pushbutton', 'String','ViewReport', ...
          'ForegroundColor','k', ...
          'BackgroundColor',[0.8 0.8 0], ...
          'FontSize',11,'FontWeight','bold', ...
          'Units','normalized','Position', [0.65 0.65 0.15 0.05], ...
          'Callback',{@viewReport,handles});
% Callback function: solveIVP
function solveIVP(~,~,handles)
global N sa0 sa1 sa2 sa3 sf 
ndbg = 1;
clc
% degree of ODE
v = get(handles.h_n,'String');      N = str2double(v);
if N<1 || N>3
    s1 = 'ERROR';
    s2 = 'The order of the ODE should be between 1 and 3';
    errordlg({s1,s2},'Execution Error');
end
    
% coefficients
sa0 = get(handles.h_a0,'String'); 
sa1 = get(handles.h_a1,'String');    
sa2 = get(handles.h_a2,'String'); 
sa3 = get(handles.h_a3,'String'); 
switch N
    case 1      % set a2, a3, v1, v2 to zero
        sa2='0';  set(handles.h_a2,'String',sa2);
        sa3='0';  set(handles.h_a3,'String',sa3);
        set(handles.h_v1,'String','0');
        set(handles.h_v2,'String','0');
    case 2      % set a3, v2 to zero
        sa3='0';  set(handles.h_a3,'String',sa3);
        set(handles.h_v2,'String','0');
end
% f(t)
sf = get(handles.h_f,'String'); 
% t0, tn and h
v = get(handles.h_t0,'String');   t0 = str2double(v);
v = get(handles.h_tn,'String');   tn = str2double(v);
v = get(handles.h_h,'String');    h = str2double(v);
% initial conditions
v = get(handles.h_v0,'String');   v0 = str2double(v);
v = get(handles.h_v1,'String');   v1 = str2double(v);
v = get(handles.h_v2,'String');   v2 = str2double(v);

if h>=(tn-t0); h=(tn-t0)/20; end
ta = (t0:h:tn)';  % n = length(ta);
% initial conditions
switch N
    case 1
        y0 = v0;
    case 2
        y0 = [v0 v1];
    case 3
        y0 = [v0 v1 v2];
end

st1 = sprintf('You are solving the IVP:');
if N==1
    st2 = sprintf('ODE: (%s)y'' + (%s)y = %s',sa1,sa0,sf);
end
if N==2
    st2 = sprintf('ODE: (%s)y'''' + (%s)y'' + (%s)y = %s',sa2,sa1,sa0,sf); 
end
if N==3
    st2 = sprintf('ODE: (%s)y'''''' + (%s)y'''' + (%s)y'' + (%s)y = %s',sa3,sa2,sa1,sa0,sf); 
end
st3 = sprintf('Solution domain:  t = [%-4.1f,%-4.1f]; Step size, h=%-6.3f',t0,tn,h);
if N==1
    st4 = sprintf('InitialCondition:   y(%-4.1f)=%-6.2f',t0,v0); 
end
if N==2
    st4 = sprintf('InitialConditions:  y(%-4.1f)=%-6.2f, y''(%-4.1f)=%-6.2f',t0,v0,t0,v1); 
end
if N==3
    st4 = sprintf('InitialConditions:  y(%-4.1f)=%-6.2f, y''(%-4.1f)=%-6.2f, y''''(%-4.1f)=%-6.2f', ...
        t0,v0,t0,v1,t0,v2); 
end
str = {st1,st2,st3,st4};
set(handles.h_p,'String',str);

% solve with myRK4
[tp,yp] = myRK4(@f,ta,y0);

if ndbg
    fid = fopen('rk4out.txt','w');
    for i=1:length(tp)
        fprintf(fid,'%7.4f %12.5e\n',tp(i),yp(i,1));
    end
    fclose(fid);
end
% plot solution 
figure(2); clf(2); set (gcf,'Color','w');
plot(tp,yp(:,1),'k-','LineWidth',2); 
grid
xlabel('t');  ylabel('y(t)');
title('Solution for y(t)');
saveas(gcf, 'rk4plot', 'jpg');

fid = fopen('rk4solution.txt','w');
fprintf(fid,'SPECIFIED IVP:\n');
fprintf(fid,'  %s\n',st2);
fprintf(fid,'  %s\n',st3);
fprintf(fid,'  %s\n',st4);
fprintf(fid,'\nSOLUTION\n');
fprintf(fid,'       t          y(t)         y''(t)\n');
fprintf(fid,' -------  ------------  ------------\n');
for i=1:length(tp)
    if N>=2
        fprintf(fid,'%8.3f  %12.4e  %12.4e\n',tp(i),yp(i,1),yp(i,2));
    else
        fprintf(fid,'%8.3f  %12.4e \n',tp(i),yp(i,1));
    end
end

currdir = pwd;
s1 = 'Note:';
s2 = 'The plot has been saved as the file rk4plot.jpg';
s3 = 'The report has been saved as the file rk4solution.txt';
s4 = sprintf('Both files are in the directory (or folder) %s',currdir);
fprintf(fid,'\n  %s\n',s1);
fprintf(fid,'  %s\n',s2);
fprintf(fid,'  %s\n',s3);
fprintf(fid,'  %s\n',s4);

fclose(fid);
% Callback function: viewReport
function viewReport(~,~,~)
system('start notepad rk4solution.txt');
% myRK4
function [tp,yp] = myRK4(f,ta,y0)
n = length(ta);         % rows
m = length(y0);         % columns
tp = ta;
h = ta(2) - ta(1);      % step size
h2 = h/2;   h6 = h/6;
yp = zeros(n,m);
yp(1,:) = y0;           % initial condition
for i=2:n
    im = i-1;
    argt = ta(im);
    for j=1:m
        argy(j) = yp(im,j);
    end
    k1 = f(argt,argy);
    argt = ta(im) + h2;
    for j=1:m
        argy(j) = yp(im,j) + k1(j)*h2;
    end
    k2 = f(argt,argy);
    argt = ta(im) + h2;
    for j=1:m
        argy(j) = yp(im,j) + k2(j)*h2;
    end
    k3 = f(argt,argy);
    argt = ta(im) + h;
    for j=1:m
        argy(j) = yp(im,j) + k3(j)*h;
    end
    k4 = f(argt,argy);
    for j=1:m
        yp(i,j) = yp(im,j) + h6*(k1(j) + 2*k2(j) + 2*k3(j) + k4(j));
    end
end
% f(t,y)
function z = f(t,y)
global N sa0 sa1 sa2 sa3 sf 
fa0=@(t) eval(sa0);     a0 = fa0(t);
fa1=@(t) eval(sa1);     a1 = fa1(t);
fa2=@(t) eval(sa2);     a2 = fa2(t);
fa3=@(t) eval(sa3);     a3 = fa3(t);
fct=@(t) eval(sf);      ft = fct(t);
switch N
    case 1
        z = (ft - a0*y(1))/a0;
    case 2
        z1 = y(2);
        z2 = (ft - a0*y(1) - a1*y(2))/a2;
        z = [z1 z2]';
    case 3
        z1 = y(2);
        z2 = y(3);
        z3 = (ft - a0*y(1) - a1*y(2) - a2*y(3))/a3;
        z = [z1 z2 z3]';
end
% createGUIenvironment
function [handles,xc,yc] = createGUIenvironment()
annotation('textbox',[0.25 0.75 0.35 0.25], ...
           'String','4^{th} order Runge-Kutta','Color',[0 0 0],'EdgeColor','none', ...
           'FontWeight','bold','FontSize',12,'BackgroundColor','g','FitBoxToText','on');
str1 = 'Use the 4{th} order Runge-Kutta method to solve up to a 3{rd} order ODE of the form';
str2 = ' a_3(t)y'''''' + a_2(t)y'''' + a_1(t)y'' + a_0y = f(t)';
str3 = ' in the domain t=[t_0,t_n];  Initial conditions: y(t_0)=v_0, y''(t_0)=v_1, y''''(t_0)=v_2.';
annotation('textbox',[0.05 0.74 0.95 0.2], ...
           'String',{[str1,str2],str3},'Color','k','EdgeColor','none', ...
           'FontWeight','bold','FontSize',10,'FitBoxToText','on');
% Input data
xc=0.05; yc=0.78; wt=0.1; ht=0.04;
% Order of ODE
uicontrol('Style', 'text','String','n, Order of the ODE', ...
          'FontSize',9,'FontWeight','bold', ...
          'Units','normalized','Position', [xc yc 2.5*wt ht]);
handles.h_n = uicontrol('Style', 'edit','String','3', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+2.5*wt yc 0.08 ht]);
% a-coefficients 
yc=yc-1.5*ht;  wx = 0.3;
annotation('textbox',[xc yc 6*wt ht], ...
           'String','Enter valid Matlab expressions for coefficients a_0,a_1,a_2,a_3.', ...
           'Color','k','EdgeColor','none', ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
yc=yc-ht;
annotation('textbox',[xc yc 1.5*wt ht],'String','Enter a_0(t)', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_a0 = uicontrol('Style', 'edit','String','-4', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+wt yc-0.01 wx ht*1.1]);
yc=yc-ht;
annotation('textbox',[xc yc 1.5*wt ht],'String','Enter a_1(t)', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_a1 = uicontrol('Style', 'edit','String','3*t', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+wt yc-0.01 wx ht*1.1]);
yc=yc-ht;
annotation('textbox',[xc yc 1.5*wt ht],'String','Enter a_2(t)', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_a2 = uicontrol('Style', 'edit','String','-t^2', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+wt yc-0.01 wx ht*1.1]);
yc=yc-ht;
annotation('textbox',[xc yc 1.5*wt ht],'String','Enter a_3(t)', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_a3 = uicontrol('Style', 'edit','String','t^3', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+wt yc-0.01 wx ht*1.1]);
yc=yc-1.5*ht;
annotation('textbox',[xc yc 6*wt ht], ...
           'String','Enter a valid Matlab expression for f(t)', ...
           'Color','k','EdgeColor','none', ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
yc=yc-ht;
annotation('textbox',[xc yc 1.5*wt ht],'String','Enter f(t)', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_f = uicontrol('Style', 'edit','String','5*t^2*log(t) + 9*t^3', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+wt yc-0.01 0.3 ht*1.1]);
% domain and step size
yc=yc-1.5*ht;  wx = 0.1;
annotation('textbox',[xc yc 6*wt ht], ...
           'String','Enter the domain, [t_0, t_n] and the solution step size, h', ...
           'Color','k','EdgeColor','none', ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
yc=yc-ht;
annotation('textbox',[xc yc 2.5*wt ht],'String','Enter initial time, t_0 ', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_t0 = uicontrol('Style', 'edit','String','1', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+1.5*wt yc-0.01 wx ht*1.1]);
yc=yc-ht;
annotation('textbox',[xc yc 2.5*wt ht],'String','Enter final time,  t_n  ', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_tn = uicontrol('Style', 'edit','String','2', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+1.5*wt yc-0.01 wx ht*1.1]);
yc=yc-ht;
annotation('textbox',[xc yc 2.5*wt ht],'String',' Enter step size,   h ', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_h = uicontrol('Style', 'edit','String','0.1', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+1.5*wt yc-0.01 wx ht*1.1]);
% Initial conditions
yc=yc-1.5*ht;
annotation('textbox',[xc yc 6*wt ht], ...
           'String','Initial conditions', ...
           'Color','k','EdgeColor','none', ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
yc=yc-ht;  wx = 0.15;
annotation('textbox',[xc yc 2.5*wt ht],'String','Enter y(t_0)   ', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_v0 = uicontrol('Style', 'edit','String','0', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+0.9*wt yc-0.01 wx ht*1.1]);
yc=yc-ht;
annotation('textbox',[xc yc 2.5*wt ht],'String','Enter y''(t_0)   ', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_v1 = uicontrol('Style', 'edit','String','1', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+0.9*wt yc-0.01 wx ht*1.1]);
yc=yc-ht;
annotation('textbox',[xc yc 2.5*wt ht],'String','Enter y''''(t_0)   ', ...
           'Color','k','EdgeColor','none','BackgroundColor',[0.9 0.9 0.9], ...
           'FontWeight','bold','FontSize',9,'FitBoxToText','on');
handles.h_v2 = uicontrol('Style', 'edit','String','3', ...
          'FontSize',10,'FontWeight','bold', ...
          'Units','normalized','Position', [xc+0.9*wt yc-0.01 wx ht*1.1]);
% problem defenition
xp=0.475;  yp=0.4;
s1 = 'You are solving this problem (from Burden):       ';
s2 = ' ODE:    (t^3)y'''''' - (t^2)y'''' + (3t)y'' - 4y = (t^3)(5ln(t) + 9)';
s3 = ' SolutionDomain: t = [1,2];  step size, h=0.1                     ';
s4= ' InitialCondition(s):   y(1)=0, y''(1)=1, y''''(1)=3';
str=[s1,s2,s3,s4];
handles.h_p = uicontrol('Style', 'text','String',str,'FontSize',9,'FontWeight','bold', ...
          'BackgroundColor','w','Units','normalized','Position', [xp yp 4.5*wt 4*ht]);

      