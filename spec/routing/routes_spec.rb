require "rails_helper"

RSpec.describe "Routing", type: :routing do
  describe "implemented endpoints" do
    it { expect(post: "/glossaries").to route_to("glossaries#create") }
    it { expect(get: "/glossaries").to route_to("glossaries#index") }
    it { expect(get: "/glossaries/1").to route_to("glossaries#show", id: "1") }
    it { expect(post: "/glossaries/1/terms").to route_to("terms#create", glossary_id: "1") }
    it { expect(post: "/translations").to route_to("translations#create") }
    it { expect(get: "/translations/1").to route_to("translations#show", id: "1") }
    it { expect(get: "/health").to route_to("health#show") }
  end

  describe "actions the controllers do not implement" do
    # These used to be routed by bare `resources` calls and dispatched to
    # controller actions that do not exist.
    it { expect(patch: "/glossaries/1").not_to be_routable }
    it { expect(delete: "/glossaries/1").not_to be_routable }
    it { expect(get: "/translations").not_to be_routable }
    it { expect(patch: "/translations/1").not_to be_routable }
    it { expect(delete: "/translations/1").not_to be_routable }
    it { expect(get: "/glossaries/1/terms").not_to be_routable }
    it { expect(get: "/glossaries/1/terms/2").not_to be_routable }
    it { expect(patch: "/glossaries/1/terms/2").not_to be_routable }
    it { expect(delete: "/glossaries/1/terms/2").not_to be_routable }
    it { expect(post: "/health").not_to be_routable }
  end
end
