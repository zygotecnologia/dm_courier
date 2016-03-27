RSpec.shared_examples "a dm courier service" do
  it "has the name method" do
    expect(subject).to respond_to(:name)
  end

  it "has the deliver! method" do
    expect(subject).to respond_to(:deliver!)
  end
end
