package MT::Plugin::SetArray;
use strict;

use MT::Plugin;
use MT;

our $VERSION = "1.00";

use base qw( MT::Plugin );

######################### Init Plugin #########################

my $plugin = __PACKAGE__->new({
    name => 'SetArray',
    key => 'setarray',
    id => 'SetArray',
    version => $VERSION,
    author_name => 'okayama',
    author_link => 'http://weeeblog.net/',
    description => '<MT_TRANS phrase=\'_PLUGIN_DESCRIPTION\'>',
    l10n_class => 'SetArray::L10N',
});

MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        tags => {
            function => {
                SetArray => \&_hdlr_setarray,
            },
        },
    });
}

sub _hdlr_setarray {
    my ($ctx, $args, $cond) = @_;
    my $tag = lc $ctx->stash('tag');
    my $name = $args->{name} || $args->{var};

    return $ctx->error(MT->translate(
        "You used a [_1] tag without a valid name attribute.", "<MT$tag>" ))
        unless defined $name;

    my ($func);
    if ($name =~ m/^(\w+)\((.+)\)$/) {
        $func = $1;
        $name = $2;
    } else {
        $func = $args->{function} if exists $args->{function};
    }

    if (exists $args->{tag}) {
        $args->{tag} =~ s/^MT:?//i;
        my ($handler) = $ctx->handler_for($args->{tag});
        my $value;
        if (defined($handler)) {
            local $ctx->{__stash}{tag} = $args->{tag};
            $value = $handler->($ctx, { %$args });
            if (my $ph = $ctx->post_process_handler) {
                $value = $ph->($ctx, $args, $value);
            }
        }

        my @datas;
        if ($value) {
            my $sep = $args->{sep} || '';
            @datas = split(/$sep/, $value);
        }

        my $data = $ctx->var($name);
        if ( defined $func ) {
            if ( 'undef' eq lc( $func ) ) {
                $data = undef;
                $ctx->var($name, $data);
            }
            else {
                $data ||= [];
                return $ctx->error( MT->translate("'[_1]' is not an array.", $name) )
                    unless 'ARRAY' eq ref($data);
                if ( 'push' eq lc( $func ) ) {
                    push @$data, @datas;
                }
                elsif ( 'unshift' eq lc( $func ) ) {
                    $data ||= [];
                    unshift @$data, @datas;
                }
                else {
                    return $ctx->error(
                        MT->translate("'[_1]' is not a valid function.", $func)
                    );
                }
            }
        } else {
            $ctx->var($name, \@datas);
        }
    }
    return '';
}