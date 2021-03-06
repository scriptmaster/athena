# A container for storing key/value pairs.  Can be used to store arbitrary data within the context of a request.
# It can be accessed via `HTTP::Request#attributes`.
#
# ### Example
#
# For example, an artbirary value can be stored in the attributes, and later provided as an action argument.
#
# ```
# require "athena"
#
# # Define a request listener to add our value before the action is executed.
# @[ADI::Register]
# struct TestListener
#   include AED::EventListenerInterface
#
#   def self.subscribed_events : AED::SubscribedEvents
#     AED::SubscribedEvents{
#       ART::Events::Request => 0,
#     }
#   end
#
#   def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
#     # Store our value within the request's attributes, restricted to a `String`.
#     event.request.attributes.set "my_arg", "foo", String
#   end
# end
#
# class ExampleController < ART::Controller
#   # Define an action argument with the same name of the argument stored in attributes.
#   #
#   # The argument is resolved via `ART::Arguments::Resolvers::RequestAttribute`.
#   get "/", my_arg : String do
#     my_arg
#   end
# end
#
# ART.run
#
# # GET / # => "foo"
# ```
struct Athena::Routing::ParameterBag
  private abstract struct Param
    abstract def value
  end

  private record Parameter(T) < Param, value : T

  @parameters : Hash(String, Param) = Hash(String, Param).new

  # Returns `true` if a parameter with the provided *name* exists, otherwise `false`.
  def has?(name : String) : Bool
    @parameters.has_key? name
  end

  # Returns the value of the parameter with the provided *name* if it exists, otherwise `nil`.
  def get?(name : String)
    @parameters[name]?.try &.value
  end

  # Returns the value of the parameter with the provided *name*.
  #
  # Raises a `KeyError` if no parameter with that name exists.
  def get(name : String)
    self.get?(name) || raise KeyError.new "No parameter exists with the name '#{name}'."
  end

  {% for type in [Bool, String] + Number::Primitive.union_types %}
    # Returns the value of the parameter with the provided *name* as a `{{type}}`.
    def get(name : String, _type : {{type}}.class) : {{type}}
      {{type}}.from_parameter(get(name)).as {{type}}
    end
  {% end %}

  # Sets a parameter with the provided *name* to *value*.
  def set(name : String, value : T) : Nil forall T
    self.set name, value, T
  end

  # Sets a parameter with the provided *name* to *value*, restricted to the given *type*.
  def set(name : String, value : _, type : T.class) : Nil forall T
    @parameters[name] = Parameter(T).new value
  end

  # Removes the parameter with the provided *name*.
  def remove(name : String) : Nil
    @parameters.delete name
  end
end
