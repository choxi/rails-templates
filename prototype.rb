RUBY_VERSION = "2.0.0"

# monkeypatch generate
def generate(command)
  run "rvm #{RUBY_VERSION}@#{app_name} do rails generate #{command}"
end

def rake(command)
  run "rvm #{RUBY_VERSION}@#{app_name} do rake #{command}"
end

# create rvmrc file
run "rvm use #{RUBY_VERSION}@#{app_name} --create"
run "rvm #{RUBY_VERSION}@#{app_name} do gem install bundler"
create_file ".rvmrc", "rvm use #{RUBY_VERSION}@#{app_name}"

gem "haml-rails"
gem "angular-rails"
gem "compass-rails"
gem "flatui-rails", git: "https://github.com/choxi/flatui-rails.git"

# authentication and authorization
gem "devise"

# testing
gem "rspec-rails", group: [ :development, :test ]
gem "factory_girl_rails", group: [ :development, :test ]

# debugging
gem "debugger", group: [ :development, :test ]

run "rvm #{RUBY_VERSION}@#{app_name} do bundle install"

file "app/views/layouts/application.html.haml", <<-CODE
!!!
%html
  %head
    %title
      = content_for?(:title) ? yield(:title) : "Untitled"
    %meta{"http-equiv"=>"Content-Type", content:"text/html; charset=utf-8"}/
    = stylesheet_link_tag :application
    = javascript_include_tag :application
    = csrf_meta_tag
    = yield(:head)

  %body
    = yield
CODE

# Configure RSpec + FactoryGirl
generate "rspec:install"
inject_into_file "spec/spec_helper.rb", "\nrequire 'factory_girl'", after: "require 'rspec/rails'"
run "echo '--format documentation' >> .rspec"

# authentication and authorization setup
generate "devise:install"
generate "devise User"
generate "devise:views"

rake "db:migrate"

# compass/sass setup
run("rvm #{RUBY_VERSION}@#{app_name} do compass init rails . --syntax sass")
run("rm app/assets/stylesheets/*.sass") # remove the compass generated files
file "app/assets/stylesheets/application.sass", <<-CODE
@import compass/reset
@import flat-ui
CODE

# landing page setup
file "app/controllers/landing_controller.rb", <<-CODE
class LandingController < ApplicationController
end
CODE

file "app/views/landing/show.html.haml", <<-CODE
%h1 #{app_name}
= link_to 'Sign Up', new_user_registration_path
= link_to 'Sign In', new_user_session_path
CODE

route "root to: 'landing#show'"

# clean up rails defaults
run "rm app/views/layouts/application.html.erb"
run "rm app/assets/stylesheets/application.css"
run "rm public/index.html"
run "rm public/images/rails.png"
run "rm public/javascripts/rails.js"
run "rm -rf test"

# commit to git
git :init
git add: "."
git commit: "-a -m 'initial commit'"