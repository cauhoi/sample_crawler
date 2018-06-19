require 'nokogiri'
require 'rubygems'
require 'mechanize'
require 'json'

class Page
  attr_reader :links,:content
  def initialize(url_options)
    @url = url_options[:main_url]
    @login_url = url_options[:login_url]
    @parse_it = Parser.new(@url,@login_url)
    @content = nil
  end

  def get_dashboard_page(user)
    if @dashboard = @parse_it.log_in(user)
      data = {due_date: get_due_date || "",
        amount: get_amount || "",
        current_usage: get_bill_history.first[1] || "",
        name: get_account_name || "",
        address: get_address || "",
        bill_history: get_bill_history || []
      }
      data
    else
      return false
    end

  end


private

  def get_due_date
    @dashboard.css('div#homepageContent div.row.contentRowPadding')[3].first_element_child.text.strip
  end
  def get_amount
    @dashboard.css('div#homepageContent div.row.contentRowPadding div.col-md-3.col-sm-3.col-xs-12 span.bodyTextGreen').text.strip
  end

  def get_account_name
    @dashboard.css('span#account-summary-info-accountname').text.strip
  end

  def get_address
    @dashboard.css('span#account-summary-info-serviceaddress').text.strip.delete("\n").delete("\r").split(" ").join(" ")
  end
  def get_bill_history
    arr1 = @dashboard.search("#UsageDateArrHdn")[0]['value'].split(',')
    arr2 = @dashboard.search("#UsageDataArrHdn")[0]['value']
    arr2 = JSON.parse(arr2.gsub(/([a-z]+)/,'"\1"'))
    result = arr2.zip(arr1).map{|x| x.flatten}

    @bill_history = result
  end


end

class Parser
  NUM_TRIES = 3
  attr_reader :url

  def initialize(url,login_url = nil)
    @url = url
    @login_url = login_url
    @agent = Mechanize.new
    @agent.open_timeout = 5
    @agent.read_timeout = 5
  end

  def log_in(user)
    retries ||= 0
    @user = user
    begin
      page = get_log_in_page

      NUM_TRIES.times do
        @inside_page = get_inside_page(page)

        if is_member_page?(@inside_page)
          return @inside_page
        else
          puts "Can't log in to user account. Please check the url and credentials"
        end
      end

      return false
    rescue StandardError, Timeout::Error => e
      puts "Error logging in to the site"
      puts e.inspect
      retry if (retries +=1) < 3
      return false
    end

  end



  private
  def is_member_page?(page)
    page_title = page.css('div#_MainView1.mainContent.mainViewMargin h1').text
    page_title.downcase == "my account overview"
  end


  def get_page
    NUM_TRIES.times do
      @agent.get(url)
    end
  end

  def get_inside_page(login_page)
    login_page.form_with(:class => 'form-signin') do |f|
      f.USER  =  @user[:username]
      f.PASSWORD = @user[:pw]
    end.submit

  end
  def get_log_in_page
    if @login_url
      @agent.get(@login_url)
    else
      @agent.click(get_page.link_with(:text => /Sign In/))
    end

  end

end



class Crawler
  LOGIN_URL = 'https://mydom.dominionenergy.com/siteminderagent/forms/login.fcc?TYPE=33554433&REALMOID=06-b1426164-283c-487c-b4ad-645d5f3e03af&GUID=&SMAUTHREASON=0&METHOD=GET&SMAGENTNAME=-SM-9MuHaTndmBnE2%2f6XM3uvK51bOMgT4jKCNSdlNMM9%2fEbWt1q3F81EmVIudNx1ceVl&TARGET=-SM-https%3a%2f%2fmydom%2edominionenergy%2ecom%2f'
  SITE_URL = 'https://www.dominionenergy.com/'

  attr_reader :user
  def initialize
    cf = YAML::load_file(File.join(__dir__, 'pass.yml'))
    #   # user name and pw are stored in a separate yml file
    @user = {username: cf['user'], pw: cf['password']}
  end

  def process
    url_options = {main_url: SITE_URL,login_url: LOGIN_URL}
    homepage = Page.new(url_options)
    if dashboard_data = homepage.get_dashboard_page(user)
      display(dashboard_data)
    end
  end

  def display(page)
    puts "Bill due date: #{page[:due_date]}"
    puts "Bill amount: #{page[:amount]}"
    puts "Usage (kWh): #{page[:current_usage]}"
    puts "Service end date (a.k.a. meter read dates)#{page[:bill_history].first.last}"
    puts "Usage History"
    Array(page[:bill_history]).each{|x| puts "Use #{x[1]}(kWh) on #{x.last}"}
  end

end

target = Crawler.new
target.process




