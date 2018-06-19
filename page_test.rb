# require 'test/unit'
require 'minitest/autorun'
require_relative 'page'
require 'rubygems'
require 'mocha'
require 'minitest/unit'
require 'mocha/minitest'

class PageTest < Minitest::Test

  def test_get_dash_board_page_should_extract_data_correctly

    page = MiniTest::Mock.new
    page.expect :log_in, @dashboard_page, [@user]
    page.expect :log_in, @dashboard_page, [@user]

    Parser.stub :new, page  do
      mypage = Page.new({main_url: "www.fake.com",login_url: "www.fake.com/login"})
      # should return the page account.html
      data =  mypage.get_dashboard_page(@user)
      assert data
      assert_equal "May 11, 2018", data[:due_date]
      assert_equal "$999.99", data[:amount]
      assert_equal "Damien Le", data[:name]
      assert_equal "123 Apple Tree ARLINGTON, VA 22203", data[:address]
    end
  end


  def test_display_should_print_out_data_correctly
    page = MiniTest::Mock.new
    page.expect :log_in, @dashboard_page, [@user]
    page.expect :log_in, @dashboard_page, [@user]
    Parser.stub :new, page  do
      mypage = Page.new({main_url: "www.fake.com",login_url: "www.fake.com/login"})
      # should return the page account.html
      data =  mypage.get_dashboard_page(@user)
      assert data
      target = Crawler.new
      assert_output(/Bill due date: May 11, 2018/) { target.display(data)}
      assert_output(/Bill amount: \$999\.99/) { target.display(data)}
      assert_output(/Usage \(kWh\): 674/) { target.display(data)}
    end

  end

  def test_login_with_wrong_name_password_should_display_error
    parsed_page = Parser.new("www.fake.com")
    Parser.any_instance.stubs(:get_inside_page).returns(@login_page)
    Parser.any_instance.stubs(:get_log_in_page).returns(@login_page)
    assert_output(/Can't log in to user account. Please check the url and credentials/) { parsed_page.log_in(@user)}
  end


  def setup
    @login_page = Nokogiri::HTML(open 'login.html')
    @dashboard_page = Nokogiri::HTML(open 'account.html')
    @user = {username: 'fake', pw: 'fake'}
  end



end