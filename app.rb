require 'sinatra'
require 'dotenv'

Dotenv.load

configure do
  enable :sessions
  set(:session_secret, ENV['SESSION_SECRET'])
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  @errors = {}
  @values = {}

  if session[:errors]
    @errors = session[:errors]
    @values = session[:values]

    session[:errors] = nil
    session[:values] = nil
  end

  erb :form
end

post '/show' do
  @errors = {
    title: [],
    items: [],
    count: []
  }

  has_error = false

  # The title of the bingo cards.
  @title = params[:title].strip

  if @title.empty?
    @errors[:title] << "Title can't be blank"
    has_error = true
  end

  # Get all items.  They should have been newline separated.
  items = params[:items].split(/\n+/).map(&:strip).reject { |i| i.strip.empty? }
  unique_items = items.dup

  if items.empty?
    @errors[:items] << "Items can't be blank"
    has_error = true
  end

  if items.length < 24
    @errors[:items] << "You must have at least 24 items."
    has_error = true
  end

  # Number of cards to make.
  count = params[:count].to_i

  if count < 1
    @errors[:count] << "Are you sure you don't want any cards?"
    has_error = true
  end

  if has_error
    session[:errors] = @errors
    session[:values] = {
      title: @title,
      items: items.join("\n"),
      count: count
    }
    return redirect '/'
  end

  # Will be populated by "groups" of items for cards.
  groups = []

  # Ensure we go through every item at least once.
  until unique_items.empty?
    # Attempt to get a sample of 24 items from the ever-reducing list.
    sample = unique_items.sample(24)

    # If the sample is less than 24 (which is possible), make up the the lack
    # of items by appending enough from the original list, exclusive of items
    # that are already in this "group".
    if sample.length < 24
      sample = sample + (items - sample).sample(24 - sample.length)
    end

    # Add the sample to our group.
    groups << sample

    # Update the unique items to everything except our sample.
    unique_items = unique_items - sample

    # Reduce the count, this counts as a card.
    count -= 1
  end

  # Assuming we have more iterations to go through after the unique ones above,
  # make N more "groups" based on a random sample of 24.
  count.times do
    # Get random sample of 24.
    sample = items.sample(24)

    # Add our sample to groups.
    groups << sample
  end

  # We'll use this in the template.  Randomize the results.
  @groups = groups.shuffle

  # Render template.
  erb :bingo
end
