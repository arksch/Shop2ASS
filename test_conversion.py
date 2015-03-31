'''
A test file for the conversion script from Lisp code with a SHOP2 file to ASP code
Run by
    $ py.test test_conversion.py
'''
import conversion

__author__ = 'arkadi'
# This code is to test the conversion.py script


def test_convert_variables():
    input = '(:- (p (f ?x)) ((q ?x c) (r ?y d) (s d))))'
    output = '(:- (p (f X)) ((q X c) (r Y d) (s d))))'
    assert conversion.clear_text(input) == output

def test_function_to_str():
    input_str = ['p', ['f', 'X'], 'Y']
    output_str = 'p(f(X), Y)'
    assert conversion.function_to_str(input_str) == output_str

def test_get_list_of_commands():
    input = '(:- (p (f X)) ((q X c) (r Y d) (s d))))'
    output = [[':-', ['p', ['f', 'X']], [['q', 'X', 'c'], ['r', 'Y', 'd'], ['s', 'd']]]]
    assert conversion.get_list_of_commands(input) == output

def test_horn_clause_conversion():
    input_str = [':-', ['p', ['f', 'X']], [['q', 'X', 'c'], ['r', 'Y', 'd'], ['s', 'd']]]
    output_str = 'p(f(X)) :- q(X, c), r(Y, d), s(d).\n'
    assert conversion.HornClause().command_list_to_ass(input_str) == output_str

def test_horn_clause_class():
    lisp_str = '(:- (p (f ?x)) ((q ?x c) (r ?y d) (s d))))'
    ass_string = 'p(f(X)) :- q(X, c), r(Y, d), s(d).\n'
    assert conversion.HornClause().lisp_to_ass(lisp_str) == ass_string
    lisp_str = '(:- (place X) (depot X))'
    ass_string = 'place(X) :- depot(X).\n'
    assert conversion.HornClause().lisp_to_ass(lisp_str) == ass_string
