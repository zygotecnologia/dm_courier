module RailsCourier
  class Message
    attr_reader :mail

    def initialize(mail)
      @mail = mail
    end
  end
end
