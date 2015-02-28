''' This script stores some methods to convert SHOP files into CLASP files

You might have to run
pip install click

Call the script by typing
python conversion.py --help

For questions ask
arkadi.schelling@gmail.com
'''
import re
import os.path
from collections import Sequence
from itertools import chain, count

from pyparsing import nestedExpr
import click

# Text preprocessing

def get_variables(lisp_code):
    return list(set(re.findall('\?[a-z]', lisp_code)))

def convert_variables(text):
    # Converts SHOP variables ?x into CLASP variables X
    variables = get_variables(text)
    for variable in variables:
        text = re.sub('\?' + variable[1:], variable.upper()[1:], text)
    return text

def strip_bad_characters(text):
    # Gringo thinks a - and a ! is an operator, but we do not want to strip :-
    text = re.sub(':-', '<HORN>', text)
    text = re.sub('[!-]', '', text)
    text = re.sub('<HORN>', ':-', text)
    return text

def strip_comments(text):
    # Everything after a ; gets stripped
    return re.sub(';.*\n', '', text)

def clear_text(text):
    # Clears text from Lisp specifics, so it can be parsed by gringo and clasp
    text = strip_comments(text)
    text = convert_variables(text)
    text = strip_bad_characters(text)
    return text

def depth(seq):
    # Gets depth of nested lists
    for level in count():
        if not seq:
            return level
        seq = list(chain.from_iterable(s for s in seq if isinstance(s, Sequence)))

def get_list_of_commands(lisp_code):
    # parses (a (x c v)) into [[a [x c v]]]
    list_of_commands = nestedExpr('(',')').parseString(lisp_code).asList()
    return list_of_commands


def function_to_str(function_list, var_dict={}):
    # A var_dict is lisp_var: (domain, ass_var)
    # ['p', ['f', 'X'], 'Y'] => p(f(X), Y)
    name = function_list[0]
    arguments = function_list[1:]
    list_of_strings = []
    for argument in arguments:
        # We have to check whether this is an embedded function, or already an atom
        if isinstance(argument, basestring): # basestring is both unicode and string
            if var_dict.has_key(argument):
                argument = var_dict[argument][1]
            list_of_strings.append(argument)
        else:
            list_of_strings.append(function_to_str(argument))
    argument_string = ', '.join(list_of_strings)
    # Got strange lists in some edge cases, thats why we stringify.
    return str(name)+'('+str(argument_string)+')'

def state_list_to_ass(state_list, var_dict={}):
    return function_to_str(state_list, var_dict)


# Some classes to deal with the different structures of the lisp code

class Commands(object):

    def __init__(self):
        self.list_of_commands = list()

    def read_lisp_string(self, string):
        self.list_of_commands = get_list_of_commands(clear_text(string))[0]

    def get_list_of_commands(self):
        return self.list_of_commands


class HornClause(Commands):

    def command_list_to_ass(self, horn_clause_list):
        # Expects something like: [':-', ['p', ['f', '?x']], [['q', '?x'], 'c'], ['r', '?y', 'd'], ['s', 'd']]]
        # [':-', [head], [tail1], [tail2], ...] with if-then-else relation between tails
        return_str = ''
        length = len(horn_clause_list)
        head = horn_clause_list[1]
        tail_list = horn_clause_list[2:]
        tail_strings = []
        for tail in tail_list:
            body_strings = []
            for body in tail:
                body_strings.append(function_to_str(body))
            tail_strings.append(', '.join(body_strings))
        # Concatenating with the if-then-else rules
        for i in range(0, len(tail_strings)):
            not_prev_tail_str = ''
            for prev_tail_str in tail_strings[:i]:
                not_prev_tail_str += 'not(' + prev_tail_str + '), '
            this_tail_str = tail_strings[i]
            return_str += function_to_str(head) + ' :- ' + not_prev_tail_str + this_tail_str + '.\n'
        return return_str

    def get_ass_string(self):
        return self.command_list_to_ass(self.list_of_commands)

    def lisp_to_ass(self, lisp_string):
        self.read_lisp_string(lisp_string)
        return self.get_ass_string()

