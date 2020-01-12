const path = require('path');

const webpack = require('webpack');
const nodeExternals = require('webpack-node-externals')

var ZipPlugin = require('zip-webpack-plugin');

function lambda(input, name) {
	return {
		entry: [input],
		target: 'node',
		mode: process.env.NODE_ENV,
		optimization: {
			minimize: false,
		},
		output: {
			path: path.resolve(__dirname, './build'),
			filename: `index.js`,
			libraryTarget: 'commonjs',
		},
		module: {
			rules: [
				{
					test: /\.js$/,
					exclude: /node_modules/,
					use: {
						loader: 'babel-loader',
						options: {
							babelrc: false,
							presets: [
								[
									'@babel/env',
									{
										targets: {
											node: '10.15'
										},
										// the babel transform will turn ES6 modules into
										// CommonJS modules, which undoes the work RollupJS
										// needs to do, so we don't transform the module types
										modules: false,
									},
								],
							],
							plugins: [
								'@babel/plugin-external-helpers'
							],
						},
					},
				},
				{
					test: /\.handlebars$/,
					loader: 'handlebars-loader',
				}
			],
		},
		externals: [
			'aws-sdk',
			'assert',
			'buffer',
			'child_process',
			'cluster',
			'console',
			'constants',
			'crypto',
			'dgram',
			'dns',
			'domain',
			'events',
			'fs',
			'http',
			'https',
			'module',
			'net',
			'os',
			'path',
			'process',
			'punycode',
			'querystring',
			'readline',
			'repl',
			'stream',
			'string_decoder',
			'timers',
			'tls',
			'tty',
			'url',
			'util',
			'vm',
			'zlib',
		],
		plugins: [
			new webpack.ProgressPlugin(),
			new ZipPlugin({
				filename: `${name}.zip`,
				fileOptions: {
					mtime: new Date(0),
				},
			}),
		],
	}
}

module.exports = [
	lambda('./src/index.js', 'lobbyboy'),
];
