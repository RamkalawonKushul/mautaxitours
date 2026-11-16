Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      resources :tours, only: %i[index show]
      resources :bookings, only: %i[create show]
    end
  end
end
