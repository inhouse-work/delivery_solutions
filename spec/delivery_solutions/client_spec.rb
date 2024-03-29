RSpec.describe DeliverySolutions::Client do
  let(:params) do
    {
      api_key: "123",
      tenant_id: "456",
      base_url: "https://example.com",
    }
  end

  describe "#initialize" do
    it "raises an error if the API key is not provided" do
      expect { described_class.new(**params.slice(:tenant_id, :base_url)) }
        .to raise_error(DeliverySolutions::Client::MissingApiKey)
    end

    it "raises an error if the tenant ID is not provided" do
      expect { described_class.new(**params.slice(:api_key, :base_url)) }
        .to raise_error(DeliverySolutions::Client::MissingTenantId)
    end

    it "does not raise an error if the API key is provided" do
      expect { described_class.new(**params) }.not_to raise_error
    end

    it "reads default values from the environment" do
      ENV["DELIVERY_SOLUTIONS_API_KEY"] = "123"
      ENV["DELIVERY_SOLUTIONS_TENANT_ID"] = "456"

      expect { described_class.new }.not_to raise_error
    end
  end
end
