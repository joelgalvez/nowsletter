require "application_system_test_case"

class BlacklistsTest < ApplicationSystemTestCase
  setup do
    @blacklist = blacklists(:one)
    sign_in_as users(:one)
  end

  test "visiting the index" do
    visit blacklists_url
    assert_selector "h1", text: "Blacklists"
  end

  test "should create blacklist" do
    visit blacklists_url
    click_on "New blacklist"

    fill_in "Url", with: @blacklist.url
    click_on "Create Blacklist"

    assert_text "Blacklist was successfully created"
    click_on "Back"
  end

  test "should update Blacklist" do
    visit blacklist_url(@blacklist)
    click_on "Edit this blacklist", match: :first

    fill_in "Url", with: @blacklist.url
    click_on "Update Blacklist"

    assert_text "Blacklist was successfully updated"
    click_on "Back"
  end

  test "should destroy Blacklist" do
    visit blacklist_url(@blacklist)
    accept_confirm { click_on "Destroy this blacklist", match: :first }

    assert_text "Blacklist was successfully destroyed"
  end
end
