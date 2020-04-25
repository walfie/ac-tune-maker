const HtmlWebpackPlugin = require("html-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const WebpackPluginPWAManifest = require("webpack-plugin-pwa-manifest");

module.exports = {
  entry: "./src/index.js",
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({ template: "./src/index.html" }),
    new WebpackPluginPWAManifest({
      name: "Animal Crossing Tune Maker",
      shortName: "AC Tune Maker",
      startURL: ".",
      theme: "#99dad3",
      generateIconOptions: {
        baseIcon: "./static/icon.svg",
        sizes: [96, 152, 192, 384, 512],
        genFavicons: true
      },
      development: { disabled: true }
    })
  ],
  module: {
    rules: [
      {
        test: /\.svg$/,
        use: [
          { loader: "raw-loader" },
          {
            loader: "svgo-loader",
            options: { externalConfig: "./svgo.yaml" }
          }
        ]
      }
    ]
  },
  output: {
    path: __dirname + "/dist",
    filename: "[name].[hash].js"
  },
  devServer: {
    overlay: true,
    hot: true,
    stats: "errors-only"
  }
};