class Operator(Commands):

    def __init__(self, operator_command_list, variables_domain, prerequisites, cost=1):
        """  Creating an operator

        Input: [':operator', ['pickup', 'A'], [['clear', 'A'], ['ontable', 'A']], [['holding', 'A']], 1]
        :param variables_domain: list of variables' domain, e. g. ['block', 'block'] for 2 variables
        :param prerequisites: list of states that are prerequisites for the operator and not in the deleted states,
         ['arm(empty)'] would mean variable 0 and 1 are in state on and and 0 in state clear.

        """
        Commands.__init__(self)
        assert len(variables_domain) == len(operator_command_list[1]) - 1, 'All variables domains should be given'
        self.operator_command_list = operator_command_list
        self.head = self.operator_command_list[1]
        self.deleted_states = self.operator_command_list[2]
        self.added_states = self.operator_command_list[3]
        self.operator_name = self.head[0]
        self.variables_domain = variables_domain
        self.variables_dict = {}
        counter = 0
        for lisp_var in self.head[1:]:
            self.variables_dict[lisp_var] = (self.variables_domain[counter],
                                             self.variables_domain[counter][0].upper() + str(counter + 1))  # A: (block, B1)
            counter += 1
        self.prerequisites = prerequisites
        if len(operator_command_list) == 5:
            self.cost = int(operator_command_list[4])
        else:
            self.cost = cost
        # (B0, B1), operator_var(block, (B0, B1)), B0 != B1
        self.var_string, self.domain_var_string, self.var_unequal_string = self._opvar_string()
        self.operator_var_string = 'operator_var(%s, %s)' % (self.operator_name, self.var_string)
        self.current_task_string = self._current_task_string() # currentTask(stack,(B0, B1), T)


    def _opvar_string(self):
        var_string = ''  # (B0, B1)
        var_domain_string = ''  # operator_var(block, (B0, B1))
        var_unequal_string = ''  # B0 != B1
        counter = 0
        for var_domain, ass_var in self.variables_dict.itervalues():
            var_domain_string += '%s(%s), ' % (var_domain, ass_var)
            var_string += '%s, ' % ass_var
            for var_domain2, ass_var2 in self.variables_dict.itervalues():
                if self.variables_domain.index(var_domain) < self.variables_domain.index(var_domain2):
                    var_unequal_string += '%s != %s, ' % (ass_var, ass_var2)
            counter += 1
        var_unequal_string = var_unequal_string[:-2]
        var_string = '(%s)' % var_string[:-2]
        var_domain_string = var_domain_string[:-2]
        return var_string, var_domain_string, var_unequal_string

    def _current_task_string(self):
        # currentTask(pickup, B, T)
        return 'currentTask(%s, %s, T)' % (self.operator_name, self.var_string)

    def name_to_ass(self):
        # operator(pickup).\n
        return 'operator(%s).\n' % self.operator_name

    def variables_to_ass(self):
        # operator_var(unstack, (C, D)):- block(C), block(D), C != D.\n
        if self.var_unequal_string:
            return_string = '%s :- %s, %s.\n' % (self.operator_var_string, self.domain_var_string,
                                                 self.var_unequal_string)
        else:
            return_string = '%s :- %s.\n' % (self.operator_var_string, self.domain_var_string)
        return return_string

    def prerequisite_to_state(self, prerequisite):
        # ('on',0,1) -> state(on(B0, B1), T)
        return 'state(%s%s, T)' % (prerequisite[0], self.var_string)

    def prerequisites_to_ass(self):
        # [('on',0,1), ('clear', 0)]
        # operator_prerequisite(pickup, B, T) :- state(arm(empty), T), state(clear(B), T), state(ontable(B), T), operator_var(pickup, B).
        body = self.operator_var_string
        for pre in self.prerequisites:
            body += ', state(%s, T)' % pre
        for state in self.deleted_states:
            body += ', state(%s, T)' % state_list_to_ass(state, var_dict=self.variables_dict)
        return 'operator_prerequisite(%s, %s, T) :- %s.\n' % (self.operator_name, self.var_string, body)

    def _prerequisite_to_list(self, prerequisite):
        # ('on',0,1) -> ['on', 'B0', 'B1']
        return_list = [prerequisite[0]]
        for i in range(1, len(prerequisite)):
            lisp_var = self.operator_command_list[1][i]
            return_list.append(self.variables_dict[lisp_var])
        return return_list

    def to_ass(self):
        # operator(unstack).
        # operator_var(unstack, (C, D)):- block(C), block(D), C != D.
        # operator_prerequisite(unstack, (C, D), T):- state(arm(empty), T), state(on(C, D), T),
        #                                             state(clear(C), T), operator_var(unstack, (C, D)).
        # deleted_state(arm(empty), T):- currentTask(unstack, (C, D), T).
        # deleted_state(on(C, D), T):- currentTask(unstack, (C, D), T).
        # deleted_state(clear(C), T):- currentTask(unstack, (C, D), T).
        # added_state(arm(C), T):- currentTask(unstack, (C, D), T).
        # added_state(clear(D), T):- currentTask(unstack, (C, D), T).
        # action(unstack, (C, D), T, T + 1, 1):- currentTask(unstack, (C, D), T).
        return_str = self.name_to_ass() + self.variables_to_ass() + self.prerequisites_to_ass()
        for del_state in self.deleted_states:
            return_str += 'deleted_state(%s, T) :- %s.\n' % (state_list_to_ass(del_state, var_dict=self.variables_dict),
                                                             self.current_task_string)
        for prerequisite in self.prerequisites:
            return_str += 'deleted_state(%s, T) :- %s.\n' % (prerequisite, self.current_task_string)
        for add_state in self.added_states:
            return_str += 'added_state(%s, T) :- %s.\n' % (state_list_to_ass(add_state, var_dict=self.variables_dict),
                                                           self.current_task_string)
        return_str += 'action(%s, %s, T, T+1, %s) :- %s.\n' % (self.operator_name, self.var_string,
                                                               self.cost, self.current_task_string)
        return return_str


