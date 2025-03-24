module Highlighting
  # Registry of the marker pairs a highlighted response can be rendered with.
  #
  # This is the extension point: a deployment that needs, say, XLIFF `<mrk>`
  # tags adds them in an initializer and they become available to the API
  # immediately, with no change to the matcher, the controller or the
  # serializer.
  #
  #   Highlighting::Markup.register(:xliff, open: "<mrk>", close: "</mrk>")
  #
  # `GET /translations/:id?markup=xliff` then renders with them.
  module Markup
    Style = Struct.new(:name, :open, :close) do
      # Wraps the resolved matches, leaving the rest of the text untouched.
      #
      # @param text [String]
      # @param matches [Array<Array(Integer, Integer)>] from Highlighting::Matcher
      def apply(text, matches)
        return text if matches.empty?

        characters = text.chars
        rendered = +""
        cursor = 0

        matches.each do |start, length|
          rendered << characters[cursor...start].join
          rendered << open << characters[start, length].join << close
          cursor = start + length
        end
        rendered << characters[cursor..].join
      end
    end

    class Unknown < Highlighting::Error; end

    DEFAULT = :highlight

    @styles = {}

    class << self
      def register(name, open:, close:)
        @styles[name.to_sym] = Style.new(name.to_sym, open.to_s.freeze, close.to_s.freeze).freeze
      end

      def fetch(name)
        key = (name.presence || DEFAULT).to_sym
        @styles.fetch(key) { raise Unknown, "unknown markup #{name.inspect} (known: #{names.join(", ")})" }
      end

      def registered?(name)
        @styles.key?(name.to_s.to_sym)
      end

      def names
        @styles.keys
      end
    end

    register(:highlight, open: "<HIGHLIGHT>", close: "</HIGHLIGHT>")
    register(:mark, open: "<mark>", close: "</mark>")
    register(:brackets, open: "[[", close: "]]")
  end
end
