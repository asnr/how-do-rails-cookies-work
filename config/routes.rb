Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/set-cookies', to: 'cookies#set_cookies'
  get '/reset-cookies', to: 'cookies#reset_cookies'
  get '/delete-cookies', to: 'cookies#delete_cookies'
end
