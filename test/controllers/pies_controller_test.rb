require "test_helper"

class PiesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pies_index_url
    assert_response :success
  end

  test "should get show" do
    get pies_show_url
    assert_response :success
  end

  test "should get new" do
    get pies_new_url
    assert_response :success
  end

  test "should get create" do
    get pies_create_url
    assert_response :success
  end

  test "should get edit" do
    get pies_edit_url
    assert_response :success
  end

  test "should get update" do
    get pies_update_url
    assert_response :success
  end

  test "should get destroy" do
    get pies_destroy_url
    assert_response :success
  end
end
