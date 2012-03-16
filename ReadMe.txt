GetOpt is an experimental options parser.  This intends to emulate the feel
of UNIX option parsing, as provided by getopt, or the perl Getopt::Long
module.

getopt takes options, and arguments, and parses the arguments according
to the options.

For instance:

	Library.LibGetOpt.getopt("ab:", "-a -b foo bar") ->

	{ "a" -> true,
	  "b" -> "foo",
	  "leftover" -> "bar",
	  "leftover_args" -> { "bar" },
	}

The usage here is fairly similar to traditional UNIX getopt; letters indicate
options, a colon indicates that the previous option requires an argument.
As an extension, a pound sign indicates that the previous option requires
a numeric argument.  A plus sign indicates that the previous option can
be specified multiple times.  If it has a : or # qualifier, this will result
in args[opt] being a table of strings/numbers, otherwise it will result
in args[opt] being a count of times specified.  So:
	
	Library.LibGetOpt.getopt("v+a:+", "-vva one -a two three four") ->
	{
	  "v" -> 2,
	  "a" -> { "one", "two" }
	  "leftover" -> "three four",
	  "leftover_args" -> { "three", "four" },
	}

If you pass in a table, instead of an argument string, it is treated as a list
of arguments; otherwise, the string is split around whitespace (but
double-quoted strings are preserved).  Quoting follows the standard Unixy
rules for double quotes; backslashed double quotes are not special, quotes
override spaces.  If quotes are mismatched, or the last character is a
backslash, an error is reported.  "" as a word yields an empty string.

If you pass in a table, instead of an option string, it can be a list of
options that can include long option forms; each item in the table is itself
a table with four members:
	long option spelling (if any)
	short option letter
	flag (nil for no flag, otherwise ":" or "#")
	description (optional)

Examples:
{ { nil, "a", nil, "the a option takes no argument" },
  { "number", "n", "#", "the -n/--number option takes a numeric argument" },
  { "text", "z", ":", "-z takes text" },
}

The "-?" flag prints out this table, or an internal mockup of one compiled
from your option string.

If you've used any other getopt, this should be pretty obvious.  If you
haven't, I'm not sure I can help you.

Options which were never specified are not included in the table -- this means
that their value is nil.  There is no way to negate or "unset" an option;
pick your options so the default is off.

Additionally, because this kind of functionality is sort of handy, and
RIFT lets us register slash commands in a sane way:  LibGetOpt can do
that for you, too!  Just call
	Library.LibGetOpt.makeslash(opts, addonname, name, func)
and LibGetOpt will register /name for you; when /name is called, it will
be parsed with the options you specified (which can be a string or table,
same as always), and the resulting table passed to func.  The makeslash
function returns true on success, and prints a diagnostic and returns
false on error.

You can also use
	Library.LibGetOpt.dequote(string)
to get a string broken down into a table of words, respecting quoting
conventions.

Code and documentation copyright 2007, 2011, 2012 Peter Seebach.  Permission
granted to use and redistribute under any terms that make you happy.  I like
the BSD license, but it's up to you.

