# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## [0.7.1](https://github.com/alexa-games/litexa/compare/v0.7.0...v0.7.1) (2020-10-03)


### Bug Fixes

* restore lost support for implicit microphone open on state transitions ([4a9f518](https://github.com/alexa-games/litexa/commit/4a9f5186a6bbbe7ce8752bc6e9f67ba343ff915a))





# [0.7.0](https://github.com/alexa-games/litexa/compare/v0.6.2...v0.7.0) (2020-10-02)


### Bug Fixes

* adding support for escaped quote characters in say strings ([#176](https://github.com/alexa-games/litexa/issues/176)) ([07c93f1](https://github.com/alexa-games/litexa/commit/07c93f1163be1ae9da337cf26b7b637afe98ce63))
* allow characters outside basic ASCII into invocation names ([#177](https://github.com/alexa-games/litexa/issues/177)) ([2e79120](https://github.com/alexa-games/litexa/commit/2e791205ae65ab8916a16f369224c362b14fb7d7))
* find global extensions in Windows when using nvm ([#189](https://github.com/alexa-games/litexa/issues/189)) ([5bf8c99](https://github.com/alexa-games/litexa/commit/5bf8c9965a5daa0f9eff7760caeddebaa59e03e1))


### Features

* adding new utterance and say alternation syntax ([#175](https://github.com/alexa-games/litexa/issues/175)) ([fe569d3](https://github.com/alexa-games/litexa/commit/fe569d31ded0a30acaf5b198f824a1bf8a072ea0))
* allow switching persistent store to session attributes instead ([#181](https://github.com/alexa-games/litexa/issues/181)) ([5d61bf5](https://github.com/alexa-games/litexa/commit/5d61bf5d307807036b08463be67b8c16e4c4b6fc))
* one shot intents are now delivered after launch is entered ([#188](https://github.com/alexa-games/litexa/issues/188)) ([a783699](https://github.com/alexa-games/litexa/commit/a7836994c4133816acb867b7fc7e8d989eb780b7))
* revamp of HTML extension for WebAPI support ([#186](https://github.com/alexa-games/litexa/issues/186)) ([ca846c0](https://github.com/alexa-games/litexa/commit/ca846c013079fec2b71d5adb5f78bf45fa9241bb))
* specify additional asset upload file extensions ([#191](https://github.com/alexa-games/litexa/issues/191)) ([4bb17f9](https://github.com/alexa-games/litexa/commit/4bb17f975489480d06bb439a71c2db245b615d54))





## [0.6.2](https://github.com/alexa-games/litexa/compare/v0.6.1...v0.6.2) (2020-07-17)


### Bug Fixes

* ignore ASK cli [Warn] async messages during deploy ([#182](https://github.com/alexa-games/litexa/issues/182)) ([f72b219](https://github.com/alexa-games/litexa/commit/f72b2195a6181f26edff16e6072376908229e857))





# [0.6.0](https://github.com/alexa-games/litexa/compare/v0.5.1...v0.6.0) (2020-06-16)


### Features

* ask-cli v2 compatibility + new “manifest” & “extensions” cmds ([#170](https://github.com/alexa-games/litexa/issues/170)) ([35700d7](https://github.com/alexa-games/litexa/commit/35700d730dd74e12699a43ea2cb19525dd71a25b))





## [0.5.1](https://github.com/alexa-games/litexa/compare/v0.5.0...v0.5.1) (2020-06-12)

**Note:** Version bump only for package @litexa/core





# [0.5.0](https://github.com/alexa-games/litexa/compare/v0.4.1...v0.5.0) (2020-04-01)


### Features

* Included unity WebGL file extension in assets whitelist. ([#141](https://github.com/alexa-games/litexa/issues/141)) ([f776dc1](https://github.com/alexa-games/litexa/commit/f776dc1dbd18018c61c733b35db830e6764db48b))





# [0.4.0](https://github.com/alexa-games/litexa/compare/v0.3.1...v0.4.0) (2020-01-30)


### Bug Fixes

* Addressed issues around localized DB type definitions. ([#104](https://github.com/alexa-games/litexa/issues/104)) ([51b83e1](https://github.com/alexa-games/litexa/commit/51b83e1e9b690b5077609e9fb6b7a8e2511da92b))
* addressed potential dependency vulnerabilities ([#91](https://github.com/alexa-games/litexa/issues/91)) ([84d2ba7](https://github.com/alexa-games/litexa/commit/84d2ba7851387deed6fff571ba072018eff9a4f0))
* matching behavior in SMAPI for undefined custom slot type ids ([#84](https://github.com/alexa-games/litexa/issues/84)) ([e7c00dd](https://github.com/alexa-games/litexa/commit/e7c00dd75f3a914208b5b7742b269a8cfdb126ec))
* remove inapplicable warning for not adding events to language model ([#108](https://github.com/alexa-games/litexa/issues/108)) ([c1f0cd8](https://github.com/alexa-games/litexa/commit/c1f0cd8af35210ec96d66b881cdb57b29f2c90b7))
* spaces are no longer added pre-punctuation while joining output speech ([#92](https://github.com/alexa-games/litexa/issues/92)) ([43133e8](https://github.com/alexa-games/litexa/commit/43133e8892be4e7bae8389f5d599b25be86a5917))
* Switched a couple absolute import references to relative. ([#120](https://github.com/alexa-games/litexa/issues/120)) ([af06edb](https://github.com/alexa-games/litexa/commit/af06edb71846231e2132d42750ae0423b8b11cd5))
* update globals.d.ts for dynamoDbConfiguration ([c898187](https://github.com/alexa-games/litexa/commit/c898187873755224566cc2840385b30279548f1d))
* update globals.d.ts for dynamoDbConfiguration ([#111](https://github.com/alexa-games/litexa/issues/111)) ([225cac2](https://github.com/alexa-games/litexa/commit/225cac251b4ccc929eb5668df4bf7e84972b05ba))
* update litexa template depedencies ([#115](https://github.com/alexa-games/litexa/issues/115)) ([a6764b5](https://github.com/alexa-games/litexa/commit/a6764b56bee5239102c9806de4a01d4ade3fd859))
* Updated deprecated mocha.opts files to RC files. ([#110](https://github.com/alexa-games/litexa/issues/110)) ([4de018d](https://github.com/alexa-games/litexa/commit/4de018d79763c37060894c57265280acdd9c822e))


### Features

* add compilation-time-defined variable type called DEPLOY ([#80](https://github.com/alexa-games/litexa/issues/80)) ([c4b37d2](https://github.com/alexa-games/litexa/commit/c4b37d29453e3e8fc34e8ae48c9286f333c0759f))
* add configurable TTL field in Litexa config ([#106](https://github.com/alexa-games/litexa/issues/106)) ([6262123](https://github.com/alexa-games/litexa/commit/62621232c31d10f03dfdeaa83de5bc941ac0e6b2))
* added '!' and 'not' negation operators ([#85](https://github.com/alexa-games/litexa/issues/85)) ([7b275af](https://github.com/alexa-games/litexa/commit/7b275af91ae305d41956ae8397ccbaca3bdb8ea2))
* added ability to override deployment's assets root path ([#94](https://github.com/alexa-games/litexa/issues/94)) ([d9eb39b](https://github.com/alexa-games/litexa/commit/d9eb39b25df791376b06c864260887b4b66bd8bb))
* added optional raw data dump command to test CLI ([#87](https://github.com/alexa-games/litexa/issues/87)) ([c5390be](https://github.com/alexa-games/litexa/commit/c5390be5a651084bf67a2f88682f4fe5475904e8))
* added say-reprompt syntax ([#86](https://github.com/alexa-games/litexa/issues/86)) ([27abbab](https://github.com/alexa-games/litexa/commit/27abbabd5bb2b65be0978bea7f87ce5a923628bd))
* added string replacement map localization method that is detached from skill code ([#100](https://github.com/alexa-games/litexa/issues/100)) ([08c5057](https://github.com/alexa-games/litexa/commit/08c505716b4916e9f5a297b9a6122975f75219cc))
* aws s3 configuration ([#90](https://github.com/alexa-games/litexa/issues/90)) ([8a1546d](https://github.com/alexa-games/litexa/commit/8a1546df3dcd6e29094b8308c964d32e52b1a96a))
* create html extension ([#93](https://github.com/alexa-games/litexa/issues/93)) ([e833b8f](https://github.com/alexa-games/litexa/commit/e833b8f81c68a81446c70237151b55b4c7807f41))
* localized pronunciations ([#82](https://github.com/alexa-games/litexa/issues/82)) ([6ae79aa](https://github.com/alexa-games/litexa/commit/6ae79aa6f38d3f6543eeea9929a17014ababbd21))
* made it so that extension interfaces are auto-enabled ([#105](https://github.com/alexa-games/litexa/issues/105)) ([d9f83ad](https://github.com/alexa-games/litexa/commit/d9f83adbe85177aba24f562ea27c466f49984899))
* multi-intent handlers ([#88](https://github.com/alexa-games/litexa/issues/88)) ([ce855d1](https://github.com/alexa-games/litexa/commit/ce855d1ed8ad69cfbc50eb901408be193371f739)), closes [#89](https://github.com/alexa-games/litexa/issues/89)





## [0.3.1](https://github.com/alexa-games/litexa/compare/v0.3.0...v0.3.1) (2019-10-14)


### Bug Fixes

* added litexa keyword to package files ([#66](https://github.com/alexa-games/litexa/issues/66)) ([0f06f86](https://github.com/alexa-games/litexa/commit/0f06f860924347f8bf08bf9bcfb7f15d2e453e57))





# [0.3.0](https://github.com/alexa-games/litexa/compare/v0.2.1...v0.3.0) (2019-10-12)


### Bug Fixes

* Added catch for ampersands in interjections. ([#48](https://github.com/alexa-games/litexa/issues/48)) ([02b0a04](https://github.com/alexa-games/litexa/commit/02b0a04d2fa4e69447a342c43ee9707030b61b42)), closes [#47](https://github.com/alexa-games/litexa/issues/47)
* Added missing regex chars for Litexa tests. ([#58](https://github.com/alexa-games/litexa/issues/58)) ([e235ed4](https://github.com/alexa-games/litexa/commit/e235ed467a6f78040f43597ca1e30b74852604ab))


### Features

* Update per-package configuration to publish publicly 🥳 ([#49](https://github.com/alexa-games/litexa/issues/49)) ([0ff383b](https://github.com/alexa-games/litexa/commit/0ff383b3bba3fe51a9fdb7166d8a5b3414beec68))





# [0.2.0](https://github.com/alexa-games/litexa/compare/v0.1.6...v0.2.0) (2019-09-19)


### Bug Fixes

* Addressed an issue when using @litexa/assets-wav alongside localization. ([#32](https://github.com/alexa-games/litexa/issues/32)) ([8f48b7c](https://github.com/alexa-games/litexa/commit/8f48b7c))
* Updated API endpoint for ISP queries to work for EU. ([#40](https://github.com/alexa-games/litexa/issues/40)) ([c9dae38](https://github.com/alexa-games/litexa/commit/c9dae38))


### Features

* Added @litexa/apl support for AnimateItem commands, and uniquifying asset URLs. ([#24](https://github.com/alexa-games/litexa/issues/24)) ([e2494a7](https://github.com/alexa-games/litexa/commit/e2494a7)), closes [#23](https://github.com/alexa-games/litexa/issues/23)
* Added @litexa/core version tracking to deployment. ([#20](https://github.com/alexa-games/litexa/issues/20)) ([afd651d](https://github.com/alexa-games/litexa/commit/afd651d)), closes [#19](https://github.com/alexa-games/litexa/issues/19)
* Added initial support for Custom Interfaces to @litexa/gadgets. ([#36](https://github.com/alexa-games/litexa/issues/36)) ([c1acbff](https://github.com/alexa-games/litexa/commit/c1acbff)), closes [#37](https://github.com/alexa-games/litexa/issues/37)
* Added support for locale-specific skill icons, and common assets. ([#18](https://github.com/alexa-games/litexa/issues/18)) ([6e19874](https://github.com/alexa-games/litexa/commit/6e19874))
* Added support for overriding DB key specification. ([#29](https://github.com/alexa-games/litexa/issues/29)) ([46c0a97](https://github.com/alexa-games/litexa/commit/46c0a97)), closes [#30](https://github.com/alexa-games/litexa/issues/30)
* Cleaned up @litexa/gadgets extension and added test coverage. ([#28](https://github.com/alexa-games/litexa/issues/28)) ([df4f2ad](https://github.com/alexa-games/litexa/commit/df4f2ad))
* Up-sell Support for In-Skill Purchasing. Bugfixes and Documentation Updates. ([085fa79](https://github.com/alexa-games/litexa/commit/085fa79))





## [0.1.6](https://github.com/alexa-games/litexa/compare/v0.1.5...v0.1.6) (2019-07-04)


### Bug Fixes

* bugfixes ([#11](https://github.com/alexa-games/litexa/issues/11)) ([46bdf16](https://github.com/alexa-games/litexa/commit/46bdf16))
* resolved issue with Windows compatibility for spawning processes ([#14](https://github.com/alexa-games/litexa/issues/14)) ([904945b](https://github.com/alexa-games/litexa/commit/904945b))





## [0.1.5](https://github.com/alexa-games/litexa/compare/v0.1.4...v0.1.5) (2019-05-22)

**Note:** Version bump only for package @litexa/core





## [0.1.4](https://github.com/alexa-games/litexa/compare/v0.1.3...v0.1.4) (2019-05-09)


### Bug Fixes

* doc fixes and play/stopMusic statements ([#6](https://github.com/alexa-games/litexa/issues/6)) ([495fc60](https://github.com/alexa-games/litexa/commit/495fc60))
* Version Numbers and Docs ([#7](https://github.com/alexa-games/litexa/issues/7)) ([1c57666](https://github.com/alexa-games/litexa/commit/1c57666))





## [0.1.3](https://github.com/alexa-labs/litexa/compare/v0.1.1...v0.1.3) (2019-05-06)


### Bug Fixes

* Cleanup ([a8a0bc2](https://github.com/alexa-labs/litexa/commit/a8a0bc2))





## [0.1.2](https://github.com/alexa-labs/litexa/compare/v0.1.1...v0.1.2) (2019-05-06)


### Bug Fixes

* Cleanup ([a8a0bc2](https://github.com/alexa-labs/litexa/commit/a8a0bc2))





## 0.1.1 (2019-05-06)

**Note:** Version bump only for package @litexa/core
