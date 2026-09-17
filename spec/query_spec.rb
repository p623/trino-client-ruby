require "spec_helper"

describe Trino::Client::Query do
  let(:faraday) do
    instance_double(Faraday::Connection)
  end

  let(:options) do
    {
      server: "localhost:8080",
      user: "test-user"
    }
  end

  describe ".start" do
    it "passes the provided Faraday client to StatementClient" do
      statement_client =
        instance_double(Trino::Client::StatementClient)

      expect(Trino::Client::StatementClient)
        .to receive(:new)
              .with(faraday, "select 1", options)
              .and_return(statement_client)

      query = described_class.start("select 1", faraday, options)

      expect(query).to be_a(described_class)
    end
  end

  describe ".resume" do
    it "passes the provided Faraday client and next URI to StatementClient" do
      statement_client =
        instance_double(Trino::Client::StatementClient)

      next_uri = "http://localhost:8080/v1/statement/next"

      expect(Trino::Client::StatementClient)
        .to receive(:new)
              .with(faraday, nil, options, next_uri)
              .and_return(statement_client)

      query = described_class.resume(next_uri, faraday, options)

      expect(query).to be_a(described_class)
    end
  end

  describe ".kill" do
    it "uses the provided Faraday client to delete the query" do
      request_headers = {}
      request = double("request", headers: request_headers)
      response = instance_double(Faraday::Response, status: 204)

      expect(faraday)
        .to receive(:delete)
              .and_yield(request)
              .and_return(response)

      expect(request)
        .to receive(:url)
              .with("/v1/query/query-id")

      result = described_class.kill("query-id", faraday, options)

      expect(request_headers).to include(
        "X-Trino-User" => "test-user"
      )
      expect(result).to eq(true)
    end

    it "returns false when deleting the query fails" do
      request = double("request", headers: {})
      response = instance_double(Faraday::Response, status: 500)

      allow(request)
        .to receive(:url)
              .with("/v1/query/query-id")

      allow(faraday)
        .to receive(:delete)
              .and_yield(request)
              .and_return(response)

      result = described_class.kill("query-id", faraday, options)

      expect(result).to eq(false)
    end
  end
end
