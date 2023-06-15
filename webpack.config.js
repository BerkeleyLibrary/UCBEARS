const glob = require('glob')
const path = require('path')
const webpack = require('webpack')
const { VueLoaderPlugin } = require('vue-loader')
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin')

const extensionRe = /\.[jt]s$/

module.exports = {
  mode: 'production',
  devtool: 'source-map',
  entry: Object.fromEntries(
    glob.sync('./app/javascript/*.[jt]s')
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
        options: { appendTsSuffixTo: [/\.vue$/] }
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
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new VueLoaderPlugin(),
    new NodePolyfillPlugin()
  ]
}
