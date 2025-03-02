function u = fcn(y)
% Define system dynamics 
%state space model

Ass = [-3.038*10^-3 -433.12 433.12; 0 -0.012 0; 0 0 -0.017];
Bss = [0 0; 9.27*10^-6 0; 0 2.34*10^-6];

Ts = 5;%sampleing period

A = Ass.*Ts + 1;

n = size(A, 1); % #states = 3 

B = Bss.*Ts;

p = size(B, 2); % #inputs = 2 

% Define cost matrices 

Q = diag([10, 1, 1]); % State cost (glucose more important) 

R = diag([1, 1]); % Control cost (insulin/glucagon effort) 

Qf = Q; % Terminal cost 

% Prediction Horizon 

N = 5; 

% Reference signal 

r = 100; 

%r_vec = repmat([r; r; r], N+1, 1);% Extend reference for the horizon 

% Construct M and C matrices 

M = [eye(n); zeros(N*n, n)];  

C = zeros((N+1)*n, N*p); 

tmp = eye(n);  

for i = 1:N  

rows = i*n + (1:n);  

C(rows,:) = [tmp*B, C(rows-n, 1:end-p)];  

tmp = A * tmp;  

M(rows, :) = tmp;  

end  

% Define Q_bar and R_bar 

Q_bar = kron(eye(N), Q); 

Q_bar = blkdiag(Q_bar, Qf); 

R_bar = kron(eye(N), R);  

% Compute quadratic program matrices 

F = C' * Q_bar * M; % Adjust for reference  

H = C' * Q_bar * C + R_bar;  

G = M' * Q_bar * M;

% Solve QP problem 


% Optimization options 

options = optimoptions('quadprog', 'Algorithm', 'active-set', 'Display', 'off'); 

x0 = [y-r;0;0]; 

X0 = zeros(1,10); 


% Solve QP problem with proper argument structure 

u_k = quadprog(H, 2.*x0'*F', [], [], [], [], zeros(1,10)', [], X0, options); 

% Extract first control action 

u = u_k(1:p);
%u(1,1) muU/ml
%u(2,1) pg/ml
%align the units
u(1,1) = u(1,1)*10^-3;


y = u;