class Lisp2Ass():

    def horn_clause(self, lisp_string):
        return HornClause().command_list_to_ass(get_list_of_commands(convert_variables(lisp_string))[0])

    def operator(self, lisp_string, variable_domains, prerequisites):
        commands = Commands()
        commands.read_lisp_string(lisp_string)
        list_of_commands = commands.get_list_of_commands()
        return Operator(list_of_commands, variable_domains, prerequisites).to_ass()

    def lisp_into_fmt(self, lisp_string, fmt):
        commands = Commands()
        commands.read_lisp_string(lisp_string)
        list_of_commands = commands.get_list_of_commands()
        return_string = ''
        for goal in list_of_commands:
            item_string = ''
            for item in goal[1:]:
                item_string += '%s, ' % item
            return_string += fmt % (goal[0], item_string[:-2])
        return return_string

    def atoms(self, lisp_string):
        return self.lisp_into_fmt(lisp_string, '%s(%s).\n')

    def initial_states(self, lisp_string):
        return self.lisp_into_fmt(lisp_string, 'state(%s(%s), 0).\n')

    def goals(self, lisp_string):
        return self.lisp_into_fmt(lisp_string, 'goal(%s(%s)).\n')

def parse_lisp(lisp_string, keyword):
    ''' This method finds the keyword in the lisp code and returns a list with snippets of the matching brackets,
    that surround this keyoword.

    :param lisp_string: (this (is (an (:operator (task! ?a) () ()))))
    :type lisp_string: string
    :param keyword: :operator
    :type keyword:
    :return: [(:operator (task! ?a) () ())]
    :rtype:
    '''
    lisp_length = len(lisp_string)
    snippets = []
    position = 0
    while position < lisp_length:
        keyword_index = lisp_string.find(keyword, position)
        if keyword_index != -1:
            start = lisp_string.rfind('(', 0, keyword_index)
            end = keyword_index
            bracket_sum = 1
            while bracket_sum != 0:
                end = lisp_string.find(')', end + 1)
                if end == -1:
                    # This should not happen for a complete string. Still, this will just return the string until the end.
                    break
                bracket_sum = lisp_string[start:end + 1].count('(') - lisp_string[start:end + 1].count(')')
            snippets.append(lisp_string[start:end + 1])
            position = end + 1
        else:
            break
    return snippets


