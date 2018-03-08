Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/set-cookies', to: 'cookies#create'
  get '/reset-cookies', to: 'cookies#reset'
  get '/delete-cookies', to: 'cookies#destroy'
  get '/show-cookies', to: 'cookies#show'
end
