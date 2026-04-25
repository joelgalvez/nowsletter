module Api
  class AvailableModelsController < BaseController
    def create
      names = params[:models]

      unless names.is_a?(Array) && names.all? { |n| n.is_a?(String) }
        return render json: { error: "models must be an array of strings" }, status: :unprocessable_entity
      end

      names = names.map(&:strip).uniq.reject(&:blank?)

      AvailableModel.transaction do
        AvailableModel.delete_all
        names.each { |name| AvailableModel.create!(name: name) }
      end

      render json: {
        message: "Available models updated",
        models: names.sort
      }, status: :ok
    end
  end
end
