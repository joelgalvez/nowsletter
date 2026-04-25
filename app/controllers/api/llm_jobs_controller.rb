module Api
  class LlmJobsController < BaseController
    before_action :set_llm_job, only: [ :update ]

    def index
      llm_jobs = LlmJob.where(status: "new").order(created_at: :desc).to_a

      render json: {
        llm_jobs: llm_jobs.map do |job|
          {
            id: job.id,
            prompt: job.prompt,
            model: job.model,
            status: job.status,
            created_at: job.created_at
          }
        end,
        total: llm_jobs.size
      }, status: :ok
    end

    def claim
      ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)

      claimed_ids = LlmJob.transaction do
        scope = LlmJob.where(id: ids, status: "new")
        ids_to_claim = scope.pluck(:id)
        scope.update_all(status: "pending", updated_at: Time.current) if ids_to_claim.any?
        ids_to_claim
      end

      render json: { claimed_ids: claimed_ids }, status: :ok
    end

    def update
      if @llm_job.update(result: params[:result], status: "parsed", seconds: params[:seconds])
        @llm_job.process
        render json: {
          message: "LlmJob updated successfully",
          llm_job: {
            id: @llm_job.id,
            result: @llm_job.result,
            status: @llm_job.status
          }
        }, status: :ok
      else
        render json: {
          error: "Failed to update llm_job",
          errors: @llm_job.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def set_llm_job
      @llm_job = LlmJob.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "LlmJob not found" }, status: :not_found
    end
  end
end
