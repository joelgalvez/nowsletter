require "test_helper"

class LlmJobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @llm_job = llm_jobs(:one)
    sign_in_as users(:one)
  end

  test "should get index" do
    get llm_jobs_url
    assert_response :success
  end

  test "should get new" do
    get new_llm_job_url
    assert_response :success
  end

  test "should create llm_job" do
    assert_difference("LlmJob.count") do
      post llm_jobs_url, params: { llm_job: { prompt: @llm_job.prompt, letter_id: @llm_job.letter_id } }
    end

    assert_redirected_to llm_job_url(LlmJob.last)
  end

  test "should show llm_job" do
    get llm_job_url(@llm_job)
    assert_response :success
  end

  test "should get edit" do
    get edit_llm_job_url(@llm_job)
    assert_response :success
  end

  test "should update llm_job" do
    patch llm_job_url(@llm_job), params: { llm_job: { prompt: @llm_job.prompt, letter_id: @llm_job.letter_id } }
    assert_redirected_to llm_job_url(@llm_job)
  end

  test "should destroy llm_job" do
    assert_difference("LlmJob.count", -1) do
      delete llm_job_url(@llm_job)
    end

    assert_redirected_to llm_jobs_url
  end
end
