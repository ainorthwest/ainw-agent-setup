import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";

const WORKER_URL = "https://ainw-agent-provisioner.lightcone.workers.dev";

export default class AgentsController extends Controller {
  @service currentUser;

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
    return (
      this.currentUser?.groups?.some((g) => g.name === "bundle") ?? false
    );
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
      // If check fails, fall through to status-based display
    } finally {
      this.isCheckingAgent = false;
    }
  }
}
