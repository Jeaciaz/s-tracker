import { defineConfig } from "vite";
import { resolve } from "path";
import elmPlugin from "vite-plugin-elm";

export default defineConfig({
	build: {
		rollupOptions: {
			input: {
				main: resolve(__dirname, "index.html"),
				offline: resolve(__dirname, "offline.html"),
			},
		},
	},
  plugins: [elmPlugin()],
});
