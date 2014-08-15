module Projects
  class Transfer
    include Interactor::Organizer

    organize [
      Projects::TransferProject
    ]

  end
end
