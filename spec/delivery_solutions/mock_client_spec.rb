# frozen_string_literal: true

FIXTURES = {
  create_order: "order/create_order/201-result",
  list_orders: "order/list_orders/200-default-response",
  get_order: "order/get_order/200-result",
  get_order_status: "order/get_order_status/200-result",
  edit_order: "order/edit_order/200-successful-edit-response",
  retry_order: "order/retry_order/201-result",
  cancel_order: "order/cancel_order/200-successfully-cancel-an-order",
  get_alternate_locations: "order/get_alternate_locations/200-result",
  update_order_status: "order/update_order_status/200-result",
  create_location: "pickup_location/create_location/" \
                   "201-response-for-required-fields-only-request",
  get_location: "pickup_location/get_location/200-result",
  list_locations: "pickup_location/list_locations/200-result"
}.freeze

RSpec.describe DeliverySolutions::MockClient do
  context "creating an order" do
    let(:response_payload) do
      File.read("lib/fixtures/order/create_order/201-result.json")
    end

    it "creates the stub" do
      client = described_class.new
        .stub(create_order: response_payload, get_order: { id: "444" })
        .stub(get_order: { id: "555" })

      expect(client.stubs.keys).to contain_exactly(:create_order, :get_order)
      expect(client.get_order.payload.id).to eq "555"
      expect(client.create_order.payload).to eq JSON.parse(response_payload)
    end

    it "allows accessing data via methods" do
      response = described_class.new.stub(create_order: response_payload).create_order

      expect(response.payload.storeExternalId).to eq "7709"
    end

    it "allows using a simple hash as a payload that overwrites the default" do
      response = described_class.new.stub(create_order: { storeExternalId: "7709" }).create_order

      expect(response.payload.storeExternalId).to eq "7709"
      expect(response.payload.deliveryContact.phone).to eq "+1 234-567-8900"
    end

    it "gets the correct data from the nested delivery address" do
      response = subject.stub(create_order: response_payload).create_order

      expect(response.payload.deliveryAddress.street).to eq "725 Albany Street"
    end

    it "gets the correct data from the nested delivery contact" do
      response = subject.stub(create_order: response_payload).create_order

      expect(response.payload.deliveryContact.phone).to eq "+1 234-567-8900"
    end

    it "gets the correct data from the nested pickup address" do
      response = subject.stub(create_order: response_payload).create_order

      expect(response.payload.pickUpAddress.street).to eq "345 Harrison Avenue"
    end

    it "rejects non-stubbable methods" do
      expect { subject.incorrect_method }
        .to raise_error DeliverySolutions::MockClient::NoStubError
    end

    it "raises an error when a stub wasn't provided and there's no fixture" do
      expect { described_class.new.unavailable_request }
        .to raise_error(DeliverySolutions::MockClient::NoStubError)
    end

    it "returns an invalid data payload when storeExternalId isn't provided" do
      error_payload = File.read("lib/fixtures/errors/invalid_data.json")

      expect { subject.stub(create_order: error_payload).create_order }
        .to raise_error DeliverySolutions::Errors::InvalidData
    end

    it "returns the error response instead of raising if specified" do
      error_payload = File.read("lib/fixtures/errors/invalid_data.json")
      response = described_class.new(raise_api_errors: false).stub(
        create_order: error_payload
      ).create_order

      expect(response.payload).to eq JSON.parse(error_payload)
    end
  end

  describe "#stub" do
    it "handles the stub when stubs are an array" do
      client = described_class.new
        .stub(list_locations: [{ name: "Stubbed Store" }])
        .stub(get_alternate_locations: [{ provider: "Stubbed Provider" }])

      first_location = client.list_locations.payload.collection.first
      first_alternate_location = client.get_alternate_locations.payload.collection.first

      expect(client.stubs.keys).to contain_exactly(:list_locations, :get_alternate_locations)
      expect(first_location.name).to eq "Stubbed Store"
      expect(first_alternate_location.provider).to eq "Stubbed Provider"
    end

    it "returns an argument error if an invalid status stub is provided" do
      expect { subject.stub(:invalid_status, create_order: {}).create_order }
        .to raise_error ArgumentError
    end

    it "gives back the default failure response" do
      failure_response = described_class.new(raise_api_errors: false).stub(
        :failure,
        create_order: {}
      ).create_order

      expect(failure_response.success?).to be false
    end
  end

  describe "returns fixtures when handed an available relevant method" do
    FIXTURES.each do |method, path|
      it "returns the fixture as the response for the #{method} method" do
        fixture_payload = JSON.parse(File.read("lib/fixtures/#{path}.json"))
        response = described_class.new(raise_api_errors: false).send(method)

        test_payload = if fixture_payload.is_a? Hash
          response.payload
        else
          response.payload.fetch(:collection)
        end

        expect(test_payload).to eq fixture_payload
      end
    end
  end
end
