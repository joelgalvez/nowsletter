module LettersHelper
  def link_to_letter(event, &block)
      link_to overview_letter_path(id: event.letter, event_id: event.id),
        class: "block border-t pt-1 border-black ",
        data: { turbo_frame: :popup, turbo_action: "advance" },
        &block
  end
end
