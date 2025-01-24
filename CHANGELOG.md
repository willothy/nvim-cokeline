# Changelog

## [1.0.0](https://github.com/willothy/nvim-cokeline/compare/v0.4.0...v1.0.0) (2025-01-24)


### ⚠ BREAKING CHANGES

* **defaults:** use TabLine/TabLineSel for default_hl
* only hide tabline based on opts.show_if_buffers_are_at_least
* don't delete buffer when falling back to history
* remove `utils.get_hex` - use `hlgroups.get_hl_attr`
* support for more highlight attrs ([#150](https://github.com/willothy/nvim-cokeline/issues/150))
* make scratch buffer if deleting last buffer

### Features

* add index property to TabPage object ([4863677](https://github.com/willothy/nvim-cokeline/commit/48636776059b5fb6de4b91a21655b06d16150ce6))
* add mapping to pick and close multiple buffers ([#205](https://github.com/willothy/nvim-cokeline/issues/205)) ([2fc8c15](https://github.com/willothy/nvim-cokeline/commit/2fc8c15400bcb6e37a6d1f6242d552d5f607efb5))
* allow passing function to mapping funcs ([1a25aee](https://github.com/willothy/nvim-cokeline/commit/1a25aee3e63d2b745df6ba0b35b607117edf4306))
* custom sorting functions ([befa096](https://github.com/willothy/nvim-cokeline/commit/befa096b2a7b17c2298123e7dbe6a89a07404038))
* global (per buffer/tab/etc) hover events ([709a379](https://github.com/willothy/nvim-cokeline/commit/709a379255157520f29aee6bfb3d33c92b0e019a))
* **history:** persist history with `resession` extension ([#174](https://github.com/willothy/nvim-cokeline/issues/174)) ([96255ec](https://github.com/willothy/nvim-cokeline/commit/96255ecf86ef7beb232c6b18d847c87c0e386166))
* sidebar.get_width() utility function ([5c46b21](https://github.com/willothy/nvim-cokeline/commit/5c46b213b234308fb93119a6ce0bab0a1f176b5e))
* support for more highlight attrs ([#150](https://github.com/willothy/nvim-cokeline/issues/150)) ([e0db489](https://github.com/willothy/nvim-cokeline/commit/e0db4891c8ce35428463269184ba01f8f4169efe))
* update default config ([da7f4c9](https://github.com/willothy/nvim-cokeline/commit/da7f4c9effe1f1f8538ff00d8648386bb24172e8))


### Bug Fixes

* 0.11 deprecations ([#202](https://github.com/willothy/nvim-cokeline/issues/202)) ([1e9faa6](https://github.com/willothy/nvim-cokeline/commit/1e9faa649750a8f1fbddfcb40784dd5c07b46b66))
* **bufdel:** ignore first retval of ui.select, prompt for filename if empty ([2f80eeb](https://github.com/willothy/nvim-cokeline/commit/2f80eebe5296f7eddc7abec2c4f14ec523c6df30))
* **buffers:** ensure current_valid_index is non-nil ([52e050a](https://github.com/willothy/nvim-cokeline/commit/52e050a319f37a5f752fe8f461db209ab03a3188)), closes [#76](https://github.com/willothy/nvim-cokeline/issues/76)
* **defaults:** use TabLine/TabLineSel for default_hl ([ee24c3b](https://github.com/willothy/nvim-cokeline/commit/ee24c3b59b119fe4a11b39d1dbcdbb56f6e7d241))
* disable warning for default_hl keys ([f9a9d8c](https://github.com/willothy/nvim-cokeline/commit/f9a9d8cd12e5cb4467b38a7def766b1b43d715c2))
* **docs:** Replace `focused` with `fg` in default_hl in readme ([#152](https://github.com/willothy/nvim-cokeline/issues/152)) ([73a6a52](https://github.com/willothy/nvim-cokeline/commit/73a6a52001aad42ada57acba875f110661aea01d))
* **docs:** update outdated reference in readme ([12e54ac](https://github.com/willothy/nvim-cokeline/commit/12e54ac80631feafd1c1c77e3b2ae7535915d498)), closes [#180](https://github.com/willothy/nvim-cokeline/issues/180)
* don't attempt shorten an empty component list  ([#208](https://github.com/willothy/nvim-cokeline/issues/208)) ([c1e8d1a](https://github.com/willothy/nvim-cokeline/commit/c1e8d1a3289d1af67d9861dcb05905c2912835b8))
* don't check mousemoveevent unless needed ([a7efa64](https://github.com/willothy/nvim-cokeline/commit/a7efa64386467114e386a0f19f4a6086a5650010))
* ensure hlgroup cache is always cleared on ColorScheme ([90ac470](https://github.com/willothy/nvim-cokeline/commit/90ac47031667d3b4d7c43b1f6a891825824b01f0))
* ensure tabs are always updated on TabNew and TabClosed ([68b915a](https://github.com/willothy/nvim-cokeline/commit/68b915ac0e389f4c094ec3d9284b2d73f9c7ac96))
* errors when rendering with no buffers visible ([89be4de](https://github.com/willothy/nvim-cokeline/commit/89be4de2e67ec3951452ec05b5f8ed6717796323))
* get config before checking deps ([dc00262](https://github.com/willothy/nvim-cokeline/commit/dc0026200d290a19ab595c0cc2d41fe2bcd22271))
* highlight caching ([0d2988c](https://github.com/willothy/nvim-cokeline/commit/0d2988c6eff6c58dfc04b08639ae5ff04a21b32c))
* **history:** iter() should not return an infinite iterator ([a2217b1](https://github.com/willothy/nvim-cokeline/commit/a2217b14ad034894fa1aff5197def3fb04aaafc7))
* incorrect function name in sidebar ([c2842a5](https://github.com/willothy/nvim-cokeline/commit/c2842a51df781d357cd3408c411a7bec147b57ae))
* **lint:** removed unused value in buffers.lua ([7310f19](https://github.com/willothy/nvim-cokeline/commit/7310f192af74c6912ca7a40ae1b16253aa95e50e))
* **mappings:** attempt to get next buffer when using history fallback ([2bf44ee](https://github.com/willothy/nvim-cokeline/commit/2bf44ee9096e488d0b84b5f364c05a282ed227f1))
* only trigger mouse drag if screenrow==1 ([321bcde](https://github.com/willothy/nvim-cokeline/commit/321bcde6706af4fb2ef73e1e3de087a12be3ba8c)), closes [#193](https://github.com/willothy/nvim-cokeline/issues/193)
* remove unused import in config.lua ([9d2ec14](https://github.com/willothy/nvim-cokeline/commit/9d2ec147adae611118c21dc03630f4952f5ae419))
* reuse pick letters ([#186](https://github.com/willothy/nvim-cokeline/issues/186)) ([a5e41ba](https://github.com/willothy/nvim-cokeline/commit/a5e41ba2bf2ccc1beb557d343ac40f6bec9e0970))
* set current_index in rendering.lua ([62b2b69](https://github.com/willothy/nvim-cokeline/commit/62b2b69d97ab17cddf6381b4a2d37a441a7b9fd0))
* update default close icon ([acf1047](https://github.com/willothy/nvim-cokeline/commit/acf104756543fd7d53a68ccd32bbdec31b946227)), closes [#148](https://github.com/willothy/nvim-cokeline/issues/148)
* use `buf_is_valid` for both `delete` and `wipeout` in `bufdelete` ([999a483](https://github.com/willothy/nvim-cokeline/commit/999a483f637779b248459cfc100299a42bb459d4))
* use `nvim_tabpage_get_number` for tab index ([#191](https://github.com/willothy/nvim-cokeline/issues/191)) ([351ee90](https://github.com/willothy/nvim-cokeline/commit/351ee90f5fd756480927791e7cc340697a3efb6f))
* use dot in require instead of slash ([b64d130](https://github.com/willothy/nvim-cokeline/commit/b64d130810e5348d986af8ea4686c7767519d3ed)), closes [#153](https://github.com/willothy/nvim-cokeline/issues/153)


### Performance Improvements

* **hover:** use upvalues instead of global table ([3292948](https://github.com/willothy/nvim-cokeline/commit/32929480b1753a5c2a99435e891da9be1e61e0b9))


### Code Refactoring

* don't delete buffer when falling back to history ([652ac5f](https://github.com/willothy/nvim-cokeline/commit/652ac5f6ab2ccf162ad74b2618cd86f9ce1f4c70))
* make scratch buffer if deleting last buffer ([368cd3e](https://github.com/willothy/nvim-cokeline/commit/368cd3ebd2395405c2e333d6aa05d8d509ed99d2))
* only hide tabline based on opts.show_if_buffers_are_at_least ([aa25d8d](https://github.com/willothy/nvim-cokeline/commit/aa25d8dccd3c48ec12e007dc424e2ea86b14fd2b))
* remove `utils.get_hex` - use `hlgroups.get_hl_attr` ([b56f12b](https://github.com/willothy/nvim-cokeline/commit/b56f12b9a72e96b1103accd6dd05b6e9f5cf44e4))

## [Unreleased](https://github.com/willothy/nvim-cokeline/tree/HEAD)

[Full Changelog](https://github.com/willothy/nvim-cokeline/compare/v0.4.0...HEAD)

**Merged pull requests:**

- refactor: use modules, lazy requires [\#157](https://github.com/willothy/nvim-cokeline/pull/157) ([willothy](https://github.com/willothy))
- fixup: \(3682c78e\): README: Replace `focused` with `fg` in default_hl [\#152](https://github.com/willothy/nvim-cokeline/pull/152) ([UtsavBalar1231](https://github.com/UtsavBalar1231))
- feat!: support for more highlight attrs [\#150](https://github.com/willothy/nvim-cokeline/pull/150) ([willothy](https://github.com/willothy))
- Update README.md [\#146](https://github.com/willothy/nvim-cokeline/pull/146) ([sashalikesplanes](https://github.com/sashalikesplanes))
- feat: custom sorting functions [\#145](https://github.com/willothy/nvim-cokeline/pull/145) ([willothy](https://github.com/willothy))
- feat: provide require\("cokeline.sidebar"\).get_width\(\) and cache sidebar widths [\#143](https://github.com/willothy/nvim-cokeline/pull/143) ([willothy](https://github.com/willothy))
- refactor!: make scratch buffer if deleting last buffer [\#142](https://github.com/willothy/nvim-cokeline/pull/142) ([willothy](https://github.com/willothy))
- feat: global \(per buffer/tab/etc\) hover events [\#140](https://github.com/willothy/nvim-cokeline/pull/140) ([willothy](https://github.com/willothy))

## [v0.4.0](https://github.com/willothy/nvim-cokeline/tree/v0.4.0) (2023-07-02)

[Full Changelog](https://github.com/willothy/nvim-cokeline/compare/v0.3.0...v0.4.0)

**Merged pull requests:**

- feat: sidebars on rhs of editor [\#138](https://github.com/willothy/nvim-cokeline/pull/138) ([willothy](https://github.com/willothy))
- feat: native tab support [\#136](https://github.com/willothy/nvim-cokeline/pull/136) ([willothy](https://github.com/willothy))
- perf: use stream-based iterators where possible [\#135](https://github.com/willothy/nvim-cokeline/pull/135) ([willothy](https://github.com/willothy))
- Use named color names [\#134](https://github.com/willothy/nvim-cokeline/pull/134) ([lucassperez](https://github.com/lucassperez))
- feat\(pick\): retain pick char order when not using filename [\#132](https://github.com/willothy/nvim-cokeline/pull/132) ([willothy](https://github.com/willothy))
- feat: buffer history ringbuffer [\#131](https://github.com/willothy/nvim-cokeline/pull/131) ([willothy](https://github.com/willothy))
- feat: support for passing highlight group names [\#130](https://github.com/willothy/nvim-cokeline/pull/130) ([nenikitov](https://github.com/nenikitov))
- feat: allow multiple vert splits in sidebar [\#129](https://github.com/willothy/nvim-cokeline/pull/129) ([willothy](https://github.com/willothy))
- fix: allow multibyte characters on buffer picker [\#123](https://github.com/willothy/nvim-cokeline/pull/123) ([lucassperez](https://github.com/lucassperez))
- feat: add fallback icon by filetype [\#121](https://github.com/willothy/nvim-cokeline/pull/121) ([Webblitchy](https://github.com/Webblitchy))
- fix: index update value [\#118](https://github.com/willothy/nvim-cokeline/pull/118) ([Equilibris](https://github.com/Equilibris))
- feat: add fill_hl config option [\#114](https://github.com/willothy/nvim-cokeline/pull/114) ([FollieHiyuki](https://github.com/FollieHiyuki))
- feat: Rearrange buffers with mouse drag [\#113](https://github.com/willothy/nvim-cokeline/pull/113) ([willothy](https://github.com/willothy))
- feat\(pick\): release taken letters when deleting buffers [\#112](https://github.com/willothy/nvim-cokeline/pull/112) ([soifou](https://github.com/soifou))
- feat: hover events [\#111](https://github.com/willothy/nvim-cokeline/pull/111) ([willothy](https://github.com/willothy))
- feat: per-component click handlers [\#106](https://github.com/willothy/nvim-cokeline/pull/106) ([willothy](https://github.com/willothy))
- feat: close by step and by index [\#104](https://github.com/willothy/nvim-cokeline/pull/104) ([willothy](https://github.com/willothy))
- feat: handle click events with Lua, add bufdelete util [\#103](https://github.com/willothy/nvim-cokeline/pull/103) ([willothy](https://github.com/willothy))
- Proposal: Add sorting by directory [\#97](https://github.com/willothy/nvim-cokeline/pull/97) ([ewok](https://github.com/ewok))
- feat: `pick.use_filename` and `pick.letters` config options [\#88](https://github.com/willothy/nvim-cokeline/pull/88) ([ProspectPyxis](https://github.com/ProspectPyxis))
- fix\(mapping\): handle gracefully keyboard interrupt on buffer pick. [\#81](https://github.com/willothy/nvim-cokeline/pull/81) ([soifou](https://github.com/soifou))
- Update README.md [\#70](https://github.com/willothy/nvim-cokeline/pull/70) ([crivotz](https://github.com/crivotz))
- Adding is_last and is_first to buffer return [\#69](https://github.com/willothy/nvim-cokeline/pull/69) ([miversen33](https://github.com/miversen33))
- Add new configuration [\#68](https://github.com/willothy/nvim-cokeline/pull/68) ([danielnieto](https://github.com/danielnieto))
- fix: check for Windows always fails when computing `unique_prefix` [\#65](https://github.com/willothy/nvim-cokeline/pull/65) ([EtiamNullam](https://github.com/EtiamNullam))
- fix: cokeline-pick-close and cokeline-pick-focus in v0.7 [\#53](https://github.com/willothy/nvim-cokeline/pull/53) ([matt-riley](https://github.com/matt-riley))

## [v0.3.0](https://github.com/willothy/nvim-cokeline/tree/v0.3.0) (2022-03-06)

[Full Changelog](https://github.com/willothy/nvim-cokeline/compare/v0.2.0...v0.3.0)

**Merged pull requests:**

- fix: Allow focusing a buffer from a non-valid buffer [\#40](https://github.com/willothy/nvim-cokeline/pull/40) ([tamirzb](https://github.com/tamirzb))

## [v0.2.0](https://github.com/willothy/nvim-cokeline/tree/v0.2.0) (2022-01-01)

[Full Changelog](https://github.com/willothy/nvim-cokeline/compare/v0.1.0...v0.2.0)

## [v0.1.0](https://github.com/willothy/nvim-cokeline/tree/v0.1.0) (2021-12-07)

[Full Changelog](https://github.com/willothy/nvim-cokeline/compare/68b23cb77e2bf76df92a8043612e655e04507ed6...v0.1.0)

**Merged pull requests:**

- Update README.md [\#27](https://github.com/willothy/nvim-cokeline/pull/27) ([KadoBOT](https://github.com/KadoBOT))
- Add author links to readme [\#20](https://github.com/willothy/nvim-cokeline/pull/20) ([alex-popov-tech](https://github.com/alex-popov-tech))
- fix: correct error in readme.md [\#7](https://github.com/willothy/nvim-cokeline/pull/7) ([olimorris](https://github.com/olimorris))
- :bug: fix: `unique_prefix` on windows [\#3](https://github.com/willothy/nvim-cokeline/pull/3) ([Neelfrost](https://github.com/Neelfrost))
- :bug: fix: use correct path separators for unique_prefix depending on OS [\#2](https://github.com/willothy/nvim-cokeline/pull/2) ([Neelfrost](https://github.com/Neelfrost))

\* _This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)_
