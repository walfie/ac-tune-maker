const HtmlWebpackPlugin = require("html-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const WebpackPluginPWAManifest = require("webpack-plugin-pwa-manifest");
const { GenerateSW } = require("workbox-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const OptimizeCssAssetsPlugin = require("optimize-css-assets-webpack-plugin");

const isProd = process.env.NODE_ENV === "production";

const webpackConfig = {
  entry: "./src/index.js",
  optimization: {
    minimizer: [new TerserPlugin({}), new OptimizeCssAssetsPlugin({})]
  },
  plugins: [
    new CleanWebpackPlugin(),
    new MiniCssExtractPlugin({
      filename: isProd ? "[name].[contenthash:8].css" : "[name].css"
    }),
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
      disabled: !isProd
    }),
    new HtmlWebpackPlugin({ template: "./src/index.html" })
  ],
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, "css-loader"]
      },
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
    filename: isProd ? "[name].[contenthash:8].js" : "[name].js"
  },
  devServer: {
    overlay: true,
    hot: true,
    stats: "errors-only"
  }
};

if (isProd) {
  webpackConfig.plugins.push(
    new GenerateSW({
      swDest: "sw.js",
      include: [/\.(html|css|js|webmanifest)$/],
      runtimeCaching: [
        {
          urlPattern: /\/.+\.[0-9a-f]+\.[a-z]+$/i,
          handler: "CacheFirst"
        }
      ]
    })
  );
}

module.exports = webpackConfig;
