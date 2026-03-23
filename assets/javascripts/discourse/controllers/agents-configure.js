import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";

const WORKER_URL = "https://ainw-agent-provisioner.lightcone.workers.dev";

export default class AgentsConfigureController extends Controller {
  @service currentUser;

  @tracked agentUsername = "";
  @tracked displayName = "";
  @tracked newUsername = "";
  @tracked newDisplayName = "";
  @tracked keyRetrieved = false;
  @tracked isLoading = true;
  @tracked isSaving = false;
  @tracked errorMessage = "";
  @tracked successMessage = "";

  constructor() {
    super(...arguments);
    this.loadConfig();
  }

  get hasChanges() {
    return (
      (this.newUsername && this.newUsername !== this.agentUsername) ||
      (this.newDisplayName && this.newDisplayName !== this.displayName)
    );
  }

  async loadConfig() {
    if (!this.currentUser) {
      this.isLoading = false;
      return;
    }

    try {
      const res = await fetch(`/agents/configure.json`);
      if (res.ok) {
        const data = await res.json();
        this.agentUsername = data.agent_username || "";
        this.displayName = data.display_name || "";
        this.keyRetrieved = data.key_retrieved || false;
        this.newUsername = this.agentUsername;
        this.newDisplayName = this.displayName;
      }
    } catch {
      this.errorMessage = "Failed to load agent configuration.";
    } finally {
      this.isLoading = false;
    }
  }

  @action
  updateNewUsername(event) {
    this.newUsername = event.target.value.trim().toLowerCase();
  }

  @action
  updateNewDisplayName(event) {
    this.newDisplayName = event.target.value.trim();
  }

  @action
  async saveChanges(event) {
    event.preventDefault();
    this.errorMessage = "";
    this.successMessage = "";
    this.isSaving = true;

    try {
      const body = {};
      if (this.newUsername && this.newUsername !== this.agentUsername) {
        body.new_username = this.newUsername;
      }
      if (this.newDisplayName && this.newDisplayName !== this.displayName) {
        body.new_display_name = this.newDisplayName;
      }

      const res = await fetch(`/agents/configure`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector(
            'meta[name="csrf-token"]'
          )?.content,
        },
        body: JSON.stringify(body),
      });

      const result = await res.json();

      if (!res.ok) {
        throw new Error(result.error || "Update failed");
      }

      this.agentUsername = result.agent_username || this.newUsername;
      if (result.display_name) {
        this.displayName = result.display_name;
      }
      this.successMessage = "Agent updated successfully.";
    } catch (err) {
      this.errorMessage = err.message;
    } finally {
      this.isSaving = false;
    }
  }
}
