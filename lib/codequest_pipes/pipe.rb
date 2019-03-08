module Pipes
  # Pipe is a mix-in which turns a class into a Pipes building block (Pipe).
  # A Pipe can only have class methods since it can't be instantiated.
  class Pipe
    attr_reader :context

    def initialize(ctx)
      @context = ctx
    end

    def call
      fail MissingCallMethod
    end

    def self.|(other)
      this = self
      Class.new(Pipe) do
        _combine(this, other)
      end
    end

    def self.call(ctx)
      return ctx if ctx.error
      _validate_ctx(_required_context_elements, ctx)
      new(ctx).call
      _validate_ctx(_provided_context_elements, ctx)
    end

    def self.require_context(*args, **kwargs)
      _required_context_elements.merge!(
        **args.map { |a| [a, nil] }.to_h,
        **kwargs
      )
    end

    def self.provide_context(*args, **kwargs)
      _provided_context_elements.merge!(
        **args.map { |a| [a, nil] }.to_h,
        **kwargs
      )
    end

    def self._combine(first, second)
      _check_interface(first)
      _check_interface(second)
      define_singleton_method(:call) do |ctx|
        first.call(ctx)
        second.call(ctx)
      end
    end
    private_class_method :_combine

    def self._check_interface(klass)
      fail MissingCallMethod unless klass.instance_methods.include?(:call)
    end
    private_class_method :_check_interface

    def self._required_context_elements
      @required_context_elements ||= {}
    end
    private_class_method :_required_context_elements

    def self._provided_context_elements
      @provided_context_elements ||= {}
    end
    private_class_method :_provided_context_elements

    def self._validate_ctx(collection, ctx)
      collection.each do |element, cls|
        _raise_missing_context(element) unless ctx.respond_to?(element)
        next unless cls
        obj = ctx.public_send(element)
        _raise_invalid_type(element, obj, cls) unless obj.is_a?(cls)
      end
    end
    private_class_method :_validate_ctx

    def self._raise_missing_context(element)
      raise MissingContext, "context does not respond to '#{element}'"
    end
    private_class_method :_raise_missing_context

    def self._raise_invalid_type(element, obj, cls)
      raise InvalidType,
        "'#{element}' has invalid type #{obj.class} (expected: #{cls})"
    end
    private_class_method :_raise_invalid_type

    private

    def method_missing(name, *args, &block)
      context.send(name, *args, &block)
    end
  end # class Pipe
end # module Pipes
