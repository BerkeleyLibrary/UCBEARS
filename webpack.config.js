const glob = require('glob')
const path = require('path')
const webpack = require('webpack')
const { VueLoaderPlugin } = require('vue-loader')
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin')
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');

const extensionRe = /\.(?:js|ts)$/

module.exports = {
  mode: 'production',
  devtool: 'source-map',
  entry: Object.fromEntries(
    glob.sync('./app/javascript/*.{js,ts}')
      .map((p) => {
        const basename = path.basename(p)
        const propertyName = basename.replace(extensionRe, '')
        return [propertyName, p]
      })
  ),
  output: {
    filename: '[name].js',
    sourceMapFilename: '[file].map',
    path: path.resolve(__dirname, 'app/assets/builds')
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        loader: 'ts-loader',
        options: {
          appendTsSuffixTo: [/\.vue$/],
          transpileOnly: true
        },
        exclude: /node_modules/
      },
      {
        test: /\.vue$/,
        loader: 'vue-loader'
      },
      {
        test: /\.scss$/,
        use: [
          'vue-style-loader',
          'css-loader',
          'sass-loader'
        ]
      },
      {
        test: /\.svg$/,
        use: ['@svgr/webpack'],
      }
    ]
  },
  resolve: {
    extensions: ['.js', '.ts', '...']
  },
  plugins: [
    new ForkTsCheckerWebpackPlugin({
      async: false,
      typescript: {
        diagnosticOptions: {
          syntactic: true,
          semantic: true,
          declaration: true,
          global: true
        },
        profile: true
      }
    }),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new webpack.SourceMapDevToolPlugin({
      test: /\.(.js|.ts|.vue)$/,
      exclude: 'node_modules',
      module: true,
      append: false
    }),
    new VueLoaderPlugin(),
    new NodePolyfillPlugin()
  ],
  watchOptions: {
    ignored: /node_modules/
  }
}
