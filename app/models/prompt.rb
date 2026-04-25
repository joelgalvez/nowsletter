class Prompt < ApplicationRecord
  before_destroy :prevent_default_deletion

  private

  def prevent_default_deletion
    if title == "default"
      errors.add(:base, "The default prompt cannot be deleted")
      throw :abort
    end
  end
end
