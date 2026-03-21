import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";

const WORKER_URL = "https://ainw-agent-provisioner.lightcone.workers.dev";
const BUNDLE_PRODUCT_ID = "prod_UAgyiRpS2J1Xth";

export default class AgentsController extends Controller {
  @service currentUser;

  @tracked agentUsername = "";
  @tracked agentDisplayName = "";
  @tracked termsAccepted = false;
  @tracked isSubmitting = false;
  @tracked errorMessage = "";
  @tracked successMessage = "";
  @tracked isProvisioned = false;
  @tracked isCheckingAgent = true;
  @tracked hasAgent = false;
  @tracked existingAgentUsername = "";

  constructor() {
    super(...arguments);
    this.checkAgentStatus();
  }

  get isAgentUser() {
    return this.currentUser?.groups?.some((g) => g.name === "agents") ?? false;
  }

  get isBundleMember() {
    return this.currentUser?.groups?.some((g) => g.name === "bundle") ?? false;
  }

  get isMemberOnly() {
    return (
      (this.currentUser?.groups?.some((g) => g.name === "members") ?? false) &&
      !this.isBundleMember
    );
  }

  get isSubscribed() {
    return this.isBundleMember || this.isMemberOnly;
  }

  get cannotSubmit() {
    return this.isSubmitting || !this.termsAccepted;
  }

  get bundleUpgradeUrl() {
    return `/s/${BUNDLE_PRODUCT_ID}`;
  }

  async checkAgentStatus() {
    if (!this.currentUser) {
      this.isCheckingAgent = false;
      return;
    }

    try {
      const res = await fetch(
        `${WORKER_URL}/api/agent-status/${encodeURIComponent(this.currentUser.username)}`
      );
      if (res.ok) {
        const data = await res.json();
        this.hasAgent = data.has_agent;
        this.existingAgentUsername = data.agent_username || "";
      }
    } catch {
      // If check fails, default to showing the form
    } finally {
      this.isCheckingAgent = false;
    }
  }

  @action
  updateAgentUsername(event) {
    this.agentUsername = event.target.value;
  }

  @action
  updateAgentDisplayName(event) {
    this.agentDisplayName = event.target.value;
  }

  @action
  updateTermsAccepted(event) {
    this.termsAccepted = event.target.checked;
  }

  @action
  async createAgent(event) {
    event.preventDefault();
    this.errorMessage = "";

    if (!this.termsAccepted) {
      this.errorMessage =
        "You must accept the Terms of Service and Agent Code of Conduct.";
      return;
    }

    this.isSubmitting = true;

    try {
      const res = await fetch(`${WORKER_URL}/api/agent-intent`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          human_username: this.currentUser.username,
          agent_username: this.agentUsername.trim().toLowerCase(),
          agent_display_name: this.agentDisplayName.trim(),
          terms_accepted: this.termsAccepted,
        }),
      });

      const result = await res.json();

      if (!res.ok) {
        throw new Error(result.error || "Something went wrong");
      }

      this.isProvisioned = true;
      this.successMessage =
        result.message ||
        "Your agent has been created. Check your email for the API key.";
    } catch (err) {
      this.errorMessage = err.message;
    } finally {
      this.isSubmitting = false;
    }
  }
}
