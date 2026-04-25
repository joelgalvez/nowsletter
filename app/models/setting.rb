class Setting < ApplicationRecord
  before_destroy { throw :abort }
end