@click.command()
@click.argument('input')
@click.argument('output')
@click.option('--atoms', default='0:0', help='Which lines to interpret as atoms. Format start:end. Should have no surrounding paranthesis.')
@click.option('--initials', default='0:0', help='Which lines to interpret as initial states. Format start:end. Should have no surrounding paranthesis.')
@click.option('--goals', default='0:0', help='Which lines to interpret as goals. Format start:end. Should have no surrounding paranthesis.')
def main(input, output, atoms, initials, goals):
    with open(input, 'r') as f_in:
        lisp_lines = f_in.readlines()
    start_atoms, end_atoms = atoms.split(':')
    lisp_atoms = '(%s)' % clear_text(' '.join(lisp_lines[int(start_atoms):int(end_atoms)]))
    start_initials, end_initials = initials.split(':')
    lisp_initials = '(%s)' % clear_text(' '.join(lisp_lines[int(start_initials):int(end_initials)]))
    start_goals, end_goals = goals.split(':')
    lisp_goals = '(%s)' % clear_text(' '.join(lisp_lines[int(start_goals):int(end_goals)]))

    # Take clean input for later parsing
    lisp_code = clear_text(' '.join(lisp_lines))

    trans = Lisp2Ass()

    script_folder = os.path.split(__file__)[0]
    with open(os.path.join(script_folder,'stub.lp', 'r')) as f_in:
        stub = f_in.read()

    ## Translate atoms, initial states and goals
    with open(output, 'w') as f_out:
        # Writing the general solver functions from stub.lp
        f_out.write(stub)

        atoms_doc = '\n%%%%%%%%%\n'
        atoms_doc += '% Atoms %\n'
        atoms_doc += '%%%%%%%%%\n\n'

        initials_doc = '\n%%%%%%%%%%%%%%%%%%\n'
        initials_doc += '% Initial States %\n'
        initials_doc += '%%%%%%%%%%%%%%%%%%\n\n'

        goals_doc = '\n%%%%%%%%%\n'
        goals_doc += '% Goals %\n'
        goals_doc += '%%%%%%%%%\n\n'

        hcl_doc = '\n%%%%%%%%%%%%%%%%\n'
        hcl_doc += '% Horn Clauses %\n'
        hcl_doc += '%%%%%%%%%%%%%%%%\n\n'

        f_out.write(atoms_doc + trans.atoms(lisp_atoms))
        f_out.write(initials_doc + trans.initial_states(lisp_initials))
        f_out.write(goals_doc + trans.goals(lisp_goals) + hcl_doc)

        ## Find Horn Clauses
        horn_clauses = parse_lisp(lisp_code, ':- ')
        for hcl in horn_clauses:
            f_out.write(trans.horn_clause(hcl))
    ## Find Operators
    operators = parse_lisp(lisp_code, ':operator')
    for op in operators:
        click.echo(op)
        variables = click.prompt('Which are the variable domains of this operator, in format var1:var2:..:var_n?',
                                 default=False)
        if variables:
            variables = variables.split(':')
        else:
            variables = []
        prerequisites = click.prompt('Which are the extra prerequisites to this operator, in format pre1:..:pre_n?',
                                     default=False)
        if prerequisites:
            prerequisites = prerequisites.split(':')
        else:
            prerequisites = []
        with open(output, 'a') as f_out:
            f_out.write(trans.operator(op, variable_domains=variables, prerequisites=prerequisites))

if __name__ == '__main__':
    main()