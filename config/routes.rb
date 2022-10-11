Rails.application.routes.draw do
  mount ActionCable.server => '/websockets' 
  resources :boards do
    resources :board_logs, only: [:index] do
      collection do 
        get :chart
      end
    end
  end
  
  resources :devices do
    member do
      patch :set
    end
    resources :device_logs, only: [:index] do
      collection do 
        get :chart
      end
    end
  end
  
  resources :programs do
    member do
      patch :set
      patch :run
    end
  end
  
  resources :panels do
    resources :widgets, except: :show do
      member do 
        patch :update_position
      end
    end
  end
  
  get "logs/index" => "logs#index", as: :logs
  get "logs/show" => "logs#show", as: :log
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "exception_test" => "application#exception_test"
  root "home#index"
end
