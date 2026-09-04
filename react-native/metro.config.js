const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Treat Drizzle's .sql migration files as source so they can be inline-imported.
config.resolver.sourceExts.push('sql');

module.exports = config;
