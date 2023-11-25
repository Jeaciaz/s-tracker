import { Elm } from "./src/Main.elm";

if (process.env.NODE_ENV === "development") {
  const ElmDebugTransform = await import("elm-debug-transformer");

  ElmDebugTransform.register({
    simple_mode: true,
  });
}

const root = document.querySelector("#app div");
const access = localStorage.getItem("access");
const refresh = localStorage.getItem("refresh");
const app = Elm.Main.init({
  node: root,
  flags: {
    dashboard: {},
    login: {},
    baseUrl: `${location.protocol}//${location.hostname}:8000`,
    tokens:
      access && refresh
        ? {
            access,
            refresh,
          }
        : null,
  },
});

app.ports.copyText.subscribe(function (text) {
  navigator.clipboard.writeText(text);
});

app.ports.alert.subscribe(alert.bind(window));

app.ports.prompt.subscribe(function ([text, id]) {
  const result = confirm(text);
  app.ports.promptResult.send([id, result]);
});

app.ports.saveTokensPort.subscribe(function ({ access, refresh }) {
  if (
    localStorage.getItem("access") === access &&
    localStorage.getItem("refresh") === refresh
  ) {
    return;
  }
  localStorage.setItem("access", access);
  localStorage.setItem("refresh", refresh);
  app.ports.tokensUpdatedPort.send({ access, refresh });
});
