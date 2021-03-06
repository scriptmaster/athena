class HTTP::Request
  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved.
  property! route : ART::ActionBase

  # See `ART::ParameterBag`.
  getter attributes : ART::ParameterBag = ART::ParameterBag.new
end
