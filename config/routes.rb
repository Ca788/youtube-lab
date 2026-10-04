Rails.application.routes.draw do
  get "/health", to: "health#show"

  devise_for :users, skip: :all

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
      end

      resource :user, only: [:show, :create], controller: "user"

      namespace :youtube do
        namespace :catalog do
          resources :live_streams, only: [:index]
          resources :categories, only: [:index]
        end

        resources :live_streams, only: [:index, :show, :create, :destroy] do
          member do
            post :sync
          end

          resources :chat_messages,
                    controller: "live_streams/chat_messages",
                    only:       [:index]

          resources :participants,
                    controller: "live_streams/participants",
                    only:       [:index]

          resources :viewer_samples,
                    controller: "live_streams/viewer_samples",
                    only:       [:index]
        end
      end
    end
  end
end
