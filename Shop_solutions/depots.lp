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

place(X) :- depot(X).
place(X) :- distributor(X).
locatable(X) :- truck(X).
locatable(X) :- hoist(X).
locatable(X) :- surface(X).
surface(X) :- pallet(X).
surface(X) :- crate(X).
different(X, Y) :- not(same(X, Y)).
same(X, X) :- .
sameloc(X, Y) :- at(X, P), at(Y, P).
bottomoftower(X, X) :- goal(on(X, Y)), not(goal(on(Y, Z))).
bottomoftower(X, Y) :- goal(on(X, Z)), bottomoftower(Z, Y).
above(X, X) :- .
above(X, Y) :- on(Z, Y), above(X, Z).
goodtower(X, Y) :- forall(Z(), supposedtobeabove(X, Z), not(above(Y, Z))).
supposedtobeabove(X, Y) :- goal(on(X, Y)).
supposedtobeabove(X, Z) :- goal(on(Y, Z)), supposedtobeabove(X, Y).
needtomove(X) :- on(X, Y), goal(on(X, Z)), different(Y, Z).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), different(Y, Z)), on(X, Y), goal(clear(Y)).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), different(Y, Z)), not(on(X, Y), goal(clear(Y))), on(X, Z), goal(on(Y, Z)), different(X, Y).
needtomove(X) :- not(on(X, Y), goal(on(X, Z)), different(Y, Z)), not(on(X, Y), goal(clear(Y))), not(on(X, Z), goal(on(Y, Z)), different(X, Y)), on(X, W), needtomove(W).

%%%%%%%%%%%%%
% Operators %
%%%%%%%%%%%%%

%%%%%% Operator: drive %%%%%% 

operator(drive).
operator_var(drive, (P2, L1, P3)) :- place(P2), locatable(L1), place(P3), L1 != P2, L1 != P3.
operator_prerequisite(drive, (P2, L1, P3), T) :- operator_var(drive, (P2, L1, P3)), state(at(L1, P2), T).
deleted_state(at(L1, P2), T) :- currentTask(drive, (P2, L1, P3), T).
added_state(at(L1, P3), T) :- currentTask(drive, (P2, L1, P3), T).
action(drive, (P2, L1, P3), T, T+1, 1) :- currentTask(drive, (P2, L1, P3), T).

%%%%%% Operator: lift %%%%%% 

operator(lift).
operator_var(lift, (C2, H1, C3, P4)) :- crate(C2), hoist(H1), crate(C3), pallet(P4), C2 != P4, H1 != C2, H1 != C3, H1 != P4, C3 != P4.
operator_prerequisite(lift, (C2, H1, C3, P4), T) :- operator_var(lift, (C2, H1, C3, P4)), state(at(C2, P4), T), state(clear(C2), T), state(available(H1), T), state(on(C2, C3), T), state(forall(U(), lastmoved(U), ['lastmoved', 'U']()), T).
deleted_state(at(C2, P4), T) :- currentTask(lift, (C2, H1, C3, P4), T).
deleted_state(clear(C2), T) :- currentTask(lift, (C2, H1, C3, P4), T).
deleted_state(available(H1), T) :- currentTask(lift, (C2, H1, C3, P4), T).
deleted_state(on(C2, C3), T) :- currentTask(lift, (C2, H1, C3, P4), T).
deleted_state(forall(U(), lastmoved(U), ['lastmoved', 'U']()), T) :- currentTask(lift, (C2, H1, C3, P4), T).
added_state(lifting(H1, C2), T) :- currentTask(lift, (C2, H1, C3, P4), T).
added_state(clear(C3), T) :- currentTask(lift, (C2, H1, C3, P4), T).
added_state(forbidden(C2, C3), T) :- currentTask(lift, (C2, H1, C3, P4), T).
added_state(lastmoved(C2), T) :- currentTask(lift, (C2, H1, C3, P4), T).
action(lift, (C2, H1, C3, P4), T, T+1, 1) :- currentTask(lift, (C2, H1, C3, P4), T).

%%%%%% Operator: drop %%%%%% 

operator(drop).
operator_var(drop, (C2, H1, C3, P4)) :- crate(C2), hoist(H1), crate(C3), pallet(P4), C2 != P4, H1 != C2, H1 != C3, H1 != P4, C3 != P4.
operator_prerequisite(drop, (C2, H1, C3, P4), T) :- operator_var(drop, (C2, H1, C3, P4)), state(lifting(H1, C2), T), state(clear(C3), T), state(forall(T(), forbidden(T, Y), ['forbidden', 'T', 'Y']()), T).
deleted_state(lifting(H1, C2), T) :- currentTask(drop, (C2, H1, C3, P4), T).
deleted_state(clear(C3), T) :- currentTask(drop, (C2, H1, C3, P4), T).
deleted_state(forall(T(), forbidden(T, Y), ['forbidden', 'T', 'Y']()), T) :- currentTask(drop, (C2, H1, C3, P4), T).
added_state(available(H1), T) :- currentTask(drop, (C2, H1, C3, P4), T).
added_state(at(C2, P4), T) :- currentTask(drop, (C2, H1, C3, P4), T).
added_state(clear(C2), T) :- currentTask(drop, (C2, H1, C3, P4), T).
added_state(on(C2, C3), T) :- currentTask(drop, (C2, H1, C3, P4), T).
action(drop, (C2, H1, C3, P4), T, T+1, 1) :- currentTask(drop, (C2, H1, C3, P4), T).

%%%%%% Operator: load %%%%%% 

operator(load).
operator_var(load, (C2, H1, C3, P4)) :- crate(C2), hoist(H1), crate(C3), pallet(P4), C2 != P4, H1 != C2, H1 != C3, H1 != P4, C3 != P4.
operator_prerequisite(load, (C2, H1, C3, P4), T) :- operator_var(load, (C2, H1, C3, P4)), state(lifting(H1, C2), T).
deleted_state(lifting(H1, C2), T) :- currentTask(load, (C2, H1, C3, P4), T).
added_state(in(C2, C3), T) :- currentTask(load, (C2, H1, C3, P4), T).
added_state(available(H1), T) :- currentTask(load, (C2, H1, C3, P4), T).
action(load, (C2, H1, C3, P4), T, T+1, 1) :- currentTask(load, (C2, H1, C3, P4), T).

%%%%%% Operator: unload %%%%%% 

operator(unload).
operator_var(unload, (C2, H1, C3, P4)) :- crate(C2), hoist(H1), crate(C3), pallet(P4), C2 != P4, H1 != C2, H1 != C3, H1 != P4, C3 != P4.
operator_prerequisite(unload, (C2, H1, C3, P4), T) :- operator_var(unload, (C2, H1, C3, P4)), state(in(C2, C3), T), state(available(H1), T).
deleted_state(in(C2, C3), T) :- currentTask(unload, (C2, H1, C3, P4), T).
deleted_state(available(H1), T) :- currentTask(unload, (C2, H1, C3, P4), T).
added_state(lifting(H1, C2), T) :- currentTask(unload, (C2, H1, C3, P4), T).
action(unload, (C2, H1, C3, P4), T, T+1, 1) :- currentTask(unload, (C2, H1, C3, P4), T).

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

