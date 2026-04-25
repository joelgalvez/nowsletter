class LlmJobChannel < ApplicationCable::Channel
  def subscribed
    if current_user&.parser?
      stream_from "llm_jobs"
    else
      reject
    end
  end
end
