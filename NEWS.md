<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# duckdb 1.1.3.9017

## Bug fixes

- Make `./cleanup` script reentrant (@Antonov548, #612, #634).

## Features

- With `duckdb(environment_scan = TRUE)`, data frame objects are available as views in duckdb SQL queries (#140, #164).

- Update vendored cpp11 to 0.5.1 (#636).

## Continuous integration

- Fetch tags for fledge workflow to avoid unnecessary NEWS entries (#633).


# duckdb 1.1.3.9016

## Bug fixes

- Avoid compiler warning related to `Rboolean` (#594).

- Check `"duckdb.materialize_message"` symbol (#592).

- `%in%` works correctly as part of a `&` conjunction (#528).

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- Use portable format modifiers.

- Correctly compute vector length for data frames passed to relational functions (#379).

- Set `initialize_in_main_thread`, add patch.

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (@romainfrancois, #186).

- Xz-compress duckdb sources in the tarball (#530).

- Add `col.types` argument to `duckdb_read_csv()` (@eli-daniels, #383, #445).

- `last_rel` (#529).

- `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- Rethrow errors with rlang if installed (#522).

- Catch and add query context for statement extraction (tidyverse/duckplyr#219, #521).

- Implement query cancellation (#514, #515).

- Add comparison expression to relational api (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

- Bump vendored cpp11 to v0.5.0 (#382, #387).

- Tweak implementation of `r_base::sum()` (#381, #385).

- `n_distinct()` supports `na.rm = TRUE` with a single vector argument again (@lschneiderbauer, #204, #216).

- New `rel_from_sql()` (#212).

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Bump for pre-release.

- Keep `cleanup` files to accommodate different build scenarios (#536).

- Update vendored sources to duckdb/duckdb@19864453f7d0ed095256d848b46e7b8630989bac (#580).

- Update vendored sources to duckdb/duckdb@c3ca3607c221d315f38227b8bf58e68746c59083 (#579).

- Update vendored sources to duckdb/duckdb@9cba6a2a03e3fbca4364cab89d81a19ab50511b8 (#578).

- Update vendored sources to duckdb/duckdb@c6c08d4c1b363231b3b9689367735c7264cacefb (#577).

- Update vendored sources to duckdb/duckdb@7f34190f3f94fc1b1575af829a9a0ccead87dc99 (#576).

- Update vendored sources to duckdb/duckdb@78b65d4a9aa80c4be4efcdd29fadd6f0c893f1ce (#575).

- Update vendored sources to duckdb/duckdb@c31c46a875979ce3343edeedcb497485ca2fd751 (duckdb/duckdb#14542, #574).

- Update vendored sources to duckdb/duckdb@4ba2e66277a7576f58318c1aac112faa67c47b11 (#573).

- Update vendored sources to duckdb/duckdb@247fcb31733a5297c1070fbd244f2349091253aa (duckdb/duckdb#14601, #572).

- Update vendored sources to duckdb/duckdb@1a519fce83b3d262247325dbf8014067686a2c94 (duckdb/duckdb#14600, #571).

- Update vendored sources to duckdb/duckdb@b653a8c2b760425a83302e894bf930f18a1bdf64 (#570).

- Update vendored sources to duckdb/duckdb@79bf967e1b6ab438e0a83a014e937af571ed7acb (#569).

- Update vendored sources to duckdb/duckdb@4b62ee43a7d5f62313d77d36dec8aea29412431f (#568).

- Update vendored sources to duckdb/duckdb@3293c92b6e657084318f7556b14077896b333109 (#567).

- Update vendored sources to duckdb/duckdb@8664b710beb205ec6fc7e9f3d18dfe24dd28625f (#566).

- Update vendored sources to duckdb/duckdb@92a1ccbcef04dda11c85fa2bf6daf27daf8d9c49 (#565).

- Update vendored sources to duckdb/duckdb@2635a87a566b90e086caa84805019f66eedf0859 (#564).

- Update vendored sources to duckdb/duckdb@0d5ec0057838081251b388726353f09cba9577ad (#563).

- Update vendored sources to duckdb/duckdb@6af32330b51af4d72d3fed665bfc03f78c8b3876 (#562).

- Update vendored sources to duckdb/duckdb@662b0b34eaaf7f52545638cbc87c10e32b33834d (#561).

- Update vendored sources to duckdb/duckdb@bccd37ae7ea09f77b6299165bf80bca3bc1efc7c (#560).

- Update vendored sources to duckdb/duckdb@5090b7396173069bb0d51b0e1341cfa9950c154f (#559).

- Update vendored sources to duckdb/duckdb@f5ebc9b8e1d6c040a2276e0ac4a41d6bf9475880 (duckdb/duckdb#14545, #558).

- Update vendored sources to duckdb/duckdb@b8c5248b9c18f7cafbdf7992421662adbd95bf38 (#557).

- Update vendored sources to duckdb/duckdb@dfdd7968262d912910d8249bde3524e068c67713 (#556).

- Update vendored sources to duckdb/duckdb@d0673165b52e89fe70d1891504e4dea82adeca85 (#555).

- Update vendored sources to duckdb/duckdb@d79e66bd032dbd2066c16a88f517f6da1cd0aa78 (#554).

- Update vendored sources to duckdb/duckdb@0359726be957673a62ab1ab61f1cca9ba5667386 (#553).

- Update vendored sources to duckdb/duckdb@10c42435f1805ee4415faa5d6da4943e8c98fa55 (#552).

- Update vendored sources to duckdb/duckdb@43d26298affa89bc6ca829a1defc4819b42b6fb4 (#551).

- Update vendored sources to duckdb/duckdb@52b43b166091c82b3f04bf8af15f0ace18207a64 (#550).

- Update vendored sources to duckdb/duckdb@0446ab42e96b6269e78f55293f4096fa10224837 (#549).

- Update vendored sources to duckdb/duckdb@ceb77af7935c3c7a4a34e1199abd4d6ea080448c (duckdb/duckdb#14430, #548).

- Update vendored sources to duckdb/duckdb@aed52f5cabe34075c53bcec4407e297124c8d336 (#547).

- Update vendored sources to duckdb/duckdb@e41a881658ae579cedebe19c5070dad660086aea (#546).

- Update vendored sources to duckdb/duckdb@98d4ad28be35cf5c37e18760e76d11bc07be1ab4 (#545).

- Update vendored sources to duckdb/duckdb@1bb332c9c59a9d15b196b4486a6d1ffcaa833ba5 (#544).

- Update vendored sources to duckdb/duckdb@0bbfe09937e3744325f3b2dfdb182e9ac1ff916f (#543).

- Update vendored sources to duckdb/duckdb@08969b4677534b6870bff4c99998c753a6e784fc (#542).

- Update vendored sources to duckdb/duckdb@4756244efa04d204be6f20d55036fc503b7ed49c (#541).

- Update vendored sources to duckdb/duckdb@217ec4722e949eaa49568bd707e49431ef727ab5 (#539).

- Move responsibility for removing CR (#533).

- Terminate all sources with newline (#531).

- Sync duckplyr tests (#527).

- Cleanup, preparation (#525).

- Bump version.

- Update vendored sources (tag v1.1.2) to duckdb/duckdb@f680b7d08f56183391b581077d4baf589e1cc8bd (#510).

- Update vendored sources to duckdb/duckdb@5f49126b92a0899a2049aaa57da886138c5f879d (#509).

- Update vendored sources to duckdb/duckdb@2c21eb1c2eec3a1e359d87fb2a2cd8e427dc03c1 (#508).

- Update vendored sources to duckdb/duckdb@cc067e6b7db33f516437567cbc726536e34ed716 (#507).

- Update vendored sources to duckdb/duckdb@d2dfc6090685470cb09326a7530066fc4b3db42a (#506).

- Update vendored sources to duckdb/duckdb@56e2e0e5721b8547f564fccf252db0ba93c85471 (#505).

- Update vendored sources to duckdb/duckdb@35dfcc06e6c76ad6bd8e4acdae1bcc30751777eb (#504).

- Update vendored sources to duckdb/duckdb@92e0964376a78f990408a0e81af155504b35d27c (#503).

- Update vendored sources to duckdb/duckdb@01e6e98e3875ed12cbcb9257f81844743b1665fa (#502).

- Update vendored sources to duckdb/duckdb@6dc2e9375870e60f82becb1cece4cc878289d3b8 (#501).

- Update vendored sources to duckdb/duckdb@52b19d5ece35be344830800db0e4961f47114aa9 (#500).

- Update vendored sources to duckdb/duckdb@0d3e84330e845ceefdc55a36d52ef0296af5d1e1 (#499).

- Update vendored sources to duckdb/duckdb@d0cf23ead54f191bf2518598edf04e209f07452e (#498).

- Update vendored sources to duckdb/duckdb@d57a94430e50263cbd1b719b984da189e5bba0c5 (#497).

- Update vendored sources to duckdb/duckdb@a5ddffef692c0627dd6c7efaed7cf65148321452 (#496).

- Update vendored sources to duckdb/duckdb@536f979f69b1bbe40d582450b6cfa6a68463f172 (#495).

- Update vendored sources to duckdb/duckdb@443380a11dbb31a1c218a759ec0c3b56880f1c38 (duckdb/duckdb#14249, #494).

- Update vendored sources to duckdb/duckdb@7919e4abc5597dc4fbeb5a19dff19ff69b5c4113 (duckdb/duckdb#14249, #493).

- Update vendored sources to duckdb/duckdb@52f967a42861032fd5f4392609afc195cd025dde (#492).

- Update vendored sources to duckdb/duckdb@1f20676c7d997fe4964a8b51378bf984e53a4b4c (#491).

- Update vendored sources to duckdb/duckdb@8cec9b1537f900e7a644e7b466ea899cf1ca8f8f (#490).

- Update vendored sources to duckdb/duckdb@4f0cd4d60035e8c6afafed47b68b2240b39e3566 (duckdb/duckdb#14212, #489).

- Update vendored sources to duckdb/duckdb@5a9a382a573b107a38f5ee277619b362d5079c32 (#488).

- Update vendored sources to duckdb/duckdb@123b82b9053c4843559035b6723c867b2618b2d9 (#487).

- Update vendored sources to duckdb/duckdb@405e15fcde8a4da4a7c6d3889f992f0a363c05f2 (duckdb/duckdb#14232, #486).

- Update vendored sources to duckdb/duckdb@0e398d95c50ae40730467c53922c8fb8d5c69f90 (#485).

- Update vendored sources to duckdb/duckdb@1eac05ecd3a6b8ec2cdf0c53ccece7ca2effef26 (#484).

- Update vendored sources to duckdb/duckdb@048f5ffcec9c1a4b73cbfbd4158cd5b6669f102b (#483).

- Update vendored sources to duckdb/duckdb@0b2d95601c2d9474f2c823ac3363e9ca14224c7c (#482).

- Update vendored sources to duckdb/duckdb@350d061846ed7e4c96d2efa7b523bb97ae84538a (#481).

- Update vendored sources to duckdb/duckdb@2f6b78c21d1634c7228e00c809a790701705c82b (#480).

- Update vendored sources to duckdb/duckdb@8aca4330ac46be3950c6b12e29040322dd245b7a (#479).

- Update vendored sources to duckdb/duckdb@9931d723ccde2b2435b1a927234338e6f0353d90 (#478).

- Update vendored sources to duckdb/duckdb@d896e73fe2db62b6749b95e30faa8bfa41dc4d32 (#477).

- Update vendored sources to duckdb/duckdb@f8c82ab2620f8066b0141df0c3982885a5258746 (#476).

- Update vendored sources to duckdb/duckdb@ee256eb45552601db71d4cad7a5cd4f46f0d5a1d (#475).

- Update vendored sources to duckdb/duckdb@130aab3f9ddb84e0c6e7f543a99881d8fc1bd6b7 (#474).

- Update vendored sources to duckdb/duckdb@92c65a4341c57f313dbeba5acc7b1fb917808010 (#473).

- Update vendored sources to duckdb/duckdb@47e1d3d60b4d6d075cf88c2707572df12a630a3a (#472).

- Update vendored sources to duckdb/duckdb@45559f5eeb1834454a30490fc4ffad1807e13f3b (#471).

- Update vendored sources to duckdb/duckdb@dfdd09f46c0169c9d8aa5381086e46a66e44fabc (#470).

- Update vendored sources to duckdb/duckdb@89828abb72219957372f316da06f007dadd2a9aa (#469).

- Update vendored sources to duckdb/duckdb@12e9777cf6283f44710b2610ba3d3735a1208751 (duckdb/duckdb#14077, #468).

- Update vendored sources to duckdb/duckdb@4a55e2334232afe94e47ab398ddb44f88fcd6658 (#467).

- Update vendored sources to duckdb/duckdb@0f3c46215feb0fb92d4998977fc31b2f52db6b14 (#466).

- Update vendored sources to duckdb/duckdb@c87246586490b442706d0be66b82d71930a00578 (#465).

- Update vendored sources to duckdb/duckdb@cd8cb3f1c81a74a3b2c1ed7d94e3913485895074 (#464).

- Update vendored sources to duckdb/duckdb@acd16816e31789bdb27e144ccd19ddb9da4fe6df (#463).

- Update vendored sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove uninitialized warnings.

- Document (#456).

- Update vendored sources (tag v1.1.1) to duckdb/duckdb@af39bd0dcf66876e09ac2a7c3baa28fe1b301151 (#454).

- Update vendored sources to duckdb/duckdb@0fe7708eef6b9b77270ca21cb9b5e30a3de84e3c (#453).

- Update vendored sources to duckdb/duckdb@34a3acc6b3354be86fe593d09e0702ab5eafe757 (#452).

- Update vendored sources to duckdb/duckdb@cb2a947e9df4f6c40b6dd5751c412d6946cbb62b (#451).

- Update vendored sources to duckdb/duckdb@64520f224d8a0a096cfe10f0c2cfbd1ac9457811 (duckdb/duckdb#13934, #450).

- Update vendored sources to duckdb/duckdb@b0eee44df70eb7bf9efac5f65dd2eaf7ad1e5403 (#449).

- Update vendored sources to duckdb/duckdb@4fe3dc559d10648691f9ab34f20207771890dd45 (#448).

- Update vendored sources to duckdb/duckdb@6c02032393583f353f2f2a0337a8e16f34dc5d82 (duckdb/duckdb#14026, #447).

- Update vendored sources to duckdb/duckdb@4ce455c84029195ffa4c3e540c10360ae8c73724 (#446).

- Update vendored sources to duckdb/duckdb@03dd0df6185d903ecbff9d80017e5449e78e5017 (#443).

- Update vendored sources to duckdb/duckdb@d1037da3139de90dc0a82df746d8ce92a50d9838 (#442).

- Update vendored sources to duckdb/duckdb@cb27c0423fa7107674c267b5de8eb93dd603cb69 (duckdb/duckdb#13993, #441).

- Update vendored sources to duckdb/duckdb@b787fcc1cb9bc4daf36e6eec19c1e9b2b162f4b0 (duckdb/duckdb#14020, #440).

- Update vendored sources to duckdb/duckdb@0ce863113043806780e776bcfb86b24afcb0263c (#439).

- Update vendored sources to duckdb/duckdb@f9e96b191088e65b4a1f95918312c40e31096dd9 (#438).

- Update vendored sources to duckdb/duckdb@2ff9c687e2c448914a28c59bd50f48f54e47de3c (#437).

- Update vendored sources to duckdb/duckdb@dcc302aef4491db8cc2efd2955ac254a4d62dcbc (#436).

- Update vendored sources to duckdb/duckdb@03976af191370d4020c172a82b28ca7885d98ea3 (#435).

- Update vendored sources to duckdb/duckdb@29c46243993319b0db24509c862126b8e17f1e8c (#434).

- Update vendored sources to duckdb/duckdb@e7da966e87539457f3de94a1bee288861fdca6d6 (#433).

- Update vendored sources to duckdb/duckdb@44bba02cea5d316e38f6edbad7fad3a1f913d63f (#432).

- Update vendored sources to duckdb/duckdb@04a1f750a6fab3f1a9cf3fb7cce5fd119c522304 (#431).

- Update vendored sources to duckdb/duckdb@0da70d9de97ff2cf39ad99b9e30b7e6cb91614b8 (duckdb/duckdb#13933, #430).

- Update vendored sources to duckdb/duckdb@df82a0e2c47e8b3ddd5a93e08530b83bc49e0da0 (#429).

- Update vendored sources to duckdb/duckdb@86723c9912fde7b76d3863b2ccd2d4333251c4af (#428).

- Update vendored sources to duckdb/duckdb@66d8ed93f67a00006ec99226c1205bcffb1ef07b (duckdb/duckdb#13941, #427).

- Update vendored sources to duckdb/duckdb@b2f68017070c1910dd3438f9428c7162cb428f84 (#426).

- Update vendored sources to duckdb/duckdb@35a104529b56c4f4f1e383e2ead26d6047d3442e (#425).

- Update vendored sources to duckdb/duckdb@b8c5fa937919631b759a70e33f068aa05de8bd36 (#424).

- Update vendored sources to duckdb/duckdb@18670a10f1b3da56382e272518d6b149e489ca51 (#423).

- Update vendored sources to duckdb/duckdb@0b0c95b9dc685e1a6ca011d8e086d885afbe0398 (#422).

- Update vendored sources to duckdb/duckdb@e5e1595da75ea01559f2b4bc9531505422b7fcdc (duckdb/duckdb#13585, #421).

- Update vendored sources to duckdb/duckdb@75d4bd0cc759dcb609ab349b87bff07dddf2ebb7 (#420).

- Update vendored sources to duckdb/duckdb@c0f29465624aaa1472ee05d4723415cfa1bfbdf9 (#419).

- Update vendored sources to duckdb/duckdb@b369bcb4e08235e52866a5f8afb7e172fe573287 (#418).

- Update vendored sources to duckdb/duckdb@414207f2120ad9019b416cf891947004c74c7347 (#417).

- Update vendored sources to duckdb/duckdb@38ceb86f1aa4cfae7c993f59de19e0cfee7ff68e (#416).

- Update vendored sources to duckdb/duckdb@0dbb79e8de897b4a710ed53becc063bcdf80884d (duckdb/duckdb#13824, #415).

- Update vendored sources to duckdb/duckdb@9af117f0e6d3f2f9ade385dadc46807c1b388dd4 (#414).

- Update vendored sources to duckdb/duckdb@88a4c1e5893f316d763343d7f66f57917b065f50 (#413).

- Update vendored sources to duckdb/duckdb@d93225aab5c8e0da34776398358373f4c0232864 (duckdb/duckdb#13872, #412).

- Update vendored sources to duckdb/duckdb@8c2ee1eb7987a981cdf4bb1ed52683784a26e3bf (duckdb/duckdb#13880, #411).

- Update vendored sources to duckdb/duckdb@081a748340c4fcd3b3652230a02432afae72bbb3 (#410).

- Update vendored sources to duckdb/duckdb@bc7683e100867fae06c1f65e055df403c2ee25cf (#409).

- Update vendored sources to duckdb/duckdb@b87545985fc03e43baf84d9554eab23ea4b21f6c (#408).

- Update vendored sources to duckdb/duckdb@1d7e05c9737821fdb2c8eba996642c9953de52f6 (#407).

- Update vendored sources to duckdb/duckdb@b383f3668095fac2574bc6a0c417047a6fe80c9f (#406).

- Update vendored sources to duckdb/duckdb@039a262ae9805f30690ae1c8ec6a7fb27812c1b5 (#405).

- Update vendored sources to duckdb/duckdb@d697acfb108f6ec1b1ed26f0062445e1d49ee1c4 (#404).

- Update vendored sources to duckdb/duckdb@dfbfdef89aad145dc9d81c275bc2c9fad4062bed (#403).

- Update vendored sources to duckdb/duckdb@c41ae2cb6e2390b9656ac2d22885df0572a87796 (#402).

- Update vendored sources to duckdb/duckdb@d066254185fa56ec851183e9178edb04ae34c0b9 (#401).

- Update vendored sources to duckdb/duckdb@5fd2501220b80adaddf009b78cac44b97813258c (#400).

- Update vendored sources to duckdb/duckdb@6d9d429d5e7f464b69671b46dcbc99a6e46378df (#399).

- Update vendored sources to duckdb/duckdb@d9e89b5cc192ea052f038d8e7b26d253ec81bc49 (#398).

- Update vendored sources to duckdb/duckdb@95038c5eee75f733c99193c66c3faa7289d6f599 (#397).

- Update vendored sources to duckdb/duckdb@8d1c2b29badfcc55246829e00e97b86b38b3606a (#396).

- Update vendored sources to duckdb/duckdb@329bb5393b686421b40261211354f4d77cac1633 (#395).

- Update vendored sources to duckdb/duckdb@403f0fc6459fc5a1f185350d30eafa555c145d1f (#394).

- Update vendored sources to duckdb/duckdb@6a197b22652d02749c3e755e75b10d75e7ad6b75 (#393).

- Show file sizes (#380, #391).

- Fix stripping call (#380, #390).

- Move stripping logic to `install.libs.R` (#380, #389).

- Strip binary if requested (#380, #386).

- Update vendored sources to hannes/duckdb-rfuns@4fccc0b6e577f5b32c84d03cd79cb9fd9827212b (#378).

- Bump.

- Update vendored sources (tag v1.1.0) to duckdb/duckdb@fa5c2fe15f3da5f32397b009196c0895fce60820 (#377).

- Update vendored sources to duckdb/duckdb@fc21edf1508fa785a0ce06ffd245fe30b20eefe0 (#376).

- Update vendored sources to duckdb/duckdb@1d3fc5aec6b846c563d6d99c96df7c30117b5a94 (#375).

- Update vendored sources to duckdb/duckdb@893d007e64df94658d4da92c02698559f89d2072 (#374).

- Update vendored sources to duckdb/duckdb@64bacde85e4c24134cf73f9b4ed3ae362510f287 (#373).

- Update vendored sources to duckdb/duckdb@93494bd74d30f7ae11456dcee6c5e5143be58606 (#372).

- Update vendored sources to duckdb/duckdb@f76d6f2e7e170d6434e2725f43bac5ede31985fa (#371).

- Update vendored sources to duckdb/duckdb@310176118d5dc9897fb752bda145ee9dca628240 (#370).

- Update vendored sources to duckdb/duckdb@c1183d72ed9b388fdc894e86f7e999b2ba8301e5 (#369).

- Update vendored sources to duckdb/duckdb@d454d2458646151fc89c60639f0c50cecf1f4ebd (#367).

- Update vendored sources to duckdb/duckdb@0e6dacd8932c22f9d383b8047fb11aad59564895 (#363).

- Update vendored sources to duckdb/duckdb@4d18b9d05caf88f0420dbdbe03d35a0faabf4aa7 (#362).

- Update vendored sources to duckdb/duckdb@c4940720ce2ee93f39f6d80ceb25a729718a6828 (#361).

- Update vendored sources to duckdb/duckdb@421acb0f7c924216bc689f3731d7a971e7e4fa2b (#360).

- Update vendored sources to duckdb/duckdb@7c988cf7bf417d6534f0ae60f6e0297ef22cd18a (#359).

- Update vendored sources to duckdb/duckdb@dd3cbcee009bf664e3a9bce2467c8af6d2bc53d2 (#358).

- Update vendored sources to duckdb/duckdb@95a9fe9f2681175788ac85dfe67a370ef9b6f32d (#357).

- Update vendored sources to duckdb/duckdb@756d4fcb624c2c180969630b11d44380704a871a (#356).

- Update vendored sources to duckdb/duckdb@450b7e45d9e717d2c475995dabbde47b5acdfc4a (#355).

- Update vendored sources to duckdb/duckdb@dffc4ffad7d9cb7c181db87b1bfb51e261bcedf6 (#354).

- Update vendored sources to duckdb/duckdb@a6e32b115826ba543e32a733cb92f68fd0549186 (#353).

- Update vendored sources to duckdb/duckdb@1f01ef8781c8a3edf192286e0044ff37f043fb47 (#352).

- Update vendored sources to duckdb/duckdb@9aa68025b1ddf0deba9e7caf17cd0dbe4abd7206 (#351).

- Update vendored sources to duckdb/duckdb@7a7547f5da232111d52c4afb05e98e19fd8c7e31 (#350).

- Update vendored sources to duckdb/duckdb@fa2daf7a09e477e30e53b4cc8f4269c39eaf62ef (#349).

- Update vendored sources to duckdb/duckdb@a65fc4ed0847cb073231ba2be21bbd8515b91171 (#348).

- Update vendored sources to duckdb/duckdb@1844ae51091ee85c9194036405abd561ff9b58ae (#347).

- Update vendored sources to duckdb/duckdb@439bb91fc33e8bc45cc6e6d73c823ab44b48876d (#346).

- Update vendored sources to duckdb/duckdb@9067c648ef182084b3159b72213097505d5b5cab (#345).

- Update vendored sources to duckdb/duckdb@a05e81d31b178bd41ff4fb3aa46c30fe2a7068e5 (#344).

- Update vendored sources to duckdb/duckdb@74c9f4df1fe5c3f39007aa38c112cb7582f91302 (#343).

- Update vendored sources to duckdb/duckdb@e90611400749d641a07dbcd5f10df85d99813f33 (#342).

- Update vendored sources to duckdb/duckdb@902af6f21cf5e15979ecab02f15223a0f9a0baff (#341).

- Update vendored sources to duckdb/duckdb@6f9795184545d841a35e75b938f78a1e0520bd8f (#340).

- Update vendored sources to duckdb/duckdb@67b69b0c6e9411a2755baffa2305000dae887937 (#339).

- Update vendored sources to duckdb/duckdb@18e97dd88525d42c5de9faf6d1a89b90590c94fe (#338).

- Update vendored sources to duckdb/duckdb@37a55bdf6665705eb6be311bc61fa8a2f2b900fe (#337).

- Update vendored sources to duckdb/duckdb@0d37df84df6c0226423eda80d2adce9b6fdf1eea (#336).

- Update vendored sources to duckdb/duckdb@2355a5bd10fe6ae24b0b7604a66b78d6c657c104 (#335).

- Update vendored sources to duckdb/duckdb@206320c56140238066fdfca3aa503ec09f7cb2bd (#334).

- Update vendored sources to duckdb/duckdb@40c9c5a5f9b54dcaf75c45ecaa311ec478721559 (#333).

- Update vendored sources to duckdb/duckdb@379a80032a96a454190c4d2f524898ecad8fec89 (#332).

- Update vendored sources to duckdb/duckdb@20100aa2560b68b2f0b46bdc07877a96ed270959 (#331).

- Update vendored sources to duckdb/duckdb@5896c638099998449f06ce1a61e6c01045ba4a7f (#330).

- Update vendored sources to duckdb/duckdb@1a2791b7b415ee41e2285e298ee97f37caf9eeeb (#329).

- Update vendored sources to duckdb/duckdb@01c5bed3c2235171f59527832b1d41fc4a669219 (#328).

- Update vendored sources to duckdb/duckdb@686bcd10b3d617b8a00c41505ab1a97d8c53319f (#327).

- Update vendored sources to duckdb/duckdb@2e78e027dbc812e301088cb72aec80025af0b7a2 (#326).

- Update vendored sources to duckdb/duckdb@4b8274729b3037ce1c3528e90896aa3f6d94559b (#325).

- Update vendored sources to duckdb/duckdb@de5f77c08b5c37afc511e581212639050be2c691 (#324).

- Update vendored sources to duckdb/duckdb@7691b57aa1ef638c4b825c388b1bd2877a4e8ec4 (#323).

- Update vendored sources to duckdb/duckdb@b881dc1265f222e0de23403d8b3c155e8a0c5f17 (#322).

- Update vendored sources to duckdb/duckdb@2be970dda0e5047b1075f938691455d63ba63a67 (#321).

- Update vendored sources to duckdb/duckdb@573bedb4c23ae67248fa7545c5af6f455b9523a8 (#320).

- Update vendored sources to duckdb/duckdb@892f631d24711e3911e8bac2baca66ebf07d9edb (#319).

- Update vendored sources to duckdb/duckdb@ea6f5c4e0903ebfe171969a214c19b77ccb7f7e8 (#318).

- Update vendored sources to duckdb/duckdb@0af71afe6c3e932c1f55b29418c3aef8eebf671f (#317).

- Update vendored sources to duckdb/duckdb@48a8b81d5264adae02777b80b73d69be6ea6aa36 (#316).

- Update vendored sources to duckdb/duckdb@5f4af5343a4f09c3ba184a171bbcf9abd9c8b139 (#315).

- Update vendored sources to duckdb/duckdb@0e6f3fb91a072d370eb81d200cff4ba952bf20f2 (#314).

- Update vendored sources to duckdb/duckdb@5bdb091a5d67460da3ca3a89f21b7cdc588d4544 (#313).

- Update vendored sources to duckdb/duckdb@6e24bb278d11538e46ce69446cd2849d331bc7a4 (#312).

- Update vendored sources to duckdb/duckdb@b1bae91af9cbf8443b69aa851accba42657fb3fb (#311).

- Update vendored sources to duckdb/duckdb@bb5f35c7af618d7636a1f61b26aa6a5c60b0d88a (#310).

- Update vendored sources to duckdb/duckdb@4cabb03b151deb6aec8b14a2496f1b2d9031574a (#309).

- Update vendored sources to duckdb/duckdb@dd2f87c0e2038e3bbfffecd904f407b80f298212 (#308).

- Update vendored sources to duckdb/duckdb@729468452530e898b34a9eec3b48574f8f6fe70e (#307).

- Update vendored sources to duckdb/duckdb@afecd99dbbcf9dec503ffffd2b9fefb8d9d826bd (#306).

- Update vendored sources to duckdb/duckdb@8eff1500c78807d6ff6f4cac99d799da27ff0f2b (#305).

- Update vendored sources to duckdb/duckdb@87ba8503f2a2d53284d0cde88e52df39959eeffa (#304).

- Update vendored sources to duckdb/duckdb@58fe5162afadc1a9b52cc095a86ad1769d3e9384 (#303).

- Update vendored sources to duckdb/duckdb@536fb3b02b0f0e436eb0b1345ae4b155c2993fa4 (#302).

- Update vendored sources to duckdb/duckdb@de92c08cb0585ccb364c3daf0b7e251841dc088b (#301).

- Update vendored sources to duckdb/duckdb@7d2a6d0332ca85730220c926fe8d2330ed2cb6cd (#300).

- Update vendored sources to duckdb/duckdb@13ace3f6ccbd81fa1f66a467583aab10bd888496 (#299).

- Update vendored sources to duckdb/duckdb@69afac464d1f0de4dedab96e26fec05d5b8118c8 (#298).

- Update vendored sources to duckdb/duckdb@e08c0bf105c2ad3d1a6445488182aedf680306e6 (#297).

- Update vendored sources to duckdb/duckdb@567bdebcba6e58da96ceb9465505a38a6c60e69f (#296).

- Update vendored sources to duckdb/duckdb@47715960b6ce0b724d9d061addbc85d0397367bf (#295).

- Update vendored sources to duckdb/duckdb@de13238537197a5e23b3450e8c931844034ca047 (#294).

- Update vendored sources to duckdb/duckdb@c84676023c279bfec3441657d54baaef499276f5 (#293).

- Update vendored sources to duckdb/duckdb@610d79431c7aeccb0d6a4cf9ce2c04a4a96d2f63 (#292).

- Update vendored sources to duckdb/duckdb@dabc6df8f5608453f2da1e23b16d55d6df2aaf52 (#291).

- Update vendored sources to duckdb/duckdb@8226769114e16a3cb42d38bfe58c218a9009b1a3 (#290).

- Update vendored sources to duckdb/duckdb@3897524b31f668ce73fef0b1e63c2a7e6e58cbb1 (#289).

- Update vendored sources to duckdb/duckdb@226c56b7dff9174ce54c83b907d59bca35363040 (#288).

- Update vendored sources to duckdb/duckdb@4d8693be1a39e3cb4c1ce42d6bc64978a5f6e7be (#287).

- Update vendored sources to duckdb/duckdb@35346d87637d8e6731ec1fcd1909c4a309a6d6ad (#286).

- Update vendored sources to duckdb/duckdb@f94b8acedb26d606691c62b3a80ee3ab45eb4ad3 (#285).

- Update vendored sources to duckdb/duckdb@42c504b821beba03867241dde68e9408a9740806 (#284).

- Update vendored sources to duckdb/duckdb@a6b5523b3a55961b282c20fe2704ec955a311069 (#283).

- Remove hotfix.

- Update vendored sources to duckdb/duckdb@56619faf054a284b88317a811d8f0cab0fe0974a (#281).

- Update vendored sources to duckdb/duckdb@8ecc90c8d60ce446f227fad40fe8fbafdaf2b4e1 (#280).

- Update vendored sources to duckdb/duckdb@0d612daeec725915c1b3083a6a8f5e854f424fb2 (#279).

- Update vendored sources to duckdb/duckdb@798f5a2ba0ddf1d849355293cd5d7debb2dc9e9a (#278).

- Update vendored sources to duckdb/duckdb@b32a97a77241fcd3fb29ac6b007035d8d733e8fc (#277).

- Update vendored sources to duckdb/duckdb@f683023d703649b6a813e6f4d5aaf2d329c58a72 (#276).

- Update vendored sources to duckdb/duckdb@7f3889c389b2e6e7111c2963c4cca1685de5e791 (#275).

- Update vendored sources to duckdb/duckdb@5819112b7e6480c377255ccab6f4e1657730b5fe (#274).

- Update vendored sources to duckdb/duckdb@9ed561eee5afc2242f73de5ea9c8cf1422c32a40 (#273).

- Update vendored sources to duckdb/duckdb@f0dbafd48f62dbd6ec1c763dd38bab2a611dac43 (#272).

- Update vendored sources to duckdb/duckdb@18c5431edff65f2260874a0a7290cd10069f9e59 (#271).

- Update vendored sources to duckdb/duckdb@f97ad19a296aa6f37e24a23a7ea2cdb87ebe6813 (#270).

- Update vendored sources to duckdb/duckdb@7abb7065d6a924f87d8cd7e61f3c1a488b825554 (#269).

- Update vendored sources to duckdb/duckdb@6aa0ab01b0e0cd008a2331a7deba1f6c7dc190fa (#268).

- Update vendored sources to duckdb/duckdb@8c1ef04afaad4e9901e714e76a22a4ecd7f96b10 (#267).

- Update vendored sources to duckdb/duckdb@e1c738e7e29e7f105d5c4a67df7a44bc2f3dc909 (#266).

- Update vendored sources to duckdb/duckdb@cdf7125edb568360896cc4ae01f7e52ece68020a (#265).

- Update vendored sources to duckdb/duckdb@16193a714ebac04fa89d0074b1c4d42e62e9fb61 (#264).

- Update vendored sources to duckdb/duckdb@285553fe3e6962bc2be7a69486e7f1bb223f8f1b (#263).

- Update vendored sources to duckdb/duckdb@e5d994bbc6c3e158264af3156f71e7f0340a1d0c (#262).

- Update vendored sources to duckdb/duckdb@627a70286b70dc6b3c35c2f5f4ebea0552f7c6e8 (#261).

- Update vendored sources to duckdb/duckdb@862852fa395b99735e5713cb55d0cea1d9320659 (#260).

- Update vendored sources to duckdb/duckdb@ecb8dc908b1fc97ed6255284701de8c57a9f8c39 (#259).

- Update vendored sources to duckdb/duckdb@b33069bb4ec5ed1e369a260efdb2aab60fa5ec79 (#247).

- Update vendored sources to duckdb/duckdb@9ad037f3adfe372f17b5178a449ac4b6f9142240 (#246).

- Update vendored sources to duckdb/duckdb@1345b3013e801be526e7fac8c8984c89b0033d6a (#245).

- Update vendored sources to duckdb/duckdb@bb97c95a1ad2c277fcf2a60bb1a8af4b0f29b6c7 (#244).

- Update vendored sources to duckdb/duckdb@26685b133edd712ef62e74dbf25ea611e1cf91dc (#243).

- Update vendored sources to duckdb/duckdb@513c2f22c0923045179a8800edf72d212a9bf682 (#242).

- Update vendored sources to duckdb/duckdb@fe535b02b3b8d2b3ac7660134fd588848be9e859 (#241).

- Update vendored sources to duckdb/duckdb@b371fc1b9a8960af25205a85ea89b381e1f98705 (#240).

- Update vendored sources to duckdb/duckdb@c4b6b8f3543bf440d4149a824eed118e4e54c4be (#239).

- Update vendored sources to duckdb/duckdb@10ea4832d3f1850685a65369e0b19c27ec81e638 (#238).

- Update vendored sources to duckdb/duckdb@f6a8ec460ae23e20e6f52859c32c96012dcc0b13 (#236).

- Update vendored sources to duckdb/duckdb@8d4a30cf72c2695c15bed2ec69b5a5bc56a5a594 (#235).

- Update vendored sources to duckdb/duckdb@367aa8db1cc622c46661d762f9cafdd88263040e (#234).

- Update vendored sources to duckdb/duckdb@3d85a139fe1f4c78284a0e8cde522a38f2bcde0a (#233).

- Update vendored sources to duckdb/duckdb@a4f0adb1cf051f6ec4d58326ccf4fc3d3f333d35 (#232).

- Update vendored sources to duckdb/duckdb@ad4639ed1a3448e0c7383d8601d3b797a1861c86 (#231).

- Update vendored sources to duckdb/duckdb@b8df1598853d55f4421bb72dd3d86db553e897b4 (#230).

- Update vendored sources to duckdb/duckdb@f5048f0ffd25b9d1d67b1a68f75ac435c9f5cbfa (#229).

- Update vendored sources to duckdb/duckdb@ac8efca3fc3bc1fa277a0ca32104e2e861b6eef5 (#228).

- Update vendored sources to duckdb/duckdb@c2e18955aff66454aa3ab5b39abd6f3c90f8010b (#227).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#226).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#220).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#219).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#218).

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10430870381

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425609276

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425483466

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10223714659

- Remove temporary patch.

- Enable creation of compilation database.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9879707346

- Adapt glue code.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9727972793

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9692337257

- Fix rfuns vendoring.

- Add another brotli patch.

- Brotli patch and compilation flags.

## Continuous integration

- Use larger retry count for lock-threads workflow (#631).

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

- Add fledge workflow.

- Use stable pak (#591).

- Latest changes (#584).

- Tweak patch call.

- Can't check incoming.

- Update actions to avoid warnings (#524).

- Use pkgdown branch (#523).

- Bring back stepwise vendoring.

- Don't remove dir.

- Add env.

- Vendor without creating PR.

- Set up R for r-hub.

- Force vendoring when tag.

- Fix passing branch names as reef.

- Pass inputs.ref to create-pull-request.

- Fix PR generation for snapshot tests for vendoring.

- Flip order.

- Use inputs.

- Use head ref for status reports.

- Check job.status.

- Tweak.

- Fix final status reporting.

- Fix status.

- Bump version of action.

- Post status for workflow_dispatch.

- Only smoke test for workflow_dispatch.

- Move condition to check if status event is triggered.

- Install package manually, faster.

- Verbosity.

- Improve support for protected branches, without fledge (#248).

- Fix vendoring (#225).

- Fix vendoring workflow (#217).

- Wait for pkgdown (#215).

- Fix builds (#213).

- Sync with latest developments.

- Use v2 instead of master.

- Inline action.

- Use dev roxygen2 and decor.

- Fix on Windows, tweak lock workflow.

- Avoid checking bashisms on Windows.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.

- Prepare for dynamic check matrix.

## Documentation

- Upgrade roxygen2.

- Fix typo.

## Testing

- Sync tests with duckplyr (#596).

- Skip if not installed.

- Skip if not installed.

- Add tests for comparison expression (@toppyy, #462).

- Update snapshot.

## Breaking changes

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## fledge

- Bump version to 1.1.3.9003 (#604).

- Bump version to 1.1.3.9002 (#602).

- Bump version to 1.1.3.9001 (#599).

## Uncategorized

- Merge branch 'cran-1.1.2'.

- Merge pull request #516 from duckdb/f-tweak.

  Fix signedness

- Merge pull request #461 from duckdb/f-exp-depth-2.

  Sync tests

- Merge pull request #392 from duckdb/cran-1.1.0.

  Bump

- Merge pull request #388 from duckdb/f-380-ppm-strip.

  Merge pull request #386 from duckdb/f-380-ppm-strip

- Merge pull request #214 from duckdb/b-ci.

  Only report success once

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13415 (#13415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13431 (#13431).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13439 (#13439).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13202 (#13202).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13268 (#13268).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13434 (#13434).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13433 (#13433).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13421 (#13421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13417 (#13417).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13411 (#13411).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13410 (#13410).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13408 (#13408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13409 (#13409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13358 (#13358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13402 (#13402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13383 (#13383).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13394 (#13394).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13401 (#13401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13370 (#13370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13399 (#13399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13329 (#13329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13344 (#13344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13354 (#13354).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13372 (#13372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13168 (#13168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13359 (#13359).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13356 (#13356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13335 (#13335).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13267 (#13267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13201 (#13201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13360 (#13360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13355 (#13355).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13346 (#13346).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13350 (#13350).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13341 (#13341).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13343 (#13343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13342 (#13342).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13317 (#13317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12886 (#12886).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13313 (#13313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13330 (#13330).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13234 (#13234).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13307 (#13307).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13167 (#13167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12682 (#12682).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13291 (#13291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13290 (#13290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13262 (#13262).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13278 (#13278).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13231 (#13231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13284 (#13284).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13281 (#13281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13283 (#13283).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13280 (#13280).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13282 (#13282).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13275 (#13275).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13260 (#13260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13261 (#13261).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13258 (#13258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13249 (#13249).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13229 (#13229).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13256 (#13256).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13162 (#13162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13230 (#13230).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13233 (#13233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13236 (#13236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13242 (#13242).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13241 (#13241).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13240 (#13240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13223 (#13223).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13207 (#13207).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13170 (#13170).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13203 (#13203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13109 (#13109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13194 (#13194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13191 (#13191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13189 (#13189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13188 (#13188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13186 (#13186).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13063 (#13063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13163 (#13163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13150 (#13150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13182 (#13182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13160 (#13160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13180 (#13180).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13161 (#13161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13151 (#13151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13146 (#13146).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13140 (#13140).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13136 (#13136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13087 (#13087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13101 (#13101).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13108 (#13108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13142 (#13142).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12978 (#12978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13130 (#13130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13123 (#13123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13137 (#13137).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13139 (#13139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13117 (#13117).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13133 (#13133).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13129 (#13129).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13131 (#13131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13127 (#13127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13125 (#13125).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13122 (#13122).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13126 (#13126).

- Merge tag 'v1.0.0-2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13114 (#13114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13093 (#13093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13110 (#13110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13118 (#13118).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13111 (#13111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13106 (#13106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12967 (#12967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13090 (#13090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13098 (#13098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13105 (#13105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13094 (#13094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13084 (#13084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13083 (#13083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13082 (#13082).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13081 (#13081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13089 (#13089).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13086 (#13086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13062 (#13062).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13073 (#13073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13076 (#13076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13074 (#13074).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13015 (#13015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13065 (#13065).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13068 (#13068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13027 (#13027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12579 (#12579).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12998 (#12998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13040 (#13040).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12920 (#12920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13054 (#13054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13056 (#13056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13057 (#13057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13052 (#13052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12995 (#12995).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13050 (#13050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13033 (#13033).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13039 (#13039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13035 (#13035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13030 (#13030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13028 (#13028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13025 (#13025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13023 (#13023).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13024 (#13024).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12953 (#12953).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13002 (#13002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12627 (#12627).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13020 (#13020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13019 (#13019).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13014 (#13014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13010 (#13010).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13013 (#13013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12728 (#12728).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13004 (#13004).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12993 (#12993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12994 (#12994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12931 (#12931).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13003 (#13003).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13001 (#13001).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12785 (#12785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13000 (#13000).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11720 (#11720).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12971 (#12971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12928 (#12928).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12829 (#12829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12929 (#12929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12979 (#12979).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12982 (#12982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12984 (#12984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12980 (#12980).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12942 (#12942).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12973 (#12973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12974 (#12974).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12972 (#12972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12965 (#12965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12968 (#12968).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12970 (#12970).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12966 (#12966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12954 (#12954).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12755 (#12755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12716 (#12716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12912 (#12912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12957 (#12957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12290 (#12290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12955 (#12955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12916 (#12916).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12948 (#12948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12824 (#12824).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12625 (#12625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12787 (#12787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12907 (#12907).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12885 (#12885).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12943 (#12943).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12938 (#12938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12937 (#12937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12932 (#12932).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12890 (#12890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12924 (#12924).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12866 (#12866).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12889 (#12889).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12918 (#12918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12908 (#12908).

- Merge branch 'cran-1.0.0-1'.

- Merge tag 'v1.0.0-1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12913 (#12913).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12914 (#12914).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12851 (#12851).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12887 (#12887).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12858 (#12858).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12888 (#12888).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12884 (#12884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12751 (#12751).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12848 (#12848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12498 (#12498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12398 (#12398).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12878 (#12878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12859 (#12859).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12834 (#12834).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12844 (#12844).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12849 (#12849).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12847 (#12847).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11191 (#11191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12840 (#12840).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12698 (#12698).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12806 (#12806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12734 (#12734).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12835 (#12835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12812 (#12812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12832 (#12832).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12691 (#12691).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12810 (#12810).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12780 (#12780).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12575 (#12575).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12803 (#12803).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12791 (#12791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12754 (#12754).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12765 (#12765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12685 (#12685).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12770 (#12770).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12768 (#12768).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12769 (#12769).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12762 (#12762).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12759 (#12759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12753 (#12753).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12636 (#12636).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12496 (#12496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12745 (#12745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12740 (#12740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12738 (#12738).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12737 (#12737).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12736 (#12736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12731 (#12731).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12730 (#12730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12599 (#12599).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12678 (#12678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12725 (#12725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12724 (#12724).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12708 (#12708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12697 (#12697).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12705 (#12705).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12717 (#12717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12681 (#12681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12692 (#12692).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12694 (#12694).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12689 (#12689).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12690 (#12690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12671 (#12671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12679 (#12679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12288 (#12288).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12655 (#12655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12669 (#12669).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12653 (#12653).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12663 (#12663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12658 (#12658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12654 (#12654).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12637 (#12637).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12650 (#12650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12642 (#12642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12652 (#12652).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12639 (#12639).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12635 (#12635).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12629 (#12629).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12630 (#12630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12633 (#12633).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12603 (#12603).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12608 (#12608).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12554 (#12554).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12539 (#12539).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12516 (#12516).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12515 (#12515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12445 (#12445).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12456 (#12456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12467 (#12467).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12465 (#12465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12470 (#12470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12461 (#12461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12448 (#12448).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12436 (#12436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12421 (#12421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12424 (#12424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12401 (#12401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12409 (#12409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12370 (#12370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12405 (#12405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12393 (#12393).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12391 (#12391).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12352 (#12352).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12360 (#12360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12344 (#12344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12332 (#12332).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12305 (#12305).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12302 (#12302).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12282 (#12282).


# duckdb 1.1.3.9015

## Bug fixes

- Avoid compiler warning related to `Rboolean` (#594).

- Check `"duckdb.materialize_message"` symbol (#592).

- `%in%` works correctly as part of a `&` conjunction (#528).

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- Use portable format modifiers.

- Correctly compute vector length for data frames passed to relational functions (#379).

- Set `initialize_in_main_thread`, add patch.

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (@romainfrancois, #186).

- Xz-compress duckdb sources in the tarball (#530).

- Add `col.types` argument to `duckdb_read_csv()` (@eli-daniels, #383, #445).

- `last_rel` (#529).

- `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- Rethrow errors with rlang if installed (#522).

- Catch and add query context for statement extraction (tidyverse/duckplyr#219, #521).

- Implement query cancellation (#514, #515).

- Add comparison expression to relational api (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

- Bump vendored cpp11 to v0.5.0 (#382, #387).

- Tweak implementation of `r_base::sum()` (#381, #385).

- `n_distinct()` supports `na.rm = TRUE` with a single vector argument again (@lschneiderbauer, #204, #216).

- New `rel_from_sql()` (#212).

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Bump for pre-release.

- Keep `cleanup` files to accommodate different build scenarios (#536).

- Update vendored sources to duckdb/duckdb@19864453f7d0ed095256d848b46e7b8630989bac (#580).

- Update vendored sources to duckdb/duckdb@c3ca3607c221d315f38227b8bf58e68746c59083 (#579).

- Update vendored sources to duckdb/duckdb@9cba6a2a03e3fbca4364cab89d81a19ab50511b8 (#578).

- Update vendored sources to duckdb/duckdb@c6c08d4c1b363231b3b9689367735c7264cacefb (#577).

- Update vendored sources to duckdb/duckdb@7f34190f3f94fc1b1575af829a9a0ccead87dc99 (#576).

- Update vendored sources to duckdb/duckdb@78b65d4a9aa80c4be4efcdd29fadd6f0c893f1ce (#575).

- Update vendored sources to duckdb/duckdb@c31c46a875979ce3343edeedcb497485ca2fd751 (duckdb/duckdb#14542, #574).

- Update vendored sources to duckdb/duckdb@4ba2e66277a7576f58318c1aac112faa67c47b11 (#573).

- Update vendored sources to duckdb/duckdb@247fcb31733a5297c1070fbd244f2349091253aa (duckdb/duckdb#14601, #572).

- Update vendored sources to duckdb/duckdb@1a519fce83b3d262247325dbf8014067686a2c94 (duckdb/duckdb#14600, #571).

- Update vendored sources to duckdb/duckdb@b653a8c2b760425a83302e894bf930f18a1bdf64 (#570).

- Update vendored sources to duckdb/duckdb@79bf967e1b6ab438e0a83a014e937af571ed7acb (#569).

- Update vendored sources to duckdb/duckdb@4b62ee43a7d5f62313d77d36dec8aea29412431f (#568).

- Update vendored sources to duckdb/duckdb@3293c92b6e657084318f7556b14077896b333109 (#567).

- Update vendored sources to duckdb/duckdb@8664b710beb205ec6fc7e9f3d18dfe24dd28625f (#566).

- Update vendored sources to duckdb/duckdb@92a1ccbcef04dda11c85fa2bf6daf27daf8d9c49 (#565).

- Update vendored sources to duckdb/duckdb@2635a87a566b90e086caa84805019f66eedf0859 (#564).

- Update vendored sources to duckdb/duckdb@0d5ec0057838081251b388726353f09cba9577ad (#563).

- Update vendored sources to duckdb/duckdb@6af32330b51af4d72d3fed665bfc03f78c8b3876 (#562).

- Update vendored sources to duckdb/duckdb@662b0b34eaaf7f52545638cbc87c10e32b33834d (#561).

- Update vendored sources to duckdb/duckdb@bccd37ae7ea09f77b6299165bf80bca3bc1efc7c (#560).

- Update vendored sources to duckdb/duckdb@5090b7396173069bb0d51b0e1341cfa9950c154f (#559).

- Update vendored sources to duckdb/duckdb@f5ebc9b8e1d6c040a2276e0ac4a41d6bf9475880 (duckdb/duckdb#14545, #558).

- Update vendored sources to duckdb/duckdb@b8c5248b9c18f7cafbdf7992421662adbd95bf38 (#557).

- Update vendored sources to duckdb/duckdb@dfdd7968262d912910d8249bde3524e068c67713 (#556).

- Update vendored sources to duckdb/duckdb@d0673165b52e89fe70d1891504e4dea82adeca85 (#555).

- Update vendored sources to duckdb/duckdb@d79e66bd032dbd2066c16a88f517f6da1cd0aa78 (#554).

- Update vendored sources to duckdb/duckdb@0359726be957673a62ab1ab61f1cca9ba5667386 (#553).

- Update vendored sources to duckdb/duckdb@10c42435f1805ee4415faa5d6da4943e8c98fa55 (#552).

- Update vendored sources to duckdb/duckdb@43d26298affa89bc6ca829a1defc4819b42b6fb4 (#551).

- Update vendored sources to duckdb/duckdb@52b43b166091c82b3f04bf8af15f0ace18207a64 (#550).

- Update vendored sources to duckdb/duckdb@0446ab42e96b6269e78f55293f4096fa10224837 (#549).

- Update vendored sources to duckdb/duckdb@ceb77af7935c3c7a4a34e1199abd4d6ea080448c (duckdb/duckdb#14430, #548).

- Update vendored sources to duckdb/duckdb@aed52f5cabe34075c53bcec4407e297124c8d336 (#547).

- Update vendored sources to duckdb/duckdb@e41a881658ae579cedebe19c5070dad660086aea (#546).

- Update vendored sources to duckdb/duckdb@98d4ad28be35cf5c37e18760e76d11bc07be1ab4 (#545).

- Update vendored sources to duckdb/duckdb@1bb332c9c59a9d15b196b4486a6d1ffcaa833ba5 (#544).

- Update vendored sources to duckdb/duckdb@0bbfe09937e3744325f3b2dfdb182e9ac1ff916f (#543).

- Update vendored sources to duckdb/duckdb@08969b4677534b6870bff4c99998c753a6e784fc (#542).

- Update vendored sources to duckdb/duckdb@4756244efa04d204be6f20d55036fc503b7ed49c (#541).

- Update vendored sources to duckdb/duckdb@217ec4722e949eaa49568bd707e49431ef727ab5 (#539).

- Move responsibility for removing CR (#533).

- Terminate all sources with newline (#531).

- Sync duckplyr tests (#527).

- Cleanup, preparation (#525).

- Bump version.

- Update vendored sources (tag v1.1.2) to duckdb/duckdb@f680b7d08f56183391b581077d4baf589e1cc8bd (#510).

- Update vendored sources to duckdb/duckdb@5f49126b92a0899a2049aaa57da886138c5f879d (#509).

- Update vendored sources to duckdb/duckdb@2c21eb1c2eec3a1e359d87fb2a2cd8e427dc03c1 (#508).

- Update vendored sources to duckdb/duckdb@cc067e6b7db33f516437567cbc726536e34ed716 (#507).

- Update vendored sources to duckdb/duckdb@d2dfc6090685470cb09326a7530066fc4b3db42a (#506).

- Update vendored sources to duckdb/duckdb@56e2e0e5721b8547f564fccf252db0ba93c85471 (#505).

- Update vendored sources to duckdb/duckdb@35dfcc06e6c76ad6bd8e4acdae1bcc30751777eb (#504).

- Update vendored sources to duckdb/duckdb@92e0964376a78f990408a0e81af155504b35d27c (#503).

- Update vendored sources to duckdb/duckdb@01e6e98e3875ed12cbcb9257f81844743b1665fa (#502).

- Update vendored sources to duckdb/duckdb@6dc2e9375870e60f82becb1cece4cc878289d3b8 (#501).

- Update vendored sources to duckdb/duckdb@52b19d5ece35be344830800db0e4961f47114aa9 (#500).

- Update vendored sources to duckdb/duckdb@0d3e84330e845ceefdc55a36d52ef0296af5d1e1 (#499).

- Update vendored sources to duckdb/duckdb@d0cf23ead54f191bf2518598edf04e209f07452e (#498).

- Update vendored sources to duckdb/duckdb@d57a94430e50263cbd1b719b984da189e5bba0c5 (#497).

- Update vendored sources to duckdb/duckdb@a5ddffef692c0627dd6c7efaed7cf65148321452 (#496).

- Update vendored sources to duckdb/duckdb@536f979f69b1bbe40d582450b6cfa6a68463f172 (#495).

- Update vendored sources to duckdb/duckdb@443380a11dbb31a1c218a759ec0c3b56880f1c38 (duckdb/duckdb#14249, #494).

- Update vendored sources to duckdb/duckdb@7919e4abc5597dc4fbeb5a19dff19ff69b5c4113 (duckdb/duckdb#14249, #493).

- Update vendored sources to duckdb/duckdb@52f967a42861032fd5f4392609afc195cd025dde (#492).

- Update vendored sources to duckdb/duckdb@1f20676c7d997fe4964a8b51378bf984e53a4b4c (#491).

- Update vendored sources to duckdb/duckdb@8cec9b1537f900e7a644e7b466ea899cf1ca8f8f (#490).

- Update vendored sources to duckdb/duckdb@4f0cd4d60035e8c6afafed47b68b2240b39e3566 (duckdb/duckdb#14212, #489).

- Update vendored sources to duckdb/duckdb@5a9a382a573b107a38f5ee277619b362d5079c32 (#488).

- Update vendored sources to duckdb/duckdb@123b82b9053c4843559035b6723c867b2618b2d9 (#487).

- Update vendored sources to duckdb/duckdb@405e15fcde8a4da4a7c6d3889f992f0a363c05f2 (duckdb/duckdb#14232, #486).

- Update vendored sources to duckdb/duckdb@0e398d95c50ae40730467c53922c8fb8d5c69f90 (#485).

- Update vendored sources to duckdb/duckdb@1eac05ecd3a6b8ec2cdf0c53ccece7ca2effef26 (#484).

- Update vendored sources to duckdb/duckdb@048f5ffcec9c1a4b73cbfbd4158cd5b6669f102b (#483).

- Update vendored sources to duckdb/duckdb@0b2d95601c2d9474f2c823ac3363e9ca14224c7c (#482).

- Update vendored sources to duckdb/duckdb@350d061846ed7e4c96d2efa7b523bb97ae84538a (#481).

- Update vendored sources to duckdb/duckdb@2f6b78c21d1634c7228e00c809a790701705c82b (#480).

- Update vendored sources to duckdb/duckdb@8aca4330ac46be3950c6b12e29040322dd245b7a (#479).

- Update vendored sources to duckdb/duckdb@9931d723ccde2b2435b1a927234338e6f0353d90 (#478).

- Update vendored sources to duckdb/duckdb@d896e73fe2db62b6749b95e30faa8bfa41dc4d32 (#477).

- Update vendored sources to duckdb/duckdb@f8c82ab2620f8066b0141df0c3982885a5258746 (#476).

- Update vendored sources to duckdb/duckdb@ee256eb45552601db71d4cad7a5cd4f46f0d5a1d (#475).

- Update vendored sources to duckdb/duckdb@130aab3f9ddb84e0c6e7f543a99881d8fc1bd6b7 (#474).

- Update vendored sources to duckdb/duckdb@92c65a4341c57f313dbeba5acc7b1fb917808010 (#473).

- Update vendored sources to duckdb/duckdb@47e1d3d60b4d6d075cf88c2707572df12a630a3a (#472).

- Update vendored sources to duckdb/duckdb@45559f5eeb1834454a30490fc4ffad1807e13f3b (#471).

- Update vendored sources to duckdb/duckdb@dfdd09f46c0169c9d8aa5381086e46a66e44fabc (#470).

- Update vendored sources to duckdb/duckdb@89828abb72219957372f316da06f007dadd2a9aa (#469).

- Update vendored sources to duckdb/duckdb@12e9777cf6283f44710b2610ba3d3735a1208751 (duckdb/duckdb#14077, #468).

- Update vendored sources to duckdb/duckdb@4a55e2334232afe94e47ab398ddb44f88fcd6658 (#467).

- Update vendored sources to duckdb/duckdb@0f3c46215feb0fb92d4998977fc31b2f52db6b14 (#466).

- Update vendored sources to duckdb/duckdb@c87246586490b442706d0be66b82d71930a00578 (#465).

- Update vendored sources to duckdb/duckdb@cd8cb3f1c81a74a3b2c1ed7d94e3913485895074 (#464).

- Update vendored sources to duckdb/duckdb@acd16816e31789bdb27e144ccd19ddb9da4fe6df (#463).

- Update vendored sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove uninitialized warnings.

- Document (#456).

- Update vendored sources (tag v1.1.1) to duckdb/duckdb@af39bd0dcf66876e09ac2a7c3baa28fe1b301151 (#454).

- Update vendored sources to duckdb/duckdb@0fe7708eef6b9b77270ca21cb9b5e30a3de84e3c (#453).

- Update vendored sources to duckdb/duckdb@34a3acc6b3354be86fe593d09e0702ab5eafe757 (#452).

- Update vendored sources to duckdb/duckdb@cb2a947e9df4f6c40b6dd5751c412d6946cbb62b (#451).

- Update vendored sources to duckdb/duckdb@64520f224d8a0a096cfe10f0c2cfbd1ac9457811 (duckdb/duckdb#13934, #450).

- Update vendored sources to duckdb/duckdb@b0eee44df70eb7bf9efac5f65dd2eaf7ad1e5403 (#449).

- Update vendored sources to duckdb/duckdb@4fe3dc559d10648691f9ab34f20207771890dd45 (#448).

- Update vendored sources to duckdb/duckdb@6c02032393583f353f2f2a0337a8e16f34dc5d82 (duckdb/duckdb#14026, #447).

- Update vendored sources to duckdb/duckdb@4ce455c84029195ffa4c3e540c10360ae8c73724 (#446).

- Update vendored sources to duckdb/duckdb@03dd0df6185d903ecbff9d80017e5449e78e5017 (#443).

- Update vendored sources to duckdb/duckdb@d1037da3139de90dc0a82df746d8ce92a50d9838 (#442).

- Update vendored sources to duckdb/duckdb@cb27c0423fa7107674c267b5de8eb93dd603cb69 (duckdb/duckdb#13993, #441).

- Update vendored sources to duckdb/duckdb@b787fcc1cb9bc4daf36e6eec19c1e9b2b162f4b0 (duckdb/duckdb#14020, #440).

- Update vendored sources to duckdb/duckdb@0ce863113043806780e776bcfb86b24afcb0263c (#439).

- Update vendored sources to duckdb/duckdb@f9e96b191088e65b4a1f95918312c40e31096dd9 (#438).

- Update vendored sources to duckdb/duckdb@2ff9c687e2c448914a28c59bd50f48f54e47de3c (#437).

- Update vendored sources to duckdb/duckdb@dcc302aef4491db8cc2efd2955ac254a4d62dcbc (#436).

- Update vendored sources to duckdb/duckdb@03976af191370d4020c172a82b28ca7885d98ea3 (#435).

- Update vendored sources to duckdb/duckdb@29c46243993319b0db24509c862126b8e17f1e8c (#434).

- Update vendored sources to duckdb/duckdb@e7da966e87539457f3de94a1bee288861fdca6d6 (#433).

- Update vendored sources to duckdb/duckdb@44bba02cea5d316e38f6edbad7fad3a1f913d63f (#432).

- Update vendored sources to duckdb/duckdb@04a1f750a6fab3f1a9cf3fb7cce5fd119c522304 (#431).

- Update vendored sources to duckdb/duckdb@0da70d9de97ff2cf39ad99b9e30b7e6cb91614b8 (duckdb/duckdb#13933, #430).

- Update vendored sources to duckdb/duckdb@df82a0e2c47e8b3ddd5a93e08530b83bc49e0da0 (#429).

- Update vendored sources to duckdb/duckdb@86723c9912fde7b76d3863b2ccd2d4333251c4af (#428).

- Update vendored sources to duckdb/duckdb@66d8ed93f67a00006ec99226c1205bcffb1ef07b (duckdb/duckdb#13941, #427).

- Update vendored sources to duckdb/duckdb@b2f68017070c1910dd3438f9428c7162cb428f84 (#426).

- Update vendored sources to duckdb/duckdb@35a104529b56c4f4f1e383e2ead26d6047d3442e (#425).

- Update vendored sources to duckdb/duckdb@b8c5fa937919631b759a70e33f068aa05de8bd36 (#424).

- Update vendored sources to duckdb/duckdb@18670a10f1b3da56382e272518d6b149e489ca51 (#423).

- Update vendored sources to duckdb/duckdb@0b0c95b9dc685e1a6ca011d8e086d885afbe0398 (#422).

- Update vendored sources to duckdb/duckdb@e5e1595da75ea01559f2b4bc9531505422b7fcdc (duckdb/duckdb#13585, #421).

- Update vendored sources to duckdb/duckdb@75d4bd0cc759dcb609ab349b87bff07dddf2ebb7 (#420).

- Update vendored sources to duckdb/duckdb@c0f29465624aaa1472ee05d4723415cfa1bfbdf9 (#419).

- Update vendored sources to duckdb/duckdb@b369bcb4e08235e52866a5f8afb7e172fe573287 (#418).

- Update vendored sources to duckdb/duckdb@414207f2120ad9019b416cf891947004c74c7347 (#417).

- Update vendored sources to duckdb/duckdb@38ceb86f1aa4cfae7c993f59de19e0cfee7ff68e (#416).

- Update vendored sources to duckdb/duckdb@0dbb79e8de897b4a710ed53becc063bcdf80884d (duckdb/duckdb#13824, #415).

- Update vendored sources to duckdb/duckdb@9af117f0e6d3f2f9ade385dadc46807c1b388dd4 (#414).

- Update vendored sources to duckdb/duckdb@88a4c1e5893f316d763343d7f66f57917b065f50 (#413).

- Update vendored sources to duckdb/duckdb@d93225aab5c8e0da34776398358373f4c0232864 (duckdb/duckdb#13872, #412).

- Update vendored sources to duckdb/duckdb@8c2ee1eb7987a981cdf4bb1ed52683784a26e3bf (duckdb/duckdb#13880, #411).

- Update vendored sources to duckdb/duckdb@081a748340c4fcd3b3652230a02432afae72bbb3 (#410).

- Update vendored sources to duckdb/duckdb@bc7683e100867fae06c1f65e055df403c2ee25cf (#409).

- Update vendored sources to duckdb/duckdb@b87545985fc03e43baf84d9554eab23ea4b21f6c (#408).

- Update vendored sources to duckdb/duckdb@1d7e05c9737821fdb2c8eba996642c9953de52f6 (#407).

- Update vendored sources to duckdb/duckdb@b383f3668095fac2574bc6a0c417047a6fe80c9f (#406).

- Update vendored sources to duckdb/duckdb@039a262ae9805f30690ae1c8ec6a7fb27812c1b5 (#405).

- Update vendored sources to duckdb/duckdb@d697acfb108f6ec1b1ed26f0062445e1d49ee1c4 (#404).

- Update vendored sources to duckdb/duckdb@dfbfdef89aad145dc9d81c275bc2c9fad4062bed (#403).

- Update vendored sources to duckdb/duckdb@c41ae2cb6e2390b9656ac2d22885df0572a87796 (#402).

- Update vendored sources to duckdb/duckdb@d066254185fa56ec851183e9178edb04ae34c0b9 (#401).

- Update vendored sources to duckdb/duckdb@5fd2501220b80adaddf009b78cac44b97813258c (#400).

- Update vendored sources to duckdb/duckdb@6d9d429d5e7f464b69671b46dcbc99a6e46378df (#399).

- Update vendored sources to duckdb/duckdb@d9e89b5cc192ea052f038d8e7b26d253ec81bc49 (#398).

- Update vendored sources to duckdb/duckdb@95038c5eee75f733c99193c66c3faa7289d6f599 (#397).

- Update vendored sources to duckdb/duckdb@8d1c2b29badfcc55246829e00e97b86b38b3606a (#396).

- Update vendored sources to duckdb/duckdb@329bb5393b686421b40261211354f4d77cac1633 (#395).

- Update vendored sources to duckdb/duckdb@403f0fc6459fc5a1f185350d30eafa555c145d1f (#394).

- Update vendored sources to duckdb/duckdb@6a197b22652d02749c3e755e75b10d75e7ad6b75 (#393).

- Show file sizes (#380, #391).

- Fix stripping call (#380, #390).

- Move stripping logic to `install.libs.R` (#380, #389).

- Strip binary if requested (#380, #386).

- Update vendored sources to hannes/duckdb-rfuns@4fccc0b6e577f5b32c84d03cd79cb9fd9827212b (#378).

- Bump.

- Update vendored sources (tag v1.1.0) to duckdb/duckdb@fa5c2fe15f3da5f32397b009196c0895fce60820 (#377).

- Update vendored sources to duckdb/duckdb@fc21edf1508fa785a0ce06ffd245fe30b20eefe0 (#376).

- Update vendored sources to duckdb/duckdb@1d3fc5aec6b846c563d6d99c96df7c30117b5a94 (#375).

- Update vendored sources to duckdb/duckdb@893d007e64df94658d4da92c02698559f89d2072 (#374).

- Update vendored sources to duckdb/duckdb@64bacde85e4c24134cf73f9b4ed3ae362510f287 (#373).

- Update vendored sources to duckdb/duckdb@93494bd74d30f7ae11456dcee6c5e5143be58606 (#372).

- Update vendored sources to duckdb/duckdb@f76d6f2e7e170d6434e2725f43bac5ede31985fa (#371).

- Update vendored sources to duckdb/duckdb@310176118d5dc9897fb752bda145ee9dca628240 (#370).

- Update vendored sources to duckdb/duckdb@c1183d72ed9b388fdc894e86f7e999b2ba8301e5 (#369).

- Update vendored sources to duckdb/duckdb@d454d2458646151fc89c60639f0c50cecf1f4ebd (#367).

- Update vendored sources to duckdb/duckdb@0e6dacd8932c22f9d383b8047fb11aad59564895 (#363).

- Update vendored sources to duckdb/duckdb@4d18b9d05caf88f0420dbdbe03d35a0faabf4aa7 (#362).

- Update vendored sources to duckdb/duckdb@c4940720ce2ee93f39f6d80ceb25a729718a6828 (#361).

- Update vendored sources to duckdb/duckdb@421acb0f7c924216bc689f3731d7a971e7e4fa2b (#360).

- Update vendored sources to duckdb/duckdb@7c988cf7bf417d6534f0ae60f6e0297ef22cd18a (#359).

- Update vendored sources to duckdb/duckdb@dd3cbcee009bf664e3a9bce2467c8af6d2bc53d2 (#358).

- Update vendored sources to duckdb/duckdb@95a9fe9f2681175788ac85dfe67a370ef9b6f32d (#357).

- Update vendored sources to duckdb/duckdb@756d4fcb624c2c180969630b11d44380704a871a (#356).

- Update vendored sources to duckdb/duckdb@450b7e45d9e717d2c475995dabbde47b5acdfc4a (#355).

- Update vendored sources to duckdb/duckdb@dffc4ffad7d9cb7c181db87b1bfb51e261bcedf6 (#354).

- Update vendored sources to duckdb/duckdb@a6e32b115826ba543e32a733cb92f68fd0549186 (#353).

- Update vendored sources to duckdb/duckdb@1f01ef8781c8a3edf192286e0044ff37f043fb47 (#352).

- Update vendored sources to duckdb/duckdb@9aa68025b1ddf0deba9e7caf17cd0dbe4abd7206 (#351).

- Update vendored sources to duckdb/duckdb@7a7547f5da232111d52c4afb05e98e19fd8c7e31 (#350).

- Update vendored sources to duckdb/duckdb@fa2daf7a09e477e30e53b4cc8f4269c39eaf62ef (#349).

- Update vendored sources to duckdb/duckdb@a65fc4ed0847cb073231ba2be21bbd8515b91171 (#348).

- Update vendored sources to duckdb/duckdb@1844ae51091ee85c9194036405abd561ff9b58ae (#347).

- Update vendored sources to duckdb/duckdb@439bb91fc33e8bc45cc6e6d73c823ab44b48876d (#346).

- Update vendored sources to duckdb/duckdb@9067c648ef182084b3159b72213097505d5b5cab (#345).

- Update vendored sources to duckdb/duckdb@a05e81d31b178bd41ff4fb3aa46c30fe2a7068e5 (#344).

- Update vendored sources to duckdb/duckdb@74c9f4df1fe5c3f39007aa38c112cb7582f91302 (#343).

- Update vendored sources to duckdb/duckdb@e90611400749d641a07dbcd5f10df85d99813f33 (#342).

- Update vendored sources to duckdb/duckdb@902af6f21cf5e15979ecab02f15223a0f9a0baff (#341).

- Update vendored sources to duckdb/duckdb@6f9795184545d841a35e75b938f78a1e0520bd8f (#340).

- Update vendored sources to duckdb/duckdb@67b69b0c6e9411a2755baffa2305000dae887937 (#339).

- Update vendored sources to duckdb/duckdb@18e97dd88525d42c5de9faf6d1a89b90590c94fe (#338).

- Update vendored sources to duckdb/duckdb@37a55bdf6665705eb6be311bc61fa8a2f2b900fe (#337).

- Update vendored sources to duckdb/duckdb@0d37df84df6c0226423eda80d2adce9b6fdf1eea (#336).

- Update vendored sources to duckdb/duckdb@2355a5bd10fe6ae24b0b7604a66b78d6c657c104 (#335).

- Update vendored sources to duckdb/duckdb@206320c56140238066fdfca3aa503ec09f7cb2bd (#334).

- Update vendored sources to duckdb/duckdb@40c9c5a5f9b54dcaf75c45ecaa311ec478721559 (#333).

- Update vendored sources to duckdb/duckdb@379a80032a96a454190c4d2f524898ecad8fec89 (#332).

- Update vendored sources to duckdb/duckdb@20100aa2560b68b2f0b46bdc07877a96ed270959 (#331).

- Update vendored sources to duckdb/duckdb@5896c638099998449f06ce1a61e6c01045ba4a7f (#330).

- Update vendored sources to duckdb/duckdb@1a2791b7b415ee41e2285e298ee97f37caf9eeeb (#329).

- Update vendored sources to duckdb/duckdb@01c5bed3c2235171f59527832b1d41fc4a669219 (#328).

- Update vendored sources to duckdb/duckdb@686bcd10b3d617b8a00c41505ab1a97d8c53319f (#327).

- Update vendored sources to duckdb/duckdb@2e78e027dbc812e301088cb72aec80025af0b7a2 (#326).

- Update vendored sources to duckdb/duckdb@4b8274729b3037ce1c3528e90896aa3f6d94559b (#325).

- Update vendored sources to duckdb/duckdb@de5f77c08b5c37afc511e581212639050be2c691 (#324).

- Update vendored sources to duckdb/duckdb@7691b57aa1ef638c4b825c388b1bd2877a4e8ec4 (#323).

- Update vendored sources to duckdb/duckdb@b881dc1265f222e0de23403d8b3c155e8a0c5f17 (#322).

- Update vendored sources to duckdb/duckdb@2be970dda0e5047b1075f938691455d63ba63a67 (#321).

- Update vendored sources to duckdb/duckdb@573bedb4c23ae67248fa7545c5af6f455b9523a8 (#320).

- Update vendored sources to duckdb/duckdb@892f631d24711e3911e8bac2baca66ebf07d9edb (#319).

- Update vendored sources to duckdb/duckdb@ea6f5c4e0903ebfe171969a214c19b77ccb7f7e8 (#318).

- Update vendored sources to duckdb/duckdb@0af71afe6c3e932c1f55b29418c3aef8eebf671f (#317).

- Update vendored sources to duckdb/duckdb@48a8b81d5264adae02777b80b73d69be6ea6aa36 (#316).

- Update vendored sources to duckdb/duckdb@5f4af5343a4f09c3ba184a171bbcf9abd9c8b139 (#315).

- Update vendored sources to duckdb/duckdb@0e6f3fb91a072d370eb81d200cff4ba952bf20f2 (#314).

- Update vendored sources to duckdb/duckdb@5bdb091a5d67460da3ca3a89f21b7cdc588d4544 (#313).

- Update vendored sources to duckdb/duckdb@6e24bb278d11538e46ce69446cd2849d331bc7a4 (#312).

- Update vendored sources to duckdb/duckdb@b1bae91af9cbf8443b69aa851accba42657fb3fb (#311).

- Update vendored sources to duckdb/duckdb@bb5f35c7af618d7636a1f61b26aa6a5c60b0d88a (#310).

- Update vendored sources to duckdb/duckdb@4cabb03b151deb6aec8b14a2496f1b2d9031574a (#309).

- Update vendored sources to duckdb/duckdb@dd2f87c0e2038e3bbfffecd904f407b80f298212 (#308).

- Update vendored sources to duckdb/duckdb@729468452530e898b34a9eec3b48574f8f6fe70e (#307).

- Update vendored sources to duckdb/duckdb@afecd99dbbcf9dec503ffffd2b9fefb8d9d826bd (#306).

- Update vendored sources to duckdb/duckdb@8eff1500c78807d6ff6f4cac99d799da27ff0f2b (#305).

- Update vendored sources to duckdb/duckdb@87ba8503f2a2d53284d0cde88e52df39959eeffa (#304).

- Update vendored sources to duckdb/duckdb@58fe5162afadc1a9b52cc095a86ad1769d3e9384 (#303).

- Update vendored sources to duckdb/duckdb@536fb3b02b0f0e436eb0b1345ae4b155c2993fa4 (#302).

- Update vendored sources to duckdb/duckdb@de92c08cb0585ccb364c3daf0b7e251841dc088b (#301).

- Update vendored sources to duckdb/duckdb@7d2a6d0332ca85730220c926fe8d2330ed2cb6cd (#300).

- Update vendored sources to duckdb/duckdb@13ace3f6ccbd81fa1f66a467583aab10bd888496 (#299).

- Update vendored sources to duckdb/duckdb@69afac464d1f0de4dedab96e26fec05d5b8118c8 (#298).

- Update vendored sources to duckdb/duckdb@e08c0bf105c2ad3d1a6445488182aedf680306e6 (#297).

- Update vendored sources to duckdb/duckdb@567bdebcba6e58da96ceb9465505a38a6c60e69f (#296).

- Update vendored sources to duckdb/duckdb@47715960b6ce0b724d9d061addbc85d0397367bf (#295).

- Update vendored sources to duckdb/duckdb@de13238537197a5e23b3450e8c931844034ca047 (#294).

- Update vendored sources to duckdb/duckdb@c84676023c279bfec3441657d54baaef499276f5 (#293).

- Update vendored sources to duckdb/duckdb@610d79431c7aeccb0d6a4cf9ce2c04a4a96d2f63 (#292).

- Update vendored sources to duckdb/duckdb@dabc6df8f5608453f2da1e23b16d55d6df2aaf52 (#291).

- Update vendored sources to duckdb/duckdb@8226769114e16a3cb42d38bfe58c218a9009b1a3 (#290).

- Update vendored sources to duckdb/duckdb@3897524b31f668ce73fef0b1e63c2a7e6e58cbb1 (#289).

- Update vendored sources to duckdb/duckdb@226c56b7dff9174ce54c83b907d59bca35363040 (#288).

- Update vendored sources to duckdb/duckdb@4d8693be1a39e3cb4c1ce42d6bc64978a5f6e7be (#287).

- Update vendored sources to duckdb/duckdb@35346d87637d8e6731ec1fcd1909c4a309a6d6ad (#286).

- Update vendored sources to duckdb/duckdb@f94b8acedb26d606691c62b3a80ee3ab45eb4ad3 (#285).

- Update vendored sources to duckdb/duckdb@42c504b821beba03867241dde68e9408a9740806 (#284).

- Update vendored sources to duckdb/duckdb@a6b5523b3a55961b282c20fe2704ec955a311069 (#283).

- Remove hotfix.

- Update vendored sources to duckdb/duckdb@56619faf054a284b88317a811d8f0cab0fe0974a (#281).

- Update vendored sources to duckdb/duckdb@8ecc90c8d60ce446f227fad40fe8fbafdaf2b4e1 (#280).

- Update vendored sources to duckdb/duckdb@0d612daeec725915c1b3083a6a8f5e854f424fb2 (#279).

- Update vendored sources to duckdb/duckdb@798f5a2ba0ddf1d849355293cd5d7debb2dc9e9a (#278).

- Update vendored sources to duckdb/duckdb@b32a97a77241fcd3fb29ac6b007035d8d733e8fc (#277).

- Update vendored sources to duckdb/duckdb@f683023d703649b6a813e6f4d5aaf2d329c58a72 (#276).

- Update vendored sources to duckdb/duckdb@7f3889c389b2e6e7111c2963c4cca1685de5e791 (#275).

- Update vendored sources to duckdb/duckdb@5819112b7e6480c377255ccab6f4e1657730b5fe (#274).

- Update vendored sources to duckdb/duckdb@9ed561eee5afc2242f73de5ea9c8cf1422c32a40 (#273).

- Update vendored sources to duckdb/duckdb@f0dbafd48f62dbd6ec1c763dd38bab2a611dac43 (#272).

- Update vendored sources to duckdb/duckdb@18c5431edff65f2260874a0a7290cd10069f9e59 (#271).

- Update vendored sources to duckdb/duckdb@f97ad19a296aa6f37e24a23a7ea2cdb87ebe6813 (#270).

- Update vendored sources to duckdb/duckdb@7abb7065d6a924f87d8cd7e61f3c1a488b825554 (#269).

- Update vendored sources to duckdb/duckdb@6aa0ab01b0e0cd008a2331a7deba1f6c7dc190fa (#268).

- Update vendored sources to duckdb/duckdb@8c1ef04afaad4e9901e714e76a22a4ecd7f96b10 (#267).

- Update vendored sources to duckdb/duckdb@e1c738e7e29e7f105d5c4a67df7a44bc2f3dc909 (#266).

- Update vendored sources to duckdb/duckdb@cdf7125edb568360896cc4ae01f7e52ece68020a (#265).

- Update vendored sources to duckdb/duckdb@16193a714ebac04fa89d0074b1c4d42e62e9fb61 (#264).

- Update vendored sources to duckdb/duckdb@285553fe3e6962bc2be7a69486e7f1bb223f8f1b (#263).

- Update vendored sources to duckdb/duckdb@e5d994bbc6c3e158264af3156f71e7f0340a1d0c (#262).

- Update vendored sources to duckdb/duckdb@627a70286b70dc6b3c35c2f5f4ebea0552f7c6e8 (#261).

- Update vendored sources to duckdb/duckdb@862852fa395b99735e5713cb55d0cea1d9320659 (#260).

- Update vendored sources to duckdb/duckdb@ecb8dc908b1fc97ed6255284701de8c57a9f8c39 (#259).

- Update vendored sources to duckdb/duckdb@b33069bb4ec5ed1e369a260efdb2aab60fa5ec79 (#247).

- Update vendored sources to duckdb/duckdb@9ad037f3adfe372f17b5178a449ac4b6f9142240 (#246).

- Update vendored sources to duckdb/duckdb@1345b3013e801be526e7fac8c8984c89b0033d6a (#245).

- Update vendored sources to duckdb/duckdb@bb97c95a1ad2c277fcf2a60bb1a8af4b0f29b6c7 (#244).

- Update vendored sources to duckdb/duckdb@26685b133edd712ef62e74dbf25ea611e1cf91dc (#243).

- Update vendored sources to duckdb/duckdb@513c2f22c0923045179a8800edf72d212a9bf682 (#242).

- Update vendored sources to duckdb/duckdb@fe535b02b3b8d2b3ac7660134fd588848be9e859 (#241).

- Update vendored sources to duckdb/duckdb@b371fc1b9a8960af25205a85ea89b381e1f98705 (#240).

- Update vendored sources to duckdb/duckdb@c4b6b8f3543bf440d4149a824eed118e4e54c4be (#239).

- Update vendored sources to duckdb/duckdb@10ea4832d3f1850685a65369e0b19c27ec81e638 (#238).

- Update vendored sources to duckdb/duckdb@f6a8ec460ae23e20e6f52859c32c96012dcc0b13 (#236).

- Update vendored sources to duckdb/duckdb@8d4a30cf72c2695c15bed2ec69b5a5bc56a5a594 (#235).

- Update vendored sources to duckdb/duckdb@367aa8db1cc622c46661d762f9cafdd88263040e (#234).

- Update vendored sources to duckdb/duckdb@3d85a139fe1f4c78284a0e8cde522a38f2bcde0a (#233).

- Update vendored sources to duckdb/duckdb@a4f0adb1cf051f6ec4d58326ccf4fc3d3f333d35 (#232).

- Update vendored sources to duckdb/duckdb@ad4639ed1a3448e0c7383d8601d3b797a1861c86 (#231).

- Update vendored sources to duckdb/duckdb@b8df1598853d55f4421bb72dd3d86db553e897b4 (#230).

- Update vendored sources to duckdb/duckdb@f5048f0ffd25b9d1d67b1a68f75ac435c9f5cbfa (#229).

- Update vendored sources to duckdb/duckdb@ac8efca3fc3bc1fa277a0ca32104e2e861b6eef5 (#228).

- Update vendored sources to duckdb/duckdb@c2e18955aff66454aa3ab5b39abd6f3c90f8010b (#227).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#226).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#220).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#219).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#218).

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10430870381

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425609276

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425483466

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10223714659

- Remove temporary patch.

- Enable creation of compilation database.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9879707346

- Adapt glue code.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9727972793

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9692337257

- Fix rfuns vendoring.

- Add another brotli patch.

- Brotli patch and compilation flags.

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

- Add fledge workflow.

- Use stable pak (#591).

- Latest changes (#584).

- Tweak patch call.

- Can't check incoming.

- Update actions to avoid warnings (#524).

- Use pkgdown branch (#523).

- Bring back stepwise vendoring.

- Don't remove dir.

- Add env.

- Vendor without creating PR.

- Set up R for r-hub.

- Force vendoring when tag.

- Fix passing branch names as reef.

- Pass inputs.ref to create-pull-request.

- Fix PR generation for snapshot tests for vendoring.

- Flip order.

- Use inputs.

- Use head ref for status reports.

- Check job.status.

- Tweak.

- Fix final status reporting.

- Fix status.

- Bump version of action.

- Post status for workflow_dispatch.

- Only smoke test for workflow_dispatch.

- Move condition to check if status event is triggered.

- Install package manually, faster.

- Verbosity.

- Improve support for protected branches, without fledge (#248).

- Fix vendoring (#225).

- Fix vendoring workflow (#217).

- Wait for pkgdown (#215).

- Fix builds (#213).

- Sync with latest developments.

- Use v2 instead of master.

- Inline action.

- Use dev roxygen2 and decor.

- Fix on Windows, tweak lock workflow.

- Avoid checking bashisms on Windows.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.

- Prepare for dynamic check matrix.

## Documentation

- Upgrade roxygen2.

- Fix typo.

## Testing

- Sync tests with duckplyr (#596).

- Skip if not installed.

- Skip if not installed.

- Add tests for comparison expression (@toppyy, #462).

- Update snapshot.

## Breaking changes

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## fledge

- Bump version to 1.1.3.9003 (#604).

- Bump version to 1.1.3.9002 (#602).

- Bump version to 1.1.3.9001 (#599).

## Uncategorized

- Merge branch 'cran-1.1.2'.

- Merge pull request #516 from duckdb/f-tweak.

  Fix signedness

- Merge pull request #461 from duckdb/f-exp-depth-2.

  Sync tests

- Merge pull request #392 from duckdb/cran-1.1.0.

  Bump

- Merge pull request #388 from duckdb/f-380-ppm-strip.

  Merge pull request #386 from duckdb/f-380-ppm-strip

- Merge pull request #214 from duckdb/b-ci.

  Only report success once

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13415 (#13415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13431 (#13431).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13439 (#13439).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13202 (#13202).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13268 (#13268).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13434 (#13434).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13433 (#13433).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13421 (#13421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13417 (#13417).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13411 (#13411).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13410 (#13410).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13408 (#13408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13409 (#13409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13358 (#13358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13402 (#13402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13383 (#13383).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13394 (#13394).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13401 (#13401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13370 (#13370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13399 (#13399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13329 (#13329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13344 (#13344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13354 (#13354).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13372 (#13372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13168 (#13168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13359 (#13359).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13356 (#13356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13335 (#13335).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13267 (#13267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13201 (#13201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13360 (#13360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13355 (#13355).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13346 (#13346).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13350 (#13350).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13341 (#13341).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13343 (#13343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13342 (#13342).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13317 (#13317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12886 (#12886).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13313 (#13313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13330 (#13330).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13234 (#13234).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13307 (#13307).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13167 (#13167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12682 (#12682).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13291 (#13291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13290 (#13290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13262 (#13262).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13278 (#13278).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13231 (#13231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13284 (#13284).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13281 (#13281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13283 (#13283).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13280 (#13280).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13282 (#13282).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13275 (#13275).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13260 (#13260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13261 (#13261).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13258 (#13258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13249 (#13249).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13229 (#13229).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13256 (#13256).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13162 (#13162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13230 (#13230).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13233 (#13233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13236 (#13236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13242 (#13242).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13241 (#13241).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13240 (#13240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13223 (#13223).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13207 (#13207).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13170 (#13170).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13203 (#13203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13109 (#13109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13194 (#13194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13191 (#13191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13189 (#13189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13188 (#13188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13186 (#13186).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13063 (#13063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13163 (#13163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13150 (#13150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13182 (#13182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13160 (#13160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13180 (#13180).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13161 (#13161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13151 (#13151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13146 (#13146).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13140 (#13140).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13136 (#13136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13087 (#13087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13101 (#13101).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13108 (#13108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13142 (#13142).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12978 (#12978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13130 (#13130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13123 (#13123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13137 (#13137).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13139 (#13139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13117 (#13117).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13133 (#13133).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13129 (#13129).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13131 (#13131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13127 (#13127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13125 (#13125).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13122 (#13122).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13126 (#13126).

- Merge tag 'v1.0.0-2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13114 (#13114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13093 (#13093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13110 (#13110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13118 (#13118).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13111 (#13111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13106 (#13106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12967 (#12967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13090 (#13090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13098 (#13098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13105 (#13105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13094 (#13094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13084 (#13084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13083 (#13083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13082 (#13082).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13081 (#13081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13089 (#13089).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13086 (#13086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13062 (#13062).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13073 (#13073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13076 (#13076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13074 (#13074).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13015 (#13015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13065 (#13065).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13068 (#13068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13027 (#13027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12579 (#12579).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12998 (#12998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13040 (#13040).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12920 (#12920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13054 (#13054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13056 (#13056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13057 (#13057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13052 (#13052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12995 (#12995).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13050 (#13050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13033 (#13033).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13039 (#13039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13035 (#13035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13030 (#13030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13028 (#13028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13025 (#13025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13023 (#13023).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13024 (#13024).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12953 (#12953).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13002 (#13002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12627 (#12627).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13020 (#13020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13019 (#13019).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13014 (#13014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13010 (#13010).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13013 (#13013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12728 (#12728).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13004 (#13004).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12993 (#12993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12994 (#12994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12931 (#12931).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13003 (#13003).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13001 (#13001).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12785 (#12785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13000 (#13000).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11720 (#11720).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12971 (#12971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12928 (#12928).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12829 (#12829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12929 (#12929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12979 (#12979).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12982 (#12982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12984 (#12984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12980 (#12980).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12942 (#12942).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12973 (#12973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12974 (#12974).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12972 (#12972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12965 (#12965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12968 (#12968).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12970 (#12970).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12966 (#12966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12954 (#12954).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12755 (#12755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12716 (#12716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12912 (#12912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12957 (#12957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12290 (#12290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12955 (#12955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12916 (#12916).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12948 (#12948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12824 (#12824).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12625 (#12625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12787 (#12787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12907 (#12907).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12885 (#12885).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12943 (#12943).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12938 (#12938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12937 (#12937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12932 (#12932).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12890 (#12890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12924 (#12924).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12866 (#12866).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12889 (#12889).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12918 (#12918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12908 (#12908).

- Merge branch 'cran-1.0.0-1'.

- Merge tag 'v1.0.0-1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12913 (#12913).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12914 (#12914).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12851 (#12851).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12887 (#12887).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12858 (#12858).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12888 (#12888).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12884 (#12884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12751 (#12751).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12848 (#12848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12498 (#12498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12398 (#12398).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12878 (#12878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12859 (#12859).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12834 (#12834).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12844 (#12844).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12849 (#12849).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12847 (#12847).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11191 (#11191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12840 (#12840).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12698 (#12698).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12806 (#12806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12734 (#12734).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12835 (#12835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12812 (#12812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12832 (#12832).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12691 (#12691).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12810 (#12810).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12780 (#12780).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12575 (#12575).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12803 (#12803).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12791 (#12791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12754 (#12754).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12765 (#12765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12685 (#12685).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12770 (#12770).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12768 (#12768).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12769 (#12769).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12762 (#12762).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12759 (#12759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12753 (#12753).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12636 (#12636).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12496 (#12496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12745 (#12745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12740 (#12740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12738 (#12738).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12737 (#12737).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12736 (#12736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12731 (#12731).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12730 (#12730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12599 (#12599).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12678 (#12678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12725 (#12725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12724 (#12724).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12708 (#12708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12697 (#12697).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12705 (#12705).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12717 (#12717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12681 (#12681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12692 (#12692).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12694 (#12694).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12689 (#12689).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12690 (#12690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12671 (#12671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12679 (#12679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12288 (#12288).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12655 (#12655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12669 (#12669).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12653 (#12653).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12663 (#12663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12658 (#12658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12654 (#12654).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12637 (#12637).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12650 (#12650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12642 (#12642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12652 (#12652).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12639 (#12639).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12635 (#12635).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12629 (#12629).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12630 (#12630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12633 (#12633).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12603 (#12603).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12608 (#12608).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12554 (#12554).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12539 (#12539).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12516 (#12516).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12515 (#12515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12445 (#12445).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12456 (#12456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12467 (#12467).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12465 (#12465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12470 (#12470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12461 (#12461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12448 (#12448).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12436 (#12436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12421 (#12421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12424 (#12424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12401 (#12401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12409 (#12409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12370 (#12370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12405 (#12405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12393 (#12393).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12391 (#12391).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12352 (#12352).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12360 (#12360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12344 (#12344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12332 (#12332).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12305 (#12305).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12302 (#12302).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12282 (#12282).

- Merge branch 'cran-1.0.0'.


# duckdb 1.1.3.9014

## Bug fixes

- Avoid compiler warning related to `Rboolean` (#594).

- Check `"duckdb.materialize_message"` symbol (#592).

- `%in%` works correctly as part of a `&` conjunction (#528).

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- Use portable format modifiers.

- Correctly compute vector length for data frames passed to relational functions (#379).

- Set `initialize_in_main_thread`, add patch.

- Compatibility with clang19 2.

- Compatibility with clang19.

- Uninitialized.

- Fix uninitialized move 5.

- Fix uninitialized move 4.

- Fix uninitialized move 3.

- Fix uninitialized move 2.

- Fix uninitialized move.

- Avoid triggering re2 in tests (#176).

- Correct usage of `win_current_group()` instead of `win_current_order()` in SQL translation (@lschneiderbauer, #173, #175).

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).

- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).

- Fix vendoring script without arguments, align.

- Don't run tests that invoke re2 by default (#121, #127).

- `dplyr::tbl()` works again when a Parquet or CSV file is passed instead of a table name (#38, #91).

- `DBI::dbQuoteIdentifier()` correctly quotes identifiers that start with a digit (#67, #92).

- Align the argument order of `dbWriteTable()` with the DBI specs (@eitsupi, #43, #49).

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (@romainfrancois, #186).

- Xz-compress duckdb sources in the tarball (#530).

- Add `col.types` argument to `duckdb_read_csv()` (@eli-daniels, #383, #445).

- `last_rel` (#529).

- `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- Rethrow errors with rlang if installed (#522).

- Catch and add query context for statement extraction (tidyverse/duckplyr#219, #521).

- Implement query cancellation (#514, #515).

- Add comparison expression to relational api (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

- Bump vendored cpp11 to v0.5.0 (#382, #387).

- Tweak implementation of `r_base::sum()` (#381, #385).

- `n_distinct()` supports `na.rm = TRUE` with a single vector argument again (@lschneiderbauer, #204, #216).

- New `rel_from_sql()` (#212).

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

- Support fetching `MAP` type (#61, #165).

- Add dbplyr translations for `clock::date_count_between()` (@edward-burn, #163, #166).

- `round()` duckdb translation uses `ROUND_EVEN()` instead of `ROUND()` (@lschneiderbauer, #146, #157).

- New `sort` argument to `rel_order()` (@toppyy, #168).

- Add dbplyr translations for `clock::add_days()`, `clock::add_years()`, `clock::get_day()`, `clock::get_month()`, and `clock::get_year()` (#153).

- Use latest tests from DBItest (#148).

- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).

- Include rfuns extension (hannes/duckdb-rfuns#78, #144).

- Map `NA` to `SQLNULL` (#143).

- New `tbl_file()` and `tbl_query()` to explicitly access tables and queries as dbplyr lazy tables (#96).

- Initial ALTREP support for `LIST` logical type (@romainfrancois, #77).

- Update core to duckdb v0.10.0 (#90).

- New private `rel_to_parquet()` to write a relation to parquet (@Tmonster, #46).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Bump for pre-release.

- Keep `cleanup` files to accommodate different build scenarios (#536).

- Update vendored sources to duckdb/duckdb@19864453f7d0ed095256d848b46e7b8630989bac (#580).

- Update vendored sources to duckdb/duckdb@c3ca3607c221d315f38227b8bf58e68746c59083 (#579).

- Update vendored sources to duckdb/duckdb@9cba6a2a03e3fbca4364cab89d81a19ab50511b8 (#578).

- Update vendored sources to duckdb/duckdb@c6c08d4c1b363231b3b9689367735c7264cacefb (#577).

- Update vendored sources to duckdb/duckdb@7f34190f3f94fc1b1575af829a9a0ccead87dc99 (#576).

- Update vendored sources to duckdb/duckdb@78b65d4a9aa80c4be4efcdd29fadd6f0c893f1ce (#575).

- Update vendored sources to duckdb/duckdb@c31c46a875979ce3343edeedcb497485ca2fd751 (duckdb/duckdb#14542, #574).

- Update vendored sources to duckdb/duckdb@4ba2e66277a7576f58318c1aac112faa67c47b11 (#573).

- Update vendored sources to duckdb/duckdb@247fcb31733a5297c1070fbd244f2349091253aa (duckdb/duckdb#14601, #572).

- Update vendored sources to duckdb/duckdb@1a519fce83b3d262247325dbf8014067686a2c94 (duckdb/duckdb#14600, #571).

- Update vendored sources to duckdb/duckdb@b653a8c2b760425a83302e894bf930f18a1bdf64 (#570).

- Update vendored sources to duckdb/duckdb@79bf967e1b6ab438e0a83a014e937af571ed7acb (#569).

- Update vendored sources to duckdb/duckdb@4b62ee43a7d5f62313d77d36dec8aea29412431f (#568).

- Update vendored sources to duckdb/duckdb@3293c92b6e657084318f7556b14077896b333109 (#567).

- Update vendored sources to duckdb/duckdb@8664b710beb205ec6fc7e9f3d18dfe24dd28625f (#566).

- Update vendored sources to duckdb/duckdb@92a1ccbcef04dda11c85fa2bf6daf27daf8d9c49 (#565).

- Update vendored sources to duckdb/duckdb@2635a87a566b90e086caa84805019f66eedf0859 (#564).

- Update vendored sources to duckdb/duckdb@0d5ec0057838081251b388726353f09cba9577ad (#563).

- Update vendored sources to duckdb/duckdb@6af32330b51af4d72d3fed665bfc03f78c8b3876 (#562).

- Update vendored sources to duckdb/duckdb@662b0b34eaaf7f52545638cbc87c10e32b33834d (#561).

- Update vendored sources to duckdb/duckdb@bccd37ae7ea09f77b6299165bf80bca3bc1efc7c (#560).

- Update vendored sources to duckdb/duckdb@5090b7396173069bb0d51b0e1341cfa9950c154f (#559).

- Update vendored sources to duckdb/duckdb@f5ebc9b8e1d6c040a2276e0ac4a41d6bf9475880 (duckdb/duckdb#14545, #558).

- Update vendored sources to duckdb/duckdb@b8c5248b9c18f7cafbdf7992421662adbd95bf38 (#557).

- Update vendored sources to duckdb/duckdb@dfdd7968262d912910d8249bde3524e068c67713 (#556).

- Update vendored sources to duckdb/duckdb@d0673165b52e89fe70d1891504e4dea82adeca85 (#555).

- Update vendored sources to duckdb/duckdb@d79e66bd032dbd2066c16a88f517f6da1cd0aa78 (#554).

- Update vendored sources to duckdb/duckdb@0359726be957673a62ab1ab61f1cca9ba5667386 (#553).

- Update vendored sources to duckdb/duckdb@10c42435f1805ee4415faa5d6da4943e8c98fa55 (#552).

- Update vendored sources to duckdb/duckdb@43d26298affa89bc6ca829a1defc4819b42b6fb4 (#551).

- Update vendored sources to duckdb/duckdb@52b43b166091c82b3f04bf8af15f0ace18207a64 (#550).

- Update vendored sources to duckdb/duckdb@0446ab42e96b6269e78f55293f4096fa10224837 (#549).

- Update vendored sources to duckdb/duckdb@ceb77af7935c3c7a4a34e1199abd4d6ea080448c (duckdb/duckdb#14430, #548).

- Update vendored sources to duckdb/duckdb@aed52f5cabe34075c53bcec4407e297124c8d336 (#547).

- Update vendored sources to duckdb/duckdb@e41a881658ae579cedebe19c5070dad660086aea (#546).

- Update vendored sources to duckdb/duckdb@98d4ad28be35cf5c37e18760e76d11bc07be1ab4 (#545).

- Update vendored sources to duckdb/duckdb@1bb332c9c59a9d15b196b4486a6d1ffcaa833ba5 (#544).

- Update vendored sources to duckdb/duckdb@0bbfe09937e3744325f3b2dfdb182e9ac1ff916f (#543).

- Update vendored sources to duckdb/duckdb@08969b4677534b6870bff4c99998c753a6e784fc (#542).

- Update vendored sources to duckdb/duckdb@4756244efa04d204be6f20d55036fc503b7ed49c (#541).

- Update vendored sources to duckdb/duckdb@217ec4722e949eaa49568bd707e49431ef727ab5 (#539).

- Move responsibility for removing CR (#533).

- Terminate all sources with newline (#531).

- Sync duckplyr tests (#527).

- Cleanup, preparation (#525).

- Bump version.

- Update vendored sources (tag v1.1.2) to duckdb/duckdb@f680b7d08f56183391b581077d4baf589e1cc8bd (#510).

- Update vendored sources to duckdb/duckdb@5f49126b92a0899a2049aaa57da886138c5f879d (#509).

- Update vendored sources to duckdb/duckdb@2c21eb1c2eec3a1e359d87fb2a2cd8e427dc03c1 (#508).

- Update vendored sources to duckdb/duckdb@cc067e6b7db33f516437567cbc726536e34ed716 (#507).

- Update vendored sources to duckdb/duckdb@d2dfc6090685470cb09326a7530066fc4b3db42a (#506).

- Update vendored sources to duckdb/duckdb@56e2e0e5721b8547f564fccf252db0ba93c85471 (#505).

- Update vendored sources to duckdb/duckdb@35dfcc06e6c76ad6bd8e4acdae1bcc30751777eb (#504).

- Update vendored sources to duckdb/duckdb@92e0964376a78f990408a0e81af155504b35d27c (#503).

- Update vendored sources to duckdb/duckdb@01e6e98e3875ed12cbcb9257f81844743b1665fa (#502).

- Update vendored sources to duckdb/duckdb@6dc2e9375870e60f82becb1cece4cc878289d3b8 (#501).

- Update vendored sources to duckdb/duckdb@52b19d5ece35be344830800db0e4961f47114aa9 (#500).

- Update vendored sources to duckdb/duckdb@0d3e84330e845ceefdc55a36d52ef0296af5d1e1 (#499).

- Update vendored sources to duckdb/duckdb@d0cf23ead54f191bf2518598edf04e209f07452e (#498).

- Update vendored sources to duckdb/duckdb@d57a94430e50263cbd1b719b984da189e5bba0c5 (#497).

- Update vendored sources to duckdb/duckdb@a5ddffef692c0627dd6c7efaed7cf65148321452 (#496).

- Update vendored sources to duckdb/duckdb@536f979f69b1bbe40d582450b6cfa6a68463f172 (#495).

- Update vendored sources to duckdb/duckdb@443380a11dbb31a1c218a759ec0c3b56880f1c38 (duckdb/duckdb#14249, #494).

- Update vendored sources to duckdb/duckdb@7919e4abc5597dc4fbeb5a19dff19ff69b5c4113 (duckdb/duckdb#14249, #493).

- Update vendored sources to duckdb/duckdb@52f967a42861032fd5f4392609afc195cd025dde (#492).

- Update vendored sources to duckdb/duckdb@1f20676c7d997fe4964a8b51378bf984e53a4b4c (#491).

- Update vendored sources to duckdb/duckdb@8cec9b1537f900e7a644e7b466ea899cf1ca8f8f (#490).

- Update vendored sources to duckdb/duckdb@4f0cd4d60035e8c6afafed47b68b2240b39e3566 (duckdb/duckdb#14212, #489).

- Update vendored sources to duckdb/duckdb@5a9a382a573b107a38f5ee277619b362d5079c32 (#488).

- Update vendored sources to duckdb/duckdb@123b82b9053c4843559035b6723c867b2618b2d9 (#487).

- Update vendored sources to duckdb/duckdb@405e15fcde8a4da4a7c6d3889f992f0a363c05f2 (duckdb/duckdb#14232, #486).

- Update vendored sources to duckdb/duckdb@0e398d95c50ae40730467c53922c8fb8d5c69f90 (#485).

- Update vendored sources to duckdb/duckdb@1eac05ecd3a6b8ec2cdf0c53ccece7ca2effef26 (#484).

- Update vendored sources to duckdb/duckdb@048f5ffcec9c1a4b73cbfbd4158cd5b6669f102b (#483).

- Update vendored sources to duckdb/duckdb@0b2d95601c2d9474f2c823ac3363e9ca14224c7c (#482).

- Update vendored sources to duckdb/duckdb@350d061846ed7e4c96d2efa7b523bb97ae84538a (#481).

- Update vendored sources to duckdb/duckdb@2f6b78c21d1634c7228e00c809a790701705c82b (#480).

- Update vendored sources to duckdb/duckdb@8aca4330ac46be3950c6b12e29040322dd245b7a (#479).

- Update vendored sources to duckdb/duckdb@9931d723ccde2b2435b1a927234338e6f0353d90 (#478).

- Update vendored sources to duckdb/duckdb@d896e73fe2db62b6749b95e30faa8bfa41dc4d32 (#477).

- Update vendored sources to duckdb/duckdb@f8c82ab2620f8066b0141df0c3982885a5258746 (#476).

- Update vendored sources to duckdb/duckdb@ee256eb45552601db71d4cad7a5cd4f46f0d5a1d (#475).

- Update vendored sources to duckdb/duckdb@130aab3f9ddb84e0c6e7f543a99881d8fc1bd6b7 (#474).

- Update vendored sources to duckdb/duckdb@92c65a4341c57f313dbeba5acc7b1fb917808010 (#473).

- Update vendored sources to duckdb/duckdb@47e1d3d60b4d6d075cf88c2707572df12a630a3a (#472).

- Update vendored sources to duckdb/duckdb@45559f5eeb1834454a30490fc4ffad1807e13f3b (#471).

- Update vendored sources to duckdb/duckdb@dfdd09f46c0169c9d8aa5381086e46a66e44fabc (#470).

- Update vendored sources to duckdb/duckdb@89828abb72219957372f316da06f007dadd2a9aa (#469).

- Update vendored sources to duckdb/duckdb@12e9777cf6283f44710b2610ba3d3735a1208751 (duckdb/duckdb#14077, #468).

- Update vendored sources to duckdb/duckdb@4a55e2334232afe94e47ab398ddb44f88fcd6658 (#467).

- Update vendored sources to duckdb/duckdb@0f3c46215feb0fb92d4998977fc31b2f52db6b14 (#466).

- Update vendored sources to duckdb/duckdb@c87246586490b442706d0be66b82d71930a00578 (#465).

- Update vendored sources to duckdb/duckdb@cd8cb3f1c81a74a3b2c1ed7d94e3913485895074 (#464).

- Update vendored sources to duckdb/duckdb@acd16816e31789bdb27e144ccd19ddb9da4fe6df (#463).

- Update vendored sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove uninitialized warnings.

- Document (#456).

- Update vendored sources (tag v1.1.1) to duckdb/duckdb@af39bd0dcf66876e09ac2a7c3baa28fe1b301151 (#454).

- Update vendored sources to duckdb/duckdb@0fe7708eef6b9b77270ca21cb9b5e30a3de84e3c (#453).

- Update vendored sources to duckdb/duckdb@34a3acc6b3354be86fe593d09e0702ab5eafe757 (#452).

- Update vendored sources to duckdb/duckdb@cb2a947e9df4f6c40b6dd5751c412d6946cbb62b (#451).

- Update vendored sources to duckdb/duckdb@64520f224d8a0a096cfe10f0c2cfbd1ac9457811 (duckdb/duckdb#13934, #450).

- Update vendored sources to duckdb/duckdb@b0eee44df70eb7bf9efac5f65dd2eaf7ad1e5403 (#449).

- Update vendored sources to duckdb/duckdb@4fe3dc559d10648691f9ab34f20207771890dd45 (#448).

- Update vendored sources to duckdb/duckdb@6c02032393583f353f2f2a0337a8e16f34dc5d82 (duckdb/duckdb#14026, #447).

- Update vendored sources to duckdb/duckdb@4ce455c84029195ffa4c3e540c10360ae8c73724 (#446).

- Update vendored sources to duckdb/duckdb@03dd0df6185d903ecbff9d80017e5449e78e5017 (#443).

- Update vendored sources to duckdb/duckdb@d1037da3139de90dc0a82df746d8ce92a50d9838 (#442).

- Update vendored sources to duckdb/duckdb@cb27c0423fa7107674c267b5de8eb93dd603cb69 (duckdb/duckdb#13993, #441).

- Update vendored sources to duckdb/duckdb@b787fcc1cb9bc4daf36e6eec19c1e9b2b162f4b0 (duckdb/duckdb#14020, #440).

- Update vendored sources to duckdb/duckdb@0ce863113043806780e776bcfb86b24afcb0263c (#439).

- Update vendored sources to duckdb/duckdb@f9e96b191088e65b4a1f95918312c40e31096dd9 (#438).

- Update vendored sources to duckdb/duckdb@2ff9c687e2c448914a28c59bd50f48f54e47de3c (#437).

- Update vendored sources to duckdb/duckdb@dcc302aef4491db8cc2efd2955ac254a4d62dcbc (#436).

- Update vendored sources to duckdb/duckdb@03976af191370d4020c172a82b28ca7885d98ea3 (#435).

- Update vendored sources to duckdb/duckdb@29c46243993319b0db24509c862126b8e17f1e8c (#434).

- Update vendored sources to duckdb/duckdb@e7da966e87539457f3de94a1bee288861fdca6d6 (#433).

- Update vendored sources to duckdb/duckdb@44bba02cea5d316e38f6edbad7fad3a1f913d63f (#432).

- Update vendored sources to duckdb/duckdb@04a1f750a6fab3f1a9cf3fb7cce5fd119c522304 (#431).

- Update vendored sources to duckdb/duckdb@0da70d9de97ff2cf39ad99b9e30b7e6cb91614b8 (duckdb/duckdb#13933, #430).

- Update vendored sources to duckdb/duckdb@df82a0e2c47e8b3ddd5a93e08530b83bc49e0da0 (#429).

- Update vendored sources to duckdb/duckdb@86723c9912fde7b76d3863b2ccd2d4333251c4af (#428).

- Update vendored sources to duckdb/duckdb@66d8ed93f67a00006ec99226c1205bcffb1ef07b (duckdb/duckdb#13941, #427).

- Update vendored sources to duckdb/duckdb@b2f68017070c1910dd3438f9428c7162cb428f84 (#426).

- Update vendored sources to duckdb/duckdb@35a104529b56c4f4f1e383e2ead26d6047d3442e (#425).

- Update vendored sources to duckdb/duckdb@b8c5fa937919631b759a70e33f068aa05de8bd36 (#424).

- Update vendored sources to duckdb/duckdb@18670a10f1b3da56382e272518d6b149e489ca51 (#423).

- Update vendored sources to duckdb/duckdb@0b0c95b9dc685e1a6ca011d8e086d885afbe0398 (#422).

- Update vendored sources to duckdb/duckdb@e5e1595da75ea01559f2b4bc9531505422b7fcdc (duckdb/duckdb#13585, #421).

- Update vendored sources to duckdb/duckdb@75d4bd0cc759dcb609ab349b87bff07dddf2ebb7 (#420).

- Update vendored sources to duckdb/duckdb@c0f29465624aaa1472ee05d4723415cfa1bfbdf9 (#419).

- Update vendored sources to duckdb/duckdb@b369bcb4e08235e52866a5f8afb7e172fe573287 (#418).

- Update vendored sources to duckdb/duckdb@414207f2120ad9019b416cf891947004c74c7347 (#417).

- Update vendored sources to duckdb/duckdb@38ceb86f1aa4cfae7c993f59de19e0cfee7ff68e (#416).

- Update vendored sources to duckdb/duckdb@0dbb79e8de897b4a710ed53becc063bcdf80884d (duckdb/duckdb#13824, #415).

- Update vendored sources to duckdb/duckdb@9af117f0e6d3f2f9ade385dadc46807c1b388dd4 (#414).

- Update vendored sources to duckdb/duckdb@88a4c1e5893f316d763343d7f66f57917b065f50 (#413).

- Update vendored sources to duckdb/duckdb@d93225aab5c8e0da34776398358373f4c0232864 (duckdb/duckdb#13872, #412).

- Update vendored sources to duckdb/duckdb@8c2ee1eb7987a981cdf4bb1ed52683784a26e3bf (duckdb/duckdb#13880, #411).

- Update vendored sources to duckdb/duckdb@081a748340c4fcd3b3652230a02432afae72bbb3 (#410).

- Update vendored sources to duckdb/duckdb@bc7683e100867fae06c1f65e055df403c2ee25cf (#409).

- Update vendored sources to duckdb/duckdb@b87545985fc03e43baf84d9554eab23ea4b21f6c (#408).

- Update vendored sources to duckdb/duckdb@1d7e05c9737821fdb2c8eba996642c9953de52f6 (#407).

- Update vendored sources to duckdb/duckdb@b383f3668095fac2574bc6a0c417047a6fe80c9f (#406).

- Update vendored sources to duckdb/duckdb@039a262ae9805f30690ae1c8ec6a7fb27812c1b5 (#405).

- Update vendored sources to duckdb/duckdb@d697acfb108f6ec1b1ed26f0062445e1d49ee1c4 (#404).

- Update vendored sources to duckdb/duckdb@dfbfdef89aad145dc9d81c275bc2c9fad4062bed (#403).

- Update vendored sources to duckdb/duckdb@c41ae2cb6e2390b9656ac2d22885df0572a87796 (#402).

- Update vendored sources to duckdb/duckdb@d066254185fa56ec851183e9178edb04ae34c0b9 (#401).

- Update vendored sources to duckdb/duckdb@5fd2501220b80adaddf009b78cac44b97813258c (#400).

- Update vendored sources to duckdb/duckdb@6d9d429d5e7f464b69671b46dcbc99a6e46378df (#399).

- Update vendored sources to duckdb/duckdb@d9e89b5cc192ea052f038d8e7b26d253ec81bc49 (#398).

- Update vendored sources to duckdb/duckdb@95038c5eee75f733c99193c66c3faa7289d6f599 (#397).

- Update vendored sources to duckdb/duckdb@8d1c2b29badfcc55246829e00e97b86b38b3606a (#396).

- Update vendored sources to duckdb/duckdb@329bb5393b686421b40261211354f4d77cac1633 (#395).

- Update vendored sources to duckdb/duckdb@403f0fc6459fc5a1f185350d30eafa555c145d1f (#394).

- Update vendored sources to duckdb/duckdb@6a197b22652d02749c3e755e75b10d75e7ad6b75 (#393).

- Show file sizes (#380, #391).

- Fix stripping call (#380, #390).

- Move stripping logic to `install.libs.R` (#380, #389).

- Strip binary if requested (#380, #386).

- Update vendored sources to hannes/duckdb-rfuns@4fccc0b6e577f5b32c84d03cd79cb9fd9827212b (#378).

- Bump.

- Update vendored sources (tag v1.1.0) to duckdb/duckdb@fa5c2fe15f3da5f32397b009196c0895fce60820 (#377).

- Update vendored sources to duckdb/duckdb@fc21edf1508fa785a0ce06ffd245fe30b20eefe0 (#376).

- Update vendored sources to duckdb/duckdb@1d3fc5aec6b846c563d6d99c96df7c30117b5a94 (#375).

- Update vendored sources to duckdb/duckdb@893d007e64df94658d4da92c02698559f89d2072 (#374).

- Update vendored sources to duckdb/duckdb@64bacde85e4c24134cf73f9b4ed3ae362510f287 (#373).

- Update vendored sources to duckdb/duckdb@93494bd74d30f7ae11456dcee6c5e5143be58606 (#372).

- Update vendored sources to duckdb/duckdb@f76d6f2e7e170d6434e2725f43bac5ede31985fa (#371).

- Update vendored sources to duckdb/duckdb@310176118d5dc9897fb752bda145ee9dca628240 (#370).

- Update vendored sources to duckdb/duckdb@c1183d72ed9b388fdc894e86f7e999b2ba8301e5 (#369).

- Update vendored sources to duckdb/duckdb@d454d2458646151fc89c60639f0c50cecf1f4ebd (#367).

- Update vendored sources to duckdb/duckdb@0e6dacd8932c22f9d383b8047fb11aad59564895 (#363).

- Update vendored sources to duckdb/duckdb@4d18b9d05caf88f0420dbdbe03d35a0faabf4aa7 (#362).

- Update vendored sources to duckdb/duckdb@c4940720ce2ee93f39f6d80ceb25a729718a6828 (#361).

- Update vendored sources to duckdb/duckdb@421acb0f7c924216bc689f3731d7a971e7e4fa2b (#360).

- Update vendored sources to duckdb/duckdb@7c988cf7bf417d6534f0ae60f6e0297ef22cd18a (#359).

- Update vendored sources to duckdb/duckdb@dd3cbcee009bf664e3a9bce2467c8af6d2bc53d2 (#358).

- Update vendored sources to duckdb/duckdb@95a9fe9f2681175788ac85dfe67a370ef9b6f32d (#357).

- Update vendored sources to duckdb/duckdb@756d4fcb624c2c180969630b11d44380704a871a (#356).

- Update vendored sources to duckdb/duckdb@450b7e45d9e717d2c475995dabbde47b5acdfc4a (#355).

- Update vendored sources to duckdb/duckdb@dffc4ffad7d9cb7c181db87b1bfb51e261bcedf6 (#354).

- Update vendored sources to duckdb/duckdb@a6e32b115826ba543e32a733cb92f68fd0549186 (#353).

- Update vendored sources to duckdb/duckdb@1f01ef8781c8a3edf192286e0044ff37f043fb47 (#352).

- Update vendored sources to duckdb/duckdb@9aa68025b1ddf0deba9e7caf17cd0dbe4abd7206 (#351).

- Update vendored sources to duckdb/duckdb@7a7547f5da232111d52c4afb05e98e19fd8c7e31 (#350).

- Update vendored sources to duckdb/duckdb@fa2daf7a09e477e30e53b4cc8f4269c39eaf62ef (#349).

- Update vendored sources to duckdb/duckdb@a65fc4ed0847cb073231ba2be21bbd8515b91171 (#348).

- Update vendored sources to duckdb/duckdb@1844ae51091ee85c9194036405abd561ff9b58ae (#347).

- Update vendored sources to duckdb/duckdb@439bb91fc33e8bc45cc6e6d73c823ab44b48876d (#346).

- Update vendored sources to duckdb/duckdb@9067c648ef182084b3159b72213097505d5b5cab (#345).

- Update vendored sources to duckdb/duckdb@a05e81d31b178bd41ff4fb3aa46c30fe2a7068e5 (#344).

- Update vendored sources to duckdb/duckdb@74c9f4df1fe5c3f39007aa38c112cb7582f91302 (#343).

- Update vendored sources to duckdb/duckdb@e90611400749d641a07dbcd5f10df85d99813f33 (#342).

- Update vendored sources to duckdb/duckdb@902af6f21cf5e15979ecab02f15223a0f9a0baff (#341).

- Update vendored sources to duckdb/duckdb@6f9795184545d841a35e75b938f78a1e0520bd8f (#340).

- Update vendored sources to duckdb/duckdb@67b69b0c6e9411a2755baffa2305000dae887937 (#339).

- Update vendored sources to duckdb/duckdb@18e97dd88525d42c5de9faf6d1a89b90590c94fe (#338).

- Update vendored sources to duckdb/duckdb@37a55bdf6665705eb6be311bc61fa8a2f2b900fe (#337).

- Update vendored sources to duckdb/duckdb@0d37df84df6c0226423eda80d2adce9b6fdf1eea (#336).

- Update vendored sources to duckdb/duckdb@2355a5bd10fe6ae24b0b7604a66b78d6c657c104 (#335).

- Update vendored sources to duckdb/duckdb@206320c56140238066fdfca3aa503ec09f7cb2bd (#334).

- Update vendored sources to duckdb/duckdb@40c9c5a5f9b54dcaf75c45ecaa311ec478721559 (#333).

- Update vendored sources to duckdb/duckdb@379a80032a96a454190c4d2f524898ecad8fec89 (#332).

- Update vendored sources to duckdb/duckdb@20100aa2560b68b2f0b46bdc07877a96ed270959 (#331).

- Update vendored sources to duckdb/duckdb@5896c638099998449f06ce1a61e6c01045ba4a7f (#330).

- Update vendored sources to duckdb/duckdb@1a2791b7b415ee41e2285e298ee97f37caf9eeeb (#329).

- Update vendored sources to duckdb/duckdb@01c5bed3c2235171f59527832b1d41fc4a669219 (#328).

- Update vendored sources to duckdb/duckdb@686bcd10b3d617b8a00c41505ab1a97d8c53319f (#327).

- Update vendored sources to duckdb/duckdb@2e78e027dbc812e301088cb72aec80025af0b7a2 (#326).

- Update vendored sources to duckdb/duckdb@4b8274729b3037ce1c3528e90896aa3f6d94559b (#325).

- Update vendored sources to duckdb/duckdb@de5f77c08b5c37afc511e581212639050be2c691 (#324).

- Update vendored sources to duckdb/duckdb@7691b57aa1ef638c4b825c388b1bd2877a4e8ec4 (#323).

- Update vendored sources to duckdb/duckdb@b881dc1265f222e0de23403d8b3c155e8a0c5f17 (#322).

- Update vendored sources to duckdb/duckdb@2be970dda0e5047b1075f938691455d63ba63a67 (#321).

- Update vendored sources to duckdb/duckdb@573bedb4c23ae67248fa7545c5af6f455b9523a8 (#320).

- Update vendored sources to duckdb/duckdb@892f631d24711e3911e8bac2baca66ebf07d9edb (#319).

- Update vendored sources to duckdb/duckdb@ea6f5c4e0903ebfe171969a214c19b77ccb7f7e8 (#318).

- Update vendored sources to duckdb/duckdb@0af71afe6c3e932c1f55b29418c3aef8eebf671f (#317).

- Update vendored sources to duckdb/duckdb@48a8b81d5264adae02777b80b73d69be6ea6aa36 (#316).

- Update vendored sources to duckdb/duckdb@5f4af5343a4f09c3ba184a171bbcf9abd9c8b139 (#315).

- Update vendored sources to duckdb/duckdb@0e6f3fb91a072d370eb81d200cff4ba952bf20f2 (#314).

- Update vendored sources to duckdb/duckdb@5bdb091a5d67460da3ca3a89f21b7cdc588d4544 (#313).

- Update vendored sources to duckdb/duckdb@6e24bb278d11538e46ce69446cd2849d331bc7a4 (#312).

- Update vendored sources to duckdb/duckdb@b1bae91af9cbf8443b69aa851accba42657fb3fb (#311).

- Update vendored sources to duckdb/duckdb@bb5f35c7af618d7636a1f61b26aa6a5c60b0d88a (#310).

- Update vendored sources to duckdb/duckdb@4cabb03b151deb6aec8b14a2496f1b2d9031574a (#309).

- Update vendored sources to duckdb/duckdb@dd2f87c0e2038e3bbfffecd904f407b80f298212 (#308).

- Update vendored sources to duckdb/duckdb@729468452530e898b34a9eec3b48574f8f6fe70e (#307).

- Update vendored sources to duckdb/duckdb@afecd99dbbcf9dec503ffffd2b9fefb8d9d826bd (#306).

- Update vendored sources to duckdb/duckdb@8eff1500c78807d6ff6f4cac99d799da27ff0f2b (#305).

- Update vendored sources to duckdb/duckdb@87ba8503f2a2d53284d0cde88e52df39959eeffa (#304).

- Update vendored sources to duckdb/duckdb@58fe5162afadc1a9b52cc095a86ad1769d3e9384 (#303).

- Update vendored sources to duckdb/duckdb@536fb3b02b0f0e436eb0b1345ae4b155c2993fa4 (#302).

- Update vendored sources to duckdb/duckdb@de92c08cb0585ccb364c3daf0b7e251841dc088b (#301).

- Update vendored sources to duckdb/duckdb@7d2a6d0332ca85730220c926fe8d2330ed2cb6cd (#300).

- Update vendored sources to duckdb/duckdb@13ace3f6ccbd81fa1f66a467583aab10bd888496 (#299).

- Update vendored sources to duckdb/duckdb@69afac464d1f0de4dedab96e26fec05d5b8118c8 (#298).

- Update vendored sources to duckdb/duckdb@e08c0bf105c2ad3d1a6445488182aedf680306e6 (#297).

- Update vendored sources to duckdb/duckdb@567bdebcba6e58da96ceb9465505a38a6c60e69f (#296).

- Update vendored sources to duckdb/duckdb@47715960b6ce0b724d9d061addbc85d0397367bf (#295).

- Update vendored sources to duckdb/duckdb@de13238537197a5e23b3450e8c931844034ca047 (#294).

- Update vendored sources to duckdb/duckdb@c84676023c279bfec3441657d54baaef499276f5 (#293).

- Update vendored sources to duckdb/duckdb@610d79431c7aeccb0d6a4cf9ce2c04a4a96d2f63 (#292).

- Update vendored sources to duckdb/duckdb@dabc6df8f5608453f2da1e23b16d55d6df2aaf52 (#291).

- Update vendored sources to duckdb/duckdb@8226769114e16a3cb42d38bfe58c218a9009b1a3 (#290).

- Update vendored sources to duckdb/duckdb@3897524b31f668ce73fef0b1e63c2a7e6e58cbb1 (#289).

- Update vendored sources to duckdb/duckdb@226c56b7dff9174ce54c83b907d59bca35363040 (#288).

- Update vendored sources to duckdb/duckdb@4d8693be1a39e3cb4c1ce42d6bc64978a5f6e7be (#287).

- Update vendored sources to duckdb/duckdb@35346d87637d8e6731ec1fcd1909c4a309a6d6ad (#286).

- Update vendored sources to duckdb/duckdb@f94b8acedb26d606691c62b3a80ee3ab45eb4ad3 (#285).

- Update vendored sources to duckdb/duckdb@42c504b821beba03867241dde68e9408a9740806 (#284).

- Update vendored sources to duckdb/duckdb@a6b5523b3a55961b282c20fe2704ec955a311069 (#283).

- Remove hotfix.

- Update vendored sources to duckdb/duckdb@56619faf054a284b88317a811d8f0cab0fe0974a (#281).

- Update vendored sources to duckdb/duckdb@8ecc90c8d60ce446f227fad40fe8fbafdaf2b4e1 (#280).

- Update vendored sources to duckdb/duckdb@0d612daeec725915c1b3083a6a8f5e854f424fb2 (#279).

- Update vendored sources to duckdb/duckdb@798f5a2ba0ddf1d849355293cd5d7debb2dc9e9a (#278).

- Update vendored sources to duckdb/duckdb@b32a97a77241fcd3fb29ac6b007035d8d733e8fc (#277).

- Update vendored sources to duckdb/duckdb@f683023d703649b6a813e6f4d5aaf2d329c58a72 (#276).

- Update vendored sources to duckdb/duckdb@7f3889c389b2e6e7111c2963c4cca1685de5e791 (#275).

- Update vendored sources to duckdb/duckdb@5819112b7e6480c377255ccab6f4e1657730b5fe (#274).

- Update vendored sources to duckdb/duckdb@9ed561eee5afc2242f73de5ea9c8cf1422c32a40 (#273).

- Update vendored sources to duckdb/duckdb@f0dbafd48f62dbd6ec1c763dd38bab2a611dac43 (#272).

- Update vendored sources to duckdb/duckdb@18c5431edff65f2260874a0a7290cd10069f9e59 (#271).

- Update vendored sources to duckdb/duckdb@f97ad19a296aa6f37e24a23a7ea2cdb87ebe6813 (#270).

- Update vendored sources to duckdb/duckdb@7abb7065d6a924f87d8cd7e61f3c1a488b825554 (#269).

- Update vendored sources to duckdb/duckdb@6aa0ab01b0e0cd008a2331a7deba1f6c7dc190fa (#268).

- Update vendored sources to duckdb/duckdb@8c1ef04afaad4e9901e714e76a22a4ecd7f96b10 (#267).

- Update vendored sources to duckdb/duckdb@e1c738e7e29e7f105d5c4a67df7a44bc2f3dc909 (#266).

- Update vendored sources to duckdb/duckdb@cdf7125edb568360896cc4ae01f7e52ece68020a (#265).

- Update vendored sources to duckdb/duckdb@16193a714ebac04fa89d0074b1c4d42e62e9fb61 (#264).

- Update vendored sources to duckdb/duckdb@285553fe3e6962bc2be7a69486e7f1bb223f8f1b (#263).

- Update vendored sources to duckdb/duckdb@e5d994bbc6c3e158264af3156f71e7f0340a1d0c (#262).

- Update vendored sources to duckdb/duckdb@627a70286b70dc6b3c35c2f5f4ebea0552f7c6e8 (#261).

- Update vendored sources to duckdb/duckdb@862852fa395b99735e5713cb55d0cea1d9320659 (#260).

- Update vendored sources to duckdb/duckdb@ecb8dc908b1fc97ed6255284701de8c57a9f8c39 (#259).

- Update vendored sources to duckdb/duckdb@b33069bb4ec5ed1e369a260efdb2aab60fa5ec79 (#247).

- Update vendored sources to duckdb/duckdb@9ad037f3adfe372f17b5178a449ac4b6f9142240 (#246).

- Update vendored sources to duckdb/duckdb@1345b3013e801be526e7fac8c8984c89b0033d6a (#245).

- Update vendored sources to duckdb/duckdb@bb97c95a1ad2c277fcf2a60bb1a8af4b0f29b6c7 (#244).

- Update vendored sources to duckdb/duckdb@26685b133edd712ef62e74dbf25ea611e1cf91dc (#243).

- Update vendored sources to duckdb/duckdb@513c2f22c0923045179a8800edf72d212a9bf682 (#242).

- Update vendored sources to duckdb/duckdb@fe535b02b3b8d2b3ac7660134fd588848be9e859 (#241).

- Update vendored sources to duckdb/duckdb@b371fc1b9a8960af25205a85ea89b381e1f98705 (#240).

- Update vendored sources to duckdb/duckdb@c4b6b8f3543bf440d4149a824eed118e4e54c4be (#239).

- Update vendored sources to duckdb/duckdb@10ea4832d3f1850685a65369e0b19c27ec81e638 (#238).

- Update vendored sources to duckdb/duckdb@f6a8ec460ae23e20e6f52859c32c96012dcc0b13 (#236).

- Update vendored sources to duckdb/duckdb@8d4a30cf72c2695c15bed2ec69b5a5bc56a5a594 (#235).

- Update vendored sources to duckdb/duckdb@367aa8db1cc622c46661d762f9cafdd88263040e (#234).

- Update vendored sources to duckdb/duckdb@3d85a139fe1f4c78284a0e8cde522a38f2bcde0a (#233).

- Update vendored sources to duckdb/duckdb@a4f0adb1cf051f6ec4d58326ccf4fc3d3f333d35 (#232).

- Update vendored sources to duckdb/duckdb@ad4639ed1a3448e0c7383d8601d3b797a1861c86 (#231).

- Update vendored sources to duckdb/duckdb@b8df1598853d55f4421bb72dd3d86db553e897b4 (#230).

- Update vendored sources to duckdb/duckdb@f5048f0ffd25b9d1d67b1a68f75ac435c9f5cbfa (#229).

- Update vendored sources to duckdb/duckdb@ac8efca3fc3bc1fa277a0ca32104e2e861b6eef5 (#228).

- Update vendored sources to duckdb/duckdb@c2e18955aff66454aa3ab5b39abd6f3c90f8010b (#227).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#226).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#220).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#219).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#218).

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10430870381

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425609276

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425483466

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10223714659

- Remove temporary patch.

- Enable creation of compilation database.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9879707346

- Adapt glue code.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9727972793

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9692337257

- Fix rfuns vendoring.

- Add another brotli patch.

- Brotli patch and compilation flags.

- Update vendored sources (tag v1.0.0) to duckdb/duckdb@1f98600c2cf8722a6d2f2d805bb4af5e701319fc.

  🦆

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources to hannes/duckdb-rfuns@397ab2a5efa254ea71e45f92b1346e2de6617d59.

- `n_distinct()` followup (@lschneiderbauer, #158).

- Improve yyjson patch.

- Add yyjson patch.

- Format.

- Adapt to `shared_ptr` changes.

- Add patch.

- Update vendored sources (tag v0.10.2) to duckdb/duckdb@1601d94f94a7e0d2eb805a94803eb1e3afbbe4ed.

- Fix patch.

- Fix generated Makevars.win.

- Add patch for re2 update.

- Apply patches during vendoring.

- Harmonize test file names.

- Restore vendor script, new script for step-by-step vendoring.

- Change maintainer.

- Use temporary clone.

- Always vendor next commit.

- Duckdir -\> upstream_dir.

- Ignore.

- Bump version.

- Build-ignore autogenerated files.

- Add revdepcheck results.

- Ellipsis before cache argument.

- Sync tests.

- Update NEWS.

- Bump version.

- Change directory location for extensions and secrets for v.0.10.0 release (@Tmonster, #73).

- Bump version.

- Update vendored sources to duckdb/duckdb@d4c774b1f15ed88c608154156d4c00f9235dbaf3 (#85).

- Executable script.

- Fix Dockerfile deps.

- Compose with threadcheck.

- Improve Docker Compose infrastructure.

- Add Docker Compose infrastructure for running with r-debug.

- Style.

- Sync duckplyr tests (#78).

- Update vendored sources to duckdb/duckdb@24148408432d05bda7cf86f2736d24920c51577c (#57).

- Update vendored sources to duckdb/duckdb@d51e1b06fad726a606ceb70c1530e21121633f31 (#53).

- Remove last instance of `default_connection()` (#50).

- Bump, tidy, news.

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

- Add fledge workflow.

- Use stable pak (#591).

- Latest changes (#584).

- Tweak patch call.

- Can't check incoming.

- Update actions to avoid warnings (#524).

- Use pkgdown branch (#523).

- Bring back stepwise vendoring.

- Don't remove dir.

- Add env.

- Vendor without creating PR.

- Set up R for r-hub.

- Force vendoring when tag.

- Fix passing branch names as reef.

- Pass inputs.ref to create-pull-request.

- Fix PR generation for snapshot tests for vendoring.

- Flip order.

- Use inputs.

- Use head ref for status reports.

- Check job.status.

- Tweak.

- Fix final status reporting.

- Fix status.

- Bump version of action.

- Post status for workflow_dispatch.

- Only smoke test for workflow_dispatch.

- Move condition to check if status event is triggered.

- Install package manually, faster.

- Verbosity.

- Improve support for protected branches, without fledge (#248).

- Fix vendoring (#225).

- Fix vendoring workflow (#217).

- Wait for pkgdown (#215).

- Fix builds (#213).

- Sync with latest developments.

- Use v2 instead of master.

- Inline action.

- Use dev roxygen2 and decor.

- Fix on Windows, tweak lock workflow.

- Avoid checking bashisms on Windows.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.

- Prepare for dynamic check matrix.

- Fail if patch does not apply.

- Add patches.

- Move caching of duckdb prebuilt archive.

- More careful patching.

- Better tag detection.

- Add R version to cache key.

- Logic.

- Fix vendoring.

- Add rhub2 workflow.

- Avoid vendoring past most recent tag.

- Always vendor tags.

- Fix condition.

- Fix.

- Fix vendoring.

- Only run check if vendoring changed anything.

- Show remaining commits to be vendored.

- Avoid concurrency, more is more.

- Logging.

- Fix typo.

- Fix typo.

- Also trigger when updating vendoring script.

- Dry-run push.

- Pull before vendoring.

- Simplify.

- Use most recent commit.

- Improve concurrency.

- Show stats.

- No cancel in progress, deep fetch.

- Debug.

- Debug.

- Debug.

- Fix typo.

- Vendor only next commit.

- Fix path.

- Vendor every five minutes, but only the next commit.

- Update vendored sources nightly (#25, #82).

## Documentation

- Upgrade roxygen2.

- Fix typo.

- Add list of contributors (#2, #94).

- Use pkgdown BS5 (@maelle, #31, #70).

- Link to R documentation page.

## Testing

- Sync tests with duckplyr (#596).

- Skip if not installed.

- Skip if not installed.

- Add tests for comparison expression (@toppyy, #462).

- Update snapshot.

- Update duckplyr tests.

- Tweak tests.

- Add csv reading test for `duckdb_read_csv(na.strings = )` (@Tmonster, #10).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0 (#84).

## Breaking changes

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## fledge

- Bump version to 1.1.3.9003 (#604).

- Bump version to 1.1.3.9002 (#602).

- Bump version to 1.1.3.9001 (#599).

## README

- Display different logo for light/dark mode (@szarnyasg, #129).

## Uncategorized

- Merge branch 'cran-1.1.2'.

- Merge pull request #516 from duckdb/f-tweak.

  Fix signedness

- Merge pull request #461 from duckdb/f-exp-depth-2.

  Sync tests

- Merge pull request #392 from duckdb/cran-1.1.0.

  Bump

- Merge pull request #388 from duckdb/f-380-ppm-strip.

  Merge pull request #386 from duckdb/f-380-ppm-strip

- Merge pull request #214 from duckdb/b-ci.

  Only report success once

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13415 (#13415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13431 (#13431).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13439 (#13439).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13202 (#13202).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13268 (#13268).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13434 (#13434).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13433 (#13433).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13421 (#13421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13417 (#13417).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13411 (#13411).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13410 (#13410).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13408 (#13408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13409 (#13409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13358 (#13358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13402 (#13402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13383 (#13383).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13394 (#13394).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13401 (#13401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13370 (#13370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13399 (#13399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13329 (#13329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13344 (#13344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13354 (#13354).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13372 (#13372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13168 (#13168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13359 (#13359).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13356 (#13356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13335 (#13335).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13267 (#13267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13201 (#13201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13360 (#13360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13355 (#13355).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13346 (#13346).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13350 (#13350).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13341 (#13341).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13343 (#13343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13342 (#13342).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13317 (#13317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12886 (#12886).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13313 (#13313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13330 (#13330).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13234 (#13234).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13307 (#13307).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13167 (#13167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12682 (#12682).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13291 (#13291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13290 (#13290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13262 (#13262).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13278 (#13278).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13231 (#13231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13284 (#13284).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13281 (#13281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13283 (#13283).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13280 (#13280).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13282 (#13282).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13275 (#13275).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13260 (#13260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13261 (#13261).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13258 (#13258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13249 (#13249).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13229 (#13229).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13256 (#13256).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13162 (#13162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13230 (#13230).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13233 (#13233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13236 (#13236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13242 (#13242).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13241 (#13241).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13240 (#13240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13223 (#13223).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13207 (#13207).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13170 (#13170).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13203 (#13203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13109 (#13109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13194 (#13194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13191 (#13191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13189 (#13189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13188 (#13188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13186 (#13186).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13063 (#13063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13163 (#13163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13150 (#13150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13182 (#13182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13160 (#13160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13180 (#13180).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13161 (#13161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13151 (#13151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13146 (#13146).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13140 (#13140).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13136 (#13136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13087 (#13087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13101 (#13101).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13108 (#13108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13142 (#13142).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12978 (#12978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13130 (#13130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13123 (#13123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13137 (#13137).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13139 (#13139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13117 (#13117).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13133 (#13133).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13129 (#13129).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13131 (#13131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13127 (#13127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13125 (#13125).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13122 (#13122).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13126 (#13126).

- Merge tag 'v1.0.0-2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13114 (#13114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13093 (#13093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13110 (#13110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13118 (#13118).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13111 (#13111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13106 (#13106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12967 (#12967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13090 (#13090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13098 (#13098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13105 (#13105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13094 (#13094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13084 (#13084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13083 (#13083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13082 (#13082).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13081 (#13081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13089 (#13089).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13086 (#13086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13062 (#13062).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13073 (#13073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13076 (#13076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13074 (#13074).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13015 (#13015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13065 (#13065).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13068 (#13068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13027 (#13027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12579 (#12579).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12998 (#12998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13040 (#13040).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12920 (#12920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13054 (#13054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13056 (#13056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13057 (#13057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13052 (#13052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12995 (#12995).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13050 (#13050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13033 (#13033).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13039 (#13039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13035 (#13035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13030 (#13030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13028 (#13028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13025 (#13025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13023 (#13023).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13024 (#13024).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12953 (#12953).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13002 (#13002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12627 (#12627).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13020 (#13020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13019 (#13019).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13014 (#13014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13010 (#13010).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13013 (#13013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12728 (#12728).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13004 (#13004).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12993 (#12993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12994 (#12994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12931 (#12931).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13003 (#13003).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13001 (#13001).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12785 (#12785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13000 (#13000).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11720 (#11720).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12971 (#12971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12928 (#12928).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12829 (#12829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12929 (#12929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12979 (#12979).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12982 (#12982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12984 (#12984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12980 (#12980).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12942 (#12942).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12973 (#12973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12974 (#12974).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12972 (#12972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12965 (#12965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12968 (#12968).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12970 (#12970).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12966 (#12966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12954 (#12954).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12755 (#12755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12716 (#12716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12912 (#12912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12957 (#12957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12290 (#12290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12955 (#12955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12916 (#12916).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12948 (#12948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12824 (#12824).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12625 (#12625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12787 (#12787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12907 (#12907).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12885 (#12885).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12943 (#12943).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12938 (#12938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12937 (#12937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12932 (#12932).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12890 (#12890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12924 (#12924).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12866 (#12866).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12889 (#12889).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12918 (#12918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12908 (#12908).

- Merge branch 'cran-1.0.0-1'.

- Merge tag 'v1.0.0-1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12913 (#12913).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12914 (#12914).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12851 (#12851).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12887 (#12887).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12858 (#12858).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12888 (#12888).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12884 (#12884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12751 (#12751).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12848 (#12848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12498 (#12498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12398 (#12398).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12878 (#12878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12859 (#12859).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12834 (#12834).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12844 (#12844).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12849 (#12849).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12847 (#12847).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11191 (#11191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12840 (#12840).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12698 (#12698).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12806 (#12806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12734 (#12734).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12835 (#12835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12812 (#12812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12832 (#12832).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12691 (#12691).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12810 (#12810).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12780 (#12780).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12575 (#12575).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12803 (#12803).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12791 (#12791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12754 (#12754).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12765 (#12765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12685 (#12685).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12770 (#12770).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12768 (#12768).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12769 (#12769).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12762 (#12762).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12759 (#12759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12753 (#12753).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12636 (#12636).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12496 (#12496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12745 (#12745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12740 (#12740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12738 (#12738).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12737 (#12737).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12736 (#12736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12731 (#12731).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12730 (#12730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12599 (#12599).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12678 (#12678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12725 (#12725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12724 (#12724).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12708 (#12708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12697 (#12697).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12705 (#12705).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12717 (#12717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12681 (#12681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12692 (#12692).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12694 (#12694).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12689 (#12689).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12690 (#12690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12671 (#12671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12679 (#12679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12288 (#12288).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12655 (#12655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12669 (#12669).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12653 (#12653).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12663 (#12663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12658 (#12658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12654 (#12654).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12637 (#12637).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12650 (#12650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12642 (#12642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12652 (#12652).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12639 (#12639).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12635 (#12635).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12629 (#12629).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12630 (#12630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12633 (#12633).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12603 (#12603).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12608 (#12608).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12554 (#12554).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12539 (#12539).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12516 (#12516).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12515 (#12515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12445 (#12445).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12456 (#12456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12467 (#12467).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12465 (#12465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12470 (#12470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12461 (#12461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12448 (#12448).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12436 (#12436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12421 (#12421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12424 (#12424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12401 (#12401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12409 (#12409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12370 (#12370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12405 (#12405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12393 (#12393).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12391 (#12391).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12352 (#12352).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12360 (#12360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12344 (#12344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12332 (#12332).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12305 (#12305).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12302 (#12302).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12282 (#12282).

- Merge branch 'cran-1.0.0'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12291 (#12291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12281 (#12281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12257 (#12257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12267 (#12267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12264 (#12264).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12271 (#12271).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12259 (#12259).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12269 (#12269).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12265 (#12265).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12260 (#12260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12266 (#12266).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12244 (#12244).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12240 (#12240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12123 (#12123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12221 (#12221).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12226 (#12226).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12238 (#12238).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12209 (#12209).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12206 (#12206).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12195 (#12195).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12194 (#12194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12193 (#12193).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12189 (#12189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12183 (#12183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12111 (#12111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12169 (#12169).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12056 (#12056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12167 (#12167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12173 (#12173).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12175 (#12175).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12163 (#12163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12157 (#12157).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12168 (#12168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12159 (#12159).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12165 (#12165).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12109 (#12109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12152 (#12152).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12162 (#12162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12160 (#12160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12156 (#12156).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12144 (#12144).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12150 (#12150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12143 (#12143).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12086 (#12086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12110 (#12110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11677 (#11677).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12135 (#12135).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12130 (#12130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12131 (#12131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12124 (#12124).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12121 (#12121).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12120 (#12120).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12119 (#12119).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12116 (#12116).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12099 (#12099).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12091 (#12091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12108 (#12108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12112 (#12112).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12081 (#12081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12077 (#12077).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11493 (#11493).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12072 (#12072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12098 (#12098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12094 (#12094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12090 (#12090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12087 (#12087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12088 (#12088).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11848 (#11848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12070 (#12070).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12085 (#12085).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12076 (#12076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12084 (#12084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12063 (#12063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12083 (#12083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12045 (#12045).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12026 (#12026).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12049 (#12049).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12068 (#12068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12064 (#12064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12055 (#12055).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12061 (#12061).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12044 (#12044).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12051 (#12051).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12050 (#12050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12054 (#12054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12052 (#12052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12053 (#12053).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12035 (#12035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12043 (#12043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11874 (#11874).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12039 (#12039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12028 (#12028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11998 (#11998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12030 (#12030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11984 (#11984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12029 (#12029).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11937 (#11937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12022 (#12022).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12027 (#12027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12025 (#12025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12011 (#12011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11867 (#11867).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11976 (#11976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11831 (#11831).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12013 (#12013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11965 (#11965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11978 (#11978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11987 (#11987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11982 (#11982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11994 (#11994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12012 (#12012).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12014 (#12014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12015 (#12015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11999 (#11999).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11761 (#11761).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11964 (#11964).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11969 (#11969).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11967 (#11967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11955 (#11955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11966 (#11966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11956 (#11956).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11929 (#11929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11920 (#11920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11441 (#11441).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11835 (#11835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11912 (#11912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11906 (#11906).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11918 (#11918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11806 (#11806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11902 (#11902).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11771 (#11771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11898 (#11898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11884 (#11884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11745 (#11745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11785 (#11785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11880 (#11880).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11879 (#11879).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11878 (#11878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11746 (#11746).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11812 (#11812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11794 (#11794).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11792 (#11792).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11788 (#11788).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11797 (#11797).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11846 (#11846).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11861 (#11861).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11524 (#11524).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11830 (#11830).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11829 (#11829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11825 (#11825).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11821 (#11821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11816 (#11816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11757 (#11757).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11795 (#11795).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11791 (#11791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11787 (#11787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11625 (#11625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11763 (#11763).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11774 (#11774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11777 (#11777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11765 (#11765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11596 (#11596).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11759 (#11759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11679 (#11679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11719 (#11719).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11717 (#11717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11736 (#11736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11732 (#11732).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11730 (#11730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11726 (#11726).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11733 (#11733).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11735 (#11735).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11702 (#11702).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11725 (#11725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11723 (#11723).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11721 (#11721).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11696 (#11696).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11716 (#11716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11711 (#11711).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11708 (#11708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11673 (#11673).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10978 (#10978).

- Merge branch 'cran-0.10.2'.

- Merge branch 'cran-0.10.2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11681 (#11681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11678 (#11678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11676 (#11676).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11674 (#11674).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11675 (#11675).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11665 (#11665).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11670 (#11670).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11671 (#11671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11668 (#11668).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11667 (#11667).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11663 (#11663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11616 (#11616).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11659 (#11659).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11656 (#11656).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11655 (#11655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11465 (#11465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11645 (#11645).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11650 (#11650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11648 (#11648).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11642 (#11642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11630 (#11630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11631 (#11631).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11614 (#11614).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11462 (#11462).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11515 (#11515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11619 (#11619).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11618 (#11618).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11622 (#11622).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11613 (#11613).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11601 (#11601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11512 (#11512).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11273 (#11273).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11551 (#11551).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11604 (#11604).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11587 (#11587).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11585 (#11585).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11580 (#11580).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11461 (#11461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11267 (#11267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11558 (#11558).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11528 (#11528).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11546 (#11546).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11544 (#11544).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11519 (#11519).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11525 (#11525).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11270 (#11270).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11496 (#11496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11513 (#11513).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11495 (#11495).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11506 (#11506).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11446 (#11446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11401 (#11401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11498 (#11498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11497 (#11497).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11247 (#11247).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11486 (#11486).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11408 (#11408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11464 (#11464).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11478 (#11478).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11466 (#11466).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11470 (#11470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11458 (#11458).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11358 (#11358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11402 (#11402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11399 (#11399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11443 (#11443).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11456 (#11456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11454 (#11454).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11429 (#11429).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11436 (#11436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11437 (#11437).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11418 (#11418).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11428 (#11428).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11424 (#11424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11414 (#11414).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11415 (#11415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11405 (#11405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11400 (#11400).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11397 (#11397).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11396 (#11396).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11392 (#11392).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11390 (#11390).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11360 (#11360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11356 (#11356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11372 (#11372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11369 (#11369).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11376 (#11376).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11343 (#11343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11252 (#11252).

- Merge branch 'cran-0.10.1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11347 (#11347).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11326 (#11326).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11313 (#11313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11340 (#11340).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11327 (#11327).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11321 (#11321).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11329 (#11329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11325 (#11325).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11314 (#11314).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11315 (#11315).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11318 (#11318).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11309 (#11309).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11320 (#11320).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11317 (#11317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11316 (#11316).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11306 (#11306).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11297 (#11297).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11304 (#11304).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10878 (#10878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11215 (#11215).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11286 (#11286).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11203 (#11203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11258 (#11258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11276 (#11276).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11233 (#11233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11220 (#11220).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11248 (#11248).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11257 (#11257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11243 (#11243).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11236 (#11236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11231 (#11231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11222 (#11222).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11139 (#11139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11223 (#11223).

- Merge branch 'cran-0.10.1'.

- Merge branch 'cran-0.10.1'.

- Merge pull request #124 from duckdb/b-34-56-58-59-60-83-conn-2.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11218 (#11218).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11214 (#11214).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11149 (#11149).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11172 (#11172).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11106 (#11106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11210 (#11210).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11171 (#11171).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11208 (#11208).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11201 (#11201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11182 (#11182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11205 (#11205).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11200 (#11200).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11199 (#11199).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11183 (#11183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11198 (#11198).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11185 (#11185).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11188 (#11188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11190 (#11190).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11177 (#11177).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11179 (#11179).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11174 (#11174).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11161 (#11161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11151 (#11151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11138 (#11138).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11132 (#11132).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11145 (#11145).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11141 (#11141).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11127 (#11127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11128 (#11128).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11130 (#11130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11136 (#11136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11114 (#11114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11108 (#11108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11111 (#11111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11093 (#11093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11083 (#11083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11103 (#11103).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11105 (#11105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11090 (#11090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11096 (#11096).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11094 (#11094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11091 (#11091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10976 (#10976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11017 (#11017).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11086 (#11086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11073 (#11073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11072 (#11072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11069 (#11069).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11056 (#11056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11064 (#11064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11057 (#11057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11031 (#11031).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11046 (#11046).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10984 (#10984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11035 (#11035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11043 (#11043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11034 (#11034).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11039 (#11039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11021 (#11021).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11020 (#11020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11011 (#11011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11002 (#11002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11008 (#11008).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11005 (#11005).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10997 (#10997).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10992 (#10992).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10993 (#10993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10994 (#10994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10998 (#10998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10983 (#10983).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10990 (#10990).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10948 (#10948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10955 (#10955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10972 (#10972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10987 (#10987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10985 (#10985).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10938 (#10938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10973 (#10973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10971 (#10971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10933 (#10933).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10594 (#10594).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10958 (#10958).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10957 (#10957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10949 (#10949).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10936 (#10936).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10946 (#10946).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10939 (#10939).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10937 (#10937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10945 (#10945).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10941 (#10941).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10944 (#10944).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10870 (#10870).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10925 (#10925).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10704 (#10704).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10923 (#10923).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10922 (#10922).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10920 (#10920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10918 (#10918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10915 (#10915).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10912 (#10912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10690 (#10690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10908 (#10908).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10828 (#10828).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10799 (#10799).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10898 (#10898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10909 (#10909).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10850 (#10850).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10873 (#10873).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10897 (#10897).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10896 (#10896).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10893 (#10893).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10890 (#10890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10864 (#10864).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10872 (#10872).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10884 (#10884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10882 (#10882).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10740 (#10740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10862 (#10862).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10863 (#10863).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10610 (#10610).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10597 (#10597).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10714 (#10714).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10855 (#10855).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10854 (#10854).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10446 (#10446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10848 (#10848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10742 (#10742).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10837 (#10837).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10774 (#10774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10789 (#10789).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10822 (#10822).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10817 (#10817).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10821 (#10821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10816 (#10816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10755 (#10755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10796 (#10796).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10807 (#10807).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10791 (#10791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10771 (#10771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10773 (#10773).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10777 (#10777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10776 (#10776).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10601 (#10601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10765 (#10765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10758 (#10758).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10658 (#10658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10642 (#10642).

- Merge pull request #103 from lnkuiper/namespace.

  Remove std:: from unordered_map

- Merge pull request #108 from Tmonster/fix_Rbuildignore.

  Fix invalid regex in .Rbuildignore

- Merge pull request #48 from olivroy/patch-1.

- Merge pull request #76 from romainfrancois/patch-1.

- Merge pull request #45 from duckdb/b-cpp11-printf.


# duckdb 1.1.3.9013

## Bug fixes

- Avoid compiler warning related to `Rboolean` (#594).

- Check `"duckdb.materialize_message"` symbol (#592).

- `%in%` works correctly as part of a `&` conjunction (#528).

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- Use portable format modifiers.

- Correctly compute vector length for data frames passed to relational functions (#379).

- Set `initialize_in_main_thread`, add patch.

- Compatibility with clang19 2.

- Compatibility with clang19.

- Uninitialized.

- Fix uninitialized move 5.

- Fix uninitialized move 4.

- Fix uninitialized move 3.

- Fix uninitialized move 2.

- Fix uninitialized move.

- Avoid triggering re2 in tests (#176).

- Correct usage of `win_current_group()` instead of `win_current_order()` in SQL translation (@lschneiderbauer, #173, #175).

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).

- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).

- Fix vendoring script without arguments, align.

- Don't run tests that invoke re2 by default (#121, #127).

- `dplyr::tbl()` works again when a Parquet or CSV file is passed instead of a table name (#38, #91).

- `DBI::dbQuoteIdentifier()` correctly quotes identifiers that start with a digit (#67, #92).

- Align the argument order of `dbWriteTable()` with the DBI specs (@eitsupi, #43, #49).

- Fix LTO builds.

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (@romainfrancois, #186).

- Xz-compress duckdb sources in the tarball (#530).

- Add `col.types` argument to `duckdb_read_csv()` (@eli-daniels, #383, #445).

- `last_rel` (#529).

- `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- Rethrow errors with rlang if installed (#522).

- Catch and add query context for statement extraction (tidyverse/duckplyr#219, #521).

- Implement query cancellation (#514, #515).

- Add comparison expression to relational api (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

- Bump vendored cpp11 to v0.5.0 (#382, #387).

- Tweak implementation of `r_base::sum()` (#381, #385).

- `n_distinct()` supports `na.rm = TRUE` with a single vector argument again (@lschneiderbauer, #204, #216).

- New `rel_from_sql()` (#212).

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

- Support fetching `MAP` type (#61, #165).

- Add dbplyr translations for `clock::date_count_between()` (@edward-burn, #163, #166).

- `round()` duckdb translation uses `ROUND_EVEN()` instead of `ROUND()` (@lschneiderbauer, #146, #157).

- New `sort` argument to `rel_order()` (@toppyy, #168).

- Add dbplyr translations for `clock::add_days()`, `clock::add_years()`, `clock::get_day()`, `clock::get_month()`, and `clock::get_year()` (#153).

- Use latest tests from DBItest (#148).

- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).

- Include rfuns extension (hannes/duckdb-rfuns#78, #144).

- Map `NA` to `SQLNULL` (#143).

- New `tbl_file()` and `tbl_query()` to explicitly access tables and queries as dbplyr lazy tables (#96).

- Initial ALTREP support for `LIST` logical type (@romainfrancois, #77).

- Update core to duckdb v0.10.0 (#90).

- New private `rel_to_parquet()` to write a relation to parquet (@Tmonster, #46).

- Update vendored sources to duckdb/duckdb@3c695d7ba94d95d9facee48d395f46ed0bd72b46 (#42).

- Add `prod()` translation for dbplyr (@m-muecke, #40).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Bump for pre-release.

- Keep `cleanup` files to accommodate different build scenarios (#536).

- Update vendored sources to duckdb/duckdb@19864453f7d0ed095256d848b46e7b8630989bac (#580).

- Update vendored sources to duckdb/duckdb@c3ca3607c221d315f38227b8bf58e68746c59083 (#579).

- Update vendored sources to duckdb/duckdb@9cba6a2a03e3fbca4364cab89d81a19ab50511b8 (#578).

- Update vendored sources to duckdb/duckdb@c6c08d4c1b363231b3b9689367735c7264cacefb (#577).

- Update vendored sources to duckdb/duckdb@7f34190f3f94fc1b1575af829a9a0ccead87dc99 (#576).

- Update vendored sources to duckdb/duckdb@78b65d4a9aa80c4be4efcdd29fadd6f0c893f1ce (#575).

- Update vendored sources to duckdb/duckdb@c31c46a875979ce3343edeedcb497485ca2fd751 (duckdb/duckdb#14542, #574).

- Update vendored sources to duckdb/duckdb@4ba2e66277a7576f58318c1aac112faa67c47b11 (#573).

- Update vendored sources to duckdb/duckdb@247fcb31733a5297c1070fbd244f2349091253aa (duckdb/duckdb#14601, #572).

- Update vendored sources to duckdb/duckdb@1a519fce83b3d262247325dbf8014067686a2c94 (duckdb/duckdb#14600, #571).

- Update vendored sources to duckdb/duckdb@b653a8c2b760425a83302e894bf930f18a1bdf64 (#570).

- Update vendored sources to duckdb/duckdb@79bf967e1b6ab438e0a83a014e937af571ed7acb (#569).

- Update vendored sources to duckdb/duckdb@4b62ee43a7d5f62313d77d36dec8aea29412431f (#568).

- Update vendored sources to duckdb/duckdb@3293c92b6e657084318f7556b14077896b333109 (#567).

- Update vendored sources to duckdb/duckdb@8664b710beb205ec6fc7e9f3d18dfe24dd28625f (#566).

- Update vendored sources to duckdb/duckdb@92a1ccbcef04dda11c85fa2bf6daf27daf8d9c49 (#565).

- Update vendored sources to duckdb/duckdb@2635a87a566b90e086caa84805019f66eedf0859 (#564).

- Update vendored sources to duckdb/duckdb@0d5ec0057838081251b388726353f09cba9577ad (#563).

- Update vendored sources to duckdb/duckdb@6af32330b51af4d72d3fed665bfc03f78c8b3876 (#562).

- Update vendored sources to duckdb/duckdb@662b0b34eaaf7f52545638cbc87c10e32b33834d (#561).

- Update vendored sources to duckdb/duckdb@bccd37ae7ea09f77b6299165bf80bca3bc1efc7c (#560).

- Update vendored sources to duckdb/duckdb@5090b7396173069bb0d51b0e1341cfa9950c154f (#559).

- Update vendored sources to duckdb/duckdb@f5ebc9b8e1d6c040a2276e0ac4a41d6bf9475880 (duckdb/duckdb#14545, #558).

- Update vendored sources to duckdb/duckdb@b8c5248b9c18f7cafbdf7992421662adbd95bf38 (#557).

- Update vendored sources to duckdb/duckdb@dfdd7968262d912910d8249bde3524e068c67713 (#556).

- Update vendored sources to duckdb/duckdb@d0673165b52e89fe70d1891504e4dea82adeca85 (#555).

- Update vendored sources to duckdb/duckdb@d79e66bd032dbd2066c16a88f517f6da1cd0aa78 (#554).

- Update vendored sources to duckdb/duckdb@0359726be957673a62ab1ab61f1cca9ba5667386 (#553).

- Update vendored sources to duckdb/duckdb@10c42435f1805ee4415faa5d6da4943e8c98fa55 (#552).

- Update vendored sources to duckdb/duckdb@43d26298affa89bc6ca829a1defc4819b42b6fb4 (#551).

- Update vendored sources to duckdb/duckdb@52b43b166091c82b3f04bf8af15f0ace18207a64 (#550).

- Update vendored sources to duckdb/duckdb@0446ab42e96b6269e78f55293f4096fa10224837 (#549).

- Update vendored sources to duckdb/duckdb@ceb77af7935c3c7a4a34e1199abd4d6ea080448c (duckdb/duckdb#14430, #548).

- Update vendored sources to duckdb/duckdb@aed52f5cabe34075c53bcec4407e297124c8d336 (#547).

- Update vendored sources to duckdb/duckdb@e41a881658ae579cedebe19c5070dad660086aea (#546).

- Update vendored sources to duckdb/duckdb@98d4ad28be35cf5c37e18760e76d11bc07be1ab4 (#545).

- Update vendored sources to duckdb/duckdb@1bb332c9c59a9d15b196b4486a6d1ffcaa833ba5 (#544).

- Update vendored sources to duckdb/duckdb@0bbfe09937e3744325f3b2dfdb182e9ac1ff916f (#543).

- Update vendored sources to duckdb/duckdb@08969b4677534b6870bff4c99998c753a6e784fc (#542).

- Update vendored sources to duckdb/duckdb@4756244efa04d204be6f20d55036fc503b7ed49c (#541).

- Update vendored sources to duckdb/duckdb@217ec4722e949eaa49568bd707e49431ef727ab5 (#539).

- Move responsibility for removing CR (#533).

- Terminate all sources with newline (#531).

- Sync duckplyr tests (#527).

- Cleanup, preparation (#525).

- Bump version.

- Update vendored sources (tag v1.1.2) to duckdb/duckdb@f680b7d08f56183391b581077d4baf589e1cc8bd (#510).

- Update vendored sources to duckdb/duckdb@5f49126b92a0899a2049aaa57da886138c5f879d (#509).

- Update vendored sources to duckdb/duckdb@2c21eb1c2eec3a1e359d87fb2a2cd8e427dc03c1 (#508).

- Update vendored sources to duckdb/duckdb@cc067e6b7db33f516437567cbc726536e34ed716 (#507).

- Update vendored sources to duckdb/duckdb@d2dfc6090685470cb09326a7530066fc4b3db42a (#506).

- Update vendored sources to duckdb/duckdb@56e2e0e5721b8547f564fccf252db0ba93c85471 (#505).

- Update vendored sources to duckdb/duckdb@35dfcc06e6c76ad6bd8e4acdae1bcc30751777eb (#504).

- Update vendored sources to duckdb/duckdb@92e0964376a78f990408a0e81af155504b35d27c (#503).

- Update vendored sources to duckdb/duckdb@01e6e98e3875ed12cbcb9257f81844743b1665fa (#502).

- Update vendored sources to duckdb/duckdb@6dc2e9375870e60f82becb1cece4cc878289d3b8 (#501).

- Update vendored sources to duckdb/duckdb@52b19d5ece35be344830800db0e4961f47114aa9 (#500).

- Update vendored sources to duckdb/duckdb@0d3e84330e845ceefdc55a36d52ef0296af5d1e1 (#499).

- Update vendored sources to duckdb/duckdb@d0cf23ead54f191bf2518598edf04e209f07452e (#498).

- Update vendored sources to duckdb/duckdb@d57a94430e50263cbd1b719b984da189e5bba0c5 (#497).

- Update vendored sources to duckdb/duckdb@a5ddffef692c0627dd6c7efaed7cf65148321452 (#496).

- Update vendored sources to duckdb/duckdb@536f979f69b1bbe40d582450b6cfa6a68463f172 (#495).

- Update vendored sources to duckdb/duckdb@443380a11dbb31a1c218a759ec0c3b56880f1c38 (duckdb/duckdb#14249, #494).

- Update vendored sources to duckdb/duckdb@7919e4abc5597dc4fbeb5a19dff19ff69b5c4113 (duckdb/duckdb#14249, #493).

- Update vendored sources to duckdb/duckdb@52f967a42861032fd5f4392609afc195cd025dde (#492).

- Update vendored sources to duckdb/duckdb@1f20676c7d997fe4964a8b51378bf984e53a4b4c (#491).

- Update vendored sources to duckdb/duckdb@8cec9b1537f900e7a644e7b466ea899cf1ca8f8f (#490).

- Update vendored sources to duckdb/duckdb@4f0cd4d60035e8c6afafed47b68b2240b39e3566 (duckdb/duckdb#14212, #489).

- Update vendored sources to duckdb/duckdb@5a9a382a573b107a38f5ee277619b362d5079c32 (#488).

- Update vendored sources to duckdb/duckdb@123b82b9053c4843559035b6723c867b2618b2d9 (#487).

- Update vendored sources to duckdb/duckdb@405e15fcde8a4da4a7c6d3889f992f0a363c05f2 (duckdb/duckdb#14232, #486).

- Update vendored sources to duckdb/duckdb@0e398d95c50ae40730467c53922c8fb8d5c69f90 (#485).

- Update vendored sources to duckdb/duckdb@1eac05ecd3a6b8ec2cdf0c53ccece7ca2effef26 (#484).

- Update vendored sources to duckdb/duckdb@048f5ffcec9c1a4b73cbfbd4158cd5b6669f102b (#483).

- Update vendored sources to duckdb/duckdb@0b2d95601c2d9474f2c823ac3363e9ca14224c7c (#482).

- Update vendored sources to duckdb/duckdb@350d061846ed7e4c96d2efa7b523bb97ae84538a (#481).

- Update vendored sources to duckdb/duckdb@2f6b78c21d1634c7228e00c809a790701705c82b (#480).

- Update vendored sources to duckdb/duckdb@8aca4330ac46be3950c6b12e29040322dd245b7a (#479).

- Update vendored sources to duckdb/duckdb@9931d723ccde2b2435b1a927234338e6f0353d90 (#478).

- Update vendored sources to duckdb/duckdb@d896e73fe2db62b6749b95e30faa8bfa41dc4d32 (#477).

- Update vendored sources to duckdb/duckdb@f8c82ab2620f8066b0141df0c3982885a5258746 (#476).

- Update vendored sources to duckdb/duckdb@ee256eb45552601db71d4cad7a5cd4f46f0d5a1d (#475).

- Update vendored sources to duckdb/duckdb@130aab3f9ddb84e0c6e7f543a99881d8fc1bd6b7 (#474).

- Update vendored sources to duckdb/duckdb@92c65a4341c57f313dbeba5acc7b1fb917808010 (#473).

- Update vendored sources to duckdb/duckdb@47e1d3d60b4d6d075cf88c2707572df12a630a3a (#472).

- Update vendored sources to duckdb/duckdb@45559f5eeb1834454a30490fc4ffad1807e13f3b (#471).

- Update vendored sources to duckdb/duckdb@dfdd09f46c0169c9d8aa5381086e46a66e44fabc (#470).

- Update vendored sources to duckdb/duckdb@89828abb72219957372f316da06f007dadd2a9aa (#469).

- Update vendored sources to duckdb/duckdb@12e9777cf6283f44710b2610ba3d3735a1208751 (duckdb/duckdb#14077, #468).

- Update vendored sources to duckdb/duckdb@4a55e2334232afe94e47ab398ddb44f88fcd6658 (#467).

- Update vendored sources to duckdb/duckdb@0f3c46215feb0fb92d4998977fc31b2f52db6b14 (#466).

- Update vendored sources to duckdb/duckdb@c87246586490b442706d0be66b82d71930a00578 (#465).

- Update vendored sources to duckdb/duckdb@cd8cb3f1c81a74a3b2c1ed7d94e3913485895074 (#464).

- Update vendored sources to duckdb/duckdb@acd16816e31789bdb27e144ccd19ddb9da4fe6df (#463).

- Update vendored sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove uninitialized warnings.

- Document (#456).

- Update vendored sources (tag v1.1.1) to duckdb/duckdb@af39bd0dcf66876e09ac2a7c3baa28fe1b301151 (#454).

- Update vendored sources to duckdb/duckdb@0fe7708eef6b9b77270ca21cb9b5e30a3de84e3c (#453).

- Update vendored sources to duckdb/duckdb@34a3acc6b3354be86fe593d09e0702ab5eafe757 (#452).

- Update vendored sources to duckdb/duckdb@cb2a947e9df4f6c40b6dd5751c412d6946cbb62b (#451).

- Update vendored sources to duckdb/duckdb@64520f224d8a0a096cfe10f0c2cfbd1ac9457811 (duckdb/duckdb#13934, #450).

- Update vendored sources to duckdb/duckdb@b0eee44df70eb7bf9efac5f65dd2eaf7ad1e5403 (#449).

- Update vendored sources to duckdb/duckdb@4fe3dc559d10648691f9ab34f20207771890dd45 (#448).

- Update vendored sources to duckdb/duckdb@6c02032393583f353f2f2a0337a8e16f34dc5d82 (duckdb/duckdb#14026, #447).

- Update vendored sources to duckdb/duckdb@4ce455c84029195ffa4c3e540c10360ae8c73724 (#446).

- Update vendored sources to duckdb/duckdb@03dd0df6185d903ecbff9d80017e5449e78e5017 (#443).

- Update vendored sources to duckdb/duckdb@d1037da3139de90dc0a82df746d8ce92a50d9838 (#442).

- Update vendored sources to duckdb/duckdb@cb27c0423fa7107674c267b5de8eb93dd603cb69 (duckdb/duckdb#13993, #441).

- Update vendored sources to duckdb/duckdb@b787fcc1cb9bc4daf36e6eec19c1e9b2b162f4b0 (duckdb/duckdb#14020, #440).

- Update vendored sources to duckdb/duckdb@0ce863113043806780e776bcfb86b24afcb0263c (#439).

- Update vendored sources to duckdb/duckdb@f9e96b191088e65b4a1f95918312c40e31096dd9 (#438).

- Update vendored sources to duckdb/duckdb@2ff9c687e2c448914a28c59bd50f48f54e47de3c (#437).

- Update vendored sources to duckdb/duckdb@dcc302aef4491db8cc2efd2955ac254a4d62dcbc (#436).

- Update vendored sources to duckdb/duckdb@03976af191370d4020c172a82b28ca7885d98ea3 (#435).

- Update vendored sources to duckdb/duckdb@29c46243993319b0db24509c862126b8e17f1e8c (#434).

- Update vendored sources to duckdb/duckdb@e7da966e87539457f3de94a1bee288861fdca6d6 (#433).

- Update vendored sources to duckdb/duckdb@44bba02cea5d316e38f6edbad7fad3a1f913d63f (#432).

- Update vendored sources to duckdb/duckdb@04a1f750a6fab3f1a9cf3fb7cce5fd119c522304 (#431).

- Update vendored sources to duckdb/duckdb@0da70d9de97ff2cf39ad99b9e30b7e6cb91614b8 (duckdb/duckdb#13933, #430).

- Update vendored sources to duckdb/duckdb@df82a0e2c47e8b3ddd5a93e08530b83bc49e0da0 (#429).

- Update vendored sources to duckdb/duckdb@86723c9912fde7b76d3863b2ccd2d4333251c4af (#428).

- Update vendored sources to duckdb/duckdb@66d8ed93f67a00006ec99226c1205bcffb1ef07b (duckdb/duckdb#13941, #427).

- Update vendored sources to duckdb/duckdb@b2f68017070c1910dd3438f9428c7162cb428f84 (#426).

- Update vendored sources to duckdb/duckdb@35a104529b56c4f4f1e383e2ead26d6047d3442e (#425).

- Update vendored sources to duckdb/duckdb@b8c5fa937919631b759a70e33f068aa05de8bd36 (#424).

- Update vendored sources to duckdb/duckdb@18670a10f1b3da56382e272518d6b149e489ca51 (#423).

- Update vendored sources to duckdb/duckdb@0b0c95b9dc685e1a6ca011d8e086d885afbe0398 (#422).

- Update vendored sources to duckdb/duckdb@e5e1595da75ea01559f2b4bc9531505422b7fcdc (duckdb/duckdb#13585, #421).

- Update vendored sources to duckdb/duckdb@75d4bd0cc759dcb609ab349b87bff07dddf2ebb7 (#420).

- Update vendored sources to duckdb/duckdb@c0f29465624aaa1472ee05d4723415cfa1bfbdf9 (#419).

- Update vendored sources to duckdb/duckdb@b369bcb4e08235e52866a5f8afb7e172fe573287 (#418).

- Update vendored sources to duckdb/duckdb@414207f2120ad9019b416cf891947004c74c7347 (#417).

- Update vendored sources to duckdb/duckdb@38ceb86f1aa4cfae7c993f59de19e0cfee7ff68e (#416).

- Update vendored sources to duckdb/duckdb@0dbb79e8de897b4a710ed53becc063bcdf80884d (duckdb/duckdb#13824, #415).

- Update vendored sources to duckdb/duckdb@9af117f0e6d3f2f9ade385dadc46807c1b388dd4 (#414).

- Update vendored sources to duckdb/duckdb@88a4c1e5893f316d763343d7f66f57917b065f50 (#413).

- Update vendored sources to duckdb/duckdb@d93225aab5c8e0da34776398358373f4c0232864 (duckdb/duckdb#13872, #412).

- Update vendored sources to duckdb/duckdb@8c2ee1eb7987a981cdf4bb1ed52683784a26e3bf (duckdb/duckdb#13880, #411).

- Update vendored sources to duckdb/duckdb@081a748340c4fcd3b3652230a02432afae72bbb3 (#410).

- Update vendored sources to duckdb/duckdb@bc7683e100867fae06c1f65e055df403c2ee25cf (#409).

- Update vendored sources to duckdb/duckdb@b87545985fc03e43baf84d9554eab23ea4b21f6c (#408).

- Update vendored sources to duckdb/duckdb@1d7e05c9737821fdb2c8eba996642c9953de52f6 (#407).

- Update vendored sources to duckdb/duckdb@b383f3668095fac2574bc6a0c417047a6fe80c9f (#406).

- Update vendored sources to duckdb/duckdb@039a262ae9805f30690ae1c8ec6a7fb27812c1b5 (#405).

- Update vendored sources to duckdb/duckdb@d697acfb108f6ec1b1ed26f0062445e1d49ee1c4 (#404).

- Update vendored sources to duckdb/duckdb@dfbfdef89aad145dc9d81c275bc2c9fad4062bed (#403).

- Update vendored sources to duckdb/duckdb@c41ae2cb6e2390b9656ac2d22885df0572a87796 (#402).

- Update vendored sources to duckdb/duckdb@d066254185fa56ec851183e9178edb04ae34c0b9 (#401).

- Update vendored sources to duckdb/duckdb@5fd2501220b80adaddf009b78cac44b97813258c (#400).

- Update vendored sources to duckdb/duckdb@6d9d429d5e7f464b69671b46dcbc99a6e46378df (#399).

- Update vendored sources to duckdb/duckdb@d9e89b5cc192ea052f038d8e7b26d253ec81bc49 (#398).

- Update vendored sources to duckdb/duckdb@95038c5eee75f733c99193c66c3faa7289d6f599 (#397).

- Update vendored sources to duckdb/duckdb@8d1c2b29badfcc55246829e00e97b86b38b3606a (#396).

- Update vendored sources to duckdb/duckdb@329bb5393b686421b40261211354f4d77cac1633 (#395).

- Update vendored sources to duckdb/duckdb@403f0fc6459fc5a1f185350d30eafa555c145d1f (#394).

- Update vendored sources to duckdb/duckdb@6a197b22652d02749c3e755e75b10d75e7ad6b75 (#393).

- Show file sizes (#380, #391).

- Fix stripping call (#380, #390).

- Move stripping logic to `install.libs.R` (#380, #389).

- Strip binary if requested (#380, #386).

- Update vendored sources to hannes/duckdb-rfuns@4fccc0b6e577f5b32c84d03cd79cb9fd9827212b (#378).

- Bump.

- Update vendored sources (tag v1.1.0) to duckdb/duckdb@fa5c2fe15f3da5f32397b009196c0895fce60820 (#377).

- Update vendored sources to duckdb/duckdb@fc21edf1508fa785a0ce06ffd245fe30b20eefe0 (#376).

- Update vendored sources to duckdb/duckdb@1d3fc5aec6b846c563d6d99c96df7c30117b5a94 (#375).

- Update vendored sources to duckdb/duckdb@893d007e64df94658d4da92c02698559f89d2072 (#374).

- Update vendored sources to duckdb/duckdb@64bacde85e4c24134cf73f9b4ed3ae362510f287 (#373).

- Update vendored sources to duckdb/duckdb@93494bd74d30f7ae11456dcee6c5e5143be58606 (#372).

- Update vendored sources to duckdb/duckdb@f76d6f2e7e170d6434e2725f43bac5ede31985fa (#371).

- Update vendored sources to duckdb/duckdb@310176118d5dc9897fb752bda145ee9dca628240 (#370).

- Update vendored sources to duckdb/duckdb@c1183d72ed9b388fdc894e86f7e999b2ba8301e5 (#369).

- Update vendored sources to duckdb/duckdb@d454d2458646151fc89c60639f0c50cecf1f4ebd (#367).

- Update vendored sources to duckdb/duckdb@0e6dacd8932c22f9d383b8047fb11aad59564895 (#363).

- Update vendored sources to duckdb/duckdb@4d18b9d05caf88f0420dbdbe03d35a0faabf4aa7 (#362).

- Update vendored sources to duckdb/duckdb@c4940720ce2ee93f39f6d80ceb25a729718a6828 (#361).

- Update vendored sources to duckdb/duckdb@421acb0f7c924216bc689f3731d7a971e7e4fa2b (#360).

- Update vendored sources to duckdb/duckdb@7c988cf7bf417d6534f0ae60f6e0297ef22cd18a (#359).

- Update vendored sources to duckdb/duckdb@dd3cbcee009bf664e3a9bce2467c8af6d2bc53d2 (#358).

- Update vendored sources to duckdb/duckdb@95a9fe9f2681175788ac85dfe67a370ef9b6f32d (#357).

- Update vendored sources to duckdb/duckdb@756d4fcb624c2c180969630b11d44380704a871a (#356).

- Update vendored sources to duckdb/duckdb@450b7e45d9e717d2c475995dabbde47b5acdfc4a (#355).

- Update vendored sources to duckdb/duckdb@dffc4ffad7d9cb7c181db87b1bfb51e261bcedf6 (#354).

- Update vendored sources to duckdb/duckdb@a6e32b115826ba543e32a733cb92f68fd0549186 (#353).

- Update vendored sources to duckdb/duckdb@1f01ef8781c8a3edf192286e0044ff37f043fb47 (#352).

- Update vendored sources to duckdb/duckdb@9aa68025b1ddf0deba9e7caf17cd0dbe4abd7206 (#351).

- Update vendored sources to duckdb/duckdb@7a7547f5da232111d52c4afb05e98e19fd8c7e31 (#350).

- Update vendored sources to duckdb/duckdb@fa2daf7a09e477e30e53b4cc8f4269c39eaf62ef (#349).

- Update vendored sources to duckdb/duckdb@a65fc4ed0847cb073231ba2be21bbd8515b91171 (#348).

- Update vendored sources to duckdb/duckdb@1844ae51091ee85c9194036405abd561ff9b58ae (#347).

- Update vendored sources to duckdb/duckdb@439bb91fc33e8bc45cc6e6d73c823ab44b48876d (#346).

- Update vendored sources to duckdb/duckdb@9067c648ef182084b3159b72213097505d5b5cab (#345).

- Update vendored sources to duckdb/duckdb@a05e81d31b178bd41ff4fb3aa46c30fe2a7068e5 (#344).

- Update vendored sources to duckdb/duckdb@74c9f4df1fe5c3f39007aa38c112cb7582f91302 (#343).

- Update vendored sources to duckdb/duckdb@e90611400749d641a07dbcd5f10df85d99813f33 (#342).

- Update vendored sources to duckdb/duckdb@902af6f21cf5e15979ecab02f15223a0f9a0baff (#341).

- Update vendored sources to duckdb/duckdb@6f9795184545d841a35e75b938f78a1e0520bd8f (#340).

- Update vendored sources to duckdb/duckdb@67b69b0c6e9411a2755baffa2305000dae887937 (#339).

- Update vendored sources to duckdb/duckdb@18e97dd88525d42c5de9faf6d1a89b90590c94fe (#338).

- Update vendored sources to duckdb/duckdb@37a55bdf6665705eb6be311bc61fa8a2f2b900fe (#337).

- Update vendored sources to duckdb/duckdb@0d37df84df6c0226423eda80d2adce9b6fdf1eea (#336).

- Update vendored sources to duckdb/duckdb@2355a5bd10fe6ae24b0b7604a66b78d6c657c104 (#335).

- Update vendored sources to duckdb/duckdb@206320c56140238066fdfca3aa503ec09f7cb2bd (#334).

- Update vendored sources to duckdb/duckdb@40c9c5a5f9b54dcaf75c45ecaa311ec478721559 (#333).

- Update vendored sources to duckdb/duckdb@379a80032a96a454190c4d2f524898ecad8fec89 (#332).

- Update vendored sources to duckdb/duckdb@20100aa2560b68b2f0b46bdc07877a96ed270959 (#331).

- Update vendored sources to duckdb/duckdb@5896c638099998449f06ce1a61e6c01045ba4a7f (#330).

- Update vendored sources to duckdb/duckdb@1a2791b7b415ee41e2285e298ee97f37caf9eeeb (#329).

- Update vendored sources to duckdb/duckdb@01c5bed3c2235171f59527832b1d41fc4a669219 (#328).

- Update vendored sources to duckdb/duckdb@686bcd10b3d617b8a00c41505ab1a97d8c53319f (#327).

- Update vendored sources to duckdb/duckdb@2e78e027dbc812e301088cb72aec80025af0b7a2 (#326).

- Update vendored sources to duckdb/duckdb@4b8274729b3037ce1c3528e90896aa3f6d94559b (#325).

- Update vendored sources to duckdb/duckdb@de5f77c08b5c37afc511e581212639050be2c691 (#324).

- Update vendored sources to duckdb/duckdb@7691b57aa1ef638c4b825c388b1bd2877a4e8ec4 (#323).

- Update vendored sources to duckdb/duckdb@b881dc1265f222e0de23403d8b3c155e8a0c5f17 (#322).

- Update vendored sources to duckdb/duckdb@2be970dda0e5047b1075f938691455d63ba63a67 (#321).

- Update vendored sources to duckdb/duckdb@573bedb4c23ae67248fa7545c5af6f455b9523a8 (#320).

- Update vendored sources to duckdb/duckdb@892f631d24711e3911e8bac2baca66ebf07d9edb (#319).

- Update vendored sources to duckdb/duckdb@ea6f5c4e0903ebfe171969a214c19b77ccb7f7e8 (#318).

- Update vendored sources to duckdb/duckdb@0af71afe6c3e932c1f55b29418c3aef8eebf671f (#317).

- Update vendored sources to duckdb/duckdb@48a8b81d5264adae02777b80b73d69be6ea6aa36 (#316).

- Update vendored sources to duckdb/duckdb@5f4af5343a4f09c3ba184a171bbcf9abd9c8b139 (#315).

- Update vendored sources to duckdb/duckdb@0e6f3fb91a072d370eb81d200cff4ba952bf20f2 (#314).

- Update vendored sources to duckdb/duckdb@5bdb091a5d67460da3ca3a89f21b7cdc588d4544 (#313).

- Update vendored sources to duckdb/duckdb@6e24bb278d11538e46ce69446cd2849d331bc7a4 (#312).

- Update vendored sources to duckdb/duckdb@b1bae91af9cbf8443b69aa851accba42657fb3fb (#311).

- Update vendored sources to duckdb/duckdb@bb5f35c7af618d7636a1f61b26aa6a5c60b0d88a (#310).

- Update vendored sources to duckdb/duckdb@4cabb03b151deb6aec8b14a2496f1b2d9031574a (#309).

- Update vendored sources to duckdb/duckdb@dd2f87c0e2038e3bbfffecd904f407b80f298212 (#308).

- Update vendored sources to duckdb/duckdb@729468452530e898b34a9eec3b48574f8f6fe70e (#307).

- Update vendored sources to duckdb/duckdb@afecd99dbbcf9dec503ffffd2b9fefb8d9d826bd (#306).

- Update vendored sources to duckdb/duckdb@8eff1500c78807d6ff6f4cac99d799da27ff0f2b (#305).

- Update vendored sources to duckdb/duckdb@87ba8503f2a2d53284d0cde88e52df39959eeffa (#304).

- Update vendored sources to duckdb/duckdb@58fe5162afadc1a9b52cc095a86ad1769d3e9384 (#303).

- Update vendored sources to duckdb/duckdb@536fb3b02b0f0e436eb0b1345ae4b155c2993fa4 (#302).

- Update vendored sources to duckdb/duckdb@de92c08cb0585ccb364c3daf0b7e251841dc088b (#301).

- Update vendored sources to duckdb/duckdb@7d2a6d0332ca85730220c926fe8d2330ed2cb6cd (#300).

- Update vendored sources to duckdb/duckdb@13ace3f6ccbd81fa1f66a467583aab10bd888496 (#299).

- Update vendored sources to duckdb/duckdb@69afac464d1f0de4dedab96e26fec05d5b8118c8 (#298).

- Update vendored sources to duckdb/duckdb@e08c0bf105c2ad3d1a6445488182aedf680306e6 (#297).

- Update vendored sources to duckdb/duckdb@567bdebcba6e58da96ceb9465505a38a6c60e69f (#296).

- Update vendored sources to duckdb/duckdb@47715960b6ce0b724d9d061addbc85d0397367bf (#295).

- Update vendored sources to duckdb/duckdb@de13238537197a5e23b3450e8c931844034ca047 (#294).

- Update vendored sources to duckdb/duckdb@c84676023c279bfec3441657d54baaef499276f5 (#293).

- Update vendored sources to duckdb/duckdb@610d79431c7aeccb0d6a4cf9ce2c04a4a96d2f63 (#292).

- Update vendored sources to duckdb/duckdb@dabc6df8f5608453f2da1e23b16d55d6df2aaf52 (#291).

- Update vendored sources to duckdb/duckdb@8226769114e16a3cb42d38bfe58c218a9009b1a3 (#290).

- Update vendored sources to duckdb/duckdb@3897524b31f668ce73fef0b1e63c2a7e6e58cbb1 (#289).

- Update vendored sources to duckdb/duckdb@226c56b7dff9174ce54c83b907d59bca35363040 (#288).

- Update vendored sources to duckdb/duckdb@4d8693be1a39e3cb4c1ce42d6bc64978a5f6e7be (#287).

- Update vendored sources to duckdb/duckdb@35346d87637d8e6731ec1fcd1909c4a309a6d6ad (#286).

- Update vendored sources to duckdb/duckdb@f94b8acedb26d606691c62b3a80ee3ab45eb4ad3 (#285).

- Update vendored sources to duckdb/duckdb@42c504b821beba03867241dde68e9408a9740806 (#284).

- Update vendored sources to duckdb/duckdb@a6b5523b3a55961b282c20fe2704ec955a311069 (#283).

- Remove hotfix.

- Update vendored sources to duckdb/duckdb@56619faf054a284b88317a811d8f0cab0fe0974a (#281).

- Update vendored sources to duckdb/duckdb@8ecc90c8d60ce446f227fad40fe8fbafdaf2b4e1 (#280).

- Update vendored sources to duckdb/duckdb@0d612daeec725915c1b3083a6a8f5e854f424fb2 (#279).

- Update vendored sources to duckdb/duckdb@798f5a2ba0ddf1d849355293cd5d7debb2dc9e9a (#278).

- Update vendored sources to duckdb/duckdb@b32a97a77241fcd3fb29ac6b007035d8d733e8fc (#277).

- Update vendored sources to duckdb/duckdb@f683023d703649b6a813e6f4d5aaf2d329c58a72 (#276).

- Update vendored sources to duckdb/duckdb@7f3889c389b2e6e7111c2963c4cca1685de5e791 (#275).

- Update vendored sources to duckdb/duckdb@5819112b7e6480c377255ccab6f4e1657730b5fe (#274).

- Update vendored sources to duckdb/duckdb@9ed561eee5afc2242f73de5ea9c8cf1422c32a40 (#273).

- Update vendored sources to duckdb/duckdb@f0dbafd48f62dbd6ec1c763dd38bab2a611dac43 (#272).

- Update vendored sources to duckdb/duckdb@18c5431edff65f2260874a0a7290cd10069f9e59 (#271).

- Update vendored sources to duckdb/duckdb@f97ad19a296aa6f37e24a23a7ea2cdb87ebe6813 (#270).

- Update vendored sources to duckdb/duckdb@7abb7065d6a924f87d8cd7e61f3c1a488b825554 (#269).

- Update vendored sources to duckdb/duckdb@6aa0ab01b0e0cd008a2331a7deba1f6c7dc190fa (#268).

- Update vendored sources to duckdb/duckdb@8c1ef04afaad4e9901e714e76a22a4ecd7f96b10 (#267).

- Update vendored sources to duckdb/duckdb@e1c738e7e29e7f105d5c4a67df7a44bc2f3dc909 (#266).

- Update vendored sources to duckdb/duckdb@cdf7125edb568360896cc4ae01f7e52ece68020a (#265).

- Update vendored sources to duckdb/duckdb@16193a714ebac04fa89d0074b1c4d42e62e9fb61 (#264).

- Update vendored sources to duckdb/duckdb@285553fe3e6962bc2be7a69486e7f1bb223f8f1b (#263).

- Update vendored sources to duckdb/duckdb@e5d994bbc6c3e158264af3156f71e7f0340a1d0c (#262).

- Update vendored sources to duckdb/duckdb@627a70286b70dc6b3c35c2f5f4ebea0552f7c6e8 (#261).

- Update vendored sources to duckdb/duckdb@862852fa395b99735e5713cb55d0cea1d9320659 (#260).

- Update vendored sources to duckdb/duckdb@ecb8dc908b1fc97ed6255284701de8c57a9f8c39 (#259).

- Update vendored sources to duckdb/duckdb@b33069bb4ec5ed1e369a260efdb2aab60fa5ec79 (#247).

- Update vendored sources to duckdb/duckdb@9ad037f3adfe372f17b5178a449ac4b6f9142240 (#246).

- Update vendored sources to duckdb/duckdb@1345b3013e801be526e7fac8c8984c89b0033d6a (#245).

- Update vendored sources to duckdb/duckdb@bb97c95a1ad2c277fcf2a60bb1a8af4b0f29b6c7 (#244).

- Update vendored sources to duckdb/duckdb@26685b133edd712ef62e74dbf25ea611e1cf91dc (#243).

- Update vendored sources to duckdb/duckdb@513c2f22c0923045179a8800edf72d212a9bf682 (#242).

- Update vendored sources to duckdb/duckdb@fe535b02b3b8d2b3ac7660134fd588848be9e859 (#241).

- Update vendored sources to duckdb/duckdb@b371fc1b9a8960af25205a85ea89b381e1f98705 (#240).

- Update vendored sources to duckdb/duckdb@c4b6b8f3543bf440d4149a824eed118e4e54c4be (#239).

- Update vendored sources to duckdb/duckdb@10ea4832d3f1850685a65369e0b19c27ec81e638 (#238).

- Update vendored sources to duckdb/duckdb@f6a8ec460ae23e20e6f52859c32c96012dcc0b13 (#236).

- Update vendored sources to duckdb/duckdb@8d4a30cf72c2695c15bed2ec69b5a5bc56a5a594 (#235).

- Update vendored sources to duckdb/duckdb@367aa8db1cc622c46661d762f9cafdd88263040e (#234).

- Update vendored sources to duckdb/duckdb@3d85a139fe1f4c78284a0e8cde522a38f2bcde0a (#233).

- Update vendored sources to duckdb/duckdb@a4f0adb1cf051f6ec4d58326ccf4fc3d3f333d35 (#232).

- Update vendored sources to duckdb/duckdb@ad4639ed1a3448e0c7383d8601d3b797a1861c86 (#231).

- Update vendored sources to duckdb/duckdb@b8df1598853d55f4421bb72dd3d86db553e897b4 (#230).

- Update vendored sources to duckdb/duckdb@f5048f0ffd25b9d1d67b1a68f75ac435c9f5cbfa (#229).

- Update vendored sources to duckdb/duckdb@ac8efca3fc3bc1fa277a0ca32104e2e861b6eef5 (#228).

- Update vendored sources to duckdb/duckdb@c2e18955aff66454aa3ab5b39abd6f3c90f8010b (#227).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#226).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#220).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#219).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#218).

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10430870381

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425609276

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425483466

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10223714659

- Remove temporary patch.

- Enable creation of compilation database.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9879707346

- Adapt glue code.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9727972793

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9692337257

- Fix rfuns vendoring.

- Add another brotli patch.

- Brotli patch and compilation flags.

- Update vendored sources (tag v1.0.0) to duckdb/duckdb@1f98600c2cf8722a6d2f2d805bb4af5e701319fc.

  🦆

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources to hannes/duckdb-rfuns@397ab2a5efa254ea71e45f92b1346e2de6617d59.

- `n_distinct()` followup (@lschneiderbauer, #158).

- Improve yyjson patch.

- Add yyjson patch.

- Format.

- Adapt to `shared_ptr` changes.

- Add patch.

- Update vendored sources (tag v0.10.2) to duckdb/duckdb@1601d94f94a7e0d2eb805a94803eb1e3afbbe4ed.

- Fix patch.

- Fix generated Makevars.win.

- Add patch for re2 update.

- Apply patches during vendoring.

- Harmonize test file names.

- Restore vendor script, new script for step-by-step vendoring.

- Change maintainer.

- Use temporary clone.

- Always vendor next commit.

- Duckdir -\> upstream_dir.

- Ignore.

- Bump version.

- Build-ignore autogenerated files.

- Add revdepcheck results.

- Ellipsis before cache argument.

- Sync tests.

- Update NEWS.

- Bump version.

- Change directory location for extensions and secrets for v.0.10.0 release (@Tmonster, #73).

- Bump version.

- Update vendored sources to duckdb/duckdb@d4c774b1f15ed88c608154156d4c00f9235dbaf3 (#85).

- Executable script.

- Fix Dockerfile deps.

- Compose with threadcheck.

- Improve Docker Compose infrastructure.

- Add Docker Compose infrastructure for running with r-debug.

- Style.

- Sync duckplyr tests (#78).

- Update vendored sources to duckdb/duckdb@24148408432d05bda7cf86f2736d24920c51577c (#57).

- Update vendored sources to duckdb/duckdb@d51e1b06fad726a606ceb70c1530e21121633f31 (#53).

- Remove last instance of `default_connection()` (#50).

- Bump, tidy, news.

- Bump version.

- Update duckplyr tests.

- Build-ignore.

- Skip DBItest tests if not installed (#30).

- Fix tests when dplyr is missing (#29).

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

- Add fledge workflow.

- Use stable pak (#591).

- Latest changes (#584).

- Tweak patch call.

- Can't check incoming.

- Update actions to avoid warnings (#524).

- Use pkgdown branch (#523).

- Bring back stepwise vendoring.

- Don't remove dir.

- Add env.

- Vendor without creating PR.

- Set up R for r-hub.

- Force vendoring when tag.

- Fix passing branch names as reef.

- Pass inputs.ref to create-pull-request.

- Fix PR generation for snapshot tests for vendoring.

- Flip order.

- Use inputs.

- Use head ref for status reports.

- Check job.status.

- Tweak.

- Fix final status reporting.

- Fix status.

- Bump version of action.

- Post status for workflow_dispatch.

- Only smoke test for workflow_dispatch.

- Move condition to check if status event is triggered.

- Install package manually, faster.

- Verbosity.

- Improve support for protected branches, without fledge (#248).

- Fix vendoring (#225).

- Fix vendoring workflow (#217).

- Wait for pkgdown (#215).

- Fix builds (#213).

- Sync with latest developments.

- Use v2 instead of master.

- Inline action.

- Use dev roxygen2 and decor.

- Fix on Windows, tweak lock workflow.

- Avoid checking bashisms on Windows.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.

- Prepare for dynamic check matrix.

- Fail if patch does not apply.

- Add patches.

- Move caching of duckdb prebuilt archive.

- More careful patching.

- Better tag detection.

- Add R version to cache key.

- Logic.

- Fix vendoring.

- Add rhub2 workflow.

- Avoid vendoring past most recent tag.

- Always vendor tags.

- Fix condition.

- Fix.

- Fix vendoring.

- Only run check if vendoring changed anything.

- Show remaining commits to be vendored.

- Avoid concurrency, more is more.

- Logging.

- Fix typo.

- Fix typo.

- Also trigger when updating vendoring script.

- Dry-run push.

- Pull before vendoring.

- Simplify.

- Use most recent commit.

- Improve concurrency.

- Show stats.

- No cancel in progress, deep fetch.

- Debug.

- Debug.

- Debug.

- Fix typo.

- Vendor only next commit.

- Fix path.

- Vendor every five minutes, but only the next commit.

- Update vendored sources nightly (#25, #82).

- Add workflow file for labelling issues as 'High Priority'.

## Documentation

- Upgrade roxygen2.

- Fix typo.

- Add list of contributors (#2, #94).

- Use pkgdown BS5 (@maelle, #31, #70).

- Link to R documentation page.

## Testing

- Sync tests with duckplyr (#596).

- Skip if not installed.

- Skip if not installed.

- Add tests for comparison expression (@toppyy, #462).

- Update snapshot.

- Update duckplyr tests.

- Tweak tests.

- Add csv reading test for `duckdb_read_csv(na.strings = )` (@Tmonster, #10).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0 (#84).

- Update duckplyr tests.

- Fix snapshot tests again.

- Skip failing test.

- Fix snapshot tests.

## Breaking changes

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## fledge

- Bump version to 1.1.3.9003 (#604).

- Bump version to 1.1.3.9002 (#602).

- Bump version to 1.1.3.9001 (#599).

## README

- Display different logo for light/dark mode (@szarnyasg, #129).

## Uncategorized

- Merge branch 'cran-1.1.2'.

- Merge pull request #516 from duckdb/f-tweak.

  Fix signedness

- Merge pull request #461 from duckdb/f-exp-depth-2.

  Sync tests

- Merge pull request #392 from duckdb/cran-1.1.0.

  Bump

- Merge pull request #388 from duckdb/f-380-ppm-strip.

  Merge pull request #386 from duckdb/f-380-ppm-strip

- Merge pull request #214 from duckdb/b-ci.

  Only report success once

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13415 (#13415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13431 (#13431).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13439 (#13439).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13202 (#13202).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13268 (#13268).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13434 (#13434).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13433 (#13433).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13421 (#13421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13417 (#13417).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13411 (#13411).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13410 (#13410).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13408 (#13408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13409 (#13409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13358 (#13358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13402 (#13402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13383 (#13383).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13394 (#13394).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13401 (#13401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13370 (#13370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13399 (#13399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13329 (#13329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13344 (#13344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13354 (#13354).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13372 (#13372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13168 (#13168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13359 (#13359).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13356 (#13356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13335 (#13335).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13267 (#13267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13201 (#13201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13360 (#13360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13355 (#13355).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13346 (#13346).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13350 (#13350).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13341 (#13341).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13343 (#13343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13342 (#13342).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13317 (#13317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12886 (#12886).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13313 (#13313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13330 (#13330).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13234 (#13234).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13307 (#13307).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13167 (#13167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12682 (#12682).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13291 (#13291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13290 (#13290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13262 (#13262).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13278 (#13278).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13231 (#13231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13284 (#13284).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13281 (#13281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13283 (#13283).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13280 (#13280).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13282 (#13282).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13275 (#13275).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13260 (#13260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13261 (#13261).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13258 (#13258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13249 (#13249).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13229 (#13229).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13256 (#13256).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13162 (#13162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13230 (#13230).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13233 (#13233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13236 (#13236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13242 (#13242).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13241 (#13241).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13240 (#13240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13223 (#13223).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13207 (#13207).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13170 (#13170).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13203 (#13203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13109 (#13109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13194 (#13194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13191 (#13191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13189 (#13189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13188 (#13188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13186 (#13186).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13063 (#13063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13163 (#13163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13150 (#13150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13182 (#13182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13160 (#13160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13180 (#13180).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13161 (#13161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13151 (#13151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13146 (#13146).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13140 (#13140).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13136 (#13136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13087 (#13087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13101 (#13101).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13108 (#13108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13142 (#13142).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12978 (#12978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13130 (#13130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13123 (#13123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13137 (#13137).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13139 (#13139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13117 (#13117).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13133 (#13133).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13129 (#13129).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13131 (#13131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13127 (#13127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13125 (#13125).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13122 (#13122).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13126 (#13126).

- Merge tag 'v1.0.0-2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13114 (#13114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13093 (#13093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13110 (#13110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13118 (#13118).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13111 (#13111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13106 (#13106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12967 (#12967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13090 (#13090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13098 (#13098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13105 (#13105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13094 (#13094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13084 (#13084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13083 (#13083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13082 (#13082).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13081 (#13081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13089 (#13089).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13086 (#13086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13062 (#13062).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13073 (#13073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13076 (#13076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13074 (#13074).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13015 (#13015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13065 (#13065).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13068 (#13068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13027 (#13027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12579 (#12579).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12998 (#12998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13040 (#13040).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12920 (#12920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13054 (#13054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13056 (#13056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13057 (#13057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13052 (#13052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12995 (#12995).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13050 (#13050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13033 (#13033).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13039 (#13039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13035 (#13035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13030 (#13030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13028 (#13028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13025 (#13025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13023 (#13023).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13024 (#13024).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12953 (#12953).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13002 (#13002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12627 (#12627).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13020 (#13020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13019 (#13019).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13014 (#13014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13010 (#13010).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13013 (#13013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12728 (#12728).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13004 (#13004).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12993 (#12993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12994 (#12994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12931 (#12931).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13003 (#13003).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13001 (#13001).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12785 (#12785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13000 (#13000).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11720 (#11720).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12971 (#12971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12928 (#12928).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12829 (#12829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12929 (#12929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12979 (#12979).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12982 (#12982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12984 (#12984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12980 (#12980).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12942 (#12942).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12973 (#12973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12974 (#12974).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12972 (#12972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12965 (#12965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12968 (#12968).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12970 (#12970).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12966 (#12966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12954 (#12954).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12755 (#12755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12716 (#12716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12912 (#12912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12957 (#12957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12290 (#12290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12955 (#12955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12916 (#12916).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12948 (#12948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12824 (#12824).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12625 (#12625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12787 (#12787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12907 (#12907).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12885 (#12885).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12943 (#12943).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12938 (#12938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12937 (#12937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12932 (#12932).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12890 (#12890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12924 (#12924).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12866 (#12866).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12889 (#12889).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12918 (#12918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12908 (#12908).

- Merge branch 'cran-1.0.0-1'.

- Merge tag 'v1.0.0-1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12913 (#12913).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12914 (#12914).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12851 (#12851).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12887 (#12887).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12858 (#12858).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12888 (#12888).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12884 (#12884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12751 (#12751).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12848 (#12848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12498 (#12498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12398 (#12398).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12878 (#12878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12859 (#12859).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12834 (#12834).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12844 (#12844).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12849 (#12849).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12847 (#12847).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11191 (#11191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12840 (#12840).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12698 (#12698).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12806 (#12806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12734 (#12734).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12835 (#12835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12812 (#12812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12832 (#12832).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12691 (#12691).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12810 (#12810).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12780 (#12780).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12575 (#12575).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12803 (#12803).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12791 (#12791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12754 (#12754).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12765 (#12765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12685 (#12685).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12770 (#12770).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12768 (#12768).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12769 (#12769).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12762 (#12762).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12759 (#12759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12753 (#12753).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12636 (#12636).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12496 (#12496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12745 (#12745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12740 (#12740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12738 (#12738).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12737 (#12737).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12736 (#12736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12731 (#12731).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12730 (#12730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12599 (#12599).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12678 (#12678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12725 (#12725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12724 (#12724).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12708 (#12708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12697 (#12697).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12705 (#12705).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12717 (#12717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12681 (#12681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12692 (#12692).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12694 (#12694).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12689 (#12689).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12690 (#12690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12671 (#12671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12679 (#12679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12288 (#12288).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12655 (#12655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12669 (#12669).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12653 (#12653).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12663 (#12663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12658 (#12658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12654 (#12654).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12637 (#12637).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12650 (#12650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12642 (#12642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12652 (#12652).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12639 (#12639).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12635 (#12635).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12629 (#12629).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12630 (#12630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12633 (#12633).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12603 (#12603).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12608 (#12608).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12554 (#12554).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12539 (#12539).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12516 (#12516).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12515 (#12515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12445 (#12445).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12456 (#12456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12467 (#12467).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12465 (#12465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12470 (#12470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12461 (#12461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12448 (#12448).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12436 (#12436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12421 (#12421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12424 (#12424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12401 (#12401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12409 (#12409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12370 (#12370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12405 (#12405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12393 (#12393).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12391 (#12391).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12352 (#12352).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12360 (#12360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12344 (#12344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12332 (#12332).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12305 (#12305).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12302 (#12302).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12282 (#12282).

- Merge branch 'cran-1.0.0'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12291 (#12291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12281 (#12281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12257 (#12257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12267 (#12267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12264 (#12264).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12271 (#12271).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12259 (#12259).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12269 (#12269).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12265 (#12265).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12260 (#12260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12266 (#12266).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12244 (#12244).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12240 (#12240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12123 (#12123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12221 (#12221).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12226 (#12226).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12238 (#12238).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12209 (#12209).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12206 (#12206).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12195 (#12195).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12194 (#12194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12193 (#12193).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12189 (#12189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12183 (#12183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12111 (#12111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12169 (#12169).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12056 (#12056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12167 (#12167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12173 (#12173).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12175 (#12175).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12163 (#12163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12157 (#12157).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12168 (#12168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12159 (#12159).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12165 (#12165).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12109 (#12109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12152 (#12152).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12162 (#12162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12160 (#12160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12156 (#12156).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12144 (#12144).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12150 (#12150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12143 (#12143).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12086 (#12086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12110 (#12110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11677 (#11677).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12135 (#12135).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12130 (#12130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12131 (#12131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12124 (#12124).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12121 (#12121).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12120 (#12120).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12119 (#12119).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12116 (#12116).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12099 (#12099).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12091 (#12091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12108 (#12108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12112 (#12112).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12081 (#12081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12077 (#12077).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11493 (#11493).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12072 (#12072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12098 (#12098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12094 (#12094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12090 (#12090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12087 (#12087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12088 (#12088).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11848 (#11848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12070 (#12070).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12085 (#12085).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12076 (#12076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12084 (#12084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12063 (#12063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12083 (#12083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12045 (#12045).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12026 (#12026).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12049 (#12049).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12068 (#12068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12064 (#12064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12055 (#12055).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12061 (#12061).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12044 (#12044).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12051 (#12051).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12050 (#12050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12054 (#12054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12052 (#12052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12053 (#12053).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12035 (#12035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12043 (#12043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11874 (#11874).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12039 (#12039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12028 (#12028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11998 (#11998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12030 (#12030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11984 (#11984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12029 (#12029).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11937 (#11937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12022 (#12022).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12027 (#12027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12025 (#12025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12011 (#12011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11867 (#11867).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11976 (#11976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11831 (#11831).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12013 (#12013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11965 (#11965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11978 (#11978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11987 (#11987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11982 (#11982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11994 (#11994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12012 (#12012).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12014 (#12014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12015 (#12015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11999 (#11999).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11761 (#11761).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11964 (#11964).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11969 (#11969).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11967 (#11967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11955 (#11955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11966 (#11966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11956 (#11956).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11929 (#11929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11920 (#11920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11441 (#11441).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11835 (#11835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11912 (#11912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11906 (#11906).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11918 (#11918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11806 (#11806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11902 (#11902).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11771 (#11771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11898 (#11898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11884 (#11884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11745 (#11745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11785 (#11785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11880 (#11880).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11879 (#11879).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11878 (#11878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11746 (#11746).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11812 (#11812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11794 (#11794).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11792 (#11792).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11788 (#11788).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11797 (#11797).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11846 (#11846).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11861 (#11861).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11524 (#11524).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11830 (#11830).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11829 (#11829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11825 (#11825).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11821 (#11821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11816 (#11816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11757 (#11757).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11795 (#11795).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11791 (#11791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11787 (#11787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11625 (#11625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11763 (#11763).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11774 (#11774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11777 (#11777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11765 (#11765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11596 (#11596).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11759 (#11759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11679 (#11679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11719 (#11719).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11717 (#11717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11736 (#11736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11732 (#11732).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11730 (#11730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11726 (#11726).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11733 (#11733).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11735 (#11735).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11702 (#11702).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11725 (#11725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11723 (#11723).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11721 (#11721).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11696 (#11696).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11716 (#11716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11711 (#11711).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11708 (#11708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11673 (#11673).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10978 (#10978).

- Merge branch 'cran-0.10.2'.

- Merge branch 'cran-0.10.2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11681 (#11681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11678 (#11678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11676 (#11676).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11674 (#11674).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11675 (#11675).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11665 (#11665).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11670 (#11670).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11671 (#11671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11668 (#11668).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11667 (#11667).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11663 (#11663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11616 (#11616).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11659 (#11659).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11656 (#11656).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11655 (#11655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11465 (#11465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11645 (#11645).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11650 (#11650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11648 (#11648).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11642 (#11642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11630 (#11630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11631 (#11631).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11614 (#11614).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11462 (#11462).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11515 (#11515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11619 (#11619).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11618 (#11618).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11622 (#11622).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11613 (#11613).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11601 (#11601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11512 (#11512).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11273 (#11273).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11551 (#11551).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11604 (#11604).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11587 (#11587).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11585 (#11585).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11580 (#11580).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11461 (#11461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11267 (#11267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11558 (#11558).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11528 (#11528).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11546 (#11546).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11544 (#11544).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11519 (#11519).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11525 (#11525).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11270 (#11270).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11496 (#11496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11513 (#11513).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11495 (#11495).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11506 (#11506).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11446 (#11446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11401 (#11401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11498 (#11498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11497 (#11497).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11247 (#11247).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11486 (#11486).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11408 (#11408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11464 (#11464).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11478 (#11478).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11466 (#11466).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11470 (#11470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11458 (#11458).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11358 (#11358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11402 (#11402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11399 (#11399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11443 (#11443).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11456 (#11456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11454 (#11454).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11429 (#11429).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11436 (#11436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11437 (#11437).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11418 (#11418).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11428 (#11428).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11424 (#11424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11414 (#11414).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11415 (#11415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11405 (#11405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11400 (#11400).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11397 (#11397).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11396 (#11396).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11392 (#11392).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11390 (#11390).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11360 (#11360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11356 (#11356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11372 (#11372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11369 (#11369).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11376 (#11376).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11343 (#11343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11252 (#11252).

- Merge branch 'cran-0.10.1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11347 (#11347).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11326 (#11326).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11313 (#11313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11340 (#11340).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11327 (#11327).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11321 (#11321).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11329 (#11329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11325 (#11325).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11314 (#11314).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11315 (#11315).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11318 (#11318).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11309 (#11309).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11320 (#11320).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11317 (#11317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11316 (#11316).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11306 (#11306).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11297 (#11297).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11304 (#11304).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10878 (#10878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11215 (#11215).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11286 (#11286).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11203 (#11203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11258 (#11258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11276 (#11276).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11233 (#11233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11220 (#11220).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11248 (#11248).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11257 (#11257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11243 (#11243).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11236 (#11236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11231 (#11231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11222 (#11222).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11139 (#11139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11223 (#11223).

- Merge branch 'cran-0.10.1'.

- Merge branch 'cran-0.10.1'.

- Merge pull request #124 from duckdb/b-34-56-58-59-60-83-conn-2.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11218 (#11218).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11214 (#11214).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11149 (#11149).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11172 (#11172).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11106 (#11106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11210 (#11210).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11171 (#11171).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11208 (#11208).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11201 (#11201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11182 (#11182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11205 (#11205).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11200 (#11200).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11199 (#11199).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11183 (#11183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11198 (#11198).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11185 (#11185).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11188 (#11188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11190 (#11190).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11177 (#11177).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11179 (#11179).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11174 (#11174).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11161 (#11161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11151 (#11151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11138 (#11138).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11132 (#11132).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11145 (#11145).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11141 (#11141).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11127 (#11127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11128 (#11128).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11130 (#11130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11136 (#11136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11114 (#11114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11108 (#11108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11111 (#11111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11093 (#11093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11083 (#11083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11103 (#11103).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11105 (#11105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11090 (#11090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11096 (#11096).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11094 (#11094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11091 (#11091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10976 (#10976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11017 (#11017).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11086 (#11086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11073 (#11073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11072 (#11072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11069 (#11069).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11056 (#11056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11064 (#11064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11057 (#11057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11031 (#11031).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11046 (#11046).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10984 (#10984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11035 (#11035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11043 (#11043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11034 (#11034).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11039 (#11039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11021 (#11021).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11020 (#11020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11011 (#11011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11002 (#11002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11008 (#11008).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11005 (#11005).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10997 (#10997).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10992 (#10992).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10993 (#10993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10994 (#10994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10998 (#10998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10983 (#10983).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10990 (#10990).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10948 (#10948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10955 (#10955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10972 (#10972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10987 (#10987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10985 (#10985).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10938 (#10938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10973 (#10973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10971 (#10971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10933 (#10933).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10594 (#10594).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10958 (#10958).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10957 (#10957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10949 (#10949).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10936 (#10936).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10946 (#10946).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10939 (#10939).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10937 (#10937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10945 (#10945).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10941 (#10941).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10944 (#10944).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10870 (#10870).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10925 (#10925).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10704 (#10704).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10923 (#10923).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10922 (#10922).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10920 (#10920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10918 (#10918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10915 (#10915).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10912 (#10912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10690 (#10690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10908 (#10908).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10828 (#10828).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10799 (#10799).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10898 (#10898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10909 (#10909).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10850 (#10850).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10873 (#10873).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10897 (#10897).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10896 (#10896).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10893 (#10893).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10890 (#10890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10864 (#10864).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10872 (#10872).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10884 (#10884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10882 (#10882).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10740 (#10740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10862 (#10862).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10863 (#10863).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10610 (#10610).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10597 (#10597).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10714 (#10714).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10855 (#10855).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10854 (#10854).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10446 (#10446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10848 (#10848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10742 (#10742).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10837 (#10837).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10774 (#10774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10789 (#10789).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10822 (#10822).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10817 (#10817).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10821 (#10821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10816 (#10816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10755 (#10755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10796 (#10796).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10807 (#10807).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10791 (#10791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10771 (#10771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10773 (#10773).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10777 (#10777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10776 (#10776).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10601 (#10601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10765 (#10765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10758 (#10758).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10658 (#10658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10642 (#10642).

- Merge pull request #103 from lnkuiper/namespace.

  Remove std:: from unordered_map

- Merge pull request #108 from Tmonster/fix_Rbuildignore.

  Fix invalid regex in .Rbuildignore

- Merge pull request #48 from olivroy/patch-1.

- Merge pull request #76 from romainfrancois/patch-1.

- Merge pull request #45 from duckdb/b-cpp11-printf.

- Merge pull request #33 from duckdb/adbcdef.

  Fix duckdb_adbc_init signature


# duckdb 1.1.3.9012

## Bug fixes

- Avoid compiler warning related to `Rboolean` (#594).

- Check `"duckdb.materialize_message"` symbol (#592).

- `%in%` works correctly as part of a `&` conjunction (#528).

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- Use portable format modifiers.

- Correctly compute vector length for data frames passed to relational functions (#379).

- Set `initialize_in_main_thread`, add patch.

- Compatibility with clang19 2.

- Compatibility with clang19.

- Uninitialized.

- Fix uninitialized move 5.

- Fix uninitialized move 4.

- Fix uninitialized move 3.

- Fix uninitialized move 2.

- Fix uninitialized move.

- Avoid triggering re2 in tests (#176).

- Correct usage of `win_current_group()` instead of `win_current_order()` in SQL translation (@lschneiderbauer, #173, #175).

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).

- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).

- Fix vendoring script without arguments, align.

- Don't run tests that invoke re2 by default (#121, #127).

- `dplyr::tbl()` works again when a Parquet or CSV file is passed instead of a table name (#38, #91).

- `DBI::dbQuoteIdentifier()` correctly quotes identifiers that start with a digit (#67, #92).

- Align the argument order of `dbWriteTable()` with the DBI specs (@eitsupi, #43, #49).

- Fix LTO builds.

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (@romainfrancois, #186).

- Xz-compress duckdb sources in the tarball (#530).

- Add `col.types` argument to `duckdb_read_csv()` (@eli-daniels, #383, #445).

- `last_rel` (#529).

- `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- Rethrow errors with rlang if installed (#522).

- Catch and add query context for statement extraction (tidyverse/duckplyr#219, #521).

- Implement query cancellation (#514, #515).

- Add comparison expression to relational api (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

- Bump vendored cpp11 to v0.5.0 (#382, #387).

- Tweak implementation of `r_base::sum()` (#381, #385).

- `n_distinct()` supports `na.rm = TRUE` with a single vector argument again (@lschneiderbauer, #204, #216).

- New `rel_from_sql()` (#212).

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

- Support fetching `MAP` type (#61, #165).

- Add dbplyr translations for `clock::date_count_between()` (@edward-burn, #163, #166).

- `round()` duckdb translation uses `ROUND_EVEN()` instead of `ROUND()` (@lschneiderbauer, #146, #157).

- New `sort` argument to `rel_order()` (@toppyy, #168).

- Add dbplyr translations for `clock::add_days()`, `clock::add_years()`, `clock::get_day()`, `clock::get_month()`, and `clock::get_year()` (#153).

- Use latest tests from DBItest (#148).

- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).

- Include rfuns extension (hannes/duckdb-rfuns#78, #144).

- Map `NA` to `SQLNULL` (#143).

- New `tbl_file()` and `tbl_query()` to explicitly access tables and queries as dbplyr lazy tables (#96).

- Initial ALTREP support for `LIST` logical type (@romainfrancois, #77).

- Update core to duckdb v0.10.0 (#90).

- New private `rel_to_parquet()` to write a relation to parquet (@Tmonster, #46).

- Update vendored sources to duckdb/duckdb@3c695d7ba94d95d9facee48d395f46ed0bd72b46 (#42).

- Add `prod()` translation for dbplyr (@m-muecke, #40).

- Support list of strings for column references in R API (@Tmonster, #14).

- Update vendored code to v0.9.1 (#26).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Bump for pre-release.

- Keep `cleanup` files to accommodate different build scenarios (#536).

- Update vendored sources to duckdb/duckdb@19864453f7d0ed095256d848b46e7b8630989bac (#580).

- Update vendored sources to duckdb/duckdb@c3ca3607c221d315f38227b8bf58e68746c59083 (#579).

- Update vendored sources to duckdb/duckdb@9cba6a2a03e3fbca4364cab89d81a19ab50511b8 (#578).

- Update vendored sources to duckdb/duckdb@c6c08d4c1b363231b3b9689367735c7264cacefb (#577).

- Update vendored sources to duckdb/duckdb@7f34190f3f94fc1b1575af829a9a0ccead87dc99 (#576).

- Update vendored sources to duckdb/duckdb@78b65d4a9aa80c4be4efcdd29fadd6f0c893f1ce (#575).

- Update vendored sources to duckdb/duckdb@c31c46a875979ce3343edeedcb497485ca2fd751 (duckdb/duckdb#14542, #574).

- Update vendored sources to duckdb/duckdb@4ba2e66277a7576f58318c1aac112faa67c47b11 (#573).

- Update vendored sources to duckdb/duckdb@247fcb31733a5297c1070fbd244f2349091253aa (duckdb/duckdb#14601, #572).

- Update vendored sources to duckdb/duckdb@1a519fce83b3d262247325dbf8014067686a2c94 (duckdb/duckdb#14600, #571).

- Update vendored sources to duckdb/duckdb@b653a8c2b760425a83302e894bf930f18a1bdf64 (#570).

- Update vendored sources to duckdb/duckdb@79bf967e1b6ab438e0a83a014e937af571ed7acb (#569).

- Update vendored sources to duckdb/duckdb@4b62ee43a7d5f62313d77d36dec8aea29412431f (#568).

- Update vendored sources to duckdb/duckdb@3293c92b6e657084318f7556b14077896b333109 (#567).

- Update vendored sources to duckdb/duckdb@8664b710beb205ec6fc7e9f3d18dfe24dd28625f (#566).

- Update vendored sources to duckdb/duckdb@92a1ccbcef04dda11c85fa2bf6daf27daf8d9c49 (#565).

- Update vendored sources to duckdb/duckdb@2635a87a566b90e086caa84805019f66eedf0859 (#564).

- Update vendored sources to duckdb/duckdb@0d5ec0057838081251b388726353f09cba9577ad (#563).

- Update vendored sources to duckdb/duckdb@6af32330b51af4d72d3fed665bfc03f78c8b3876 (#562).

- Update vendored sources to duckdb/duckdb@662b0b34eaaf7f52545638cbc87c10e32b33834d (#561).

- Update vendored sources to duckdb/duckdb@bccd37ae7ea09f77b6299165bf80bca3bc1efc7c (#560).

- Update vendored sources to duckdb/duckdb@5090b7396173069bb0d51b0e1341cfa9950c154f (#559).

- Update vendored sources to duckdb/duckdb@f5ebc9b8e1d6c040a2276e0ac4a41d6bf9475880 (duckdb/duckdb#14545, #558).

- Update vendored sources to duckdb/duckdb@b8c5248b9c18f7cafbdf7992421662adbd95bf38 (#557).

- Update vendored sources to duckdb/duckdb@dfdd7968262d912910d8249bde3524e068c67713 (#556).

- Update vendored sources to duckdb/duckdb@d0673165b52e89fe70d1891504e4dea82adeca85 (#555).

- Update vendored sources to duckdb/duckdb@d79e66bd032dbd2066c16a88f517f6da1cd0aa78 (#554).

- Update vendored sources to duckdb/duckdb@0359726be957673a62ab1ab61f1cca9ba5667386 (#553).

- Update vendored sources to duckdb/duckdb@10c42435f1805ee4415faa5d6da4943e8c98fa55 (#552).

- Update vendored sources to duckdb/duckdb@43d26298affa89bc6ca829a1defc4819b42b6fb4 (#551).

- Update vendored sources to duckdb/duckdb@52b43b166091c82b3f04bf8af15f0ace18207a64 (#550).

- Update vendored sources to duckdb/duckdb@0446ab42e96b6269e78f55293f4096fa10224837 (#549).

- Update vendored sources to duckdb/duckdb@ceb77af7935c3c7a4a34e1199abd4d6ea080448c (duckdb/duckdb#14430, #548).

- Update vendored sources to duckdb/duckdb@aed52f5cabe34075c53bcec4407e297124c8d336 (#547).

- Update vendored sources to duckdb/duckdb@e41a881658ae579cedebe19c5070dad660086aea (#546).

- Update vendored sources to duckdb/duckdb@98d4ad28be35cf5c37e18760e76d11bc07be1ab4 (#545).

- Update vendored sources to duckdb/duckdb@1bb332c9c59a9d15b196b4486a6d1ffcaa833ba5 (#544).

- Update vendored sources to duckdb/duckdb@0bbfe09937e3744325f3b2dfdb182e9ac1ff916f (#543).

- Update vendored sources to duckdb/duckdb@08969b4677534b6870bff4c99998c753a6e784fc (#542).

- Update vendored sources to duckdb/duckdb@4756244efa04d204be6f20d55036fc503b7ed49c (#541).

- Update vendored sources to duckdb/duckdb@217ec4722e949eaa49568bd707e49431ef727ab5 (#539).

- Move responsibility for removing CR (#533).

- Terminate all sources with newline (#531).

- Sync duckplyr tests (#527).

- Cleanup, preparation (#525).

- Bump version.

- Update vendored sources (tag v1.1.2) to duckdb/duckdb@f680b7d08f56183391b581077d4baf589e1cc8bd (#510).

- Update vendored sources to duckdb/duckdb@5f49126b92a0899a2049aaa57da886138c5f879d (#509).

- Update vendored sources to duckdb/duckdb@2c21eb1c2eec3a1e359d87fb2a2cd8e427dc03c1 (#508).

- Update vendored sources to duckdb/duckdb@cc067e6b7db33f516437567cbc726536e34ed716 (#507).

- Update vendored sources to duckdb/duckdb@d2dfc6090685470cb09326a7530066fc4b3db42a (#506).

- Update vendored sources to duckdb/duckdb@56e2e0e5721b8547f564fccf252db0ba93c85471 (#505).

- Update vendored sources to duckdb/duckdb@35dfcc06e6c76ad6bd8e4acdae1bcc30751777eb (#504).

- Update vendored sources to duckdb/duckdb@92e0964376a78f990408a0e81af155504b35d27c (#503).

- Update vendored sources to duckdb/duckdb@01e6e98e3875ed12cbcb9257f81844743b1665fa (#502).

- Update vendored sources to duckdb/duckdb@6dc2e9375870e60f82becb1cece4cc878289d3b8 (#501).

- Update vendored sources to duckdb/duckdb@52b19d5ece35be344830800db0e4961f47114aa9 (#500).

- Update vendored sources to duckdb/duckdb@0d3e84330e845ceefdc55a36d52ef0296af5d1e1 (#499).

- Update vendored sources to duckdb/duckdb@d0cf23ead54f191bf2518598edf04e209f07452e (#498).

- Update vendored sources to duckdb/duckdb@d57a94430e50263cbd1b719b984da189e5bba0c5 (#497).

- Update vendored sources to duckdb/duckdb@a5ddffef692c0627dd6c7efaed7cf65148321452 (#496).

- Update vendored sources to duckdb/duckdb@536f979f69b1bbe40d582450b6cfa6a68463f172 (#495).

- Update vendored sources to duckdb/duckdb@443380a11dbb31a1c218a759ec0c3b56880f1c38 (duckdb/duckdb#14249, #494).

- Update vendored sources to duckdb/duckdb@7919e4abc5597dc4fbeb5a19dff19ff69b5c4113 (duckdb/duckdb#14249, #493).

- Update vendored sources to duckdb/duckdb@52f967a42861032fd5f4392609afc195cd025dde (#492).

- Update vendored sources to duckdb/duckdb@1f20676c7d997fe4964a8b51378bf984e53a4b4c (#491).

- Update vendored sources to duckdb/duckdb@8cec9b1537f900e7a644e7b466ea899cf1ca8f8f (#490).

- Update vendored sources to duckdb/duckdb@4f0cd4d60035e8c6afafed47b68b2240b39e3566 (duckdb/duckdb#14212, #489).

- Update vendored sources to duckdb/duckdb@5a9a382a573b107a38f5ee277619b362d5079c32 (#488).

- Update vendored sources to duckdb/duckdb@123b82b9053c4843559035b6723c867b2618b2d9 (#487).

- Update vendored sources to duckdb/duckdb@405e15fcde8a4da4a7c6d3889f992f0a363c05f2 (duckdb/duckdb#14232, #486).

- Update vendored sources to duckdb/duckdb@0e398d95c50ae40730467c53922c8fb8d5c69f90 (#485).

- Update vendored sources to duckdb/duckdb@1eac05ecd3a6b8ec2cdf0c53ccece7ca2effef26 (#484).

- Update vendored sources to duckdb/duckdb@048f5ffcec9c1a4b73cbfbd4158cd5b6669f102b (#483).

- Update vendored sources to duckdb/duckdb@0b2d95601c2d9474f2c823ac3363e9ca14224c7c (#482).

- Update vendored sources to duckdb/duckdb@350d061846ed7e4c96d2efa7b523bb97ae84538a (#481).

- Update vendored sources to duckdb/duckdb@2f6b78c21d1634c7228e00c809a790701705c82b (#480).

- Update vendored sources to duckdb/duckdb@8aca4330ac46be3950c6b12e29040322dd245b7a (#479).

- Update vendored sources to duckdb/duckdb@9931d723ccde2b2435b1a927234338e6f0353d90 (#478).

- Update vendored sources to duckdb/duckdb@d896e73fe2db62b6749b95e30faa8bfa41dc4d32 (#477).

- Update vendored sources to duckdb/duckdb@f8c82ab2620f8066b0141df0c3982885a5258746 (#476).

- Update vendored sources to duckdb/duckdb@ee256eb45552601db71d4cad7a5cd4f46f0d5a1d (#475).

- Update vendored sources to duckdb/duckdb@130aab3f9ddb84e0c6e7f543a99881d8fc1bd6b7 (#474).

- Update vendored sources to duckdb/duckdb@92c65a4341c57f313dbeba5acc7b1fb917808010 (#473).

- Update vendored sources to duckdb/duckdb@47e1d3d60b4d6d075cf88c2707572df12a630a3a (#472).

- Update vendored sources to duckdb/duckdb@45559f5eeb1834454a30490fc4ffad1807e13f3b (#471).

- Update vendored sources to duckdb/duckdb@dfdd09f46c0169c9d8aa5381086e46a66e44fabc (#470).

- Update vendored sources to duckdb/duckdb@89828abb72219957372f316da06f007dadd2a9aa (#469).

- Update vendored sources to duckdb/duckdb@12e9777cf6283f44710b2610ba3d3735a1208751 (duckdb/duckdb#14077, #468).

- Update vendored sources to duckdb/duckdb@4a55e2334232afe94e47ab398ddb44f88fcd6658 (#467).

- Update vendored sources to duckdb/duckdb@0f3c46215feb0fb92d4998977fc31b2f52db6b14 (#466).

- Update vendored sources to duckdb/duckdb@c87246586490b442706d0be66b82d71930a00578 (#465).

- Update vendored sources to duckdb/duckdb@cd8cb3f1c81a74a3b2c1ed7d94e3913485895074 (#464).

- Update vendored sources to duckdb/duckdb@acd16816e31789bdb27e144ccd19ddb9da4fe6df (#463).

- Update vendored sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove uninitialized warnings.

- Document (#456).

- Update vendored sources (tag v1.1.1) to duckdb/duckdb@af39bd0dcf66876e09ac2a7c3baa28fe1b301151 (#454).

- Update vendored sources to duckdb/duckdb@0fe7708eef6b9b77270ca21cb9b5e30a3de84e3c (#453).

- Update vendored sources to duckdb/duckdb@34a3acc6b3354be86fe593d09e0702ab5eafe757 (#452).

- Update vendored sources to duckdb/duckdb@cb2a947e9df4f6c40b6dd5751c412d6946cbb62b (#451).

- Update vendored sources to duckdb/duckdb@64520f224d8a0a096cfe10f0c2cfbd1ac9457811 (duckdb/duckdb#13934, #450).

- Update vendored sources to duckdb/duckdb@b0eee44df70eb7bf9efac5f65dd2eaf7ad1e5403 (#449).

- Update vendored sources to duckdb/duckdb@4fe3dc559d10648691f9ab34f20207771890dd45 (#448).

- Update vendored sources to duckdb/duckdb@6c02032393583f353f2f2a0337a8e16f34dc5d82 (duckdb/duckdb#14026, #447).

- Update vendored sources to duckdb/duckdb@4ce455c84029195ffa4c3e540c10360ae8c73724 (#446).

- Update vendored sources to duckdb/duckdb@03dd0df6185d903ecbff9d80017e5449e78e5017 (#443).

- Update vendored sources to duckdb/duckdb@d1037da3139de90dc0a82df746d8ce92a50d9838 (#442).

- Update vendored sources to duckdb/duckdb@cb27c0423fa7107674c267b5de8eb93dd603cb69 (duckdb/duckdb#13993, #441).

- Update vendored sources to duckdb/duckdb@b787fcc1cb9bc4daf36e6eec19c1e9b2b162f4b0 (duckdb/duckdb#14020, #440).

- Update vendored sources to duckdb/duckdb@0ce863113043806780e776bcfb86b24afcb0263c (#439).

- Update vendored sources to duckdb/duckdb@f9e96b191088e65b4a1f95918312c40e31096dd9 (#438).

- Update vendored sources to duckdb/duckdb@2ff9c687e2c448914a28c59bd50f48f54e47de3c (#437).

- Update vendored sources to duckdb/duckdb@dcc302aef4491db8cc2efd2955ac254a4d62dcbc (#436).

- Update vendored sources to duckdb/duckdb@03976af191370d4020c172a82b28ca7885d98ea3 (#435).

- Update vendored sources to duckdb/duckdb@29c46243993319b0db24509c862126b8e17f1e8c (#434).

- Update vendored sources to duckdb/duckdb@e7da966e87539457f3de94a1bee288861fdca6d6 (#433).

- Update vendored sources to duckdb/duckdb@44bba02cea5d316e38f6edbad7fad3a1f913d63f (#432).

- Update vendored sources to duckdb/duckdb@04a1f750a6fab3f1a9cf3fb7cce5fd119c522304 (#431).

- Update vendored sources to duckdb/duckdb@0da70d9de97ff2cf39ad99b9e30b7e6cb91614b8 (duckdb/duckdb#13933, #430).

- Update vendored sources to duckdb/duckdb@df82a0e2c47e8b3ddd5a93e08530b83bc49e0da0 (#429).

- Update vendored sources to duckdb/duckdb@86723c9912fde7b76d3863b2ccd2d4333251c4af (#428).

- Update vendored sources to duckdb/duckdb@66d8ed93f67a00006ec99226c1205bcffb1ef07b (duckdb/duckdb#13941, #427).

- Update vendored sources to duckdb/duckdb@b2f68017070c1910dd3438f9428c7162cb428f84 (#426).

- Update vendored sources to duckdb/duckdb@35a104529b56c4f4f1e383e2ead26d6047d3442e (#425).

- Update vendored sources to duckdb/duckdb@b8c5fa937919631b759a70e33f068aa05de8bd36 (#424).

- Update vendored sources to duckdb/duckdb@18670a10f1b3da56382e272518d6b149e489ca51 (#423).

- Update vendored sources to duckdb/duckdb@0b0c95b9dc685e1a6ca011d8e086d885afbe0398 (#422).

- Update vendored sources to duckdb/duckdb@e5e1595da75ea01559f2b4bc9531505422b7fcdc (duckdb/duckdb#13585, #421).

- Update vendored sources to duckdb/duckdb@75d4bd0cc759dcb609ab349b87bff07dddf2ebb7 (#420).

- Update vendored sources to duckdb/duckdb@c0f29465624aaa1472ee05d4723415cfa1bfbdf9 (#419).

- Update vendored sources to duckdb/duckdb@b369bcb4e08235e52866a5f8afb7e172fe573287 (#418).

- Update vendored sources to duckdb/duckdb@414207f2120ad9019b416cf891947004c74c7347 (#417).

- Update vendored sources to duckdb/duckdb@38ceb86f1aa4cfae7c993f59de19e0cfee7ff68e (#416).

- Update vendored sources to duckdb/duckdb@0dbb79e8de897b4a710ed53becc063bcdf80884d (duckdb/duckdb#13824, #415).

- Update vendored sources to duckdb/duckdb@9af117f0e6d3f2f9ade385dadc46807c1b388dd4 (#414).

- Update vendored sources to duckdb/duckdb@88a4c1e5893f316d763343d7f66f57917b065f50 (#413).

- Update vendored sources to duckdb/duckdb@d93225aab5c8e0da34776398358373f4c0232864 (duckdb/duckdb#13872, #412).

- Update vendored sources to duckdb/duckdb@8c2ee1eb7987a981cdf4bb1ed52683784a26e3bf (duckdb/duckdb#13880, #411).

- Update vendored sources to duckdb/duckdb@081a748340c4fcd3b3652230a02432afae72bbb3 (#410).

- Update vendored sources to duckdb/duckdb@bc7683e100867fae06c1f65e055df403c2ee25cf (#409).

- Update vendored sources to duckdb/duckdb@b87545985fc03e43baf84d9554eab23ea4b21f6c (#408).

- Update vendored sources to duckdb/duckdb@1d7e05c9737821fdb2c8eba996642c9953de52f6 (#407).

- Update vendored sources to duckdb/duckdb@b383f3668095fac2574bc6a0c417047a6fe80c9f (#406).

- Update vendored sources to duckdb/duckdb@039a262ae9805f30690ae1c8ec6a7fb27812c1b5 (#405).

- Update vendored sources to duckdb/duckdb@d697acfb108f6ec1b1ed26f0062445e1d49ee1c4 (#404).

- Update vendored sources to duckdb/duckdb@dfbfdef89aad145dc9d81c275bc2c9fad4062bed (#403).

- Update vendored sources to duckdb/duckdb@c41ae2cb6e2390b9656ac2d22885df0572a87796 (#402).

- Update vendored sources to duckdb/duckdb@d066254185fa56ec851183e9178edb04ae34c0b9 (#401).

- Update vendored sources to duckdb/duckdb@5fd2501220b80adaddf009b78cac44b97813258c (#400).

- Update vendored sources to duckdb/duckdb@6d9d429d5e7f464b69671b46dcbc99a6e46378df (#399).

- Update vendored sources to duckdb/duckdb@d9e89b5cc192ea052f038d8e7b26d253ec81bc49 (#398).

- Update vendored sources to duckdb/duckdb@95038c5eee75f733c99193c66c3faa7289d6f599 (#397).

- Update vendored sources to duckdb/duckdb@8d1c2b29badfcc55246829e00e97b86b38b3606a (#396).

- Update vendored sources to duckdb/duckdb@329bb5393b686421b40261211354f4d77cac1633 (#395).

- Update vendored sources to duckdb/duckdb@403f0fc6459fc5a1f185350d30eafa555c145d1f (#394).

- Update vendored sources to duckdb/duckdb@6a197b22652d02749c3e755e75b10d75e7ad6b75 (#393).

- Show file sizes (#380, #391).

- Fix stripping call (#380, #390).

- Move stripping logic to `install.libs.R` (#380, #389).

- Strip binary if requested (#380, #386).

- Update vendored sources to hannes/duckdb-rfuns@4fccc0b6e577f5b32c84d03cd79cb9fd9827212b (#378).

- Bump.

- Update vendored sources (tag v1.1.0) to duckdb/duckdb@fa5c2fe15f3da5f32397b009196c0895fce60820 (#377).

- Update vendored sources to duckdb/duckdb@fc21edf1508fa785a0ce06ffd245fe30b20eefe0 (#376).

- Update vendored sources to duckdb/duckdb@1d3fc5aec6b846c563d6d99c96df7c30117b5a94 (#375).

- Update vendored sources to duckdb/duckdb@893d007e64df94658d4da92c02698559f89d2072 (#374).

- Update vendored sources to duckdb/duckdb@64bacde85e4c24134cf73f9b4ed3ae362510f287 (#373).

- Update vendored sources to duckdb/duckdb@93494bd74d30f7ae11456dcee6c5e5143be58606 (#372).

- Update vendored sources to duckdb/duckdb@f76d6f2e7e170d6434e2725f43bac5ede31985fa (#371).

- Update vendored sources to duckdb/duckdb@310176118d5dc9897fb752bda145ee9dca628240 (#370).

- Update vendored sources to duckdb/duckdb@c1183d72ed9b388fdc894e86f7e999b2ba8301e5 (#369).

- Update vendored sources to duckdb/duckdb@d454d2458646151fc89c60639f0c50cecf1f4ebd (#367).

- Update vendored sources to duckdb/duckdb@0e6dacd8932c22f9d383b8047fb11aad59564895 (#363).

- Update vendored sources to duckdb/duckdb@4d18b9d05caf88f0420dbdbe03d35a0faabf4aa7 (#362).

- Update vendored sources to duckdb/duckdb@c4940720ce2ee93f39f6d80ceb25a729718a6828 (#361).

- Update vendored sources to duckdb/duckdb@421acb0f7c924216bc689f3731d7a971e7e4fa2b (#360).

- Update vendored sources to duckdb/duckdb@7c988cf7bf417d6534f0ae60f6e0297ef22cd18a (#359).

- Update vendored sources to duckdb/duckdb@dd3cbcee009bf664e3a9bce2467c8af6d2bc53d2 (#358).

- Update vendored sources to duckdb/duckdb@95a9fe9f2681175788ac85dfe67a370ef9b6f32d (#357).

- Update vendored sources to duckdb/duckdb@756d4fcb624c2c180969630b11d44380704a871a (#356).

- Update vendored sources to duckdb/duckdb@450b7e45d9e717d2c475995dabbde47b5acdfc4a (#355).

- Update vendored sources to duckdb/duckdb@dffc4ffad7d9cb7c181db87b1bfb51e261bcedf6 (#354).

- Update vendored sources to duckdb/duckdb@a6e32b115826ba543e32a733cb92f68fd0549186 (#353).

- Update vendored sources to duckdb/duckdb@1f01ef8781c8a3edf192286e0044ff37f043fb47 (#352).

- Update vendored sources to duckdb/duckdb@9aa68025b1ddf0deba9e7caf17cd0dbe4abd7206 (#351).

- Update vendored sources to duckdb/duckdb@7a7547f5da232111d52c4afb05e98e19fd8c7e31 (#350).

- Update vendored sources to duckdb/duckdb@fa2daf7a09e477e30e53b4cc8f4269c39eaf62ef (#349).

- Update vendored sources to duckdb/duckdb@a65fc4ed0847cb073231ba2be21bbd8515b91171 (#348).

- Update vendored sources to duckdb/duckdb@1844ae51091ee85c9194036405abd561ff9b58ae (#347).

- Update vendored sources to duckdb/duckdb@439bb91fc33e8bc45cc6e6d73c823ab44b48876d (#346).

- Update vendored sources to duckdb/duckdb@9067c648ef182084b3159b72213097505d5b5cab (#345).

- Update vendored sources to duckdb/duckdb@a05e81d31b178bd41ff4fb3aa46c30fe2a7068e5 (#344).

- Update vendored sources to duckdb/duckdb@74c9f4df1fe5c3f39007aa38c112cb7582f91302 (#343).

- Update vendored sources to duckdb/duckdb@e90611400749d641a07dbcd5f10df85d99813f33 (#342).

- Update vendored sources to duckdb/duckdb@902af6f21cf5e15979ecab02f15223a0f9a0baff (#341).

- Update vendored sources to duckdb/duckdb@6f9795184545d841a35e75b938f78a1e0520bd8f (#340).

- Update vendored sources to duckdb/duckdb@67b69b0c6e9411a2755baffa2305000dae887937 (#339).

- Update vendored sources to duckdb/duckdb@18e97dd88525d42c5de9faf6d1a89b90590c94fe (#338).

- Update vendored sources to duckdb/duckdb@37a55bdf6665705eb6be311bc61fa8a2f2b900fe (#337).

- Update vendored sources to duckdb/duckdb@0d37df84df6c0226423eda80d2adce9b6fdf1eea (#336).

- Update vendored sources to duckdb/duckdb@2355a5bd10fe6ae24b0b7604a66b78d6c657c104 (#335).

- Update vendored sources to duckdb/duckdb@206320c56140238066fdfca3aa503ec09f7cb2bd (#334).

- Update vendored sources to duckdb/duckdb@40c9c5a5f9b54dcaf75c45ecaa311ec478721559 (#333).

- Update vendored sources to duckdb/duckdb@379a80032a96a454190c4d2f524898ecad8fec89 (#332).

- Update vendored sources to duckdb/duckdb@20100aa2560b68b2f0b46bdc07877a96ed270959 (#331).

- Update vendored sources to duckdb/duckdb@5896c638099998449f06ce1a61e6c01045ba4a7f (#330).

- Update vendored sources to duckdb/duckdb@1a2791b7b415ee41e2285e298ee97f37caf9eeeb (#329).

- Update vendored sources to duckdb/duckdb@01c5bed3c2235171f59527832b1d41fc4a669219 (#328).

- Update vendored sources to duckdb/duckdb@686bcd10b3d617b8a00c41505ab1a97d8c53319f (#327).

- Update vendored sources to duckdb/duckdb@2e78e027dbc812e301088cb72aec80025af0b7a2 (#326).

- Update vendored sources to duckdb/duckdb@4b8274729b3037ce1c3528e90896aa3f6d94559b (#325).

- Update vendored sources to duckdb/duckdb@de5f77c08b5c37afc511e581212639050be2c691 (#324).

- Update vendored sources to duckdb/duckdb@7691b57aa1ef638c4b825c388b1bd2877a4e8ec4 (#323).

- Update vendored sources to duckdb/duckdb@b881dc1265f222e0de23403d8b3c155e8a0c5f17 (#322).

- Update vendored sources to duckdb/duckdb@2be970dda0e5047b1075f938691455d63ba63a67 (#321).

- Update vendored sources to duckdb/duckdb@573bedb4c23ae67248fa7545c5af6f455b9523a8 (#320).

- Update vendored sources to duckdb/duckdb@892f631d24711e3911e8bac2baca66ebf07d9edb (#319).

- Update vendored sources to duckdb/duckdb@ea6f5c4e0903ebfe171969a214c19b77ccb7f7e8 (#318).

- Update vendored sources to duckdb/duckdb@0af71afe6c3e932c1f55b29418c3aef8eebf671f (#317).

- Update vendored sources to duckdb/duckdb@48a8b81d5264adae02777b80b73d69be6ea6aa36 (#316).

- Update vendored sources to duckdb/duckdb@5f4af5343a4f09c3ba184a171bbcf9abd9c8b139 (#315).

- Update vendored sources to duckdb/duckdb@0e6f3fb91a072d370eb81d200cff4ba952bf20f2 (#314).

- Update vendored sources to duckdb/duckdb@5bdb091a5d67460da3ca3a89f21b7cdc588d4544 (#313).

- Update vendored sources to duckdb/duckdb@6e24bb278d11538e46ce69446cd2849d331bc7a4 (#312).

- Update vendored sources to duckdb/duckdb@b1bae91af9cbf8443b69aa851accba42657fb3fb (#311).

- Update vendored sources to duckdb/duckdb@bb5f35c7af618d7636a1f61b26aa6a5c60b0d88a (#310).

- Update vendored sources to duckdb/duckdb@4cabb03b151deb6aec8b14a2496f1b2d9031574a (#309).

- Update vendored sources to duckdb/duckdb@dd2f87c0e2038e3bbfffecd904f407b80f298212 (#308).

- Update vendored sources to duckdb/duckdb@729468452530e898b34a9eec3b48574f8f6fe70e (#307).

- Update vendored sources to duckdb/duckdb@afecd99dbbcf9dec503ffffd2b9fefb8d9d826bd (#306).

- Update vendored sources to duckdb/duckdb@8eff1500c78807d6ff6f4cac99d799da27ff0f2b (#305).

- Update vendored sources to duckdb/duckdb@87ba8503f2a2d53284d0cde88e52df39959eeffa (#304).

- Update vendored sources to duckdb/duckdb@58fe5162afadc1a9b52cc095a86ad1769d3e9384 (#303).

- Update vendored sources to duckdb/duckdb@536fb3b02b0f0e436eb0b1345ae4b155c2993fa4 (#302).

- Update vendored sources to duckdb/duckdb@de92c08cb0585ccb364c3daf0b7e251841dc088b (#301).

- Update vendored sources to duckdb/duckdb@7d2a6d0332ca85730220c926fe8d2330ed2cb6cd (#300).

- Update vendored sources to duckdb/duckdb@13ace3f6ccbd81fa1f66a467583aab10bd888496 (#299).

- Update vendored sources to duckdb/duckdb@69afac464d1f0de4dedab96e26fec05d5b8118c8 (#298).

- Update vendored sources to duckdb/duckdb@e08c0bf105c2ad3d1a6445488182aedf680306e6 (#297).

- Update vendored sources to duckdb/duckdb@567bdebcba6e58da96ceb9465505a38a6c60e69f (#296).

- Update vendored sources to duckdb/duckdb@47715960b6ce0b724d9d061addbc85d0397367bf (#295).

- Update vendored sources to duckdb/duckdb@de13238537197a5e23b3450e8c931844034ca047 (#294).

- Update vendored sources to duckdb/duckdb@c84676023c279bfec3441657d54baaef499276f5 (#293).

- Update vendored sources to duckdb/duckdb@610d79431c7aeccb0d6a4cf9ce2c04a4a96d2f63 (#292).

- Update vendored sources to duckdb/duckdb@dabc6df8f5608453f2da1e23b16d55d6df2aaf52 (#291).

- Update vendored sources to duckdb/duckdb@8226769114e16a3cb42d38bfe58c218a9009b1a3 (#290).

- Update vendored sources to duckdb/duckdb@3897524b31f668ce73fef0b1e63c2a7e6e58cbb1 (#289).

- Update vendored sources to duckdb/duckdb@226c56b7dff9174ce54c83b907d59bca35363040 (#288).

- Update vendored sources to duckdb/duckdb@4d8693be1a39e3cb4c1ce42d6bc64978a5f6e7be (#287).

- Update vendored sources to duckdb/duckdb@35346d87637d8e6731ec1fcd1909c4a309a6d6ad (#286).

- Update vendored sources to duckdb/duckdb@f94b8acedb26d606691c62b3a80ee3ab45eb4ad3 (#285).

- Update vendored sources to duckdb/duckdb@42c504b821beba03867241dde68e9408a9740806 (#284).

- Update vendored sources to duckdb/duckdb@a6b5523b3a55961b282c20fe2704ec955a311069 (#283).

- Remove hotfix.

- Update vendored sources to duckdb/duckdb@56619faf054a284b88317a811d8f0cab0fe0974a (#281).

- Update vendored sources to duckdb/duckdb@8ecc90c8d60ce446f227fad40fe8fbafdaf2b4e1 (#280).

- Update vendored sources to duckdb/duckdb@0d612daeec725915c1b3083a6a8f5e854f424fb2 (#279).

- Update vendored sources to duckdb/duckdb@798f5a2ba0ddf1d849355293cd5d7debb2dc9e9a (#278).

- Update vendored sources to duckdb/duckdb@b32a97a77241fcd3fb29ac6b007035d8d733e8fc (#277).

- Update vendored sources to duckdb/duckdb@f683023d703649b6a813e6f4d5aaf2d329c58a72 (#276).

- Update vendored sources to duckdb/duckdb@7f3889c389b2e6e7111c2963c4cca1685de5e791 (#275).

- Update vendored sources to duckdb/duckdb@5819112b7e6480c377255ccab6f4e1657730b5fe (#274).

- Update vendored sources to duckdb/duckdb@9ed561eee5afc2242f73de5ea9c8cf1422c32a40 (#273).

- Update vendored sources to duckdb/duckdb@f0dbafd48f62dbd6ec1c763dd38bab2a611dac43 (#272).

- Update vendored sources to duckdb/duckdb@18c5431edff65f2260874a0a7290cd10069f9e59 (#271).

- Update vendored sources to duckdb/duckdb@f97ad19a296aa6f37e24a23a7ea2cdb87ebe6813 (#270).

- Update vendored sources to duckdb/duckdb@7abb7065d6a924f87d8cd7e61f3c1a488b825554 (#269).

- Update vendored sources to duckdb/duckdb@6aa0ab01b0e0cd008a2331a7deba1f6c7dc190fa (#268).

- Update vendored sources to duckdb/duckdb@8c1ef04afaad4e9901e714e76a22a4ecd7f96b10 (#267).

- Update vendored sources to duckdb/duckdb@e1c738e7e29e7f105d5c4a67df7a44bc2f3dc909 (#266).

- Update vendored sources to duckdb/duckdb@cdf7125edb568360896cc4ae01f7e52ece68020a (#265).

- Update vendored sources to duckdb/duckdb@16193a714ebac04fa89d0074b1c4d42e62e9fb61 (#264).

- Update vendored sources to duckdb/duckdb@285553fe3e6962bc2be7a69486e7f1bb223f8f1b (#263).

- Update vendored sources to duckdb/duckdb@e5d994bbc6c3e158264af3156f71e7f0340a1d0c (#262).

- Update vendored sources to duckdb/duckdb@627a70286b70dc6b3c35c2f5f4ebea0552f7c6e8 (#261).

- Update vendored sources to duckdb/duckdb@862852fa395b99735e5713cb55d0cea1d9320659 (#260).

- Update vendored sources to duckdb/duckdb@ecb8dc908b1fc97ed6255284701de8c57a9f8c39 (#259).

- Update vendored sources to duckdb/duckdb@b33069bb4ec5ed1e369a260efdb2aab60fa5ec79 (#247).

- Update vendored sources to duckdb/duckdb@9ad037f3adfe372f17b5178a449ac4b6f9142240 (#246).

- Update vendored sources to duckdb/duckdb@1345b3013e801be526e7fac8c8984c89b0033d6a (#245).

- Update vendored sources to duckdb/duckdb@bb97c95a1ad2c277fcf2a60bb1a8af4b0f29b6c7 (#244).

- Update vendored sources to duckdb/duckdb@26685b133edd712ef62e74dbf25ea611e1cf91dc (#243).

- Update vendored sources to duckdb/duckdb@513c2f22c0923045179a8800edf72d212a9bf682 (#242).

- Update vendored sources to duckdb/duckdb@fe535b02b3b8d2b3ac7660134fd588848be9e859 (#241).

- Update vendored sources to duckdb/duckdb@b371fc1b9a8960af25205a85ea89b381e1f98705 (#240).

- Update vendored sources to duckdb/duckdb@c4b6b8f3543bf440d4149a824eed118e4e54c4be (#239).

- Update vendored sources to duckdb/duckdb@10ea4832d3f1850685a65369e0b19c27ec81e638 (#238).

- Update vendored sources to duckdb/duckdb@f6a8ec460ae23e20e6f52859c32c96012dcc0b13 (#236).

- Update vendored sources to duckdb/duckdb@8d4a30cf72c2695c15bed2ec69b5a5bc56a5a594 (#235).

- Update vendored sources to duckdb/duckdb@367aa8db1cc622c46661d762f9cafdd88263040e (#234).

- Update vendored sources to duckdb/duckdb@3d85a139fe1f4c78284a0e8cde522a38f2bcde0a (#233).

- Update vendored sources to duckdb/duckdb@a4f0adb1cf051f6ec4d58326ccf4fc3d3f333d35 (#232).

- Update vendored sources to duckdb/duckdb@ad4639ed1a3448e0c7383d8601d3b797a1861c86 (#231).

- Update vendored sources to duckdb/duckdb@b8df1598853d55f4421bb72dd3d86db553e897b4 (#230).

- Update vendored sources to duckdb/duckdb@f5048f0ffd25b9d1d67b1a68f75ac435c9f5cbfa (#229).

- Update vendored sources to duckdb/duckdb@ac8efca3fc3bc1fa277a0ca32104e2e861b6eef5 (#228).

- Update vendored sources to duckdb/duckdb@c2e18955aff66454aa3ab5b39abd6f3c90f8010b (#227).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#226).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#220).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#219).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#218).

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10430870381

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425609276

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425483466

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10223714659

- Remove temporary patch.

- Enable creation of compilation database.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9879707346

- Adapt glue code.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9727972793

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9692337257

- Fix rfuns vendoring.

- Add another brotli patch.

- Brotli patch and compilation flags.

- Update vendored sources (tag v1.0.0) to duckdb/duckdb@1f98600c2cf8722a6d2f2d805bb4af5e701319fc.

  🦆

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources to hannes/duckdb-rfuns@397ab2a5efa254ea71e45f92b1346e2de6617d59.

- `n_distinct()` followup (@lschneiderbauer, #158).

- Improve yyjson patch.

- Add yyjson patch.

- Format.

- Adapt to `shared_ptr` changes.

- Add patch.

- Update vendored sources (tag v0.10.2) to duckdb/duckdb@1601d94f94a7e0d2eb805a94803eb1e3afbbe4ed.

- Fix patch.

- Fix generated Makevars.win.

- Add patch for re2 update.

- Apply patches during vendoring.

- Harmonize test file names.

- Restore vendor script, new script for step-by-step vendoring.

- Change maintainer.

- Use temporary clone.

- Always vendor next commit.

- Duckdir -\> upstream_dir.

- Ignore.

- Bump version.

- Build-ignore autogenerated files.

- Add revdepcheck results.

- Ellipsis before cache argument.

- Sync tests.

- Update NEWS.

- Bump version.

- Change directory location for extensions and secrets for v.0.10.0 release (@Tmonster, #73).

- Bump version.

- Update vendored sources to duckdb/duckdb@d4c774b1f15ed88c608154156d4c00f9235dbaf3 (#85).

- Executable script.

- Fix Dockerfile deps.

- Compose with threadcheck.

- Improve Docker Compose infrastructure.

- Add Docker Compose infrastructure for running with r-debug.

- Style.

- Sync duckplyr tests (#78).

- Update vendored sources to duckdb/duckdb@24148408432d05bda7cf86f2736d24920c51577c (#57).

- Update vendored sources to duckdb/duckdb@d51e1b06fad726a606ceb70c1530e21121633f31 (#53).

- Remove last instance of `default_connection()` (#50).

- Bump, tidy, news.

- Bump version.

- Update duckplyr tests.

- Build-ignore.

- Skip DBItest tests if not installed (#30).

- Fix tests when dplyr is missing (#29).

- CRAN comments.

- Bump verson.

- Remove unneeded importFrom (#27).

- Build-ignore.

- Updated results.

- Adapt to changed setops implementation in duckplyr.

- Whitespace sync.

- Add revdepcheck results, CC @hannes.

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

- Add fledge workflow.

- Use stable pak (#591).

- Latest changes (#584).

- Tweak patch call.

- Can't check incoming.

- Update actions to avoid warnings (#524).

- Use pkgdown branch (#523).

- Bring back stepwise vendoring.

- Don't remove dir.

- Add env.

- Vendor without creating PR.

- Set up R for r-hub.

- Force vendoring when tag.

- Fix passing branch names as reef.

- Pass inputs.ref to create-pull-request.

- Fix PR generation for snapshot tests for vendoring.

- Flip order.

- Use inputs.

- Use head ref for status reports.

- Check job.status.

- Tweak.

- Fix final status reporting.

- Fix status.

- Bump version of action.

- Post status for workflow_dispatch.

- Only smoke test for workflow_dispatch.

- Move condition to check if status event is triggered.

- Install package manually, faster.

- Verbosity.

- Improve support for protected branches, without fledge (#248).

- Fix vendoring (#225).

- Fix vendoring workflow (#217).

- Wait for pkgdown (#215).

- Fix builds (#213).

- Sync with latest developments.

- Use v2 instead of master.

- Inline action.

- Use dev roxygen2 and decor.

- Fix on Windows, tweak lock workflow.

- Avoid checking bashisms on Windows.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.

- Prepare for dynamic check matrix.

- Fail if patch does not apply.

- Add patches.

- Move caching of duckdb prebuilt archive.

- More careful patching.

- Better tag detection.

- Add R version to cache key.

- Logic.

- Fix vendoring.

- Add rhub2 workflow.

- Avoid vendoring past most recent tag.

- Always vendor tags.

- Fix condition.

- Fix.

- Fix vendoring.

- Only run check if vendoring changed anything.

- Show remaining commits to be vendored.

- Avoid concurrency, more is more.

- Logging.

- Fix typo.

- Fix typo.

- Also trigger when updating vendoring script.

- Dry-run push.

- Pull before vendoring.

- Simplify.

- Use most recent commit.

- Improve concurrency.

- Show stats.

- No cancel in progress, deep fetch.

- Debug.

- Debug.

- Debug.

- Fix typo.

- Vendor only next commit.

- Fix path.

- Vendor every five minutes, but only the next commit.

- Update vendored sources nightly (#25, #82).

- Add workflow file for labelling issues as 'High Priority'.

## Documentation

- Upgrade roxygen2.

- Fix typo.

- Add list of contributors (#2, #94).

- Use pkgdown BS5 (@maelle, #31, #70).

- Link to R documentation page.

- Add dev installation instructions, CC @hannes.

## Testing

- Sync tests with duckplyr (#596).

- Skip if not installed.

- Skip if not installed.

- Add tests for comparison expression (@toppyy, #462).

- Update snapshot.

- Update duckplyr tests.

- Tweak tests.

- Add csv reading test for `duckdb_read_csv(na.strings = )` (@Tmonster, #10).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0 (#84).

- Update duckplyr tests.

- Fix snapshot tests again.

- Skip failing test.

- Fix snapshot tests.

## Breaking changes

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## fledge

- Bump version to 1.1.3.9003 (#604).

- Bump version to 1.1.3.9002 (#602).

- Bump version to 1.1.3.9001 (#599).

## README

- Display different logo for light/dark mode (@szarnyasg, #129).

## Uncategorized

- Merge branch 'cran-1.1.2'.

- Merge pull request #516 from duckdb/f-tweak.

  Fix signedness

- Merge pull request #461 from duckdb/f-exp-depth-2.

  Sync tests

- Merge pull request #392 from duckdb/cran-1.1.0.

  Bump

- Merge pull request #388 from duckdb/f-380-ppm-strip.

  Merge pull request #386 from duckdb/f-380-ppm-strip

- Merge pull request #214 from duckdb/b-ci.

  Only report success once

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13415 (#13415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13431 (#13431).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13439 (#13439).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13202 (#13202).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13268 (#13268).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13434 (#13434).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13433 (#13433).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13421 (#13421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13417 (#13417).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13411 (#13411).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13410 (#13410).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13408 (#13408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13409 (#13409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13358 (#13358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13402 (#13402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13383 (#13383).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13394 (#13394).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13401 (#13401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13370 (#13370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13399 (#13399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13329 (#13329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13344 (#13344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13354 (#13354).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13372 (#13372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13168 (#13168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13359 (#13359).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13356 (#13356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13335 (#13335).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13267 (#13267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13201 (#13201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13360 (#13360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13355 (#13355).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13346 (#13346).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13350 (#13350).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13341 (#13341).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13343 (#13343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13342 (#13342).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13317 (#13317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12886 (#12886).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13313 (#13313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13330 (#13330).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13234 (#13234).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13307 (#13307).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13167 (#13167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12682 (#12682).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13291 (#13291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13290 (#13290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13262 (#13262).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13278 (#13278).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13231 (#13231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13284 (#13284).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13281 (#13281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13283 (#13283).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13280 (#13280).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13282 (#13282).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13275 (#13275).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13260 (#13260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13261 (#13261).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13258 (#13258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13249 (#13249).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13229 (#13229).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13256 (#13256).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13162 (#13162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13230 (#13230).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13233 (#13233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13236 (#13236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13242 (#13242).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13241 (#13241).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13240 (#13240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13223 (#13223).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13207 (#13207).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13170 (#13170).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13203 (#13203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13109 (#13109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13194 (#13194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13191 (#13191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13189 (#13189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13188 (#13188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13186 (#13186).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13063 (#13063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13163 (#13163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13150 (#13150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13182 (#13182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13160 (#13160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13180 (#13180).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13161 (#13161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13151 (#13151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13146 (#13146).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13140 (#13140).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13136 (#13136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13087 (#13087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13101 (#13101).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13108 (#13108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13142 (#13142).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12978 (#12978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13130 (#13130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13123 (#13123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13137 (#13137).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13139 (#13139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13117 (#13117).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13133 (#13133).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13129 (#13129).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13131 (#13131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13127 (#13127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13125 (#13125).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13122 (#13122).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13126 (#13126).

- Merge tag 'v1.0.0-2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13114 (#13114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13093 (#13093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13110 (#13110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13118 (#13118).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13111 (#13111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13106 (#13106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12967 (#12967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13090 (#13090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13098 (#13098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13105 (#13105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13094 (#13094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13084 (#13084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13083 (#13083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13082 (#13082).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13081 (#13081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13089 (#13089).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13086 (#13086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13062 (#13062).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13073 (#13073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13076 (#13076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13074 (#13074).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13015 (#13015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13065 (#13065).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13068 (#13068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13027 (#13027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12579 (#12579).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12998 (#12998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13040 (#13040).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12920 (#12920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13054 (#13054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13056 (#13056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13057 (#13057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13052 (#13052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12995 (#12995).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13050 (#13050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13033 (#13033).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13039 (#13039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13035 (#13035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13030 (#13030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13028 (#13028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13025 (#13025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13023 (#13023).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13024 (#13024).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12953 (#12953).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13002 (#13002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12627 (#12627).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13020 (#13020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13019 (#13019).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13014 (#13014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13010 (#13010).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13013 (#13013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12728 (#12728).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13004 (#13004).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12993 (#12993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12994 (#12994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12931 (#12931).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13003 (#13003).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13001 (#13001).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12785 (#12785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13000 (#13000).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11720 (#11720).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12971 (#12971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12928 (#12928).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12829 (#12829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12929 (#12929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12979 (#12979).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12982 (#12982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12984 (#12984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12980 (#12980).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12942 (#12942).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12973 (#12973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12974 (#12974).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12972 (#12972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12965 (#12965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12968 (#12968).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12970 (#12970).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12966 (#12966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12954 (#12954).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12755 (#12755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12716 (#12716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12912 (#12912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12957 (#12957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12290 (#12290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12955 (#12955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12916 (#12916).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12948 (#12948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12824 (#12824).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12625 (#12625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12787 (#12787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12907 (#12907).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12885 (#12885).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12943 (#12943).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12938 (#12938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12937 (#12937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12932 (#12932).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12890 (#12890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12924 (#12924).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12866 (#12866).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12889 (#12889).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12918 (#12918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12908 (#12908).

- Merge branch 'cran-1.0.0-1'.

- Merge tag 'v1.0.0-1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12913 (#12913).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12914 (#12914).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12851 (#12851).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12887 (#12887).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12858 (#12858).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12888 (#12888).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12884 (#12884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12751 (#12751).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12848 (#12848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12498 (#12498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12398 (#12398).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12878 (#12878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12859 (#12859).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12834 (#12834).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12844 (#12844).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12849 (#12849).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12847 (#12847).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11191 (#11191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12840 (#12840).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12698 (#12698).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12806 (#12806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12734 (#12734).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12835 (#12835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12812 (#12812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12832 (#12832).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12691 (#12691).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12810 (#12810).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12780 (#12780).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12575 (#12575).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12803 (#12803).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12791 (#12791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12754 (#12754).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12765 (#12765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12685 (#12685).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12770 (#12770).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12768 (#12768).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12769 (#12769).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12762 (#12762).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12759 (#12759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12753 (#12753).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12636 (#12636).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12496 (#12496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12745 (#12745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12740 (#12740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12738 (#12738).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12737 (#12737).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12736 (#12736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12731 (#12731).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12730 (#12730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12599 (#12599).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12678 (#12678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12725 (#12725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12724 (#12724).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12708 (#12708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12697 (#12697).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12705 (#12705).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12717 (#12717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12681 (#12681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12692 (#12692).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12694 (#12694).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12689 (#12689).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12690 (#12690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12671 (#12671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12679 (#12679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12288 (#12288).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12655 (#12655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12669 (#12669).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12653 (#12653).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12663 (#12663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12658 (#12658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12654 (#12654).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12637 (#12637).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12650 (#12650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12642 (#12642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12652 (#12652).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12639 (#12639).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12635 (#12635).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12629 (#12629).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12630 (#12630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12633 (#12633).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12603 (#12603).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12608 (#12608).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12554 (#12554).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12539 (#12539).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12516 (#12516).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12515 (#12515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12445 (#12445).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12456 (#12456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12467 (#12467).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12465 (#12465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12470 (#12470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12461 (#12461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12448 (#12448).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12436 (#12436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12421 (#12421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12424 (#12424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12401 (#12401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12409 (#12409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12370 (#12370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12405 (#12405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12393 (#12393).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12391 (#12391).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12352 (#12352).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12360 (#12360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12344 (#12344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12332 (#12332).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12305 (#12305).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12302 (#12302).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12282 (#12282).

- Merge branch 'cran-1.0.0'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12291 (#12291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12281 (#12281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12257 (#12257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12267 (#12267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12264 (#12264).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12271 (#12271).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12259 (#12259).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12269 (#12269).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12265 (#12265).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12260 (#12260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12266 (#12266).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12244 (#12244).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12240 (#12240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12123 (#12123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12221 (#12221).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12226 (#12226).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12238 (#12238).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12209 (#12209).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12206 (#12206).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12195 (#12195).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12194 (#12194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12193 (#12193).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12189 (#12189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12183 (#12183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12111 (#12111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12169 (#12169).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12056 (#12056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12167 (#12167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12173 (#12173).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12175 (#12175).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12163 (#12163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12157 (#12157).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12168 (#12168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12159 (#12159).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12165 (#12165).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12109 (#12109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12152 (#12152).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12162 (#12162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12160 (#12160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12156 (#12156).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12144 (#12144).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12150 (#12150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12143 (#12143).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12086 (#12086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12110 (#12110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11677 (#11677).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12135 (#12135).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12130 (#12130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12131 (#12131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12124 (#12124).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12121 (#12121).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12120 (#12120).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12119 (#12119).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12116 (#12116).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12099 (#12099).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12091 (#12091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12108 (#12108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12112 (#12112).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12081 (#12081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12077 (#12077).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11493 (#11493).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12072 (#12072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12098 (#12098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12094 (#12094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12090 (#12090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12087 (#12087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12088 (#12088).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11848 (#11848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12070 (#12070).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12085 (#12085).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12076 (#12076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12084 (#12084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12063 (#12063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12083 (#12083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12045 (#12045).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12026 (#12026).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12049 (#12049).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12068 (#12068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12064 (#12064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12055 (#12055).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12061 (#12061).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12044 (#12044).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12051 (#12051).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12050 (#12050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12054 (#12054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12052 (#12052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12053 (#12053).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12035 (#12035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12043 (#12043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11874 (#11874).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12039 (#12039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12028 (#12028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11998 (#11998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12030 (#12030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11984 (#11984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12029 (#12029).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11937 (#11937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12022 (#12022).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12027 (#12027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12025 (#12025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12011 (#12011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11867 (#11867).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11976 (#11976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11831 (#11831).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12013 (#12013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11965 (#11965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11978 (#11978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11987 (#11987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11982 (#11982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11994 (#11994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12012 (#12012).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12014 (#12014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12015 (#12015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11999 (#11999).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11761 (#11761).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11964 (#11964).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11969 (#11969).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11967 (#11967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11955 (#11955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11966 (#11966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11956 (#11956).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11929 (#11929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11920 (#11920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11441 (#11441).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11835 (#11835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11912 (#11912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11906 (#11906).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11918 (#11918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11806 (#11806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11902 (#11902).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11771 (#11771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11898 (#11898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11884 (#11884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11745 (#11745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11785 (#11785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11880 (#11880).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11879 (#11879).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11878 (#11878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11746 (#11746).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11812 (#11812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11794 (#11794).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11792 (#11792).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11788 (#11788).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11797 (#11797).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11846 (#11846).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11861 (#11861).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11524 (#11524).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11830 (#11830).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11829 (#11829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11825 (#11825).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11821 (#11821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11816 (#11816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11757 (#11757).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11795 (#11795).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11791 (#11791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11787 (#11787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11625 (#11625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11763 (#11763).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11774 (#11774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11777 (#11777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11765 (#11765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11596 (#11596).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11759 (#11759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11679 (#11679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11719 (#11719).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11717 (#11717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11736 (#11736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11732 (#11732).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11730 (#11730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11726 (#11726).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11733 (#11733).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11735 (#11735).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11702 (#11702).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11725 (#11725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11723 (#11723).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11721 (#11721).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11696 (#11696).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11716 (#11716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11711 (#11711).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11708 (#11708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11673 (#11673).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10978 (#10978).

- Merge branch 'cran-0.10.2'.

- Merge branch 'cran-0.10.2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11681 (#11681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11678 (#11678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11676 (#11676).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11674 (#11674).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11675 (#11675).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11665 (#11665).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11670 (#11670).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11671 (#11671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11668 (#11668).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11667 (#11667).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11663 (#11663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11616 (#11616).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11659 (#11659).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11656 (#11656).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11655 (#11655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11465 (#11465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11645 (#11645).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11650 (#11650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11648 (#11648).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11642 (#11642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11630 (#11630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11631 (#11631).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11614 (#11614).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11462 (#11462).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11515 (#11515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11619 (#11619).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11618 (#11618).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11622 (#11622).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11613 (#11613).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11601 (#11601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11512 (#11512).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11273 (#11273).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11551 (#11551).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11604 (#11604).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11587 (#11587).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11585 (#11585).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11580 (#11580).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11461 (#11461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11267 (#11267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11558 (#11558).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11528 (#11528).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11546 (#11546).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11544 (#11544).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11519 (#11519).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11525 (#11525).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11270 (#11270).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11496 (#11496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11513 (#11513).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11495 (#11495).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11506 (#11506).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11446 (#11446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11401 (#11401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11498 (#11498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11497 (#11497).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11247 (#11247).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11486 (#11486).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11408 (#11408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11464 (#11464).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11478 (#11478).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11466 (#11466).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11470 (#11470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11458 (#11458).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11358 (#11358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11402 (#11402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11399 (#11399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11443 (#11443).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11456 (#11456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11454 (#11454).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11429 (#11429).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11436 (#11436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11437 (#11437).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11418 (#11418).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11428 (#11428).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11424 (#11424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11414 (#11414).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11415 (#11415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11405 (#11405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11400 (#11400).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11397 (#11397).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11396 (#11396).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11392 (#11392).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11390 (#11390).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11360 (#11360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11356 (#11356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11372 (#11372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11369 (#11369).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11376 (#11376).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11343 (#11343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11252 (#11252).

- Merge branch 'cran-0.10.1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11347 (#11347).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11326 (#11326).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11313 (#11313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11340 (#11340).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11327 (#11327).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11321 (#11321).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11329 (#11329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11325 (#11325).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11314 (#11314).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11315 (#11315).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11318 (#11318).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11309 (#11309).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11320 (#11320).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11317 (#11317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11316 (#11316).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11306 (#11306).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11297 (#11297).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11304 (#11304).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10878 (#10878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11215 (#11215).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11286 (#11286).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11203 (#11203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11258 (#11258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11276 (#11276).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11233 (#11233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11220 (#11220).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11248 (#11248).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11257 (#11257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11243 (#11243).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11236 (#11236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11231 (#11231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11222 (#11222).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11139 (#11139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11223 (#11223).

- Merge branch 'cran-0.10.1'.

- Merge branch 'cran-0.10.1'.

- Merge pull request #124 from duckdb/b-34-56-58-59-60-83-conn-2.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11218 (#11218).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11214 (#11214).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11149 (#11149).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11172 (#11172).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11106 (#11106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11210 (#11210).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11171 (#11171).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11208 (#11208).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11201 (#11201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11182 (#11182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11205 (#11205).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11200 (#11200).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11199 (#11199).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11183 (#11183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11198 (#11198).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11185 (#11185).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11188 (#11188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11190 (#11190).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11177 (#11177).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11179 (#11179).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11174 (#11174).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11161 (#11161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11151 (#11151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11138 (#11138).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11132 (#11132).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11145 (#11145).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11141 (#11141).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11127 (#11127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11128 (#11128).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11130 (#11130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11136 (#11136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11114 (#11114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11108 (#11108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11111 (#11111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11093 (#11093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11083 (#11083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11103 (#11103).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11105 (#11105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11090 (#11090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11096 (#11096).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11094 (#11094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11091 (#11091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10976 (#10976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11017 (#11017).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11086 (#11086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11073 (#11073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11072 (#11072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11069 (#11069).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11056 (#11056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11064 (#11064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11057 (#11057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11031 (#11031).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11046 (#11046).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10984 (#10984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11035 (#11035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11043 (#11043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11034 (#11034).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11039 (#11039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11021 (#11021).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11020 (#11020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11011 (#11011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11002 (#11002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11008 (#11008).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11005 (#11005).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10997 (#10997).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10992 (#10992).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10993 (#10993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10994 (#10994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10998 (#10998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10983 (#10983).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10990 (#10990).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10948 (#10948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10955 (#10955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10972 (#10972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10987 (#10987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10985 (#10985).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10938 (#10938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10973 (#10973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10971 (#10971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10933 (#10933).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10594 (#10594).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10958 (#10958).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10957 (#10957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10949 (#10949).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10936 (#10936).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10946 (#10946).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10939 (#10939).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10937 (#10937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10945 (#10945).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10941 (#10941).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10944 (#10944).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10870 (#10870).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10925 (#10925).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10704 (#10704).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10923 (#10923).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10922 (#10922).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10920 (#10920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10918 (#10918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10915 (#10915).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10912 (#10912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10690 (#10690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10908 (#10908).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10828 (#10828).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10799 (#10799).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10898 (#10898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10909 (#10909).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10850 (#10850).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10873 (#10873).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10897 (#10897).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10896 (#10896).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10893 (#10893).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10890 (#10890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10864 (#10864).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10872 (#10872).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10884 (#10884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10882 (#10882).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10740 (#10740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10862 (#10862).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10863 (#10863).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10610 (#10610).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10597 (#10597).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10714 (#10714).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10855 (#10855).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10854 (#10854).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10446 (#10446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10848 (#10848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10742 (#10742).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10837 (#10837).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10774 (#10774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10789 (#10789).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10822 (#10822).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10817 (#10817).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10821 (#10821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10816 (#10816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10755 (#10755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10796 (#10796).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10807 (#10807).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10791 (#10791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10771 (#10771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10773 (#10773).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10777 (#10777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10776 (#10776).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10601 (#10601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10765 (#10765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10758 (#10758).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10658 (#10658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10642 (#10642).

- Merge pull request #103 from lnkuiper/namespace.

  Remove std:: from unordered_map

- Merge pull request #108 from Tmonster/fix_Rbuildignore.

  Fix invalid regex in .Rbuildignore

- Merge pull request #48 from olivroy/patch-1.

- Merge pull request #76 from romainfrancois/patch-1.

- Merge pull request #45 from duckdb/b-cpp11-printf.

- Merge pull request #33 from duckdb/adbcdef.

  Fix duckdb_adbc_init signature

- Merge pull request #28 from duckdb/f-news.

- Merge pull request #19 from szarnyasg/nits-links-for-extensions.

  Add links and fix nits for extensions

- Merge pull request #20 from Tmonster/fix-vendor-script.

  fix vendor script


# duckdb 1.1.3.9011

## Bug fixes

- Avoid compiler warning related to `Rboolean` (#594).

- Check `"duckdb.materialize_message"` symbol (#592).

- `%in%` works correctly as part of a `&` conjunction (#528).

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- Use portable format modifiers.

- Correctly compute vector length for data frames passed to relational functions (#379).

- Set `initialize_in_main_thread`, add patch.

- Compatibility with clang19 2.

- Compatibility with clang19.

- Uninitialized.

- Fix uninitialized move 5.

- Fix uninitialized move 4.

- Fix uninitialized move 3.

- Fix uninitialized move 2.

- Fix uninitialized move.

- Avoid triggering re2 in tests (#176).

- Correct usage of `win_current_group()` instead of `win_current_order()` in SQL translation (@lschneiderbauer, #173, #175).

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).

- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).

- Fix vendoring script without arguments, align.

- Don't run tests that invoke re2 by default (#121, #127).

- `dplyr::tbl()` works again when a Parquet or CSV file is passed instead of a table name (#38, #91).

- `DBI::dbQuoteIdentifier()` correctly quotes identifiers that start with a digit (#67, #92).

- Align the argument order of `dbWriteTable()` with the DBI specs (@eitsupi, #43, #49).

- Fix LTO builds.

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (@romainfrancois, #186).

- Xz-compress duckdb sources in the tarball (#530).

- Add `col.types` argument to `duckdb_read_csv()` (@eli-daniels, #383, #445).

- `last_rel` (#529).

- `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- Rethrow errors with rlang if installed (#522).

- Catch and add query context for statement extraction (tidyverse/duckplyr#219, #521).

- Implement query cancellation (#514, #515).

- Add comparison expression to relational api (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

- Bump vendored cpp11 to v0.5.0 (#382, #387).

- Tweak implementation of `r_base::sum()` (#381, #385).

- `n_distinct()` supports `na.rm = TRUE` with a single vector argument again (@lschneiderbauer, #204, #216).

- New `rel_from_sql()` (#212).

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

- Support fetching `MAP` type (#61, #165).

- Add dbplyr translations for `clock::date_count_between()` (@edward-burn, #163, #166).

- `round()` duckdb translation uses `ROUND_EVEN()` instead of `ROUND()` (@lschneiderbauer, #146, #157).

- New `sort` argument to `rel_order()` (@toppyy, #168).

- Add dbplyr translations for `clock::add_days()`, `clock::add_years()`, `clock::get_day()`, `clock::get_month()`, and `clock::get_year()` (#153).

- Use latest tests from DBItest (#148).

- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).

- Include rfuns extension (hannes/duckdb-rfuns#78, #144).

- Map `NA` to `SQLNULL` (#143).

- New `tbl_file()` and `tbl_query()` to explicitly access tables and queries as dbplyr lazy tables (#96).

- Initial ALTREP support for `LIST` logical type (@romainfrancois, #77).

- Update core to duckdb v0.10.0 (#90).

- New private `rel_to_parquet()` to write a relation to parquet (@Tmonster, #46).

- Update vendored sources to duckdb/duckdb@3c695d7ba94d95d9facee48d395f46ed0bd72b46 (#42).

- Add `prod()` translation for dbplyr (@m-muecke, #40).

- Support list of strings for column references in R API (@Tmonster, #14).

- Update vendored code to v0.9.1 (#26).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Bump for pre-release.

- Keep `cleanup` files to accommodate different build scenarios (#536).

- Update vendored sources to duckdb/duckdb@19864453f7d0ed095256d848b46e7b8630989bac (#580).

- Update vendored sources to duckdb/duckdb@c3ca3607c221d315f38227b8bf58e68746c59083 (#579).

- Update vendored sources to duckdb/duckdb@9cba6a2a03e3fbca4364cab89d81a19ab50511b8 (#578).

- Update vendored sources to duckdb/duckdb@c6c08d4c1b363231b3b9689367735c7264cacefb (#577).

- Update vendored sources to duckdb/duckdb@7f34190f3f94fc1b1575af829a9a0ccead87dc99 (#576).

- Update vendored sources to duckdb/duckdb@78b65d4a9aa80c4be4efcdd29fadd6f0c893f1ce (#575).

- Update vendored sources to duckdb/duckdb@c31c46a875979ce3343edeedcb497485ca2fd751 (duckdb/duckdb#14542, #574).

- Update vendored sources to duckdb/duckdb@4ba2e66277a7576f58318c1aac112faa67c47b11 (#573).

- Update vendored sources to duckdb/duckdb@247fcb31733a5297c1070fbd244f2349091253aa (duckdb/duckdb#14601, #572).

- Update vendored sources to duckdb/duckdb@1a519fce83b3d262247325dbf8014067686a2c94 (duckdb/duckdb#14600, #571).

- Update vendored sources to duckdb/duckdb@b653a8c2b760425a83302e894bf930f18a1bdf64 (#570).

- Update vendored sources to duckdb/duckdb@79bf967e1b6ab438e0a83a014e937af571ed7acb (#569).

- Update vendored sources to duckdb/duckdb@4b62ee43a7d5f62313d77d36dec8aea29412431f (#568).

- Update vendored sources to duckdb/duckdb@3293c92b6e657084318f7556b14077896b333109 (#567).

- Update vendored sources to duckdb/duckdb@8664b710beb205ec6fc7e9f3d18dfe24dd28625f (#566).

- Update vendored sources to duckdb/duckdb@92a1ccbcef04dda11c85fa2bf6daf27daf8d9c49 (#565).

- Update vendored sources to duckdb/duckdb@2635a87a566b90e086caa84805019f66eedf0859 (#564).

- Update vendored sources to duckdb/duckdb@0d5ec0057838081251b388726353f09cba9577ad (#563).

- Update vendored sources to duckdb/duckdb@6af32330b51af4d72d3fed665bfc03f78c8b3876 (#562).

- Update vendored sources to duckdb/duckdb@662b0b34eaaf7f52545638cbc87c10e32b33834d (#561).

- Update vendored sources to duckdb/duckdb@bccd37ae7ea09f77b6299165bf80bca3bc1efc7c (#560).

- Update vendored sources to duckdb/duckdb@5090b7396173069bb0d51b0e1341cfa9950c154f (#559).

- Update vendored sources to duckdb/duckdb@f5ebc9b8e1d6c040a2276e0ac4a41d6bf9475880 (duckdb/duckdb#14545, #558).

- Update vendored sources to duckdb/duckdb@b8c5248b9c18f7cafbdf7992421662adbd95bf38 (#557).

- Update vendored sources to duckdb/duckdb@dfdd7968262d912910d8249bde3524e068c67713 (#556).

- Update vendored sources to duckdb/duckdb@d0673165b52e89fe70d1891504e4dea82adeca85 (#555).

- Update vendored sources to duckdb/duckdb@d79e66bd032dbd2066c16a88f517f6da1cd0aa78 (#554).

- Update vendored sources to duckdb/duckdb@0359726be957673a62ab1ab61f1cca9ba5667386 (#553).

- Update vendored sources to duckdb/duckdb@10c42435f1805ee4415faa5d6da4943e8c98fa55 (#552).

- Update vendored sources to duckdb/duckdb@43d26298affa89bc6ca829a1defc4819b42b6fb4 (#551).

- Update vendored sources to duckdb/duckdb@52b43b166091c82b3f04bf8af15f0ace18207a64 (#550).

- Update vendored sources to duckdb/duckdb@0446ab42e96b6269e78f55293f4096fa10224837 (#549).

- Update vendored sources to duckdb/duckdb@ceb77af7935c3c7a4a34e1199abd4d6ea080448c (duckdb/duckdb#14430, #548).

- Update vendored sources to duckdb/duckdb@aed52f5cabe34075c53bcec4407e297124c8d336 (#547).

- Update vendored sources to duckdb/duckdb@e41a881658ae579cedebe19c5070dad660086aea (#546).

- Update vendored sources to duckdb/duckdb@98d4ad28be35cf5c37e18760e76d11bc07be1ab4 (#545).

- Update vendored sources to duckdb/duckdb@1bb332c9c59a9d15b196b4486a6d1ffcaa833ba5 (#544).

- Update vendored sources to duckdb/duckdb@0bbfe09937e3744325f3b2dfdb182e9ac1ff916f (#543).

- Update vendored sources to duckdb/duckdb@08969b4677534b6870bff4c99998c753a6e784fc (#542).

- Update vendored sources to duckdb/duckdb@4756244efa04d204be6f20d55036fc503b7ed49c (#541).

- Update vendored sources to duckdb/duckdb@217ec4722e949eaa49568bd707e49431ef727ab5 (#539).

- Move responsibility for removing CR (#533).

- Terminate all sources with newline (#531).

- Sync duckplyr tests (#527).

- Cleanup, preparation (#525).

- Bump version.

- Update vendored sources (tag v1.1.2) to duckdb/duckdb@f680b7d08f56183391b581077d4baf589e1cc8bd (#510).

- Update vendored sources to duckdb/duckdb@5f49126b92a0899a2049aaa57da886138c5f879d (#509).

- Update vendored sources to duckdb/duckdb@2c21eb1c2eec3a1e359d87fb2a2cd8e427dc03c1 (#508).

- Update vendored sources to duckdb/duckdb@cc067e6b7db33f516437567cbc726536e34ed716 (#507).

- Update vendored sources to duckdb/duckdb@d2dfc6090685470cb09326a7530066fc4b3db42a (#506).

- Update vendored sources to duckdb/duckdb@56e2e0e5721b8547f564fccf252db0ba93c85471 (#505).

- Update vendored sources to duckdb/duckdb@35dfcc06e6c76ad6bd8e4acdae1bcc30751777eb (#504).

- Update vendored sources to duckdb/duckdb@92e0964376a78f990408a0e81af155504b35d27c (#503).

- Update vendored sources to duckdb/duckdb@01e6e98e3875ed12cbcb9257f81844743b1665fa (#502).

- Update vendored sources to duckdb/duckdb@6dc2e9375870e60f82becb1cece4cc878289d3b8 (#501).

- Update vendored sources to duckdb/duckdb@52b19d5ece35be344830800db0e4961f47114aa9 (#500).

- Update vendored sources to duckdb/duckdb@0d3e84330e845ceefdc55a36d52ef0296af5d1e1 (#499).

- Update vendored sources to duckdb/duckdb@d0cf23ead54f191bf2518598edf04e209f07452e (#498).

- Update vendored sources to duckdb/duckdb@d57a94430e50263cbd1b719b984da189e5bba0c5 (#497).

- Update vendored sources to duckdb/duckdb@a5ddffef692c0627dd6c7efaed7cf65148321452 (#496).

- Update vendored sources to duckdb/duckdb@536f979f69b1bbe40d582450b6cfa6a68463f172 (#495).

- Update vendored sources to duckdb/duckdb@443380a11dbb31a1c218a759ec0c3b56880f1c38 (duckdb/duckdb#14249, #494).

- Update vendored sources to duckdb/duckdb@7919e4abc5597dc4fbeb5a19dff19ff69b5c4113 (duckdb/duckdb#14249, #493).

- Update vendored sources to duckdb/duckdb@52f967a42861032fd5f4392609afc195cd025dde (#492).

- Update vendored sources to duckdb/duckdb@1f20676c7d997fe4964a8b51378bf984e53a4b4c (#491).

- Update vendored sources to duckdb/duckdb@8cec9b1537f900e7a644e7b466ea899cf1ca8f8f (#490).

- Update vendored sources to duckdb/duckdb@4f0cd4d60035e8c6afafed47b68b2240b39e3566 (duckdb/duckdb#14212, #489).

- Update vendored sources to duckdb/duckdb@5a9a382a573b107a38f5ee277619b362d5079c32 (#488).

- Update vendored sources to duckdb/duckdb@123b82b9053c4843559035b6723c867b2618b2d9 (#487).

- Update vendored sources to duckdb/duckdb@405e15fcde8a4da4a7c6d3889f992f0a363c05f2 (duckdb/duckdb#14232, #486).

- Update vendored sources to duckdb/duckdb@0e398d95c50ae40730467c53922c8fb8d5c69f90 (#485).

- Update vendored sources to duckdb/duckdb@1eac05ecd3a6b8ec2cdf0c53ccece7ca2effef26 (#484).

- Update vendored sources to duckdb/duckdb@048f5ffcec9c1a4b73cbfbd4158cd5b6669f102b (#483).

- Update vendored sources to duckdb/duckdb@0b2d95601c2d9474f2c823ac3363e9ca14224c7c (#482).

- Update vendored sources to duckdb/duckdb@350d061846ed7e4c96d2efa7b523bb97ae84538a (#481).

- Update vendored sources to duckdb/duckdb@2f6b78c21d1634c7228e00c809a790701705c82b (#480).

- Update vendored sources to duckdb/duckdb@8aca4330ac46be3950c6b12e29040322dd245b7a (#479).

- Update vendored sources to duckdb/duckdb@9931d723ccde2b2435b1a927234338e6f0353d90 (#478).

- Update vendored sources to duckdb/duckdb@d896e73fe2db62b6749b95e30faa8bfa41dc4d32 (#477).

- Update vendored sources to duckdb/duckdb@f8c82ab2620f8066b0141df0c3982885a5258746 (#476).

- Update vendored sources to duckdb/duckdb@ee256eb45552601db71d4cad7a5cd4f46f0d5a1d (#475).

- Update vendored sources to duckdb/duckdb@130aab3f9ddb84e0c6e7f543a99881d8fc1bd6b7 (#474).

- Update vendored sources to duckdb/duckdb@92c65a4341c57f313dbeba5acc7b1fb917808010 (#473).

- Update vendored sources to duckdb/duckdb@47e1d3d60b4d6d075cf88c2707572df12a630a3a (#472).

- Update vendored sources to duckdb/duckdb@45559f5eeb1834454a30490fc4ffad1807e13f3b (#471).

- Update vendored sources to duckdb/duckdb@dfdd09f46c0169c9d8aa5381086e46a66e44fabc (#470).

- Update vendored sources to duckdb/duckdb@89828abb72219957372f316da06f007dadd2a9aa (#469).

- Update vendored sources to duckdb/duckdb@12e9777cf6283f44710b2610ba3d3735a1208751 (duckdb/duckdb#14077, #468).

- Update vendored sources to duckdb/duckdb@4a55e2334232afe94e47ab398ddb44f88fcd6658 (#467).

- Update vendored sources to duckdb/duckdb@0f3c46215feb0fb92d4998977fc31b2f52db6b14 (#466).

- Update vendored sources to duckdb/duckdb@c87246586490b442706d0be66b82d71930a00578 (#465).

- Update vendored sources to duckdb/duckdb@cd8cb3f1c81a74a3b2c1ed7d94e3913485895074 (#464).

- Update vendored sources to duckdb/duckdb@acd16816e31789bdb27e144ccd19ddb9da4fe6df (#463).

- Update vendored sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove uninitialized warnings.

- Document (#456).

- Update vendored sources (tag v1.1.1) to duckdb/duckdb@af39bd0dcf66876e09ac2a7c3baa28fe1b301151 (#454).

- Update vendored sources to duckdb/duckdb@0fe7708eef6b9b77270ca21cb9b5e30a3de84e3c (#453).

- Update vendored sources to duckdb/duckdb@34a3acc6b3354be86fe593d09e0702ab5eafe757 (#452).

- Update vendored sources to duckdb/duckdb@cb2a947e9df4f6c40b6dd5751c412d6946cbb62b (#451).

- Update vendored sources to duckdb/duckdb@64520f224d8a0a096cfe10f0c2cfbd1ac9457811 (duckdb/duckdb#13934, #450).

- Update vendored sources to duckdb/duckdb@b0eee44df70eb7bf9efac5f65dd2eaf7ad1e5403 (#449).

- Update vendored sources to duckdb/duckdb@4fe3dc559d10648691f9ab34f20207771890dd45 (#448).

- Update vendored sources to duckdb/duckdb@6c02032393583f353f2f2a0337a8e16f34dc5d82 (duckdb/duckdb#14026, #447).

- Update vendored sources to duckdb/duckdb@4ce455c84029195ffa4c3e540c10360ae8c73724 (#446).

- Update vendored sources to duckdb/duckdb@03dd0df6185d903ecbff9d80017e5449e78e5017 (#443).

- Update vendored sources to duckdb/duckdb@d1037da3139de90dc0a82df746d8ce92a50d9838 (#442).

- Update vendored sources to duckdb/duckdb@cb27c0423fa7107674c267b5de8eb93dd603cb69 (duckdb/duckdb#13993, #441).

- Update vendored sources to duckdb/duckdb@b787fcc1cb9bc4daf36e6eec19c1e9b2b162f4b0 (duckdb/duckdb#14020, #440).

- Update vendored sources to duckdb/duckdb@0ce863113043806780e776bcfb86b24afcb0263c (#439).

- Update vendored sources to duckdb/duckdb@f9e96b191088e65b4a1f95918312c40e31096dd9 (#438).

- Update vendored sources to duckdb/duckdb@2ff9c687e2c448914a28c59bd50f48f54e47de3c (#437).

- Update vendored sources to duckdb/duckdb@dcc302aef4491db8cc2efd2955ac254a4d62dcbc (#436).

- Update vendored sources to duckdb/duckdb@03976af191370d4020c172a82b28ca7885d98ea3 (#435).

- Update vendored sources to duckdb/duckdb@29c46243993319b0db24509c862126b8e17f1e8c (#434).

- Update vendored sources to duckdb/duckdb@e7da966e87539457f3de94a1bee288861fdca6d6 (#433).

- Update vendored sources to duckdb/duckdb@44bba02cea5d316e38f6edbad7fad3a1f913d63f (#432).

- Update vendored sources to duckdb/duckdb@04a1f750a6fab3f1a9cf3fb7cce5fd119c522304 (#431).

- Update vendored sources to duckdb/duckdb@0da70d9de97ff2cf39ad99b9e30b7e6cb91614b8 (duckdb/duckdb#13933, #430).

- Update vendored sources to duckdb/duckdb@df82a0e2c47e8b3ddd5a93e08530b83bc49e0da0 (#429).

- Update vendored sources to duckdb/duckdb@86723c9912fde7b76d3863b2ccd2d4333251c4af (#428).

- Update vendored sources to duckdb/duckdb@66d8ed93f67a00006ec99226c1205bcffb1ef07b (duckdb/duckdb#13941, #427).

- Update vendored sources to duckdb/duckdb@b2f68017070c1910dd3438f9428c7162cb428f84 (#426).

- Update vendored sources to duckdb/duckdb@35a104529b56c4f4f1e383e2ead26d6047d3442e (#425).

- Update vendored sources to duckdb/duckdb@b8c5fa937919631b759a70e33f068aa05de8bd36 (#424).

- Update vendored sources to duckdb/duckdb@18670a10f1b3da56382e272518d6b149e489ca51 (#423).

- Update vendored sources to duckdb/duckdb@0b0c95b9dc685e1a6ca011d8e086d885afbe0398 (#422).

- Update vendored sources to duckdb/duckdb@e5e1595da75ea01559f2b4bc9531505422b7fcdc (duckdb/duckdb#13585, #421).

- Update vendored sources to duckdb/duckdb@75d4bd0cc759dcb609ab349b87bff07dddf2ebb7 (#420).

- Update vendored sources to duckdb/duckdb@c0f29465624aaa1472ee05d4723415cfa1bfbdf9 (#419).

- Update vendored sources to duckdb/duckdb@b369bcb4e08235e52866a5f8afb7e172fe573287 (#418).

- Update vendored sources to duckdb/duckdb@414207f2120ad9019b416cf891947004c74c7347 (#417).

- Update vendored sources to duckdb/duckdb@38ceb86f1aa4cfae7c993f59de19e0cfee7ff68e (#416).

- Update vendored sources to duckdb/duckdb@0dbb79e8de897b4a710ed53becc063bcdf80884d (duckdb/duckdb#13824, #415).

- Update vendored sources to duckdb/duckdb@9af117f0e6d3f2f9ade385dadc46807c1b388dd4 (#414).

- Update vendored sources to duckdb/duckdb@88a4c1e5893f316d763343d7f66f57917b065f50 (#413).

- Update vendored sources to duckdb/duckdb@d93225aab5c8e0da34776398358373f4c0232864 (duckdb/duckdb#13872, #412).

- Update vendored sources to duckdb/duckdb@8c2ee1eb7987a981cdf4bb1ed52683784a26e3bf (duckdb/duckdb#13880, #411).

- Update vendored sources to duckdb/duckdb@081a748340c4fcd3b3652230a02432afae72bbb3 (#410).

- Update vendored sources to duckdb/duckdb@bc7683e100867fae06c1f65e055df403c2ee25cf (#409).

- Update vendored sources to duckdb/duckdb@b87545985fc03e43baf84d9554eab23ea4b21f6c (#408).

- Update vendored sources to duckdb/duckdb@1d7e05c9737821fdb2c8eba996642c9953de52f6 (#407).

- Update vendored sources to duckdb/duckdb@b383f3668095fac2574bc6a0c417047a6fe80c9f (#406).

- Update vendored sources to duckdb/duckdb@039a262ae9805f30690ae1c8ec6a7fb27812c1b5 (#405).

- Update vendored sources to duckdb/duckdb@d697acfb108f6ec1b1ed26f0062445e1d49ee1c4 (#404).

- Update vendored sources to duckdb/duckdb@dfbfdef89aad145dc9d81c275bc2c9fad4062bed (#403).

- Update vendored sources to duckdb/duckdb@c41ae2cb6e2390b9656ac2d22885df0572a87796 (#402).

- Update vendored sources to duckdb/duckdb@d066254185fa56ec851183e9178edb04ae34c0b9 (#401).

- Update vendored sources to duckdb/duckdb@5fd2501220b80adaddf009b78cac44b97813258c (#400).

- Update vendored sources to duckdb/duckdb@6d9d429d5e7f464b69671b46dcbc99a6e46378df (#399).

- Update vendored sources to duckdb/duckdb@d9e89b5cc192ea052f038d8e7b26d253ec81bc49 (#398).

- Update vendored sources to duckdb/duckdb@95038c5eee75f733c99193c66c3faa7289d6f599 (#397).

- Update vendored sources to duckdb/duckdb@8d1c2b29badfcc55246829e00e97b86b38b3606a (#396).

- Update vendored sources to duckdb/duckdb@329bb5393b686421b40261211354f4d77cac1633 (#395).

- Update vendored sources to duckdb/duckdb@403f0fc6459fc5a1f185350d30eafa555c145d1f (#394).

- Update vendored sources to duckdb/duckdb@6a197b22652d02749c3e755e75b10d75e7ad6b75 (#393).

- Show file sizes (#380, #391).

- Fix stripping call (#380, #390).

- Move stripping logic to `install.libs.R` (#380, #389).

- Strip binary if requested (#380, #386).

- Update vendored sources to hannes/duckdb-rfuns@4fccc0b6e577f5b32c84d03cd79cb9fd9827212b (#378).

- Bump.

- Update vendored sources (tag v1.1.0) to duckdb/duckdb@fa5c2fe15f3da5f32397b009196c0895fce60820 (#377).

- Update vendored sources to duckdb/duckdb@fc21edf1508fa785a0ce06ffd245fe30b20eefe0 (#376).

- Update vendored sources to duckdb/duckdb@1d3fc5aec6b846c563d6d99c96df7c30117b5a94 (#375).

- Update vendored sources to duckdb/duckdb@893d007e64df94658d4da92c02698559f89d2072 (#374).

- Update vendored sources to duckdb/duckdb@64bacde85e4c24134cf73f9b4ed3ae362510f287 (#373).

- Update vendored sources to duckdb/duckdb@93494bd74d30f7ae11456dcee6c5e5143be58606 (#372).

- Update vendored sources to duckdb/duckdb@f76d6f2e7e170d6434e2725f43bac5ede31985fa (#371).

- Update vendored sources to duckdb/duckdb@310176118d5dc9897fb752bda145ee9dca628240 (#370).

- Update vendored sources to duckdb/duckdb@c1183d72ed9b388fdc894e86f7e999b2ba8301e5 (#369).

- Update vendored sources to duckdb/duckdb@d454d2458646151fc89c60639f0c50cecf1f4ebd (#367).

- Update vendored sources to duckdb/duckdb@0e6dacd8932c22f9d383b8047fb11aad59564895 (#363).

- Update vendored sources to duckdb/duckdb@4d18b9d05caf88f0420dbdbe03d35a0faabf4aa7 (#362).

- Update vendored sources to duckdb/duckdb@c4940720ce2ee93f39f6d80ceb25a729718a6828 (#361).

- Update vendored sources to duckdb/duckdb@421acb0f7c924216bc689f3731d7a971e7e4fa2b (#360).

- Update vendored sources to duckdb/duckdb@7c988cf7bf417d6534f0ae60f6e0297ef22cd18a (#359).

- Update vendored sources to duckdb/duckdb@dd3cbcee009bf664e3a9bce2467c8af6d2bc53d2 (#358).

- Update vendored sources to duckdb/duckdb@95a9fe9f2681175788ac85dfe67a370ef9b6f32d (#357).

- Update vendored sources to duckdb/duckdb@756d4fcb624c2c180969630b11d44380704a871a (#356).

- Update vendored sources to duckdb/duckdb@450b7e45d9e717d2c475995dabbde47b5acdfc4a (#355).

- Update vendored sources to duckdb/duckdb@dffc4ffad7d9cb7c181db87b1bfb51e261bcedf6 (#354).

- Update vendored sources to duckdb/duckdb@a6e32b115826ba543e32a733cb92f68fd0549186 (#353).

- Update vendored sources to duckdb/duckdb@1f01ef8781c8a3edf192286e0044ff37f043fb47 (#352).

- Update vendored sources to duckdb/duckdb@9aa68025b1ddf0deba9e7caf17cd0dbe4abd7206 (#351).

- Update vendored sources to duckdb/duckdb@7a7547f5da232111d52c4afb05e98e19fd8c7e31 (#350).

- Update vendored sources to duckdb/duckdb@fa2daf7a09e477e30e53b4cc8f4269c39eaf62ef (#349).

- Update vendored sources to duckdb/duckdb@a65fc4ed0847cb073231ba2be21bbd8515b91171 (#348).

- Update vendored sources to duckdb/duckdb@1844ae51091ee85c9194036405abd561ff9b58ae (#347).

- Update vendored sources to duckdb/duckdb@439bb91fc33e8bc45cc6e6d73c823ab44b48876d (#346).

- Update vendored sources to duckdb/duckdb@9067c648ef182084b3159b72213097505d5b5cab (#345).

- Update vendored sources to duckdb/duckdb@a05e81d31b178bd41ff4fb3aa46c30fe2a7068e5 (#344).

- Update vendored sources to duckdb/duckdb@74c9f4df1fe5c3f39007aa38c112cb7582f91302 (#343).

- Update vendored sources to duckdb/duckdb@e90611400749d641a07dbcd5f10df85d99813f33 (#342).

- Update vendored sources to duckdb/duckdb@902af6f21cf5e15979ecab02f15223a0f9a0baff (#341).

- Update vendored sources to duckdb/duckdb@6f9795184545d841a35e75b938f78a1e0520bd8f (#340).

- Update vendored sources to duckdb/duckdb@67b69b0c6e9411a2755baffa2305000dae887937 (#339).

- Update vendored sources to duckdb/duckdb@18e97dd88525d42c5de9faf6d1a89b90590c94fe (#338).

- Update vendored sources to duckdb/duckdb@37a55bdf6665705eb6be311bc61fa8a2f2b900fe (#337).

- Update vendored sources to duckdb/duckdb@0d37df84df6c0226423eda80d2adce9b6fdf1eea (#336).

- Update vendored sources to duckdb/duckdb@2355a5bd10fe6ae24b0b7604a66b78d6c657c104 (#335).

- Update vendored sources to duckdb/duckdb@206320c56140238066fdfca3aa503ec09f7cb2bd (#334).

- Update vendored sources to duckdb/duckdb@40c9c5a5f9b54dcaf75c45ecaa311ec478721559 (#333).

- Update vendored sources to duckdb/duckdb@379a80032a96a454190c4d2f524898ecad8fec89 (#332).

- Update vendored sources to duckdb/duckdb@20100aa2560b68b2f0b46bdc07877a96ed270959 (#331).

- Update vendored sources to duckdb/duckdb@5896c638099998449f06ce1a61e6c01045ba4a7f (#330).

- Update vendored sources to duckdb/duckdb@1a2791b7b415ee41e2285e298ee97f37caf9eeeb (#329).

- Update vendored sources to duckdb/duckdb@01c5bed3c2235171f59527832b1d41fc4a669219 (#328).

- Update vendored sources to duckdb/duckdb@686bcd10b3d617b8a00c41505ab1a97d8c53319f (#327).

- Update vendored sources to duckdb/duckdb@2e78e027dbc812e301088cb72aec80025af0b7a2 (#326).

- Update vendored sources to duckdb/duckdb@4b8274729b3037ce1c3528e90896aa3f6d94559b (#325).

- Update vendored sources to duckdb/duckdb@de5f77c08b5c37afc511e581212639050be2c691 (#324).

- Update vendored sources to duckdb/duckdb@7691b57aa1ef638c4b825c388b1bd2877a4e8ec4 (#323).

- Update vendored sources to duckdb/duckdb@b881dc1265f222e0de23403d8b3c155e8a0c5f17 (#322).

- Update vendored sources to duckdb/duckdb@2be970dda0e5047b1075f938691455d63ba63a67 (#321).

- Update vendored sources to duckdb/duckdb@573bedb4c23ae67248fa7545c5af6f455b9523a8 (#320).

- Update vendored sources to duckdb/duckdb@892f631d24711e3911e8bac2baca66ebf07d9edb (#319).

- Update vendored sources to duckdb/duckdb@ea6f5c4e0903ebfe171969a214c19b77ccb7f7e8 (#318).

- Update vendored sources to duckdb/duckdb@0af71afe6c3e932c1f55b29418c3aef8eebf671f (#317).

- Update vendored sources to duckdb/duckdb@48a8b81d5264adae02777b80b73d69be6ea6aa36 (#316).

- Update vendored sources to duckdb/duckdb@5f4af5343a4f09c3ba184a171bbcf9abd9c8b139 (#315).

- Update vendored sources to duckdb/duckdb@0e6f3fb91a072d370eb81d200cff4ba952bf20f2 (#314).

- Update vendored sources to duckdb/duckdb@5bdb091a5d67460da3ca3a89f21b7cdc588d4544 (#313).

- Update vendored sources to duckdb/duckdb@6e24bb278d11538e46ce69446cd2849d331bc7a4 (#312).

- Update vendored sources to duckdb/duckdb@b1bae91af9cbf8443b69aa851accba42657fb3fb (#311).

- Update vendored sources to duckdb/duckdb@bb5f35c7af618d7636a1f61b26aa6a5c60b0d88a (#310).

- Update vendored sources to duckdb/duckdb@4cabb03b151deb6aec8b14a2496f1b2d9031574a (#309).

- Update vendored sources to duckdb/duckdb@dd2f87c0e2038e3bbfffecd904f407b80f298212 (#308).

- Update vendored sources to duckdb/duckdb@729468452530e898b34a9eec3b48574f8f6fe70e (#307).

- Update vendored sources to duckdb/duckdb@afecd99dbbcf9dec503ffffd2b9fefb8d9d826bd (#306).

- Update vendored sources to duckdb/duckdb@8eff1500c78807d6ff6f4cac99d799da27ff0f2b (#305).

- Update vendored sources to duckdb/duckdb@87ba8503f2a2d53284d0cde88e52df39959eeffa (#304).

- Update vendored sources to duckdb/duckdb@58fe5162afadc1a9b52cc095a86ad1769d3e9384 (#303).

- Update vendored sources to duckdb/duckdb@536fb3b02b0f0e436eb0b1345ae4b155c2993fa4 (#302).

- Update vendored sources to duckdb/duckdb@de92c08cb0585ccb364c3daf0b7e251841dc088b (#301).

- Update vendored sources to duckdb/duckdb@7d2a6d0332ca85730220c926fe8d2330ed2cb6cd (#300).

- Update vendored sources to duckdb/duckdb@13ace3f6ccbd81fa1f66a467583aab10bd888496 (#299).

- Update vendored sources to duckdb/duckdb@69afac464d1f0de4dedab96e26fec05d5b8118c8 (#298).

- Update vendored sources to duckdb/duckdb@e08c0bf105c2ad3d1a6445488182aedf680306e6 (#297).

- Update vendored sources to duckdb/duckdb@567bdebcba6e58da96ceb9465505a38a6c60e69f (#296).

- Update vendored sources to duckdb/duckdb@47715960b6ce0b724d9d061addbc85d0397367bf (#295).

- Update vendored sources to duckdb/duckdb@de13238537197a5e23b3450e8c931844034ca047 (#294).

- Update vendored sources to duckdb/duckdb@c84676023c279bfec3441657d54baaef499276f5 (#293).

- Update vendored sources to duckdb/duckdb@610d79431c7aeccb0d6a4cf9ce2c04a4a96d2f63 (#292).

- Update vendored sources to duckdb/duckdb@dabc6df8f5608453f2da1e23b16d55d6df2aaf52 (#291).

- Update vendored sources to duckdb/duckdb@8226769114e16a3cb42d38bfe58c218a9009b1a3 (#290).

- Update vendored sources to duckdb/duckdb@3897524b31f668ce73fef0b1e63c2a7e6e58cbb1 (#289).

- Update vendored sources to duckdb/duckdb@226c56b7dff9174ce54c83b907d59bca35363040 (#288).

- Update vendored sources to duckdb/duckdb@4d8693be1a39e3cb4c1ce42d6bc64978a5f6e7be (#287).

- Update vendored sources to duckdb/duckdb@35346d87637d8e6731ec1fcd1909c4a309a6d6ad (#286).

- Update vendored sources to duckdb/duckdb@f94b8acedb26d606691c62b3a80ee3ab45eb4ad3 (#285).

- Update vendored sources to duckdb/duckdb@42c504b821beba03867241dde68e9408a9740806 (#284).

- Update vendored sources to duckdb/duckdb@a6b5523b3a55961b282c20fe2704ec955a311069 (#283).

- Remove hotfix.

- Update vendored sources to duckdb/duckdb@56619faf054a284b88317a811d8f0cab0fe0974a (#281).

- Update vendored sources to duckdb/duckdb@8ecc90c8d60ce446f227fad40fe8fbafdaf2b4e1 (#280).

- Update vendored sources to duckdb/duckdb@0d612daeec725915c1b3083a6a8f5e854f424fb2 (#279).

- Update vendored sources to duckdb/duckdb@798f5a2ba0ddf1d849355293cd5d7debb2dc9e9a (#278).

- Update vendored sources to duckdb/duckdb@b32a97a77241fcd3fb29ac6b007035d8d733e8fc (#277).

- Update vendored sources to duckdb/duckdb@f683023d703649b6a813e6f4d5aaf2d329c58a72 (#276).

- Update vendored sources to duckdb/duckdb@7f3889c389b2e6e7111c2963c4cca1685de5e791 (#275).

- Update vendored sources to duckdb/duckdb@5819112b7e6480c377255ccab6f4e1657730b5fe (#274).

- Update vendored sources to duckdb/duckdb@9ed561eee5afc2242f73de5ea9c8cf1422c32a40 (#273).

- Update vendored sources to duckdb/duckdb@f0dbafd48f62dbd6ec1c763dd38bab2a611dac43 (#272).

- Update vendored sources to duckdb/duckdb@18c5431edff65f2260874a0a7290cd10069f9e59 (#271).

- Update vendored sources to duckdb/duckdb@f97ad19a296aa6f37e24a23a7ea2cdb87ebe6813 (#270).

- Update vendored sources to duckdb/duckdb@7abb7065d6a924f87d8cd7e61f3c1a488b825554 (#269).

- Update vendored sources to duckdb/duckdb@6aa0ab01b0e0cd008a2331a7deba1f6c7dc190fa (#268).

- Update vendored sources to duckdb/duckdb@8c1ef04afaad4e9901e714e76a22a4ecd7f96b10 (#267).

- Update vendored sources to duckdb/duckdb@e1c738e7e29e7f105d5c4a67df7a44bc2f3dc909 (#266).

- Update vendored sources to duckdb/duckdb@cdf7125edb568360896cc4ae01f7e52ece68020a (#265).

- Update vendored sources to duckdb/duckdb@16193a714ebac04fa89d0074b1c4d42e62e9fb61 (#264).

- Update vendored sources to duckdb/duckdb@285553fe3e6962bc2be7a69486e7f1bb223f8f1b (#263).

- Update vendored sources to duckdb/duckdb@e5d994bbc6c3e158264af3156f71e7f0340a1d0c (#262).

- Update vendored sources to duckdb/duckdb@627a70286b70dc6b3c35c2f5f4ebea0552f7c6e8 (#261).

- Update vendored sources to duckdb/duckdb@862852fa395b99735e5713cb55d0cea1d9320659 (#260).

- Update vendored sources to duckdb/duckdb@ecb8dc908b1fc97ed6255284701de8c57a9f8c39 (#259).

- Update vendored sources to duckdb/duckdb@b33069bb4ec5ed1e369a260efdb2aab60fa5ec79 (#247).

- Update vendored sources to duckdb/duckdb@9ad037f3adfe372f17b5178a449ac4b6f9142240 (#246).

- Update vendored sources to duckdb/duckdb@1345b3013e801be526e7fac8c8984c89b0033d6a (#245).

- Update vendored sources to duckdb/duckdb@bb97c95a1ad2c277fcf2a60bb1a8af4b0f29b6c7 (#244).

- Update vendored sources to duckdb/duckdb@26685b133edd712ef62e74dbf25ea611e1cf91dc (#243).

- Update vendored sources to duckdb/duckdb@513c2f22c0923045179a8800edf72d212a9bf682 (#242).

- Update vendored sources to duckdb/duckdb@fe535b02b3b8d2b3ac7660134fd588848be9e859 (#241).

- Update vendored sources to duckdb/duckdb@b371fc1b9a8960af25205a85ea89b381e1f98705 (#240).

- Update vendored sources to duckdb/duckdb@c4b6b8f3543bf440d4149a824eed118e4e54c4be (#239).

- Update vendored sources to duckdb/duckdb@10ea4832d3f1850685a65369e0b19c27ec81e638 (#238).

- Update vendored sources to duckdb/duckdb@f6a8ec460ae23e20e6f52859c32c96012dcc0b13 (#236).

- Update vendored sources to duckdb/duckdb@8d4a30cf72c2695c15bed2ec69b5a5bc56a5a594 (#235).

- Update vendored sources to duckdb/duckdb@367aa8db1cc622c46661d762f9cafdd88263040e (#234).

- Update vendored sources to duckdb/duckdb@3d85a139fe1f4c78284a0e8cde522a38f2bcde0a (#233).

- Update vendored sources to duckdb/duckdb@a4f0adb1cf051f6ec4d58326ccf4fc3d3f333d35 (#232).

- Update vendored sources to duckdb/duckdb@ad4639ed1a3448e0c7383d8601d3b797a1861c86 (#231).

- Update vendored sources to duckdb/duckdb@b8df1598853d55f4421bb72dd3d86db553e897b4 (#230).

- Update vendored sources to duckdb/duckdb@f5048f0ffd25b9d1d67b1a68f75ac435c9f5cbfa (#229).

- Update vendored sources to duckdb/duckdb@ac8efca3fc3bc1fa277a0ca32104e2e861b6eef5 (#228).

- Update vendored sources to duckdb/duckdb@c2e18955aff66454aa3ab5b39abd6f3c90f8010b (#227).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#226).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#220).

- Update vendored sources to duckdb/duckdb@d5b10fc4d96afe2fcdc8af04b4bf77b856026c3b (#219).

- Update vendored sources to duckdb/duckdb@e1568a2981c0f0ec86f322848a8bddb36e81e1d1 (#218).

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10430870381

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425609276

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10425483466

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/10223714659

- Remove temporary patch.

- Enable creation of compilation database.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9879707346

- Adapt glue code.

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9727972793

- Auto-update from GitHub Actions.

  Run: https://github.com/duckdb/duckdb-r/actions/runs/9692337257

- Fix rfuns vendoring.

- Add another brotli patch.

- Brotli patch and compilation flags.

- Update vendored sources (tag v1.0.0) to duckdb/duckdb@1f98600c2cf8722a6d2f2d805bb4af5e701319fc.

  🦆

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources (tag v0.10.3) to duckdb/duckdb@70fd6a8a2450c1e2a7d0547d4c0666a649dc378e.

- Update vendored sources to hannes/duckdb-rfuns@397ab2a5efa254ea71e45f92b1346e2de6617d59.

- `n_distinct()` followup (@lschneiderbauer, #158).

- Improve yyjson patch.

- Add yyjson patch.

- Format.

- Adapt to `shared_ptr` changes.

- Add patch.

- Update vendored sources (tag v0.10.2) to duckdb/duckdb@1601d94f94a7e0d2eb805a94803eb1e3afbbe4ed.

- Fix patch.

- Fix generated Makevars.win.

- Add patch for re2 update.

- Apply patches during vendoring.

- Harmonize test file names.

- Restore vendor script, new script for step-by-step vendoring.

- Change maintainer.

- Use temporary clone.

- Always vendor next commit.

- Duckdir -\> upstream_dir.

- Ignore.

- Bump version.

- Build-ignore autogenerated files.

- Add revdepcheck results.

- Ellipsis before cache argument.

- Sync tests.

- Update NEWS.

- Bump version.

- Change directory location for extensions and secrets for v.0.10.0 release (@Tmonster, #73).

- Bump version.

- Update vendored sources to duckdb/duckdb@d4c774b1f15ed88c608154156d4c00f9235dbaf3 (#85).

- Executable script.

- Fix Dockerfile deps.

- Compose with threadcheck.

- Improve Docker Compose infrastructure.

- Add Docker Compose infrastructure for running with r-debug.

- Style.

- Sync duckplyr tests (#78).

- Update vendored sources to duckdb/duckdb@24148408432d05bda7cf86f2736d24920c51577c (#57).

- Update vendored sources to duckdb/duckdb@d51e1b06fad726a606ceb70c1530e21121633f31 (#53).

- Remove last instance of `default_connection()` (#50).

- Bump, tidy, news.

- Bump version.

- Update duckplyr tests.

- Build-ignore.

- Skip DBItest tests if not installed (#30).

- Fix tests when dplyr is missing (#29).

- CRAN comments.

- Bump verson.

- Remove unneeded importFrom (#27).

- Build-ignore.

- Updated results.

- Adapt to changed setops implementation in duckplyr.

- Whitespace sync.

- Add revdepcheck results, CC @hannes.

- Cache duckdb .o files for fast CI/CD.

- Use local ccache.

- Tweak URLs.

- Move sources.mk.

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

- Add fledge workflow.

- Use stable pak (#591).

- Latest changes (#584).

- Tweak patch call.

- Can't check incoming.

- Update actions to avoid warnings (#524).

- Use pkgdown branch (#523).

- Bring back stepwise vendoring.

- Don't remove dir.

- Add env.

- Vendor without creating PR.

- Set up R for r-hub.

- Force vendoring when tag.

- Fix passing branch names as reef.

- Pass inputs.ref to create-pull-request.

- Fix PR generation for snapshot tests for vendoring.

- Flip order.

- Use inputs.

- Use head ref for status reports.

- Check job.status.

- Tweak.

- Fix final status reporting.

- Fix status.

- Bump version of action.

- Post status for workflow_dispatch.

- Only smoke test for workflow_dispatch.

- Move condition to check if status event is triggered.

- Install package manually, faster.

- Verbosity.

- Improve support for protected branches, without fledge (#248).

- Fix vendoring (#225).

- Fix vendoring workflow (#217).

- Wait for pkgdown (#215).

- Fix builds (#213).

- Sync with latest developments.

- Use v2 instead of master.

- Inline action.

- Use dev roxygen2 and decor.

- Fix on Windows, tweak lock workflow.

- Avoid checking bashisms on Windows.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.

- Prepare for dynamic check matrix.

- Fail if patch does not apply.

- Add patches.

- Move caching of duckdb prebuilt archive.

- More careful patching.

- Better tag detection.

- Add R version to cache key.

- Logic.

- Fix vendoring.

- Add rhub2 workflow.

- Avoid vendoring past most recent tag.

- Always vendor tags.

- Fix condition.

- Fix.

- Fix vendoring.

- Only run check if vendoring changed anything.

- Show remaining commits to be vendored.

- Avoid concurrency, more is more.

- Logging.

- Fix typo.

- Fix typo.

- Also trigger when updating vendoring script.

- Dry-run push.

- Pull before vendoring.

- Simplify.

- Use most recent commit.

- Improve concurrency.

- Show stats.

- No cancel in progress, deep fetch.

- Debug.

- Debug.

- Debug.

- Fix typo.

- Vendor only next commit.

- Fix path.

- Vendor every five minutes, but only the next commit.

- Update vendored sources nightly (#25, #82).

- Add workflow file for labelling issues as 'High Priority'.

## Documentation

- Upgrade roxygen2.

- Fix typo.

- Add list of contributors (#2, #94).

- Use pkgdown BS5 (@maelle, #31, #70).

- Link to R documentation page.

- Add dev installation instructions, CC @hannes.

## Testing

- Sync tests with duckplyr (#596).

- Skip if not installed.

- Skip if not installed.

- Add tests for comparison expression (@toppyy, #462).

- Update snapshot.

- Update duckplyr tests.

- Tweak tests.

- Add csv reading test for `duckdb_read_csv(na.strings = )` (@Tmonster, #10).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0 (#84).

- Update duckplyr tests.

- Fix snapshot tests again.

- Skip failing test.

- Fix snapshot tests.

## Breaking changes

- Breaking change: Rename `tbl_query()` to `tbl_function()`, remove `translate_duckdb()` (#133, #159, #211).

## fledge

- Bump version to 1.1.3.9003 (#604).

- Bump version to 1.1.3.9002 (#602).

- Bump version to 1.1.3.9001 (#599).

## README

- Display different logo for light/dark mode (@szarnyasg, #129).

## Uncategorized

- Merge branch 'cran-1.1.2'.

- Merge pull request #516 from duckdb/f-tweak.

  Fix signedness

- Merge pull request #461 from duckdb/f-exp-depth-2.

  Sync tests

- Merge pull request #392 from duckdb/cran-1.1.0.

  Bump

- Merge pull request #388 from duckdb/f-380-ppm-strip.

  Merge pull request #386 from duckdb/f-380-ppm-strip

- Merge pull request #214 from duckdb/b-ci.

  Only report success once

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13415 (#13415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13431 (#13431).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13439 (#13439).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13202 (#13202).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13268 (#13268).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13434 (#13434).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13433 (#13433).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13421 (#13421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13417 (#13417).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13411 (#13411).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13410 (#13410).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13408 (#13408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13409 (#13409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13358 (#13358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13402 (#13402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13383 (#13383).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13394 (#13394).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13401 (#13401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13370 (#13370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13399 (#13399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13329 (#13329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13344 (#13344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13354 (#13354).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13372 (#13372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13168 (#13168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13359 (#13359).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13356 (#13356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13335 (#13335).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13267 (#13267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13201 (#13201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13360 (#13360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13355 (#13355).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13346 (#13346).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13350 (#13350).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13341 (#13341).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13343 (#13343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13342 (#13342).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13317 (#13317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12886 (#12886).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13313 (#13313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13330 (#13330).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13234 (#13234).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13307 (#13307).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13167 (#13167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12682 (#12682).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13291 (#13291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13290 (#13290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13262 (#13262).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13278 (#13278).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13231 (#13231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13284 (#13284).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13281 (#13281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13283 (#13283).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13280 (#13280).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13282 (#13282).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13275 (#13275).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13260 (#13260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13261 (#13261).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13258 (#13258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13249 (#13249).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13229 (#13229).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13256 (#13256).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13162 (#13162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13230 (#13230).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13233 (#13233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13236 (#13236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13242 (#13242).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13241 (#13241).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13240 (#13240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13223 (#13223).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13207 (#13207).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13170 (#13170).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13203 (#13203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13109 (#13109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13194 (#13194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13191 (#13191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13189 (#13189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13188 (#13188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13186 (#13186).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13063 (#13063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13163 (#13163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13150 (#13150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13182 (#13182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13160 (#13160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13180 (#13180).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13161 (#13161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13151 (#13151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13146 (#13146).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13140 (#13140).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13136 (#13136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13087 (#13087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13101 (#13101).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13108 (#13108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13142 (#13142).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12978 (#12978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13130 (#13130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13123 (#13123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13137 (#13137).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13139 (#13139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13117 (#13117).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13133 (#13133).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13129 (#13129).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13131 (#13131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13127 (#13127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13125 (#13125).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13122 (#13122).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13126 (#13126).

- Merge tag 'v1.0.0-2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13114 (#13114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13093 (#13093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13110 (#13110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13118 (#13118).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13111 (#13111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13106 (#13106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12967 (#12967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13090 (#13090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13098 (#13098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13105 (#13105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13094 (#13094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13084 (#13084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13083 (#13083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13082 (#13082).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13081 (#13081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13089 (#13089).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13086 (#13086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13062 (#13062).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13073 (#13073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13076 (#13076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13074 (#13074).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13015 (#13015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13065 (#13065).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13068 (#13068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13027 (#13027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12579 (#12579).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12998 (#12998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13040 (#13040).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12920 (#12920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13054 (#13054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13056 (#13056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13057 (#13057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13052 (#13052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12995 (#12995).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13050 (#13050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13033 (#13033).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13039 (#13039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13035 (#13035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13030 (#13030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13028 (#13028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13025 (#13025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13023 (#13023).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13024 (#13024).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12953 (#12953).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13002 (#13002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12627 (#12627).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13020 (#13020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13019 (#13019).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13014 (#13014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13010 (#13010).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13013 (#13013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12728 (#12728).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13004 (#13004).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12993 (#12993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12994 (#12994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12931 (#12931).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13003 (#13003).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13001 (#13001).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12785 (#12785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/13000 (#13000).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11720 (#11720).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12971 (#12971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12928 (#12928).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12829 (#12829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12929 (#12929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12979 (#12979).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12982 (#12982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12984 (#12984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12980 (#12980).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12942 (#12942).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12973 (#12973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12974 (#12974).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12972 (#12972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12965 (#12965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12968 (#12968).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12970 (#12970).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12966 (#12966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12954 (#12954).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12755 (#12755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12716 (#12716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12912 (#12912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12957 (#12957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12290 (#12290).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12955 (#12955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12916 (#12916).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12948 (#12948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12824 (#12824).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12625 (#12625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12787 (#12787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12907 (#12907).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12885 (#12885).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12943 (#12943).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12938 (#12938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12937 (#12937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12932 (#12932).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12890 (#12890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12924 (#12924).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12866 (#12866).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12889 (#12889).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12918 (#12918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12908 (#12908).

- Merge branch 'cran-1.0.0-1'.

- Merge tag 'v1.0.0-1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12913 (#12913).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12914 (#12914).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12851 (#12851).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12887 (#12887).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12858 (#12858).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12888 (#12888).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12884 (#12884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12751 (#12751).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12848 (#12848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12498 (#12498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12398 (#12398).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12878 (#12878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12859 (#12859).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12834 (#12834).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12844 (#12844).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12849 (#12849).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12847 (#12847).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11191 (#11191).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12840 (#12840).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12698 (#12698).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12806 (#12806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12734 (#12734).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12835 (#12835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12812 (#12812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12832 (#12832).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12691 (#12691).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12810 (#12810).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12780 (#12780).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12575 (#12575).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12803 (#12803).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12791 (#12791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12754 (#12754).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12765 (#12765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12685 (#12685).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12770 (#12770).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12768 (#12768).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12769 (#12769).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12762 (#12762).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12759 (#12759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12753 (#12753).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12636 (#12636).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12496 (#12496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12745 (#12745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12740 (#12740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12738 (#12738).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12737 (#12737).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12736 (#12736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12731 (#12731).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12730 (#12730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12599 (#12599).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12678 (#12678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12725 (#12725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12724 (#12724).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12708 (#12708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12697 (#12697).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12705 (#12705).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12717 (#12717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12681 (#12681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12692 (#12692).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12694 (#12694).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12689 (#12689).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12690 (#12690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12671 (#12671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12679 (#12679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12288 (#12288).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12655 (#12655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12669 (#12669).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12653 (#12653).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12663 (#12663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12658 (#12658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12654 (#12654).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12637 (#12637).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12650 (#12650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12642 (#12642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12652 (#12652).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12639 (#12639).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12635 (#12635).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12629 (#12629).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12630 (#12630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12633 (#12633).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12603 (#12603).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12608 (#12608).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12554 (#12554).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12539 (#12539).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12516 (#12516).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12515 (#12515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12445 (#12445).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12456 (#12456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12467 (#12467).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12465 (#12465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12470 (#12470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12461 (#12461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12448 (#12448).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12436 (#12436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12421 (#12421).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12424 (#12424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12401 (#12401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12409 (#12409).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12370 (#12370).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12405 (#12405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12393 (#12393).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12391 (#12391).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12352 (#12352).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12360 (#12360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12344 (#12344).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12332 (#12332).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12305 (#12305).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12302 (#12302).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12282 (#12282).

- Merge branch 'cran-1.0.0'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12291 (#12291).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12281 (#12281).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12257 (#12257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12267 (#12267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12264 (#12264).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12271 (#12271).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12259 (#12259).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12269 (#12269).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12265 (#12265).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12260 (#12260).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12266 (#12266).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12244 (#12244).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12240 (#12240).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12123 (#12123).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12221 (#12221).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12226 (#12226).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12238 (#12238).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12209 (#12209).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12206 (#12206).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12195 (#12195).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12194 (#12194).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12193 (#12193).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12189 (#12189).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12183 (#12183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12111 (#12111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12169 (#12169).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12056 (#12056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12167 (#12167).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12173 (#12173).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12175 (#12175).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12163 (#12163).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12157 (#12157).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12168 (#12168).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12159 (#12159).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12165 (#12165).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12109 (#12109).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12152 (#12152).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12162 (#12162).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12160 (#12160).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12156 (#12156).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12144 (#12144).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12150 (#12150).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12143 (#12143).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12086 (#12086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12110 (#12110).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11677 (#11677).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12135 (#12135).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12130 (#12130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12131 (#12131).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12124 (#12124).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12121 (#12121).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12120 (#12120).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12119 (#12119).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12116 (#12116).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12099 (#12099).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12091 (#12091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12108 (#12108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12112 (#12112).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12081 (#12081).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12077 (#12077).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11493 (#11493).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12072 (#12072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12098 (#12098).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12094 (#12094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12090 (#12090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12087 (#12087).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12088 (#12088).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11848 (#11848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12070 (#12070).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12085 (#12085).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12076 (#12076).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12084 (#12084).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12063 (#12063).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12083 (#12083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12045 (#12045).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12026 (#12026).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12049 (#12049).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12068 (#12068).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12064 (#12064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12055 (#12055).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12061 (#12061).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12044 (#12044).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12051 (#12051).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12050 (#12050).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12054 (#12054).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12052 (#12052).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12053 (#12053).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12035 (#12035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12043 (#12043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11874 (#11874).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12039 (#12039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12028 (#12028).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11998 (#11998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12030 (#12030).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11984 (#11984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12029 (#12029).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11937 (#11937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12022 (#12022).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12027 (#12027).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12025 (#12025).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12011 (#12011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11867 (#11867).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11976 (#11976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11831 (#11831).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12013 (#12013).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11965 (#11965).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11978 (#11978).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11987 (#11987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11982 (#11982).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11994 (#11994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12012 (#12012).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12014 (#12014).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/12015 (#12015).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11999 (#11999).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11761 (#11761).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11964 (#11964).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11969 (#11969).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11967 (#11967).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11955 (#11955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11966 (#11966).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11956 (#11956).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11929 (#11929).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11920 (#11920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11441 (#11441).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11835 (#11835).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11912 (#11912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11906 (#11906).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11918 (#11918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11806 (#11806).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11902 (#11902).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11771 (#11771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11898 (#11898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11884 (#11884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11745 (#11745).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11785 (#11785).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11880 (#11880).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11879 (#11879).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11878 (#11878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11746 (#11746).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11812 (#11812).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11794 (#11794).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11792 (#11792).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11788 (#11788).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11797 (#11797).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11846 (#11846).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11861 (#11861).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11524 (#11524).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11830 (#11830).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11829 (#11829).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11825 (#11825).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11821 (#11821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11816 (#11816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11757 (#11757).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11795 (#11795).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11791 (#11791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11787 (#11787).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11625 (#11625).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11763 (#11763).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11774 (#11774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11777 (#11777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11765 (#11765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11596 (#11596).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11759 (#11759).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11679 (#11679).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11719 (#11719).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11717 (#11717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11736 (#11736).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11732 (#11732).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11730 (#11730).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11726 (#11726).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11733 (#11733).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11735 (#11735).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11702 (#11702).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11725 (#11725).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11723 (#11723).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11721 (#11721).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11696 (#11696).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11716 (#11716).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11711 (#11711).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11708 (#11708).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11673 (#11673).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10978 (#10978).

- Merge branch 'cran-0.10.2'.

- Merge branch 'cran-0.10.2'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11681 (#11681).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11678 (#11678).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11676 (#11676).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11674 (#11674).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11675 (#11675).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11665 (#11665).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11670 (#11670).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11671 (#11671).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11668 (#11668).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11667 (#11667).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11663 (#11663).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11616 (#11616).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11659 (#11659).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11656 (#11656).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11655 (#11655).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11465 (#11465).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11645 (#11645).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11650 (#11650).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11648 (#11648).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11642 (#11642).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11630 (#11630).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11631 (#11631).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11614 (#11614).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11462 (#11462).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11515 (#11515).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11619 (#11619).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11618 (#11618).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11622 (#11622).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11613 (#11613).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11601 (#11601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11512 (#11512).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11273 (#11273).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11551 (#11551).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11604 (#11604).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11587 (#11587).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11585 (#11585).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11580 (#11580).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11461 (#11461).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11267 (#11267).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11558 (#11558).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11528 (#11528).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11546 (#11546).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11544 (#11544).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11519 (#11519).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11525 (#11525).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11270 (#11270).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11496 (#11496).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11513 (#11513).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11495 (#11495).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11506 (#11506).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11446 (#11446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11401 (#11401).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11498 (#11498).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11497 (#11497).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11247 (#11247).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11486 (#11486).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11408 (#11408).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11464 (#11464).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11478 (#11478).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11466 (#11466).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11470 (#11470).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11458 (#11458).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11358 (#11358).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11402 (#11402).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11399 (#11399).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11443 (#11443).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11456 (#11456).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11454 (#11454).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11429 (#11429).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11436 (#11436).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11437 (#11437).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11418 (#11418).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11428 (#11428).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11424 (#11424).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11414 (#11414).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11415 (#11415).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11405 (#11405).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11400 (#11400).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11397 (#11397).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11396 (#11396).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11392 (#11392).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11390 (#11390).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11360 (#11360).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11356 (#11356).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11372 (#11372).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11369 (#11369).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11376 (#11376).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11343 (#11343).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11252 (#11252).

- Merge branch 'cran-0.10.1'.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11347 (#11347).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11326 (#11326).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11313 (#11313).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11340 (#11340).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11327 (#11327).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11321 (#11321).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11329 (#11329).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11325 (#11325).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11314 (#11314).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11315 (#11315).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11318 (#11318).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11309 (#11309).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11320 (#11320).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11317 (#11317).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11316 (#11316).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11306 (#11306).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11297 (#11297).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11304 (#11304).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10878 (#10878).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11215 (#11215).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11286 (#11286).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11203 (#11203).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11258 (#11258).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11276 (#11276).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11233 (#11233).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11220 (#11220).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11248 (#11248).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11257 (#11257).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11243 (#11243).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11236 (#11236).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11231 (#11231).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11222 (#11222).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11139 (#11139).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11223 (#11223).

- Merge branch 'cran-0.10.1'.

- Merge branch 'cran-0.10.1'.

- Merge pull request #124 from duckdb/b-34-56-58-59-60-83-conn-2.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11218 (#11218).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11214 (#11214).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11149 (#11149).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11172 (#11172).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11106 (#11106).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11210 (#11210).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11171 (#11171).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11208 (#11208).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11201 (#11201).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11182 (#11182).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11205 (#11205).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11200 (#11200).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11199 (#11199).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11183 (#11183).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11198 (#11198).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11185 (#11185).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11188 (#11188).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11190 (#11190).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11177 (#11177).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11179 (#11179).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11174 (#11174).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11161 (#11161).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11151 (#11151).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11138 (#11138).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11132 (#11132).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11145 (#11145).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11141 (#11141).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11127 (#11127).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11128 (#11128).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11130 (#11130).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11136 (#11136).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11114 (#11114).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11108 (#11108).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11111 (#11111).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11093 (#11093).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11083 (#11083).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11103 (#11103).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11105 (#11105).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11090 (#11090).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11100 (#11100).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11096 (#11096).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11094 (#11094).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11091 (#11091).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10976 (#10976).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11017 (#11017).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11086 (#11086).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11073 (#11073).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11072 (#11072).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11069 (#11069).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11056 (#11056).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11064 (#11064).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11057 (#11057).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11031 (#11031).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11046 (#11046).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10984 (#10984).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11035 (#11035).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11043 (#11043).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11034 (#11034).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11039 (#11039).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11021 (#11021).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11020 (#11020).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11011 (#11011).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11002 (#11002).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11008 (#11008).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/11005 (#11005).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10997 (#10997).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10992 (#10992).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10993 (#10993).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10994 (#10994).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10998 (#10998).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10983 (#10983).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10990 (#10990).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10948 (#10948).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10955 (#10955).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10972 (#10972).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10987 (#10987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10985 (#10985).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10938 (#10938).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10973 (#10973).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10971 (#10971).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10933 (#10933).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10594 (#10594).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10958 (#10958).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10957 (#10957).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10949 (#10949).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10936 (#10936).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10946 (#10946).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10939 (#10939).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10937 (#10937).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10945 (#10945).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10941 (#10941).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10944 (#10944).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10870 (#10870).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10925 (#10925).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10704 (#10704).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10923 (#10923).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10922 (#10922).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10920 (#10920).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10918 (#10918).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10915 (#10915).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10912 (#10912).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10690 (#10690).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10908 (#10908).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10828 (#10828).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10799 (#10799).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10898 (#10898).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10909 (#10909).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10850 (#10850).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10873 (#10873).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10897 (#10897).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10896 (#10896).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10893 (#10893).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10890 (#10890).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10864 (#10864).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10872 (#10872).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10884 (#10884).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10882 (#10882).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10740 (#10740).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10862 (#10862).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10863 (#10863).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10610 (#10610).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10597 (#10597).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10714 (#10714).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10855 (#10855).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10854 (#10854).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10446 (#10446).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10848 (#10848).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10742 (#10742).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10837 (#10837).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10774 (#10774).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10789 (#10789).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10822 (#10822).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10817 (#10817).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10821 (#10821).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10816 (#10816).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10755 (#10755).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10796 (#10796).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10807 (#10807).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10791 (#10791).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10771 (#10771).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10773 (#10773).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10777 (#10777).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10776 (#10776).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10601 (#10601).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10765 (#10765).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10758 (#10758).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10658 (#10658).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/10642 (#10642).

- Merge pull request #103 from lnkuiper/namespace.

  Remove std:: from unordered_map

- Merge pull request #108 from Tmonster/fix_Rbuildignore.

  Fix invalid regex in .Rbuildignore

- Merge pull request #48 from olivroy/patch-1.

- Merge pull request #76 from romainfrancois/patch-1.

- Merge pull request #45 from duckdb/b-cpp11-printf.

- Merge pull request #33 from duckdb/adbcdef.

  Fix duckdb_adbc_init signature

- Merge pull request #28 from duckdb/f-news.

- Merge pull request #19 from szarnyasg/nits-links-for-extensions.

  Add links and fix nits for extensions

- Merge pull request #20 from Tmonster/fix-vendor-script.

  fix vendor script

- Merge pull request #18 from Tmonster/update_extension_documentation_on_readme.

- Merge pull request #17 from duckdb/add-link-to-docs.

- Merge pull request #15 from duckdb/change-logo.

  Change logo to new one

- Merge pull request #5 from Tmonster/update_readme.

- Merge branch 'release'.

- Merge branch 'release'.

- Merge branch 'release'.

- Merge branch 'release'.

- Merge branch 'release'.

- Merge branch 'main' into dev.

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/8482 (#8482).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/8717 (#8717).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/8172 (#8172).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/8378 (#8378).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/7987 (#7987).

- PLACEHOLDER https://github.com/duckdb/duckdb-r/pull/8307 (#8307).

- Merge branch 'b-altrep' into krlmlr-main.

  Release v0.8.1-3


# duckdb 1.1.3.9010

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9009

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9008

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9007

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9006

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9005

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9004

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9003

## fledge

  - Bump version to 1.1.3.9002 (#602).


# duckdb 1.1.3.9002

## fledge

  - Bump version to 1.1.3.9001 (#599).


# duckdb 1.1.3.9001

## Continuous integration

  - Add fledge workflow.


# duckdb 1.1.3.9000

- Internal changes only.


# duckdb 1.1.3

## Features

- Update to duckdb v1.1.3, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.3> for details.

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (#186, @romainfrancois).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument to `rel_from_altrep_df()` in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Keep `cleanup` files to accommodate different build scenarios (#536).


# duckdb 1.1.2

## Features

- Update to duckdb v1.1.2, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.2> for details.

## Features

- Long-running queries can now be canceled immediately with Ctrl + C (terminal) or Escape (RStudio IDE and Workbench) (#514, #515).

- Add `col.types` argument to `duckdb_read_csv()` (#445, @eli-daniels).

- Rethrow errors with rlang if installed (#522).

- Improve error message for parsing erros during statement extraction (tidyverse/duckplyr#219, #521).

## Bug fixes

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- `rfuns` extension: `%in%` works correctly as part of a `&` conjunction (#528).

## Internal

- New interal APIs: `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- xz-compress duckdb sources in the tarball (#530).

- `rfuns` extension: Fix signedness.


# duckdb 1.1.1

## Features

- Update to duckdb v1.1.1, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.1> for details.

- Add comparison expression to relational API (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

## Chore

- Update vendored extension sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove warnings for uninitialized variables.


# duckdb 1.1.0

## Features

- Update to duckdb v1.1.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.0> for details.

- Upgrade vendored cpp11 to 0.5.0.


# duckdb 1.0.0-2

## Features

- Reduce the package installation size on macOS (#185).


# duckdb 1.0.0-1

## Bug fixes

- Upgrade vendored cpp11 to 0.4.7 to fix compilation with R-devel.

- Support `dplyr::tbl(conn, I(...))`.


# duckdb 1.0.0

## Bug fixes

- Update to duckdb v1.0.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.0.0> for details.


# duckdb 0.10.3

## Features

- Update to duckdb v0.10.3, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.3> for details.
- Support fetching `MAP` type (#61, #165).
- Add dbplyr translations for `clock::date_count_between()` (@edward-burn, #163, #166).
- `round()` duckdb translation uses `ROUND_EVEN()` instead of `ROUND()` (@lschneiderbauer, #146, #157).
- New `sort` argument to `rel_order()` (@toppyy, #168).
- Add dbplyr translations for `clock::add_days()`, `clock::add_years()`, `clock::get_day()`, `clock::get_month()`, and `clock::get_year()` (@edward-burn, #153).

## Bug fixes

- Correct usage of `win_current_group()` instead of `win_current_order()` in SQL translation (@lschneiderbauer, #173, #175).


# duckdb 0.10.2

## Features

- Update to duckdb v0.10.2, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.2> for details.
- The `"difftime"` class is now mapped to the `INTERVAL` data type (#151).
- Use latest tests from DBItest (#148).
- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).
- Include rfuns extension (hannes/duckdb-rfuns#78, #144).
- Map `NA` to `SQLNULL` (#143).

## Bug fixes

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).
- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).


# duckdb 0.10.1

## Features

- Update to duckdb v0.10.1, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.1> for details.
- Fix shutdown semantics for the driver object created by `duckdb()`. A database file is closed (and available to be opened from another session) after the last connection that uses this file calls `dbDisconnect()` . The `shutdown` argument to `dbDisconnect()` or the `duckdb_shutdown()` functions are no longer necessary. Two database connections from the same R session can access the same file concurrently in read-write mode (#124).

## Bug fixes

- Don't run tests that invoke re2 by default (#121, #127).

- Fix compilation for R 4.0 and R 4.1, regression introduced in v0.10.0. Using `librstrtmgr.a` from UCRT build of rtools40 (#130).

## Internal

- The C++ core is now vendored commit by commit, once every five minutes. Vendoring stops if `R CMD check` fails or if a previously unreleased tag is reached.

- New maintainer: Kirill Müller.

## Continuous integration

- Add rhub2 workflow.


# duckdb 0.10.0

## Bug fixes

- `dplyr::tbl()` works again when a Parquet or CSV file is passed instead of a table name (#38, #91).

- `DBI::dbQuoteIdentifier()` correctly quotes identifiers that start with a digit (#67, #92).

- Align the argument order of `dbWriteTable()` with the DBI specs (@eitsupi, #43, #49).

## Features

- New `tbl_file()` and `tbl_query()` to explicitly access tables and queries as dbplyr lazy tables (#96). The `cache` argument to `tbl()` and to the new functions must be named.

- Initial ALTREP support for `LIST` logical type (@romainfrancois, #77).

- Update core to duckdb v0.10.0 (#90).

- New private `rel_to_parquet()` to write a relation to parquet (@Tmonster, #46).

## Chore

- Change directory location for extensions and secrets for v.0.10.0 release (@Tmonster, #73).

- Remove last instance of `default_connection()` (#50).

## Documentation

- Add list of contributors (#2, #94).

- Use pkgdown BS5 (@maelle, #31, #70) with DuckDB logo (#76, @romainfrancois).

- Link to R documentation page.

- Include `NEWS.md` on CRAN (#48, @olivroy).

## Testing

- Add csv reading test for `duckdb_read_csv(na.strings = )` (@Tmonster, #10).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0 (#84).

# duckdb 0.9.2-1

- Fix compiler warning on R-devel (#45).


# duckdb 0.9.2

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.9.2>.

- Add dbplyr translation for `prod()` (#40, @m-muecke).


# duckdb 0.9.1-1

- Fix LTO checks on CRAN.


# duckdb 0.9.1

- See blog post at <https://duckdb.org/2023/09/26/announcing-duckdb-090.html>.

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.9.1>.

- Move sources to <https://github.com/duckdb/duckdb-r> (@krlmlr).

- Add ADBC integration with the adbcdrivermanager package (duckdb/duckdb#8172, @paleolimbot).

- Full support of lists and structs in R (duckdb/duckdb#8503, @krlmlr).

# duckdb 0.8.1-3

- Internal changes to support the duckplyr package.

# duckdb 0.8.1-2

- Compatibility with dbplyr.

- Internal changes to support the duckplyr package.

# duckdb 0.8.1-1

- Fix CRAN checks.

# duckdb 0.8.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.8.1>.

# duckdb 0.8.0

- See blog post at <https://duckdb.org/2023/05/17/announcing-duckdb-080.html>.

# duckdb 0.7.1-1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.7.1>.

# duckdb 0.7.0

- See blog post at <https://duckdb.org/2023/02/13/announcing-duckdb-070.html>.

# duckdb 0.6.2

- New `duckdb_prepare_substrait_json()`.

# duckdb 0.6.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.6.1>.

# duckdb 0.6.0

- See blog post at <https://duckdb.org/2022/11/14/announcing-duckdb-060.html>.

# duckdb 0.5.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.5.1>.

# duckdb 0.5.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.5.0>.

# duckdb 0.4.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.4.0>.

# duckdb 0.3.4-1

- Minor changes for CRAN compatibility.

# duckdb 0.3.4

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.4>.

# duckdb 0.3.3

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.3>.

# duckdb 0.3.2

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.2>.

# duckdb 0.3.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.1>.

# duckdb 0.3.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.0>.

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.2.9>.

# duckdb 0.2.8

This preview release of DuckDB is named "Ceruttii" after a [long-extinct relative of the present-day Harleqin Duck](https://en.wikipedia.org/wiki/Harlequin_duck#Taxonomy) (Histrionicus Ceruttii).
Binary builds are listed below. Feedback is very welcome.

Note: Again, this release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the [documentation](https://duckdb.org/docs/sql/statements/export) for details.

### SQL

 - #2064: `RANGE`/`GENERATE_SERIES` for timestamp + interval
 - #1905: Add `PARQUET_METADATA` and `PARQUET_SCHEMA` functions
 - #2059, #1995, #2020 & #1960: Window `RANGE` framing, `NTH_VALUE` and other improvements

### APIs

 - Many Arrow integration improvements
 - Many ODBC driver improvements
 - #1815: Initial version: SQLite UDF API
 - #2001: Support DBConfig in C API

### Engine

 - #1975, #1876 & #2009: Unified row layout for sorting, aggregate & joins
 - #1930 & #1904: List Storage
 - #2050: CSV Reader/Casting Framework Refactor & add support for `TRY_CAST`
 - #1950: Add Constant Segment Compression to Storage
 - #1957: Add pipe/stream file system





# duckdb 0.2.7

This preview release of DuckDB is named "Mollissima" after the Common Eider (Somateria mollissima).
 Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:

SQL
 - #1847: Unify catalog access functions, and provide views for common PostgreSQL catalog functions
 - #1822: Python/JSON-Style Struct & List Syntax
 - #1862: #1584 Implementing `NEXTAFTER` for float and double
 - #1860: `FIRST` implementation for nested types
 - #1858: `UNNEST` table function & array syntax in parser
 - #1761: Issue #1746: Moving `QUANTILE`

APIs

 - #1852, #1840, #1831, #1819 and #1779: Improvements to Arrow Integration
 - #1843: First iteration of ODBC driver
 - #1832: Add visualizer extension
 - #1803: Converting Nested Types to native python
 - #1773: Add support for key/value style configuration, and expose this in the Python API

Engine
 - #1808: Row-Group Based Storage
 - #1842: Add (Persistent) Struct Storage Support
 - #1859: Read and write atomically with offsets
 - #1851: Internal Type Rework
 - #1845: Nested join payloads
 - #1813: Aggregate Row Layout
 - #1836: Join Row Layout
 - #1804: Use Allocator class in buffer manager and add a test for a custom allocator usage





# duckdb 0.2.6

This preview release of DuckDB is named "Jamaicensis" after the [blue-billed Ruddy Duck (Oxyura jamaicensis)](https://en.wikipedia.org/wiki/Ruddy_duck). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Also note: Due to changes in the internal storage (#1530), databases created with this release wil require somewhat more disk space. This is transient as we are working hard to finalise the on-disk storage format.

Major changes:

Engine
 - #1666: External merge sort, #1580: Parallel scan of ordered result and #1561: Rework physical ORDER BY
 - #1520 & #1574: Window function computation parallelism
 - #1540: Add table functions that take a subquery parameter
 - #1533: Using vectors, instead of column chunks as lists
 - #1530: Store null values separate from main data in a Validity Segment

SQL
 - #1568: Positional Reference Operator `#1` etc.
 - #1671: `QUANTILE` variants and #1685: Temporal quantiles
 - #1695: New Timestamp Types `TIMESTAMP_NS`, `TIMESTAMP_MS` and `TIMESTAMP_NS`
 - #1647: Add support for UTC offset timestamp parsing to regular timestamp conversion
 - #1659: Add support for `USING` keyword in `DELETE` statement
 - #1638, #1663, #1621 & #1484: Many changes arount `ARRAY` syntax
 - #1610: Add support for `CURRVAL`
 - #1544: Add `SKIP` as an option to `READ_CSV` and `COPY`

APIs
 - #1525: Add loadable extensions support
 - #1711: Parallel Arrow Scans
 - #1569: Map-style UDFs for Python API
 - #1534: Extensible Replacement Scans & Automatic Pandas Scans and #1487: Automatically use parquet or CSV scan when using a table name that ends in `.parquet` or `.csv`
 - #1649: Add a QueryRelation object that can be used to convert a query directly into a relation object, #1665: Adding from_query to python api
 - #1550: Shell: Add support for Ctrl + arrow keys to linenoise, and make Ctrl+C terminate the current query instead of the process
 - #1514: Using `ALTREP` to speed up string column transfer to R
 - #1502: R: implementation of Rstudio connection-contract tab





# duckdb 0.2.5

This preview release of DuckDB is named "Falcata" after the Falcated Duck (Mareca falcata). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major Changes:

Engine
 - #1356: **Incremental Checkpointing**
 - #1422: Optimize Top N Implementation

SQL
 - #1406, #1372, #1387: Many, many new aggregate functions
 - #1460: `QUANTILE` aggregate variant that takes a list of quantiles &  #1346: Approximate Quantiles
 - #1461: `JACCARD`, #1441 `LEVENSHTEIN` & `HAMMING` distance  scalar function
 - #1370: `FACTORIAL` scalar function and ! postfix operator
 - #1363: `IS (NOT) DISTINCT FROM`
 - #1385: `LIST_EXTRACT` to get a single element from a list
 - #1361: Aliases in the `HAVING` clause (fixes issue #1358)
 - #1355: Limit clause with non constant values

APIs:
 - #1430 & #1424: **DuckDB WASM builds**
 - #1419: Exporting the appender api to C
 - #1408: Add blob support to C API
 - #1432,  #1459 & #1456: Progress Bar
 - #1440: Detailed profiler.






# duckdb 0.2.4

This preview release of DuckDB is named "Jubata" after the [Australian Wood Duck](https://en.wikipedia.org/wiki/Australian_wood_duck) (Chenonetta jubata). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:
SQL
 - #1231: Full Text Search extension
 - #1309: Filter Clause for Aggregates
 - #1195: `SAMPLE` Operator
 - #1244: `SHOW` select queries
 - #1301: `CHR` and `ASCII` functions & #1252: Add `GAMMA` and `LGAMMA` functions

Engine
 - #1211: (Mostly) Lock-Free Buffer Manager
 - #1325: Unsigned Integer Types Support
 - #1229: Filter Pull Up Optimizer
 - #1296: Optimizer that removes redundant `DELIM_GET` and `DELIM_JOIN` operators
 - #1219: `DATE`, `TIME` and `TIMESTAMP` rework: move to epoch format & microsecond support

Clients
 - #1287 and #1275: Improving JDBC compatibility
 - #1260: Rework client API and prepared statements, and improve DuckDB -> Pandas conversion
 - #1230: Add support for parallel scanning of pandas data frames
 - #1256: JNI appender
 - #1209: Write shell history to file when added to allow crash recovery, and fix crash when .importing file with invalid
 - #1204: Add support for blobs to the R API and #1202: Add blob support to the python api

Parquet
 - #1314: Refactor and nested types support for Parquet Reader



# duckdb 0.2.3

This preview release of DuckDB is named "Serrator" after the Red-breasted merganser (Mergus serrator). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:

SQL:
 - #1179: Interval Cleanup & Extended `INTERVAL` Syntax
 - #1147: Add exact `MEDIAN` and `QUANTILE` functions
 - #1129: Support scalar functions with `CREATE FUNCTION`
 - #1137: Add support for (`NOT`) `ILIKE`, and optimize certain types of `LIKE` expressions

Engine
 - #1160: Perfect Aggregate Hash Tables
 - #1133: Statistics Rework & Statistics Propagation
 - #1144: Common Aggregate Optimizer, #1143: CSE Optimizer and #1135: Optimizing expressions in grouping keys
 - #1138: Use predication in filters
 - #1071: Removing string null termination requirement

Clients
 - #1112: Add DuckDB node.js API
 - #1168: Add support for Pandas category types
 - #1181: Extend DuckDB::LibraryVersion() to output dev version in format `0.2.3-devXXX` & #1176: Python binding: Add module attributes for introspecting DuckDB version

Parquet Reader:
 - #1183: Filter pushdown for Parquet reader
 - #1167: Exporting Parquet statistics to DuckDB
 - #1162: Add support for compression codec in Parquet writer &  #1163: Add ZSTD Compression Code and add ZSTD codec as option for Parquet export
 - #1103: Add object cache and Parquet metadata cache











# duckdb 0.2.2

This is a preview release of DuckDB.
Starting from this release, releases get named as well. Names are chosen from species of ducks (of course). We start with "Clypeata".

*Note*: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the `EXPORT DATABASE` command with the old version followed by `IMPORT DATABASE` with the new version to migrate your data. See the [documentation](https://duckdb.org/docs/sql/statements/export) for details.

Binary builds are listed below. Feedback is very welcome. Major changes:

SQL
 - #1057: Add PRAGMA for enabling/disabling optimizer & extend output for query graph
 - #1048: Allow CTEs in subqueries (including CTEs themselves) and #987: Allow CTEs in CREATE VIEW statements
 - #1046: Prettify Explain/Query Profiler output
 - #1037: Support FROM clauses in UPDATE statements
 - #1006: STRING_SPLIT and STRING_SPLIT_REGEX SQL functions
 - #1000: Implement MD5 function
 - #936: Add GLOB support to Parquet & CSV readers
 - #899: Table functions information_schema_schemata() and information_schema_tables() and #903: Add table function information_schema_columns()

Engine
 - #984: Parallel grouped aggregations and #1045: Some performance fixes for aggregate hash table
 - #1008: Index Join
 - #991: Local Storage Rework: Per-morsel version info and flush intermediate chunks to the base tables
 - #906: Parallel scanning of single Parquet files and #982: ZSTD Support in Parquet library
 - #883: Unify Table Scans with Table Functions
 - #873: TPC-H Extension
 - #884: Remove NFC-normalization requirement for all data and add COLLATE NFC

Client
 - #1001: Dynamic Syntax Highlighting in Shell
 - #933: Upgrade shell.c to 3330000
 - #918: Add in support for Python datetime types in bindings
 - #950: Support dates and times output into arrow
 - #893: Support for Arrow NULL columns


# duckdb 0.2.1

This is a preview release of DuckDB. Binary builds are listed below. Feedback is very welcome. Major changes:

Engine
 - #770: Enable Inter-Pipeline Parallelism
 - #835: Type system updates with #779: `INTERVAL` Type,  #858: Fixed-precision `DECIMAL` types & #819: `HUGEINT` type
 - #790: Parquet write support

API
 - #866: Initial Arrow support
 - #809: Aggregate UDF support with #843: Generic `CreateAggregateFunction()` & #752: `CreateVectorizedFunction()` using only template parameters

SQL
 - #824: `strftime` and `strptime`
 - #858: `EXPORT DATABASE` and `IMPORT DATABASE`
 - #832: read_csv(_auto) improvements: optional parameters, configurable sample size, line number info



# duckdb 0.2.0

This is a preview release of DuckDB. Binary builds are listed below. Feedback is very welcome.

SQL:
 - #730: `FULL OUTER JOIN` Support
 - #732: Support for `NULLS FIRST`/`NULLS LAST`
 - #698: Add implementation of the `LEAST`/`GREATEST` functions
 - #772: Implement `TRIM` function and add optional second parameter to `RTRIM`/`LTRIM`/`TRIM`
 - #771: Extended Regex Options

Clients:
 - Python: #720: Making Pandas optional and add support for PyPy
 - C++: #712: C++ UDF API





# duckdb 0.1.9

This is a preview release of DuckDB. Binary are listed below. Feedback is very welcome. Major changes:
New [website](http://duckdb.org/) [woo-ho](https://www.youtube.com/watch?v=H9cmPE88a_0)!

Engine
 - #653: Parquet reader integration

SQL
 - #685: Case insensitive binding of column names
 - #662: add `EPOCH_MS` function and test cases

Clients
 - #681: JDBC Read-only mode for and #677 duplicate()` method to allow multiple connections to same database



# duckdb 0.1.8

This is a preview release of DuckDB. Feedback is very welcome.

SQL
 - SQL functions `IF` and `IFNULL` #644
 - SQL string functions `LEFT` #620 and `RIGHT` #631
 - #641: `BLOB` type support
 - #640: `LIKE` escape support

Clients
 - #627: Insertion support for Python relation API



# duckdb 0.1.7

This is the sixth preview release of DuckDB. Feedback is very welcome.
Binary builds are available as well.

SQL
- [Add / remove columns, change default values & column type](https://duckdb.org/docs/sql/statements/alter_table) #612
- [Collation support](https://duckdb.org/docs/sql/expressions/collations)
- CSV sniffer `READ_CSV_AUTO` for dialect, data type and header detection #582
- `SHOW` & `DESCRIBE` Tables #501
- String function `CONTAINS`  #488
- String functions `LPAD` / `RPAD`, `LTRIM` / `RTRIM`, `REPEAT`, `REPLACE` & `UNICODE` #597
- Bit functions `BIT_LENGTH`, `BIT_COUNT`, `BIT_AND`, `BIT_OR`, `BIT_XOR` & `BIT_AGG` #608

Engine
- `LIKE` optimization rules #559
- Adaptive filters in table scans #574
- ICU Extension for extended Collations & Extension Support #594
- Extended zone map support in scans #551
- Disallow NaN/INF in the system #541
- Use UTF Grapheme Cluster Breakers in Reverse and Shell #570

Clients
- Relation API for C++ #509 and Python #598
 - Java (TM) JDBC (R) Client for DuckDB #492 #520 #550



# duckdb 0.1.6

This is the fifth preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here: http://download.duckdb.org/alias/v0.1.6/

SQL
- #455 Table renames `ALTER TABLE tbl RENAME TO tbl2`
- #457 Nested list type can be created using `LIST` aggregation and unpacked with the new `UNNEST` operator
- #463 `INSTR` string function, #477 `PREFIX` string function, #480 `SUFFIX` string function

Engine
- #442 Optimized casting performance to strings
- #444 Variable return types for table-producing functions
- #453 Rework aggregate function interface
- #474 Selection vector rework
- #478 UTF8 NFC normalization of all incoming strings
- #482 Skipping table segments during scan based on min/max indices

Python client
- #451 `date` / `datetime` support
- #467 `description` field for cursor
- #473 Adding `read_only` flag to `connect`
- #481 Rewrite of Python API using `pybind11`

R client
- #468 Support for prepared statements in R client
- #479 Adding automatic CSV to table function `read_csv_duckdb`
- #483 Direct scan operator for R `data.frame` objects



# duckdb 0.1.5

This is the fourth preview release of DuckDB. Feedback is very welcome. Note: The v0.1.4 version was skipped because of a Python packaging issue.

Binary builds can be found here:
http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/

Major changes:
 - #409 Vector Overhaul
 - #423 Remove individual vector cardinalities
 - #418 `DATE_TRUNC` SQL function
 - #424 `REVERSE` SQL function
 - #416 Support for `SELECT table.* FROM table`
 - #414 STRUCT types in query execution
 - #431 Changed internal string representation
 - #433 Rename internal type `index_t` to `idx_t`
 - #439 Support for temporary structures in read-only mode
 - #440 Builds on Solaris & OpenBSD


*Note*: This release contains a bug in the Python API that leads to crashes when fetching strings to NumPy/Pandas #447 


# duckdb 0.1.3

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/

Major changes:
  * #388 Major updates to shell
  * #390 Unused Column & Column Lifetime Optimizers
  * #402 String and compound keys in indices/primary keys
  * #406 Adaptive reordering of filter expressions
  


# duckdb 0.1.2

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/6fcb5ef8e91dcb3c9b2c4ca86dab3b1037446b24/


# duckdb 0.1.1

This is the second preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/2e51e9bae7699853420851d3d2237f232fc2a9a8/


# duckdb 0.1.0

This is the first preview release of DuckDB. Feedback is very welcome.

Binary builds can be found here: http://download.duckdb.org/rev/c1cbc9d0b5f98a425bfb7edb5e6c59b5d10550e4/
