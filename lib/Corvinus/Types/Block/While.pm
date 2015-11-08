package Corvinus::Types::Block::While {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub while {
        my ($self, $condition, $block) = @_;

        while ($condition->run) {
            if (defined(my $res = $block->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    *cat_timp = \&while;
}

1;
