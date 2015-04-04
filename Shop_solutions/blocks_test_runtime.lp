% Writing my own HTN with clasp

%%%%%%%%%
% Atoms %
%%%%%%%%%

%domain(atom).
block(b1).
block(b2).
block(b3).
block(b4).
block(b5).
block(b6).
block(b7).
block(b8).


%%%%%%%%%%%%%%%%%%
% Initial States %
%%%%%%%%%%%%%%%%%%

%state(name(atoms), 0).
state(ontable(b1), 0).
state(on(b3,b1), 0).
state(clear(b3), 0).
state(ontable(b2), 0).
state(clear(b2), 0).
state(ontable(b4), 0).
state(on(b5,b4), 0).
state(on(b6,b5), 0).
state(clear(b6), 0).
state(ontable(b7), 0).
state(on(b8, b7), 0).
state(clear(b8), 0).
state(arm(empty), 0).
%currentTask(achievegoals, 0).
%currentTask(teststack, 0).

%%%%%%%%%
% Goals %
%%%%%%%%%

goal(on(b1, b3)).
goal(on(b2, b1)).
goal(on(b4, b7)).



%%%%%%%%%% 
% Axioms %
%%%%%%%%%%

%%%%%%%%%%%%%
% Operators %
%%%%%%%%%%%%%

% One action each step. Methods are a collection of operators and other methods, thus they can overlap.
% :- time(T), action(Task1, Var1, T, T+1, C1), action(Task2, Var2, T, T+1, C2), Task1 != Task2.
% Every action after the first one has a preceding action.
% :- time(T), action(Task1, Var1, T, T+1, C1), not action(Task2, Var2, T-1, T, C2), T > 0.



%----------------------%
% --- Operator pickup  %
%----------------------%

operator(pickup).
operator_var(pickup, B) :- block(B).
operator_prerequisite(pickup, B, T) :- state(arm(empty), T), state(clear(B), T), state(ontable(B), T), operator_var(pickup, B).
deleted_state(arm(empty), T) :- currentTask(pickup, B, T).
deleted_state(clear(B), T) :- currentTask(pickup, B, T).
deleted_state(ontable(B), T) :- currentTask(pickup, B, T).
added_state(arm(B), T) :- currentTask(pickup, B, T).
action(pickup, B, T, T+1, 1) :- currentTask(pickup, B, T).

%-----------------------%
% --- Operator putdown  %
%-----------------------%

operator(putdown).
operator_var(putdown, B) :- block(B).
operator_prerequisite(putdown, B, T) :- state(arm(B), T), operator_var(putdown, B).
deleted_state(arm(B), T) :- currentTask(putdown, B, T).
added_state(arm(empty), T) :- currentTask(putdown, B, T).
added_state(ontable(B), T) :- currentTask(putdown, B, T).
added_state(clear(B), T) :- currentTask(putdown, B, T).
action(putdown, B, T, T+1, 1) :- currentTask(putdown, B, T).

%---------------------%
% --- Operator stack  %
%---------------------%

operator(stack).
operator_var(stack, (C, D)) :- block(C), block(D), C != D.
operator_prerequisite(stack, (C,D), T) :- state(arm(C), T), state(clear(D), T), operator_var(stack, (C,D)).
deleted_state(arm(C), T) :- currentTask(stack, (C,D), T).
deleted_state(clear(D), T) :- currentTask(stack, (C,D), T).
added_state(on(C,D), T) :- currentTask(stack, (C,D), T).
added_state(arm(empty), T) :- currentTask(stack, (C,D), T).
added_state(clear(C), T) :- currentTask(stack, (C,D), T).
action(stack, (C,D), T, T+1, 1) :- currentTask(stack, (C,D), T).

%---------------------%
% --- Operator unstack  %
%---------------------%

operator(unstack).
operator_var(unstack, (C, D)) :- block(C), block(D), C != D.
operator_prerequisite(unstack, (C,D), T) :- state(arm(empty), T), state(on(C,D), T), state(clear(C), T), operator_var(unstack, (C,D)).
deleted_state(arm(empty), T) :- currentTask(unstack, (C,D), T).
deleted_state(on(C, D), T) :- currentTask(unstack, (C,D), T).
deleted_state(clear(C), T) :- currentTask(unstack, (C,D), T).
added_state(arm(C), T) :- currentTask(unstack, (C,D), T).
added_state(clear(D), T) :- currentTask(unstack, (C,D), T).
action(unstack, (C, D), T, T+1, 1) :- currentTask(unstack, (C,D), T).

%%%%%%%%%%%
% Methods %
%%%%%%%%%%%

% When a method calls an operator we have to check prerequisites before we perform the task.
% currentTask(Operator, Var, T) :- called(Operator, Var, T), prerequisite(Operator, State), state(State, T), 

%---------------------------%
% --- Method achievegoals   %
%---------------------------%

% TODO: MUCH OPTIMIZATION like in the lisp code. Move blocks that can be moved to their goal directly. Add goals for blocks that block the way of another block. Add dont-move labels.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   START OF THE GENERAL SOLVING FUNCTION   %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% It is important to KNOW if a goal is not fulfilled.
% neg_state(State, T) :- time(T), goal(State), not state(State, T).
not_finished(T) :- time(T), goal(State), not state(State, T).
:- goal(State), not state(State, T), maxtime(T).

%%%%%%%%%%%%%%%%%%
% Law of inertia %
%%%%%%%%%%%%%%%%%%
maxtime(20).
time(0..T) :- maxtime(T).
state(X, T+1) :- time(T), state(X, T), not deleted_state(X, T).
state(X, T+1) :- time(T), added_state(X, T).
:- deleted_state(X, T), not state(X,T).

1 {curTask(Op, T) : operator(Op)} 1 :- time(T), not_finished(T).
1 {currentTask(Op, Var, T) : operator_prerequisite(Op, Var, T) } 1 :- curTask(Op, T).

%%%%%%%%%%%%%%%%
% Optimization %
%%%%%%%%%%%%%%%%

#minimize{C, T : action(Op, Var, T, TT, C)}.

#show currentTask/3.


