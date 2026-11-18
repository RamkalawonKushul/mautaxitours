Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      resources :tours, only: %i[index show]
      resources :bookings, only: %i[create show]
      resources :transport_enquiries, only: %i[create]
      namespace :admin do
        post "session", to: "sessions#create"
        resources :bookings, only: %i[index show update]
        resources :customers, only: %i[index]
        resources :payments, only: %i[index]
        resources :transport_enquiries, path: "transfers", only: %i[index update]
        resource :reports, only: %i[show]
        resources :tours, only: %i[index show create update destroy]
        resources :vehicle_options, path: "vehicles", only: %i[index create update destroy]
      end
      get "vehicles", to: "vehicle_options#index"
    end
  end
end
