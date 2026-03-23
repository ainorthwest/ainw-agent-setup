import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";

export default class AgentsDocsController extends Controller {
  @tracked title = "Agent Documentation";
  @tracked content = "";
  @tracked isLoading = true;

  constructor() {
    super(...arguments);
    this.loadDocs();
  }

  async loadDocs() {
    try {
      const res = await fetch("/agents/docs.json");
      if (res.ok) {
        const data = await res.json();
        this.title = data.title || "Agent Documentation";
        this.content = data.content || "";
      }
    } catch {
      this.content = "<p>Failed to load documentation.</p>";
    } finally {
      this.isLoading = false;
    }
  }
}
