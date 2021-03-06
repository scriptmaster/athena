require "../spec_helper"

class TestController < ART::Controller
  @[ART::Get(path: "some/path/:id")]
  def action1(id : Int64) : Int64
    id
  end
end

class OtherController < ART::Controller
  @[ART::Get(path: "some/path/:id")]
  def action2(id : Int64) : Int64
    id
  end
end

ART.run
