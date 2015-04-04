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
different(X, Y) :- not(same(X, Y)).

%%%%%%%%%%%%%
% Operators %
%%%%%%%%%%%%%

%%%%%% Operator: loadtruck %%%%%% 

operator(loadtruck).
operator_var(loadtruck, (T2, O1, L3)) :- truck(T2), object(O1), location(L3), T2 != L3, O1 != T2, O1 != L3.
operator_prerequisite(loadtruck, (T2, O1, L3), T) :- operator_var(loadtruck, (T2, O1, L3)), state(objat(O1, L3), T), state(:protection(truckat(Truck, Loc)), T).
deleted_state(objat(O1, L3), T) :- currentTask(loadtruck, (T2, O1, L3), T).
deleted_state(:protection(truckat(Truck, Loc)), T) :- currentTask(loadtruck, (T2, O1, L3), T).
added_state(intruck(O1, T2), T) :- currentTask(loadtruck, (T2, O1, L3), T).
action(loadtruck, (T2, O1, L3), T, T+1, 1) :- currentTask(loadtruck, (T2, O1, L3), T).

%%%%%% Operator: unloadtruck %%%%%% 

operator(unloadtruck).
operator_var(unloadtruck, (T2, O1, L3)) :- truck(T2), object(O1), location(L3), T2 != L3, O1 != T2, O1 != L3.
operator_prerequisite(unloadtruck, (T2, O1, L3), T) :- operator_var(unloadtruck, (T2, O1, L3)), state(intruck(O1, T2), T), state(:protection(truckat(Truck, Loc)), T).
deleted_state(intruck(O1, T2), T) :- currentTask(unloadtruck, (T2, O1, L3), T).
deleted_state(:protection(truckat(Truck, Loc)), T) :- currentTask(unloadtruck, (T2, O1, L3), T).
added_state(objat(O1, L3), T) :- currentTask(unloadtruck, (T2, O1, L3), T).
action(unloadtruck, (T2, O1, L3), T, T+1, 1) :- currentTask(unloadtruck, (T2, O1, L3), T).

%%%%%% Operator: loadairplane %%%%%% 

operator(loadairplane).
operator_var(loadairplane, (L3, A2, O1)) :- location(L3), airplane(A2), object(O1), A2 != L3, O1 != L3, O1 != A2.
operator_prerequisite(loadairplane, (L3, A2, O1), T) :- operator_var(loadairplane, (L3, A2, O1)), state(objat(O1, L3), T), state(:protection(airplaneat(Airplane, Loc)), T).
deleted_state(objat(O1, L3), T) :- currentTask(loadairplane, (L3, A2, O1), T).
deleted_state(:protection(airplaneat(Airplane, Loc)), T) :- currentTask(loadairplane, (L3, A2, O1), T).
added_state(inairplane(O1, A2), T) :- currentTask(loadairplane, (L3, A2, O1), T).
action(loadairplane, (L3, A2, O1), T, T+1, 1) :- currentTask(loadairplane, (L3, A2, O1), T).

%%%%%% Operator: unloadairplane %%%%%% 

operator(unloadairplane).
operator_var(unloadairplane, (L3, A2, O1)) :- location(L3), airplane(A2), object(O1), A2 != L3, O1 != L3, O1 != A2.
operator_prerequisite(unloadairplane, (L3, A2, O1), T) :- operator_var(unloadairplane, (L3, A2, O1)), state(inairplane(O1, A2), T), state(:protection(airplaneat(Airplane, Loc)), T).
deleted_state(inairplane(O1, A2), T) :- currentTask(unloadairplane, (L3, A2, O1), T).
deleted_state(:protection(airplaneat(Airplane, Loc)), T) :- currentTask(unloadairplane, (L3, A2, O1), T).
added_state(objat(O1, L3), T) :- currentTask(unloadairplane, (L3, A2, O1), T).
action(unloadairplane, (L3, A2, O1), T, T+1, 1) :- currentTask(unloadairplane, (L3, A2, O1), T).

%%%%%% Operator: drivetruck %%%%%% 

operator(drivetruck).
operator_var(drivetruck, (L2, T1, L3)) :- location(L2), truck(T1), location(L3), T1 != L2, T1 != L3.
operator_prerequisite(drivetruck, (L2, T1, L3), T) :- operator_var(drivetruck, (L2, T1, L3)), state(truckat(T1, L2), T).
deleted_state(truckat(T1, L2), T) :- currentTask(drivetruck, (L2, T1, L3), T).
added_state(truckat(T1, L3), T) :- currentTask(drivetruck, (L2, T1, L3), T).
added_state(:protection(truckat(Truck, Locto)), T) :- currentTask(drivetruck, (L2, T1, L3), T).
action(drivetruck, (L2, T1, L3), T, T+1, 1) :- currentTask(drivetruck, (L2, T1, L3), T).

%%%%%% Operator: flyairplane %%%%%% 

operator(flyairplane).
operator_var(flyairplane, (A1, A2, A3)) :- airplane(A1), airport(A2), airport(A3), A1 != A2, A1 != A3.
operator_prerequisite(flyairplane, (A1, A2, A3), T) :- operator_var(flyairplane, (A1, A2, A3)), state(airplaneat(A1, A2), T).
deleted_state(airplaneat(A1, A2), T) :- currentTask(flyairplane, (A1, A2, A3), T).
added_state(airplaneat(A1, A3), T) :- currentTask(flyairplane, (A1, A2, A3), T).
added_state(:protection(airplaneat(Airplane, Airportto)), T) :- currentTask(flyairplane, (A1, A2, A3), T).
action(flyairplane, (A1, A2, A3), T, T+1, 1) :- currentTask(flyairplane, (A1, A2, A3), T).

%%%%%% Operator: addprotection %%%%%% 

operator(addprotection).
operator_var(addprotection, (S1)) :- state(S1).
operator_prerequisite(addprotection, (S1), T) :- operator_var(addprotection, (S1)).
added_state(:protection(S1), T) :- currentTask(addprotection, (S1), T).
action(addprotection, (S1), T, T+1, 0) :- currentTask(addprotection, (S1), T).

%%%%%% Operator: deleteprotection %%%%%% 

operator(deleteprotection).
operator_var(deleteprotection, (S1)) :- state(S1).
operator_prerequisite(deleteprotection, (S1), T) :- operator_var(deleteprotection, (S1)), state(:protection(S1), T).
deleted_state(:protection(S1), T) :- currentTask(deleteprotection, (S1), T).
action(deleteprotection, (S1), T, T+1, 0) :- currentTask(deleteprotection, (S1), T).

