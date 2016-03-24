RSpec::Matchers.define :a_message_of_mail do |mail|
  match do |actual|
    actual.instance_of?(RailsCourier::Message) && mail == actual.mail
  end
end
