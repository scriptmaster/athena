require "spec"
require "log/spec"

require "../src/athena"
require "./controllers/*"

Spec.before_suite do
  ENV[Athena::ENV_NAME] = "test"
end

CLIENT = HTTP::Client.new "localhost", 3000

class TestController < ART::Controller
  get "test" do
    "TEST"
  end
end

macro create_route(return_type, view = nil, &)
  ART::Action.new(
    ->{ ->{ {{yield}} } },
    "fake_method",
    "GET",
    Array(ART::Arguments::ArgumentMetadata(Nil)).new,
    Array(ART::ParamConverterInterface::ConfigurationInterface).new,
    {{view}} || ART::Action::View.new,
    TestController,
    {{return_type}},
    typeof(Tuple.new),
  )
end

def new_context(*, request : HTTP::Request = new_request, response : HTTP::Server::Response = new_response) : HTTP::Server::Context
  HTTP::Server::Context.new request, response
end

def new_argument(has_default : Bool = false, is_nillable : Bool = false, default : Int32? = nil) : ART::Arguments::ArgumentMetadata
  ART::Arguments::ArgumentMetadata(Int32).new("id", has_default, is_nillable, default)
end

def new_route(
  arguments : Array(ART::Arguments::ArgumentMetadata)? = nil,
  param_converters : Array(ART::ParamConverterInterface::ConfigurationInterface)? = nil,
  view : ART::Action::View = ART::Action::View.new
) : ART::ActionBase
  ART::Action.new(
    ->{ test_controller = TestController.new; ->test_controller.get_test },
    "get_test",
    "GET",
    arguments || Array(ART::Arguments::ArgumentMetadata(Nil)).new,
    param_converters || Array(ART::ParamConverterInterface::ConfigurationInterface).new,
    view,
    TestController,
    String,
    typeof(Tuple.new),
  )
end

def new_request(*, path : String = "/test", method : String = "GET", route : ART::ActionBase = new_route) : HTTP::Request
  request = HTTP::Request.new method, path
  request.route = route
  request
end

def new_response(*, io : IO = IO::Memory.new) : HTTP::Server::Response
  HTTP::Server::Response.new io
end

def run_server : Nil
  around_all do |example|
    server = ART::Server.new
    spawn { server.not_nil!.start }
    sleep 0.5
    example.run
  ensure
    server.not_nil!.stop
  end

  before_each do
    CLIENT.close # Close the client so each spec file gets its own connection.
  end
end

# Asserts compile time errors given a *path* to a program and a *message*.
def assert_error(path : String, message : String) : Nil
  buffer = IO::Memory.new
  result = Process.run("crystal", ["run", "--no-color", "--no-codegen", "spec/" + path], error: buffer)
  fail buffer.to_s if result.success?
  buffer.to_s.should contain message
  buffer.close
end

# Runs the the binary with the given *name* and *args*.
def run_binary(name : String = "bin/athena", args : Array(String) = [] of String, &block : String -> Nil)
  buffer = IO::Memory.new
  Process.run(name, args, error: buffer, output: buffer)
  yield buffer.to_s
  buffer.close
end

# Test implementation of `AED::EventDispatcherInterface` that keeps track of the events that were dispatched.
class TracableEventDispatcher < AED::EventDispatcher
  getter emitted_events : Array(AED::Event.class) = [] of AED::Event.class

  def self.new
    new [] of AED::EventListenerInterface
  end

  def dispatch(event : AED::Event) : Nil
    @emitted_events << event.class

    super
  end
end
