class Message < ApplicationRecord
    has_rich_text :body
    belongs_to :list
end
