@[ADI::Register]
# Sets the related `ART::Action` on the current request using `ART::RouteResolver`.
struct Athena::Routing::Listeners::Routing
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Request => 25,
    }
  end

  # Assigns the resolved `ART::Action` and path parameters to the request.
  #
  # The resolved route is dupped to avoid mutating the master copy in the singleton.
  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    # The route_resolver must be called here for controller DI to work.
    # Other option would be to new up a route resolver for every request. :shrug:
    route = ART.route_resolver.resolve event.request

    request = event.request

    LOGGER.info &.emit "Matched route #{request.path}", uri: request.path, method: request.method, path_params: route.params, query_params: request.query_params.to_h

    request.route = route.payload.not_nil!.dup

    route.params.not_nil!.merge!(event.request.query_params.to_h).each do |key, value|
      event.request.attributes.set key, value
    end
  end
end
