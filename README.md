Shop2ASS
========

Semi-automatic conversion of lisp code from the Shop system for Answer Set Solving with Gringo and Clasp.

Clone this git repository by

    $ git clone https://github.com/arksch/Shop2ASS.git

You can then see the options

    $ cd Shop2ASS
    $ python conversion.py --help
    
For usual input and output type

    $ python conversion.py input_file output_file
    
The script will then ask you to give the right variable domains for *:operators* from the given Shop file.
You can also add prerequisites that are implicitly used by the *:methods* that call these operators.

Note that this script does not translate *:methods*, yet.

For translating problem descriptions try to have all atoms, initial states and goals in one block each,
with no leading and trailing paranthesis in the same lines. Then call

    $ python conversion input_file output_file --atoms startline:endline --initials startline:endline --goals startline:endline
    
Note that counting starts with zero and each last line is not included.

How to start the ASS solver?
----------------------------

This script only runs semi-automatically.
You will have to alter some of the output to apply to Gringo/Clasp logic and syntax.
Once you have tuned the output of the main problem and the problem's instance you can run it

    $ ./path/to/gringo problem instance | ./path/to/clasp 0

Note that this will not run fast, since the included stub only performs a very dumb guessing.
To improve the solving you should look at the Shop methods and probably include some additional goals and states.

For questions write me a mail.