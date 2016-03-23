package Corvinus::Convert::Convert {

    # This module is used only as parent!

    use 5.014;
    use overload;

    sub to_s {
        my ($self) = @_;
        $self->isa('SCALAR')
          || $self->isa('REF')
          ? Corvinus::Types::String::String->new(overload::StrVal($self) ? "$self" : defined($$self) ? "$$self" : "")
          : $self;
    }

    *to_str  = \&to_s;
    *ca_text = \&to_s;

    sub to_obj {
        my ($self, $obj) = @_;
        return $self if ref($self) eq ref($obj);
        $obj->new($self);
    }

    *ca_obiect = \&to_obj;

    sub to_i {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($_[0]->get_value)->as_int);
    }

    *ca_int    = \&to_i;
    *ca_intreg = \&to_i;
    *to_int    = \&to_i;

    sub to_rat {
        Corvinus::Types::Number::Number->new(Math::BigRat->new($_[0]->get_value));
    }

    *ca_rational = \&to_rat;
    *ca_rat      = \&to_rat;
    *to_rational = \&to_rat;
    *to_r        = \&to_rat;

    sub to_complex {
        Corvinus::Types::Number::Complex->new($_[0]->get_value);
    }

    *ca_complex = \&to_complex;
    *to_c       = \&to_complex;

    sub to_n {
        Corvinus::Types::Number::Number->new($_[0]->get_value);
    }

    *ca_num    = \&to_n;
    *ca_numar  = \&to_n;
    *to_num    = \&to_n;
    *to_number = \&to_n;

    sub to_float {
        my ($value) = $_[0]->get_value;
        Corvinus::Types::Number::Number->new(ref($value) eq 'Math::BigRat' ? $value->as_float : Math::BigFloat->new($value));
    }

    *to_f = \&to_float;

    sub to_file {
        Corvinus::Types::Glob::File->new($_[0]->get_value);
    }

    *ca_fisier = \&to_file;

    sub to_dir {
        Corvinus::Types::Glob::Dir->new($_[0]->get_value);
    }

    *ca_folder = \&to_dir;

    sub to_bool {
        Corvinus::Types::Bool::Bool->new($_[0]->get_value);
    }

    *ca_bool = \&to_bool;

    sub to_regex {
        Corvinus::Types::Regex::Regex->new($_[0]->get_value);
    }

    *to_re    = \&to_regex;
    *ca_re    = \&to_regex;
    *ca_regex = \&to_regex;

    sub to_byte {
        Corvinus::Types::Byte::Byte->new(CORE::ord($_[0]->get_value));
    }

    *ca_octet = \&to_byte;

    sub to_bytes {
        Corvinus::Types::Byte::Bytes->call($_[0]->get_value);
    }

    *ca_octeti = \&to_bytes;

    sub to_char {
        Corvinus::Types::Char::Char->call($_[0]->get_value);
    }

    *ca_caracter = \&to_char;

    sub to_chars {
        Corvinus::Types::Char::Chars->call($_[0]->get_value);
    }

    *ca_caractere = \&to_chars;

    sub to_grapheme {
        Corvinus::Types::Grapheme::Grapheme->call($_[0]);
    }

    *ca_grafem = \&to_grapheme;
    *to_graph  = \&to_grapheme;

    sub to_graphemes {
        Corvinus::Types::Grapheme::Graphemes->call($_[0]);
    }

    *ca_grafeme = \&to_graphemes;
    *to_graphs  = \&to_graphemes;

    sub to_array {
        Corvinus::Types::Array::Array->new($_[0]);
    }

    *ca_lista = \&to_array;

    sub to_caller {
        Corvinus::Module::OO->__NEW__($_[0]->get_value);
    }

    sub to_fcaller {
        Corvinus::Module::Func->__NEW__($_[0]->get_value);
    }
};

1
