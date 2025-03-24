# ActionController::ParamsWrapper is on by default for JSON requests: it takes
# a body like `{"source_text": "hi"}` and quietly re-presents it as
# `{"translation": {"source_text": "hi"}}`. That made a JSON request behave
# differently from the same request form-encoded — the documented
# "400 Bad Request when the top-level key is missing" only happened for the
# latter.
#
# The API documents an explicit wrapper key on every write, so requiring one is
# the honest contract. Turning wrapping off makes both content types behave the
# same and makes `params.require` mean what it says.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters false
end
