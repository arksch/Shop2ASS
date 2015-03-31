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


