Rails.application.routes.draw do
  resources :ways
  resources :core_values do
    collection do
      post :add_to_user
    end
  end

  # Route for removing user's core values
  resources :user_core_values, only: [ :destroy ] do
    collection do
      patch :update_importance_levels
    end
  end
  get "dashboard/index"


  devise_for :users  # Uncomment this line
  get "/auth/:provider/callback", to: "sessions#omniauth"
  # root 'pies#index'
  root "dashboard#index"  # Change this from 'pies#index'

  get "storyline", to: "dashboard#storyline"
  delete "/sign_out", to: "sessions#destroy"


  post "ai_text_rewriter/generate_first_degree", to: "ai_text_rewriter#generate_first_degree"

  post "ai_text_rewriter/generate_second_degree", to: "ai_text_rewriter#generate_second_degree"

  post "ai_text_rewriter/generate_storyline", to: "ai_text_rewriter#generate_storyline"

  post "ai_text_rewriter/analyze_core_value", to: "ai_text_rewriter#analyze_core_value"

  post "ai_text_rewriter/create_core_value", to: "ai_text_rewriter#create_core_value"

# Add this to your routes.rb temporarily
get "ai_text_rewriter/debug_methods", to: "ai_text_rewriter#debug_methods"


  # for Anthropic AI Claude integration
  resources :wheel_of_life, only: [ :index ] do
    member do
      get :show_category
    end
    collection do
      post :process_response
      get :get_audio_summary
    end
  end




  resources :pies do
    resources :slices do
      resources :elements do
        member do
          patch :toggle
          post :make_tangible
        end
        collection do
          patch :reorder
        end
      end
    end
  end

  resource :setting, only: [ :edit, :update ]

  # Chat routes
  resources :chat, only: [ :index, :show ] do
    member do
      post :send_message
      get :get_messages
      post :restart
      get :action_plan
      get :export_data
    end
  end

  post "chat/new_session", to: "chat#new_session"
  get "new_chat_session", to: "chat#new_session"
end
