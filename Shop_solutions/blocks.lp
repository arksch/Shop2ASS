%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   START OF THE GENERAL METHODS   %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

not_finished(T) :- time(T), goal(State), not state(State, T).
:- goal(State), not state(State, T), maxtime(T).

%%%%%%%%%%%%%%%%%%
% Law of inertia %
%%%%%%%%%%%%%%%%%%
maxtime(100).  %% MANY PROBLEMS MIGHT NOT BE SOLVABLE IN 100 STEPS %%%
time(0..T) :- maxtime(T).
state(X, T+1) :- time(T), state(X, T), not deleted_state(X, T).
state(X, T+1) :- time(T), added_state(X, T).
:- deleted_state(X, T), not state(X,T).

%%%%%%%%%%%%%%%%%
% Stupid Solver %
%%%%%%%%%%%%%%%%%

%%%!!! YOU WILL HAVE TO CHANGE THIS GUESSING TO GET ACCEPTABLE PERFORMANCE !!!%%%

1 {currentTask(Op, Var, T) : operator_prerequisite(Op, Var, T), operator(Op) } 1 :- time(T), not_finished(T).
#minimize{C, T : action(Op, Var, T, TT, C)}.

%%%%%%%%%%%%%%%%
% Optimization %
%%%%%%%%%%%%%%%%

%%%!!! YOU WILL HAVE WRITE MANY OF THE SHOP METHODS HERE TO GET ACCEPTABLE PEFORMANCE !!!%%%

%%%%%%%%%%%%%%%%%%%%%%%%
% Showing the solution %
%%%%%%%%%%%%%%%%%%%%%%%%

#show currentTask/3.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% START OF THE PROBLEM SPECIFIC OPERATORS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%
% Atoms %
%%%%%%%%%


%%%%%%%%%%%%%%%%%%
% Initial States %
%%%%%%%%%%%%%%%%%%


%%%%%%%%%
% Goals %
%%%%%%%%%


%%%%%%%%%%%%%%%%
% Horn Clauses %
%%%%%%%%%%%%%%%%

same(X, X) :- .
needtomove(X) :- on(X, Y), goal(on(X, Z)), not(same(Y, Z)).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), not(same(Y, Z))), ontable(X), goal(on(X, Z)).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), not(same(Y, Z))), not(ontable(X), goal(on(X, Z))), on(X, Y), goal(ontable(X)).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), not(same(Y, Z))), not(ontable(X), goal(on(X, Z))), not(on(X, Y), goal(ontable(X))), on(X, Y), goal(clear(Y)).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), not(same(Y, Z))), not(ontable(X), goal(on(X, Z))), not(on(X, Y), goal(ontable(X))), not(on(X, Y), goal(clear(Y))), on(X, Z), goal(on(Y, Z)), not(same(X, Y)).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), not(same(Y, Z))), not(ontable(X), goal(on(X, Z))), not(on(X, Y), goal(ontable(X))), not(on(X, Y), goal(clear(Y))), not(on(X, Z), goal(on(Y, Z)), not(same(X, Y))), on(X, W), needtomove(W).

%%%%%%%%%%%%%
% Operators %
%%%%%%%%%%%%%

%%%%%% Operator: pickup %%%%%% 

operator(pickup).
operator_var(pickup, (B1)) :- block(B1).
operator_prerequisite(pickup, (B1), T) :- operator_var(pickup, (B1)), state(arm(empty), T), state(clear(B1), T), state(ontable(B1), T).
deleted_state(clear(B1), T) :- currentTask(pickup, (B1), T).
deleted_state(ontable(B1), T) :- currentTask(pickup, (B1), T).
deleted_state(arm(empty), T) :- currentTask(pickup, (B1), T).
added_state(holding(B1), T) :- currentTask(pickup, (B1), T).
action(pickup, (B1), T, T+1, 1) :- currentTask(pickup, (B1), T).

%%%%%% Operator: putdown %%%%%% 

operator(putdown).
operator_var(putdown, (B1)) :- block(B1).
operator_prerequisite(putdown, (B1), T) :- operator_var(putdown, (B1)), state(holding(B1), T).
deleted_state(holding(B1), T) :- currentTask(putdown, (B1), T).
added_state(ontable(B1), T) :- currentTask(putdown, (B1), T).
added_state(clear(B1), T) :- currentTask(putdown, (B1), T).
action(putdown, (B1), T, T+1, 1) :- currentTask(putdown, (B1), T).

%%%%%% Operator: stack %%%%%% 

operator(stack).
operator_var(stack, (B1, B2)) :- block(B1), block(B2).
operator_prerequisite(stack, (B1, B2), T) :- operator_var(stack, (B1, B2)), state(arm(empty), T), state(holding(B1), T), state(clear(B2), T).
deleted_state(holding(B1), T) :- currentTask(stack, (B1, B2), T).
deleted_state(clear(B2), T) :- currentTask(stack, (B1, B2), T).
deleted_state(arm(empty), T) :- currentTask(stack, (B1, B2), T).
added_state(on(B1, B2), T) :- currentTask(stack, (B1, B2), T).
added_state(clear(B1), T) :- currentTask(stack, (B1, B2), T).
action(stack, (B1, B2), T, T+1, 1) :- currentTask(stack, (B1, B2), T).

%%%%%% Operator: unstack %%%%%% 

operator(unstack).
operator_var(unstack, (B1, B2)) :- block(B1), block(B2).
operator_prerequisite(unstack, (B1, B2), T) :- operator_var(unstack, (B1, B2)), state(clear(B1), T), state(on(B1, B2), T).
deleted_state(clear(B1), T) :- currentTask(unstack, (B1, B2), T).
deleted_state(on(B1, B2), T) :- currentTask(unstack, (B1, B2), T).
added_state(holding(B1), T) :- currentTask(unstack, (B1, B2), T).
added_state(clear(B2), T) :- currentTask(unstack, (B1, B2), T).
action(unstack, (B1, B2), T, T+1, 1) :- currentTask(unstack, (B1, B2), T).

%%%%%% Operator: assert %%%%%% 

operator(assert).
operator_var(assert, (S1)) :- state(S1).
operator_prerequisite(assert, (S1), T) :- operator_var(assert, (S1)).
added_state(G(), T) :- currentTask(assert, (S1), T).
action(assert, (S1), T, T+1, 0) :- currentTask(assert, (S1), T).

%%%%%% Operator: remove %%%%%% 

operator(remove).
operator_var(remove, (S1)) :- state(S1).
operator_prerequisite(remove, (S1), T) :- operator_var(remove, (S1)), state(G(), T).
deleted_state(G(), T) :- currentTask(remove, (S1), T).
action(remove, (S1), T, T+1, 0) :- currentTask(remove, (S1), T).

