import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import resXVitePlugin from "rescript-x/res-x-vite-plugin.mjs";

export default defineConfig({
  plugins: [tailwindcss(), resXVitePlugin()],
  server: {
    // ATProto OAuth requires redirect_uri with 127.0.0.1 (not localhost)
    host: "127.0.0.1",
  },
});
