const glob = require('glob')
const path = require('path')
const webpack = require('webpack')
const { VueLoaderPlugin } = require('vue-loader')
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin')

module.exports = {
  mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
  devtool: process.env.NODE_ENV === 'production' ? false : 'source-map',

  entry: Object.fromEntries(
    glob.sync('./app/javascript/*.js')
      .map((p) => [path.basename(p, '.js'), p])
  ),
  output: {
    filename: '[name].js',
    sourceMapFilename: '[file].map',
    path: path.resolve(__dirname, 'app/assets/builds')
  },
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader',
        options: {
          hotReload: true
        }
      },
      {
        test: /\.scss$/,
        use: [
          'vue-style-loader',
          'css-loader',
          'sass-loader'
        ]
      }
    ]
  },
  resolve: {
    extensions: ['.vue', '...']
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin(), 
    new VueLoaderPlugin(),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new NodePolyfillPlugin()
  ],
  performance: {
    // We've got some largish assets...and that's okay!
    maxEntrypointSize: 15000000, 
    maxAssetSize: 15000000,
    hints: 'warning'
  },
  watchOptions: {
    poll: 1000
  }
}
