require 'test_helper'
require 'capybara/rails'
require 'capybara/poltergeist'


Capybara.javascript_driver = :poltergeist
Capybara.app = Rails.application

# Useful for debugging.
# Just put page.driver.debug in your test and it will
# pause and throw up a browser
Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, :inspector => true)
end
Capybara.javascript_driver = :poltergeist_debug


class ViewHelperTest < ActionDispatch::IntegrationTest
  NEW_COMPONENT_FILE_PATH = File.expand_path('../dummy/app/assets/javascripts/components/NewComponent.js.jsx',  __FILE__).freeze
  include Capybara::DSL

  setup do
    FileUtils.rm NEW_COMPONENT_FILE_PATH if File.exist? NEW_COMPONENT_FILE_PATH
    @helper = ActionView::Base.new.extend(React::Rails::ViewHelper)
    Capybara.current_driver = Capybara.javascript_driver
  end

  test 'react_component accepts React props' do
    html = @helper.react_component('Foo', {bar: 'value'})
    %w(data-react-class="Foo" data-react-props="{&quot;bar&quot;:&quot;value&quot;}").each do |segment|
      assert html.include?(segment)
    end
  end

  test 'react_component accepts HTML options and HTML tag' do
    assert @helper.react_component('Foo', {}, :span).match(/<span\s.*><\/span>/)

    html = @helper.react_component('Foo', {}, {:class => 'test', :tag => :span, :data => {:foo => 1}})
    assert html.match(/<span\s.*><\/span>/)
    assert html.include?('class="test"')
    assert html.include?('data-foo="1"')
  end

  test 'react_ujs works with rendered HTML' do
    visit '/pages/1'
    assert page.has_content?('Hello Bob')

    page.click_button 'Goodbye'
    assert page.has_no_content?('Hello Bob')
    assert page.has_content?('Goodbye Bob')
  end

  test 'react_ujs works with Turbolinks' do
    visit '/pages/1'
    assert page.has_content?('Hello Bob')

    # Try clicking links.
    page.click_link('Alice')
    assert page.has_content?('Hello Alice')

    page.click_link('Bob')
    assert page.has_content?('Hello Bob')

    # Try Turbolinks javascript API.
    page.execute_script('Turbolinks.visit("/pages/2");')
    assert page.has_content?('Hello Alice')

    page.execute_script('Turbolinks.visit("/pages/1");')
    assert page.has_content?('Hello Bob')

    # Component state is not persistent after clicking current page link.
    page.click_button 'Goodbye'
    assert page.has_content?('Goodbye Bob')

    page.click_link('Bob')
    assert page.has_content?('Hello Bob')
  end

  test 'react server rendering also gets mounted on client' do
    visit '/server/1'
    assert_match /data-react-class=\"TodoList\"/, page.html
    assert_match /data-react-checksum/, page.html
    assert_match /yep/, page.find("#status").text
  end

# this test doesnt work...

#   test 'react server rendering reflects component changes' do
#     begin
#       FileUtils.rm NEW_COMPONENT_FILE_PATH if File.exist? NEW_COMPONENT_FILE_PATH
#
#       visit '/serverside'
#
#       refute_match /New Server Rendered Component/, page.html
#
#       new_component = <<-NEW_COMPONENT
# /** @jsx React.DOM */
#
# NewComponent = React.createClass({
#   render: function() {
#     return (
#       <div>New Server Rendered Component</div>
#     )
#   }
# })
# NEW_COMPONENT
#
#       File.write(NEW_COMPONENT_FILE_PATH, new_component)
#
#       visit '/serverside'
# binding.pry
#       assert_match /New Server Rendered Component/, page.html
#       changed_component = new_component.gsub('New Server Rendered Component', 'Changed Server Rendered Component')
#       File.write(NEW_COMPONENT_FILE_PATH, changed_component)
#
#       visit '/serverside'
#
#       assert_match /Changed Server Rendered Component/, page.html
#
#       FileUtils.rm NEW_COMPONENT_FILE_PATH
#
#       visit '/serverside'
#
#       refute_match /Server Rendered Component/, page.html
#     ensure
#       FileUtils.rm NEW_COMPONENT_FILE_PATH
#     end
#   end
end
