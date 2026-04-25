class AvailableModelsController < ApplicationController
  def index
    @available_models = AvailableModel.order(:name)
  end
end
