import type { Config } from "jest";

const config: Config = {
  clearMocks: true,
  maxWorkers: 1,
  testEnvironment: "node",
  testMatch: ["**.test.ts"],
  preset: "ts-jest",
  moduleNameMapper: {
    "^(\\.{1,2}/.*)\\.js$": "$1",
  },
  transform: {
    "^.+\\.[jt]s?$": "ts-jest",
  },
  transformIgnorePatterns: ["/node_modules/(?!@meshsdk/.*)"],
  passWithNoTests: true,
};

export default config;