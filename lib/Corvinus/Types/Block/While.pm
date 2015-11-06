package Corvinus::Types::Block::While {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub cat_timp {
        my ($self, $condition, $block) = @_;

        while ($condition->run) {
            if (defined(my $res = $block->_run_code)) {
                return $res;
            }
        }

        $self;
    }
}

1;
