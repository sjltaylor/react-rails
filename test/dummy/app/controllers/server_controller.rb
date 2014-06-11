class ServerController < ApplicationController
  def show
    @todos = %w{todo1 todo2 todo3}
  end
  def serverside
    render('serverside', layout: 'nojs')
  end
end
