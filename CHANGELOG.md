# Changelog

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
