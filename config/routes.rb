Rails.application.routes.draw do
  resources :translations
  resources :glossaries do
    resources :terms
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
