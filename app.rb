require 'sinatra'

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  erb :form
end

post '/show' do
  # The title of the bingo cards.
  @title = params[:title]

  # Get all items.  They should have been newline separated.
  items = params[:items].split(/\n+/)
  unique_items = items.dup

  # Number of cards to make.
  count = params[:count].to_i

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