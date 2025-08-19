class ChatController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat_session, only: [ :show, :send_message, :get_messages, :restart ]

  def index
    @chat_sessions = current_user.chat_sessions.recent.limit(10)
  end

  def show
    @chat_messages = @chat_session.chat_messages.chronological.includes(:chat_session)
    @completion_percentage = @chat_session.completion_percentage
  end

  def new_session
    @chat_session = current_user.chat_sessions.create!(status: "active")

    # Start the conversation
    conversation_manager = ConversationManager.new(@chat_session)
    conversation_manager.start_conversation

    redirect_to chat_path(@chat_session)
  end

  def send_message
    user_input = params[:message]&.strip

    if user_input.blank?
      render json: { error: "Message cannot be empty" }, status: :bad_request
      return
    end

    begin
      conversation_manager = ConversationManager.new(@chat_session)
      result = conversation_manager.process_user_message(user_input)

      render json: {
        success: true,
        user_message: serialize_message(result[:user_message]),
        assistant_message: serialize_message(result[:assistant_message]),
        completion_status: result[:completion_status],
        session_completed: @chat_session.completed?
      }
    rescue => e
      Rails.logger.error "Chat error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Provide more specific error messages based on the error type
      error_message = case e.message
      when /quota|rate limit|429/i
        "I'm currently experiencing high usage and need a moment to catch up. Please try again in a few minutes, or we can continue our conversation tomorrow when my systems refresh."
      when /network|connection|timeout/i
        "I'm having trouble connecting right now. Please check your internet connection and try again in a moment."
      else
        "I'm experiencing some technical difficulties. Your message was saved, so please try sending it again."
      end

      render json: {
        error: error_message
      }, status: :internal_server_error
    end
  end

  def get_messages
    messages = @chat_session.chat_messages.chronological

    render json: {
      messages: messages.map { |msg| serialize_message(msg) },
      completion_status: @chat_session.completion_percentage,
      session_completed: @chat_session.completed?
    }
  end

  def restart
    # Mark current session as paused and create a new one
    @chat_session.update(status: "paused")

    new_session = current_user.chat_sessions.create!(status: "active")
    conversation_manager = ConversationManager.new(new_session)
    conversation_manager.start_conversation

    render json: {
      success: true,
      redirect_url: chat_path(new_session)
    }
  end

  def action_plan
    if @chat_session.completed?
      action_plan = @chat_session.get_conversation_state("action_plan")
      extracted_data = ExtractedDataPoint.for_session_summary(@chat_session)

      render json: {
        action_plan: action_plan,
        extracted_data: extracted_data,
        completion_percentage: @chat_session.completion_percentage
      }
    else
      render json: { error: "Session not completed yet" }, status: :bad_request
    end
  end

  def export_data
    extracted_data = ExtractedDataPoint.for_session_summary(@chat_session)
    action_plan = @chat_session.get_conversation_state("action_plan")

    export_data = {
      session_id: @chat_session.id,
      created_at: @chat_session.created_at,
      completed_at: @chat_session.completed_at,
      extracted_data: extracted_data,
      action_plan: action_plan,
      messages: @chat_session.chat_messages.chronological.map do |msg|
        {
          role: msg.role,
          content: msg.content,
          created_at: msg.created_at
        }
      end
    }

    respond_to do |format|
      format.json { render json: export_data }
      format.csv do
        send_data generate_csv(export_data),
                  filename: "health_conversation_#{@chat_session.id}.csv",
                  type: "text/csv"
      end
    end
  end

  private

  def set_chat_session
    @chat_session = current_user.chat_sessions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to new_chat_session_path, alert: "Chat session not found."
  end

  def serialize_message(message)
    {
      id: message.id,
      role: message.role,
      content: message.content,
      audio_url: message.audio_url,
      has_audio: message.has_audio?,
      created_at: message.created_at.iso8601,
      metadata: message.message_metadata
    }
  end

  def generate_csv(data)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << [ "Category", "Value", "Date" ]

      data[:extracted_data].each do |category, value|
        csv << [ category.humanize, value, data[:created_at] ]
      end

      csv << []
      csv << [ "Action Plan" ]
      csv << [ data[:action_plan] ]
    end
  end
end
