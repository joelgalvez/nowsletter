require "test_helper"

module Api
  class LlmJobsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @letter = letters(:one)
      @parser = User.create!(
        email_address: "parser@example.com",
        password: "password",
        role: "parser"
      )
      @parser.regenerate_api_token!
      @auth_headers = { "Authorization" => "Bearer #{@parser.raw_api_token}" }
    end

    # ---------- index ----------

    test "index returns only 'new' jobs and does NOT mutate their status" do
      LlmJob.delete_all
      new_job     = LlmJob.create!(letter: @letter, prompt: "p1", status: "new")
      pending_job = LlmJob.create!(letter: @letter, prompt: "p2", status: "pending")
      parsed_job  = LlmJob.create!(letter: @letter, prompt: "p3", status: "parsed")

      get "/api/llm_jobs", headers: @auth_headers

      assert_response :ok
      body = JSON.parse(response.body)
      returned_ids = body["llm_jobs"].map { |j| j["id"] }
      assert_equal [ new_job.id ], returned_ids
      assert_equal 1, body["total"]

      # Critical: index is a pure read — status must still be "new".
      assert_equal "new", new_job.reload.status
      assert_equal "pending", pending_job.reload.status
      assert_equal "parsed", parsed_job.reload.status
    end

    test "index requires parser role" do
      get "/api/llm_jobs"
      assert_response :unauthorized
    end

    # ---------- claim ----------

    test "claim transitions only listed 'new' jobs to 'pending' and returns their ids" do
      a = LlmJob.create!(letter: @letter, prompt: "a", status: "new")
      b = LlmJob.create!(letter: @letter, prompt: "b", status: "new")
      c = LlmJob.create!(letter: @letter, prompt: "c", status: "new")

      post "/api/llm_jobs/claim",
        params: { ids: [ a.id, b.id ] },
        headers: @auth_headers

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal [ a.id, b.id ].sort, body["claimed_ids"].sort

      assert_equal "pending", a.reload.status
      assert_equal "pending", b.reload.status
      assert_equal "new",     c.reload.status
    end

    test "claim ignores ids that are not 'new' and does not re-transition them" do
      already_pending = LlmJob.create!(letter: @letter, prompt: "p", status: "pending")
      parsed          = LlmJob.create!(letter: @letter, prompt: "r", status: "parsed")
      fresh           = LlmJob.create!(letter: @letter, prompt: "f", status: "new")

      original_pending_updated_at = already_pending.updated_at

      post "/api/llm_jobs/claim",
        params: { ids: [ already_pending.id, parsed.id, fresh.id ] },
        headers: @auth_headers

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal [ fresh.id ], body["claimed_ids"]

      # Non-'new' rows are untouched — no status change, no timestamp bump.
      assert_equal "pending", already_pending.reload.status
      assert_in_delta original_pending_updated_at.to_f, already_pending.updated_at.to_f, 0.001
      assert_equal "parsed", parsed.reload.status
      assert_equal "pending", fresh.reload.status
    end

    test "claim is idempotent: a second claim on the same ids returns empty" do
      job = LlmJob.create!(letter: @letter, prompt: "x", status: "new")

      post "/api/llm_jobs/claim", params: { ids: [ job.id ] }, headers: @auth_headers
      assert_equal [ job.id ], JSON.parse(response.body)["claimed_ids"]

      post "/api/llm_jobs/claim", params: { ids: [ job.id ] }, headers: @auth_headers
      assert_response :ok
      assert_equal [], JSON.parse(response.body)["claimed_ids"]
    end

    test "claim with unknown or missing ids returns empty claimed_ids" do
      post "/api/llm_jobs/claim", params: { ids: [ 999_999 ] }, headers: @auth_headers
      assert_response :ok
      assert_equal [], JSON.parse(response.body)["claimed_ids"]

      post "/api/llm_jobs/claim", params: {}, headers: @auth_headers
      assert_response :ok
      assert_equal [], JSON.parse(response.body)["claimed_ids"]
    end

    test "claim requires parser role" do
      job = LlmJob.create!(letter: @letter, prompt: "x", status: "new")
      post "/api/llm_jobs/claim", params: { ids: [ job.id ] }
      assert_response :unauthorized
      assert_equal "new", job.reload.status
    end
  end
end
