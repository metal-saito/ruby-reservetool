# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReservationTool::HTTPAPI do
  def app
    described_class
  end

  before do
    app.set :container, ReservationTool::Container.new
  end

  let(:payload) do
    {
      user_name: "Alice",
      resource_name: "Room-A",
      starts_at: "2025-01-02T09:00:00Z",
      ends_at: "2025-01-02T10:00:00Z"
    }
  end

  it "creates a reservation" do
    post "/reservations", payload.to_json, { "CONTENT_TYPE" => "application/json" }

    expect(last_response.status).to eq(201)
    body = JSON.parse(last_response.body)
    expect(body["id"]).to eq("RES-0001")
    expect(body["resource_name"]).to eq("Room-A")
  end

  it "lists reservations" do
    2.times do |i|
      post "/reservations", payload.merge(user_name: "User#{i}", starts_at: "2025-01-02T0#{i + 8}:00:00Z", ends_at: "2025-01-02T0#{i + 9}:00:00Z").to_json, { "CONTENT_TYPE" => "application/json" }
      expect(last_response).to be_created
    end

    get "/reservations"

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body.size).to eq(2)
    expect(body.first["user_name"]).to eq("User0")
  end

  it "returns 422 for invalid payload" do
    post "/reservations", { user_name: "" }.to_json, { "CONTENT_TYPE" => "application/json" }

    expect(last_response.status).to eq(422)
    expect(last_response.body).to include("必須")
  end

  it "returns 409 when overlapping" do
    post "/reservations", payload.to_json, { "CONTENT_TYPE" => "application/json" }
    expect(last_response).to be_created

    post "/reservations", payload.to_json, { "CONTENT_TYPE" => "application/json" }

    expect(last_response.status).to eq(409)
  end

  it "cancels a reservation" do
    post "/reservations", payload.to_json, { "CONTENT_TYPE" => "application/json" }
    reservation_id = JSON.parse(last_response.body)["id"]

    delete "/reservations/#{reservation_id}"

    expect(last_response.status).to eq(204)
    expect(last_response.body).to eq("")
  end

  it "returns 404 when deleting unknown id" do
    delete "/reservations/UNKNOWN"

    expect(last_response.status).to eq(404)
  end
end

