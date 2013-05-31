# The UnobtrusiveYAMLColumn serializer in contrast to ActiveRecord::Coders::YAMLColumn doesn't serialize
# UTF-8 characters in their Hex byte representation. Instead it serializes the char itself (e.g. é instead of \xC3\xA9).
# A likely reason ActiveRecord::Coders::YAMLColumn is doing this is to achieve maximum compatibility.
# This module is for cases where it's more important to have the actual characters in their end form in the DB which
# saves a consumer of this DB from having to convert the hex literals. This is useful for situations where other
# programming languages work with Tolk's translations through the database.
#
# Furthermore it'll use .ya2yaml(:syck_compatible => true) instead of YAML.dump if it can.
# ya2yaml will generate lighter YAML markup. For example it won't end multi-line values with \ for each line.
#
# The expansion of UTF-8 hex literals was inspired by
# @see http://blog.rayapps.com/2013/03/11/7-things-that-can-go-wrong-with-ruby-19-string-encodings/#toc_12
# and the comment
# @see http://blog.rayapps.com/2013/03/11/7-things-that-can-go-wrong-with-ruby-19-string-encodings/#comment-829265574
module Tolk
  class UnobtrusiveYAMLColumn < ActiveRecord::Coders::YAMLColumn
    def dump(obj)
      return super unless obj.respond_to?(:gsub)
      processed = expand_utf8_hex_literals(obj)
      processed.respond_to?(:ya2yaml) ? processed.ya2yaml(:syck_compatible => true) : processed.to_yaml
    end

    def load(yaml)
      return super unless yaml.respond_to?(:gsub)
      processed = expand_utf8_hex_literals(yaml)
      super(processed)
    end

    private

    def expand_utf8_hex_literals(obj)
      # if yaml sting contains old Syck-style encoded UTF-8 characters
      # then replace them with corresponding UTF-8 characters
      obj.gsub(/\\x([0-9A-F]{2})/){ [$1].pack("H2") }.force_encoding("UTF-8")
    end
  end
end
