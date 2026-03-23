export default function () {
  this.route("agents", { path: "/agents", resetNamespace: true }, function () {
    this.route("configure", { path: "/configure" });
    this.route("docs", { path: "/docs" });
  });
}
