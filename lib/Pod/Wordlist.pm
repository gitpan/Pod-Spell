package Pod::Wordlist;
use strict;
use warnings;
use File::Slurp                    qw( read_file );
use Lingua::EN::Inflect            qw( PL        );
use File::ShareDir::ProjectDistDir qw( dist_file );

use Class::Tiny {
    wordlist  => \&_copy_wordlist,
    _is_debug => 0,
};

use constant MAXWORDLENGTH => 50; ## no critic ( ProhibitConstantPragma )

our $VERSION = '1.08'; # VERSION

our %Wordlist; ## no critic ( Variables::ProhibitPackageVars )

sub _copy_wordlist { return { %Wordlist } }

foreach ( read_file( dist_file('Pod-Spell', 'wordlist') ) ) {
	chomp( $_ );
	$Wordlist{$_} = 1;
	$Wordlist{PL($_)} = 1;
}


sub learn_stopwords {
	my ( $self, $text ) = @_;
	my $stopwords = $self->wordlist;

	while ( $text =~ m<(\S+)>g ) {
		my $word = $1;
		if ( $word =~ m/^!(.+)/s ) {
			# "!word" deletes from the stopword list
			my $negation = $1;
			# different $1 from above
			delete $stopwords->{$negation};
			delete $stopwords->{PL($negation)};
			print "Unlearning stopword $word\n" if $self->_is_debug;
		}
		else {
			$stopwords->{$word} = 1;
			$stopwords->{PL($word)} = 1;
			print "Learning stopword $1\n" if $self->_is_debug;
		}
	}
	return;
}


sub strip_stopwords {
	my ($self, $text) = @_;

	# Count the things in $text
	print "Content: <", $text, ">\n" if $self->_is_debug;

	my $stopwords = $self->wordlist;
	my $word;
	$text =~ tr/\xA0\xAD/ /d;

	# i.e., normalize non-breaking spaces, and delete soft-hyphens

	my $out = '';

	my ( $leading, $trailing );
	while ( $text =~ m<(\S+)>g ) {

		# Trim normal English punctuation, if leading or trailing.
		next if length $1 > MAXWORDLENGTH;
		$word = $1;
		if   ( $word =~ s/^([\`\"\'\(\[])//s ) { $leading = $1 }
		else                                   { $leading = '' }

		if   ( $word =~ s/([\)\]\'\"\.\:\;\,\?\!]+)$//s ) { $trailing = $1 }
		else                                              { $trailing = '' }

		if   ( $word =~ s/('s)$//s ) { $trailing = $1 . $trailing }

		if (
			# if it looks like it starts with a sigil, etc.
			$word =~ m/^[\&\%\$\@\:\<\*\\\_]/s

			# or contains anything strange
			or $word =~ m/[\%\^\&\#\$\@\_\<\>\(\)\[\]\{\}\\\*\:\+\/\=\|\`\~]/

		  )
		{
			print "rejecting {$word}\n" if $self->_is_debug && $word ne '_';
			next;
		}
		else {
			if ( exists $stopwords->{$word} or exists $stopwords->{ lc $word } )
			{
				print " [Rejecting \"$word\" as a stopword]\n"
					if $self->_is_debug;
			}
			elsif ( $word =~ /-/ ) {
				# check individual parts
				my @keep;
				for my $part ( split /-/, $word ) {
					if ( exists $stopwords->{$part} or exists $stopwords->{ lc $part } )
					{
						print " [Rejecting \"$part\" as a stopword]\n"
							if $self->_is_debug;
					}
					else {
						push @keep, $part;
					}
				}
				if ( @keep ) {
					$out .= $leading . join( "-", @keep ) . "$trailing ";
				}
			}
			else {
				$out .= "$leading$word$trailing ";
			}
		}
	}

	return $out;
}

1;

# ABSTRACT: English words that come up in Perl documentation

__END__

=pod

=head1 NAME

Pod::Wordlist - English words that come up in Perl documentation

=head1 VERSION

version 1.08

=head1 DESCRIPTION

Pod::Wordlist is used by L<Pod::Spell|Pod::Spell>, providing a set of words
that are English jargon words that come up in Perl documentation, but which are
not to be found in general English lexicons.  (For example: autovivify,
backreference, chroot, stringify, wantarray.)

You can also use this wordlist with your word processor by just
pasting C<share/wordlist>'s content into your wordprocessor, deleting
the leading Perl code so that only the wordlist remains, and then
spellchecking this resulting list and adding every word in it to your
private lexicon.

=head1 ATTRIBUTES

=head2 wordlist

	ref $self->wordlist eq 'HASH'; # true

This is the instance of the wordlist

=head1 METHODS

=head2 learn_stopwords

    $wordlist->learn_stopwords( $text );

Modifies the stopword list based on a text block. See the rules
for <adding stopwords|Pod::Spell/ADDING STOPWORDS> for details.

=head2 strip_stopwords

    my $out = $wordlist->strip_stopwords( $text );

Returns a string with space separated words from the original
text with stopwords removed.

=head1 WORDLIST

Note that the scope of this file is only English, specifically American
English.  (But you may find in useful to incorporate into your own
lexicons, even if they are for other dialects/languages.)

remove any q{'s} before adding to the list.

The list should be sorted and uniqued. The following will work (with GNU
Coreutils ).

	sort share/wordlist -u > /tmp/sorted && mv /tmp/sorted share/wordlist

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/pod-spell/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Sean M. Burke <sburke@cpan.org>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
