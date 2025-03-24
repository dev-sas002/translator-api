Rails.application.routes.draw do
  # Only the actions that are actually implemented are routed; a bare
  # `resources` call would dispatch to controller actions that do not exist.
  resources :translations, only: %i[create show]
  resources :glossaries, only: %i[create index show] do
    resources :terms, only: %i[create]
  end

  get "/health", to: "health#show"
end
