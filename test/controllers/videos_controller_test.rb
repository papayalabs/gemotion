require "test_helper"

class VideosControllerTest < ActionDispatch::IntegrationTest
  test "should get start" do
    get videos_start_url
    assert_response :success
  end
end
