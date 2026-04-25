class LlmJobsController < ApplicationController
  allow_roles :admin, :parser, except: :status
  skip_before_action :require_authentication, only: :status
  skip_before_action :require_admin_access, only: :status

  before_action :set_llm_job, only: %i[ show edit update destroy ]

  # GET /llm_jobs or /llm_jobs.json
  def index
    @llm_jobs = LlmJob.includes(:letter, :substitutes).order(created_at: :desc).page(params[:page]).per(25)
  end

  # GET /llm_jobs/1 or /llm_jobs/1.json
  def show
  end

  def status
    has_jobs = GlobalSetting.keep_server_up? || LlmJob.exists?(status: "new")
    render json: { has_jobs: has_jobs }
  end


  # GET /llm_jobs/new
  def new
    @llm_job = LlmJob.new
  end

  # GET /llm_jobs/1/edit
  def edit
  end

  # POST /llm_jobs or /llm_jobs.json
  def create
    @llm_job = LlmJob.new(llm_job_params)

    respond_to do |format|
      if @llm_job.save
        format.html { redirect_to @llm_job, notice: "Llm job was successfully created." }
        format.json { render :show, status: :created, location: @llm_job }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @llm_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /llm_jobs/1 or /llm_jobs/1.json
  def update
    respond_to do |format|
      if @llm_job.update(llm_job_params)
        format.html { redirect_to @llm_job, notice: "Llm job was successfully updated." }
        format.json { render :show, status: :ok, location: @llm_job }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @llm_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /llm_jobs/1 or /llm_jobs/1.json
  def destroy
    @llm_job.destroy!

    respond_to do |format|
      format.html { redirect_to llm_jobs_path, status: :see_other, notice: "Llm job was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_llm_job
      @llm_job = LlmJob.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def llm_job_params
      params.expect(llm_job: [ :prompt, :result, :status, :letter_id ])
    end
end
